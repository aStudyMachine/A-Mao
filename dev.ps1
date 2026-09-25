# =====================================================================
# dev.ps1 — 源码调试唯一入口（A-Mao 后端单元）
#
# 注意：本文件含中文注释，必须保存为 UTF-8 with BOM 编码——Windows
#       PowerShell 5.1 会把无 BOM 的 UTF-8 按 ANSI 读取，中文直接
#       破坏语法解析。
#
# 定位：环境准备与调试启动指令完全收敛至本脚本。禁止手动安装依赖到
#       全局环境，禁止绕过本脚本直接启动。
#
# 本机私有配置：项目根 .env（不入库，模板 .env.example）+ scripts\
#       local-env.ps1 公共库（解析/注入/settings 优先级）。首次使用先跑
#       .\init.ps1 生成 .env 与 settings.xml；未配置 .env 时本脚本回退
#       PATH 工具链探测，行为与引入该机制之前一致。
#       前置依赖：PowerShell 7（阶段 2b 调试窗口宿主）——缺失即快速失败。
#
# 启动模块：由 -Module 显式指定（仓库内相对路径），脚本不绑定任何具
#       体模块——新增/删除启动模块无需改脚本；未指定或模块不存在即报
#       错并列出 amao-boot 下的可用模块。
#
# 单元形态：当前仅 backend（Java 后端，Maven 多模块单仓）。前端
#       Vue 3 工程建立后，在 $Units 数组追加 frontend 单元即可
#       （工具链 node、环境 node_modules、启动 npm run dev）。
#
# 启动形态：两段式——先「预备构建」把依赖链产物 install 进本地仓库
#       （前台快速失败），再在调试窗口对单模块 spring-boot:run。
#       不能用 `-pl <module> -am spring-boot:run` 一步到位：-am 会把根
#       项目纳入 reactor，直接目标先在根项目执行 → Unable to find a
#       suitable main class。test/prod 环境走 CI/CD（Linux），不在本
#       脚本范围。
#
# 纪律（为什么存在这些检查）：
#   1. 工具链必须解析到用户真实安装的持久版本，禁止使用 AI 沙箱/
#      临时环境——临时工具链的 home 指向会被轮换清理的 base，base
#      一换环境即坏死（潜伏故障，换机/换版本都不立刻发病）。
#   2. 环境就绪判据不能只看版本号：必须校验依赖目录真实完整，
#      "目录存在但缺关键文件"的空壳形态也要判不就绪并重建。
#   3. 重建统一走清空重建，禁止增量修补（修补出的环境带病运行）。
#      Maven 后端例外：依赖收敛在用户本地仓库，就绪重建走
#      mvn -U dependency:resolve，无需清空重建。
#
# 用法：
#   .\dev.ps1 -Module amao-boot/amao-boot-user-service                # 环境检查 + 启动该模块
#   .\dev.ps1 -Module amao-boot/amao-boot-user-service -Check         # 仅做环境检查，不启动
#   .\dev.ps1 -Module amao-boot/amao-boot-user-service -Unit backend  # 只启动指定单元（可多个：-Unit a,b）
#
#   -Module 必填：不传即报错并列出可用模块（本脚本不做任何模块的默认假设）。
# =====================================================================
param(
    [string]$Module,
    [switch]$Check,
    [string[]]$Unit
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot

# ---- 本机私有配置（.env）加载 ----
# 先于单元配置执行：工具链候选与 settings 解析都依赖它。.env 缺失时不注入
# 任何变量、也不报错，行为与引入本机制之前一致（未配置设备零改动可用）。
. (Join-Path $Root "scripts\local-env.ps1")
$script:LocalEnv = Import-LocalDevEnv -Root $Root

# 工具链候选：.env 提供了 JDK_HOME 时只认它——显式声明即不接受 PATH 里的
# 其他 JDK，避免多设备间版本漂移；未提供时回退 PATH 探测（与改造前一致）。
if ($script:LocalEnv.JdkHome -ne '') {
    $script:JavaCandidates = @((Join-Path $script:LocalEnv.JdkHome "bin\java.exe"))
} else {
    $script:JavaCandidates = @("java")
}

# ---- 模块解析（-Module 必填；脚本不绑定任何具体启动模块）----
function Get-AvailableModules {
    # 探测 amao-boot 下含 pom.xml 的子目录，仅用于报错时列出候选。
    $bootDir = Join-Path $Root "amao-boot"
    $mods = @()
    if (Test-Path $bootDir) {
        $mods = Get-ChildItem $bootDir -Directory |
            Where-Object { Test-Path (Join-Path $_.FullName "pom.xml") } |
            ForEach-Object { "amao-boot/$($_.Name)" }
    }
    if ($mods.Count -eq 0) { return "（未发现可用启动模块）" }
    return ($mods -join '、')
}

function Resolve-Module {
    param([string]$ModulePath)
    # 前置校验：参数缺失或模块不存在一律快速失败（并给出候选），避免
    # "环境检查通过、Maven 才报 reactor 找不到模块"的潜伏失败。
    if ([string]::IsNullOrWhiteSpace($ModulePath)) {
        throw "必须指定启动模块：-Module <模块路径>（仓库内相对路径，如 amao-boot/amao-boot-user-service）。可用模块：$(Get-AvailableModules)"
    }
    $modulePom = Join-Path (Join-Path $Root $ModulePath) "pom.xml"
    if (-not (Test-Path $modulePom)) {
        throw "启动模块不存在：$ModulePath（未找到 $modulePom）。可用模块：$(Get-AvailableModules)"
    }
    return $ModulePath
}

# ---- 单元配置（每栈一个单元；当前仅 backend）----
# 字段说明：
#   Name                 单元名（日志/报错标识，如 backend / frontend）
#   ToolchainCandidates  工具链候选解析顺序（本机配置的 JDK_HOME 优先，否则 PATH 探测）
#   ExpectedVersion      期望主版本（用于回读复核）
#   EnvDir               依赖环境目录（相对项目根；为空表示该单元无项目内依赖目录，跳过目录检查）
#   LockFile             依赖锁定文件（相对项目根）
#   PrepareTemplate      预备构建参数模板（{module} 由 -Module 代入；install 依赖链）
#   RunTemplate          调试启动参数模板（{module} 由 -Module 代入；单模块 run）
$Units = @(
    @{
        Name = "backend"
        ToolchainCandidates = $script:JavaCandidates
        ExpectedVersion = "25"
        EnvDir = ""
        LockFile = "pom.xml"
        # 预备构建：依赖链产物 install 进本地仓库（供单模块 run 解析兄弟模块 SNAPSHOT）
        PrepareTemplate = "-pl {module} -am install -DskipTests"
        # 调试启动：单模块 reactor，直接目标只命中本模块
        RunTemplate = "-pl {module} spring-boot:run"
    }
)

# ---- 单元筛选（-Unit 指定则只处理匹配项；未指定处理全部）----
if ($Unit -and $Unit.Count -gt 0) {
    $ActiveUnits = @()
    foreach ($name in $Unit) {
        $match = @($Units | Where-Object { $_.Name -eq $name })
        if ($match.Count -eq 0) {
            $available = ($Units | ForEach-Object { $_.Name }) -join ', '
            throw "未知单元名：$name（可用：$available）"
        }
        $ActiveUnits += $match[0]
    }
} else {
    $ActiveUnits = $Units
}

function Resolve-Toolchain {
    param([string[]]$Candidates, [string]$ExpectedVersion, [string]$UnitName)
    # 逐候选解析真实工具链，回读版本复核；版本不符或全部失败则明确报错退出。
    foreach ($candidate in $Candidates) {
        $resolved = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($resolved) {
            # 回读版本复核。注意：java -version 输出走 stderr，在
            # $ErrorActionPreference='Stop' 下用 PowerShell 的 2>&1 重定向
            # 会把 stderr 包装成 ErrorRecord 并直接抛 NativeCommandError
            # （PS 5.1 经典坑）；故经 cmd /c 合并，拿回纯文本。
            $versionOutput = (cmd /c "`"$($resolved.Source)`" -version 2>&1") | Out-String
            if ($versionOutput -match ('version "?' + [regex]::Escape($ExpectedVersion) + '\b')) {
                return $resolved.Source
            }
            Write-Host "  [$UnitName] 候选 $($resolved.Source) 版本不符（期望 $ExpectedVersion），继续下一候选..." -ForegroundColor DarkYellow
        }
    }
    throw "[$UnitName] 未找到版本 $ExpectedVersion 的工具链。候选：$($Candidates -join '、')。请核对 .env 的 JDK_HOME（或 PATH 中的 java）并安装 JDK $ExpectedVersion 后重试。"
}

# 注：settings.xml 的解析（-s 参数来源）已上移到 scripts\local-env.ps1 的
# Get-MavenSettingsArgs，由 dev.ps1 / build.ps1 / init.ps1 共用同一套优先级，
# 避免各入口各写一份而漂移（build.ps1 改造前就漏了 -s）。

function Test-EnvReady {
    param([string]$UnitName, [string]$EnvDir, [string]$LockFile)
    # 就绪判据：EnvDir 非空时目录必须存在；锁定文件必须存在。
    # Maven 后端 EnvDir 为空（依赖收敛在用户本地仓库），仅校验锁定文件。
    $lockPath = Join-Path $Root $LockFile
    if (-not (Test-Path $lockPath)) {
        Write-Host "  [$UnitName] 锁定文件缺失：$lockPath" -ForegroundColor DarkYellow
        return $false
    }
    if ($EnvDir -ne "") {
        $envPath = Join-Path $Root $EnvDir
        if (-not (Test-Path $envPath)) {
            Write-Host "  [$UnitName] 依赖目录缺失：$envPath" -ForegroundColor DarkYellow
            return $false
        }
    }
    return $true
}

function Ensure-Env {
    param([string]$UnitName, [string]$LockFile)
    # Maven 后端无项目内依赖目录可清空重建；就绪重建 = 强制刷新解析锁定依赖。
    # 统一走仓库自带 mvnw.cmd（Maven Wrapper），设备无需安装 Maven。
    Write-Host "==> [$UnitName] 环境不就绪，重建（mvnw -U dependency:resolve）..." -ForegroundColor Cyan
    Invoke-Expression "& '$Root\mvnw.cmd' $script:MvnSettingsArgs -f `"$(Join-Path $Root $LockFile)`" -U dependency:resolve"
    if ($LASTEXITCODE -ne 0) {
        throw "[$UnitName] 依赖重建失败：mvn -U dependency:resolve 退出码 $LASTEXITCODE"
    }
}

function Pause-IfInteractive {
    # 暂停包装必须调用真正的 Read-Host；禁止写成调用自身
    # （自递归只在错误分支触发，会冲掉真正的报错）。
    if ($Host.Name -eq "ConsoleHost" -and -not $env:CI) {
        Read-Host "按回车退出" | Out-Null
    }
}

try {
    # ---- 阶段 0：-Module 前置校验（先于任何有副作用的动作）----
    $Module = Resolve-Module -ModulePath $Module

    # ---- 阶段 0.5：解析 settings.xml 路径（-s）----
    # 优先级见 scripts\local-env.ps1::Get-MavenSettingsArgs（显式指定 > init 生成
    # > MAVEN_HOME\conf > 用户级 ~\.m2）。mvnw 不读 MAVEN_HOME\conf\settings.xml，
    # 必须靠 -s 显式指定（踩坑记录 通-10）。
    $script:MvnSettingsArgs = Get-MavenSettingsArgs -LocalEnv $script:LocalEnv -Root $Root
    if ($script:MvnSettingsArgs -eq '') {
        Write-Host "  提示：未找到 settings.xml，本次不带 -s（依赖落 Maven 默认仓库且无镜像加速）。" -ForegroundColor DarkYellow
        Write-Host "        执行 .\init.ps1 可生成带 localRepository 与镜像的 settings。" -ForegroundColor DarkYellow
    } else {
        Write-Host "==> settings：$script:MvnSettingsArgs" -ForegroundColor DarkGray
    }
    if ($script:LocalEnv.EnvFileExists) {
        Write-Host "==> 本机配置：$Root\.env" -ForegroundColor DarkGray
    } else {
        Write-Host "==> 未检测到 .env，回退 PATH 工具链探测；建议先执行 .\init.ps1 生成本机配置。" -ForegroundColor DarkYellow
    }

    # ---- 阶段 1：逐单元解析工具链 + 环境就绪检查/重建 ----
    # 循环变量禁止命名 $unit：与脚本参数 $Unit 同名（PowerShell 变量名大小写
    # 不敏感），会被参数的 [string[]] 类型约束强制转换，取不到哈希表字段。
    foreach ($activeUnit in $ActiveUnits) {
        $tool = Resolve-Toolchain -Candidates $activeUnit.ToolchainCandidates -ExpectedVersion $activeUnit.ExpectedVersion -UnitName $activeUnit.Name
        Write-Host "==> [$($activeUnit.Name)] 工具链：$tool" -ForegroundColor DarkGray
        if (-not (Test-EnvReady -UnitName $activeUnit.Name -EnvDir $activeUnit.EnvDir -LockFile $activeUnit.LockFile)) {
            Ensure-Env -UnitName $activeUnit.Name -LockFile $activeUnit.LockFile
        }
    }

    # ---- 阶段 1.5：调试窗口宿主（PowerShell 7）前置校验 ----
    # 阶段 2b 的调试窗口固定用 pwsh 7 起（见 acdfe15）；缺失时若交给
    # Start-Process，报错只会是笼统的「启动失败」，真因被埋掉，故前移。
    $script:PwshPath = Test-Pwsh7
    if (-not $script:PwshPath) {
        throw "未检测到 PowerShell 7（pwsh.exe）：dev.ps1 的调试窗口依赖它。`n  安装：winget install --id Microsoft.PowerShell --source winget`n  安装后重开终端再执行（PATH 需刷新）。"
    }
    Write-Host "==> 调试窗口宿主：$script:PwshPath" -ForegroundColor DarkGray

    if ($Check) {
        Write-Host "==> 全部单元环境就绪。" -ForegroundColor Green
        exit 0
    }

    # ---- 阶段 2：逐单元两段式启动；任一失败则停止全部已启动进程 ----
    $started = @()
    foreach ($activeUnit in $ActiveUnits) {
        # ---- 阶段 2a：预备构建（前台快速失败）——依赖链产物 install 进本地仓库 ----
        $prepareCommand = "& '$Root\mvnw.cmd' $script:MvnSettingsArgs $($activeUnit.PrepareTemplate.Replace('{module}', $Module))"
        Write-Host "==> [$($activeUnit.Name)] 预备构建（模块 $Module）：$prepareCommand" -ForegroundColor Cyan
        Invoke-Expression $prepareCommand
        if ($LASTEXITCODE -ne 0) {
            throw "[$($activeUnit.Name)] 预备构建失败（退出码 $LASTEXITCODE）：$prepareCommand"
        }

        # ---- 阶段 2b：调试窗口对单模块 spring-boot:run（日志与热停均在该窗口）----
        $runCommand = "& '$Root\mvnw.cmd' $script:MvnSettingsArgs $($activeUnit.RunTemplate.Replace('{module}', $Module))"
        Write-Host "==> [$($activeUnit.Name)] 启动源码调试（模块 $Module）：$runCommand" -ForegroundColor Cyan
        try {
            $cmd = '"' + $runCommand + '"'
            # 宿主用探测到的绝对路径（避免 PATH 差异导致命中不同版本）
            $proc = Start-Process -FilePath $script:PwshPath -ArgumentList @("-NoExit", "-Command", $cmd) -WorkingDirectory $Root -PassThru
            $started += $proc
            Write-Host "  [$($activeUnit.Name)] 已启动，PID=$($proc.Id)" -ForegroundColor DarkGray
        }
        catch {
            foreach ($p in $started) {
                try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch {}
            }
            throw "[$($activeUnit.Name)] 启动失败：$runCommand"
        }
    }

    Write-Host "==> 全部单元已启动（模块 $Module）。关闭对应调试窗口即停止；PID：$($started.Id -join ', ')" -ForegroundColor Green
    exit 0
}
catch {
    Write-Error $_
    Pause-IfInteractive
    exit 1
}
