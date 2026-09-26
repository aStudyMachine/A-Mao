# =====================================================================
# init.ps1 — 本机开发环境一次性初始化（A-Mao 后端单元）
#
# 注意：本文件含中文注释，必须保存为 UTF-8 with BOM 编码——Windows
#       PowerShell 5.1 会把无 BOM 的 UTF-8 按 ANSI 读取，中文直接
#       破坏语法解析（开发规范 §2）。
#
# 定位：本机开发环境的「判据 + 原子阶段」入口。**默认只读体检，执行需显式声明。**
#       四个原子阶段（可按需单选，互不隐式串联）：
#         Maven      : .env 读取 → 必填项 → JDK 校验 → 落点目录 → settings 渲染
#         Skills     : 跨 Agent 技能桥接（调用 .agents\setup_skills.ps1）
#         Middleware : WSL docker compose up -d → 等 healthy → 宿主端口可达性复核
#         Data       : 种子数据幂等导入（sql\init-data.sql）→ 数据层机械校验
#       阶段间前置条件由各阶段在动作前自行校验并给出"先做哪一步"的指引，
#       不做静默自动串联（关键动作前置校验，架构规范 §4.7）。
#
# 纪律（为什么存在这些检查）：
#   1. 只增不改：已存在的 settings.xml 一律不覆盖——里面可能含私服
#      凭据，静默覆盖是不可接受的破坏；不一致时退出码 2 交人工处置。
#   2. 生成给 Maven 解析的 XML 必须写「无 BOM 的 UTF-8」：PS 5.1 的
#      Set-Content -Encoding UTF8 会写 BOM，故统一走 .NET 的
#      UTF8Encoding($false)。
#   3. 不回显配置值：MAVEN_MIRROR_URL 可能内嵌凭据，只打印路径。
#   4. 必填项缺失即快速失败，不做静默回退——静默回落到 C 盘默认仓库
#      正是本次改造要消除的形态。
#   5. **默认动作只读**：最高频的问题是"现在环境对不对"，它不该有写盘/
#      起容器/导数据的代价；要执行必须显式（-Apply 或 -Stage）。
#   6. **流程用加法选择，不用 -Skip\* 减法开关**：减法开关随阶段数增长
#      变成组合爆炸，且等于把"流程顺序"固化进脚本；顺序该由调用方
#      （人或 Agent）决定，脚本只负责"每个阶段怎么做对"。
#   7. 种子数据必须由本脚本导入：sql\init-data.sql 本身幂等（先 DELETE
#      后 INSERT，可重复执行），但此前**没有任何调用点**——compose 只
#      挂载了 DDL，于是新设备"建表成功、库里无 admin"，症状表现为
#      HTTP 200 + 「用户名或密码错误」，把排查引向密码/权限/Nacos。
#   8. 中间件经 WSL 调用：本机 Docker 装在 WSL2 内，Windows 侧通常无
#      docker CLI；WSL 未起或 daemon 未启动时必须在此明确报错并给出
#      修复命令，不允许拖到 Maven/Spring 阶段才看到笼统失败。
#   9. 判据只采信当轮新鲜数据：容器健康与数据行数现查现判，不沿用
#      "上次跑通过"的结论（架构规范 §4.2）。
#  10. 技能桥接冲突（真实目录/其它链接占用）**不阻断**后续阶段：它只
#      影响 AI Agent 读取项目技能，与"环境可用"无关；报错并给出人工
#      处理指引即可，避免单个 junction 把整个初始化卡死。
#  11. **判据实现只此一处（含 scripts\local-env.ps1 共享库）**：Agent 要
#      复核环境，应调用本脚本的阶段或共享库的 Test-\* 函数，禁止另写一套
#      等价检查（架构规范 §4.1：同一判据复制两份必然漂移）。
#
# 用法：
#   .\init.ps1                          # 只读体检全链路（默认；无任何副作用）
#   .\init.ps1 -Apply                   # 执行全部四个阶段（幂等，可重复执行）
#   .\init.ps1 -Stage Middleware        # 只执行指定阶段（可多个：-Stage Maven,Data）
#   .\init.ps1 -Check                   # 与不传参数等价（显式写法，便于阅读）
#
# 退出码：0 成功；1 需用户动作（缺 .env / 必填项缺失 / JDK 不符）；
#         2 settings 已存在且内容不同（未做任何改动）；
#         3 环境不满足（执行模式下某阶段失败，或体检模式存在失败项）
#           —— 体检模式也会返回 3，便于 Agent/CI 机械判定。
# =====================================================================
param(
    [switch]$Check,
    [switch]$Apply,
    [ValidateSet('Maven', 'Skills', 'Middleware', 'Data')]
    [string[]]$Stage
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot

function ConvertTo-XmlText {
    param([string]$Value)
    # 先替换 & 再替换 < >，避免二次转义（路径含 & 时 XML 才合法）。
    return $Value.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')
}

function New-SettingsContent {
    param([string]$TemplatePath, [string]$MavenRepoLocal, [string]$MavenMirrorUrl)

    # 渲染模板：替换 localRepository 占位符；镜像段在未配置镜像时整段移除
    # （连同 BEGIN/END 标记），避免留下空 <url/> 被 Maven 解析报错。
    $content = [System.IO.File]::ReadAllText($TemplatePath)
    $content = $content.Replace('{{MAVEN_REPO_LOCAL}}', (ConvertTo-XmlText $MavenRepoLocal))
    if ([string]::IsNullOrWhiteSpace($MavenMirrorUrl)) {
        $content = [regex]::Replace($content, '(?s)<!--\s*BEGIN-MIRRORS.*?END-MIRRORS\s*-->', '')
    } else {
        $content = $content.Replace('{{MAVEN_MIRROR_URL}}', (ConvertTo-XmlText $MavenMirrorUrl))
    }
    return $content
}

# ===================== 中间件与种子阶段（阶段 6-8）=====================
# 常量唯一权威：docker\docker-compose.yml（改端口/账号须两侧同步并更新
# docs\配置与接口参考.md）。
$script:MwContainers       = @("amao-mysql", "amao-redis", "amao-nacos")
$script:MwMysqlUser        = "root"
$script:MwMysqlPwd         = "123456"
$script:MwDbName           = "a-mao"
$script:MwHealthyTimeoutSec = 180
$script:MwPollIntervalSec   = 5

function ConvertTo-BashSingleQuoted {
    param([string]$Value)
    # 包成 bash 单引号串并转义内部单引号。目的：让最终交给 wsl.exe 的
    # 整条命令**不含双引号**，从而完全绕开 Windows → wsl.exe 的参数引号
    # 解析（命令里含 && / < / > / % 时经 cmd /c 会被 cmd 自行解释，故本
    # 模块一律直调 wsl.exe，不经 cmd /c）。
    return "'" + $Value.Replace("'", "'\''") + "'"
}

function Get-WslPath {
    param([string]$WindowsPath)
    # 盘符路径 → WSL 的 /mnt/<盘符>/... 形态。无法映射（UNC 路径、已在
    # WSL 文件系统内等）返回空串，由调用方显式报错——禁止静默退化
    # （架构规范 §4.6）。
    if ($WindowsPath -match '^([A-Za-z]):[\\/](.*)$') {
        return "/mnt/" + $Matches[1].ToLower() + "/" + ($Matches[2] -replace '\\', '/')
    }
    return ''
}

function Invoke-WslBash {
    param([string]$BashCommand)
    # 统一 WSL 调用入口。要点：
    #   - 直调 wsl.exe（不经 cmd /c）：见 ConvertTo-BashSingleQuoted 注释。
    #   - 临时把 ErrorActionPreference 降为 Continue：native 命令的 stderr
    #     在 Stop 下会被包装成 NativeCommandError（PS 5.1 经典坑，与
    #     Test-JdkVersion 同因）。
    #   - 成败只看退出码：docker/mysql 的告警走 stderr（如
    #     "Using a password on the command line interface..."）不代表失败。
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = (& wsl.exe -e bash -c $BashCommand 2>&1 | Out-String)
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prevEap
    }
    return [pscustomobject]@{ Output = $output; ExitCode = $exitCode }
}

function Test-WslAvailable {
    # 判据须实际执行回读（echo 结果复核），不只看 wsl.exe 是否存在。
    $probe = Invoke-WslBash -BashCommand "echo WSL_OK"
    return ($probe.Output -match 'WSL_OK')
}

function Get-WslDockerIssue {
    # 返回空串 = WSL 内 docker 可用；否则返回一句话原因，供报错直接拼接。
    $probe = Invoke-WslBash -BashCommand "docker info --format '{{.ServerVersion}}'"
    if ($probe.ExitCode -eq 0) { return '' }
    if ($probe.Output -match 'command not found') { return "WSL 内未安装 docker CLI" }
    if ($probe.Output -match 'Cannot connect to the Docker daemon') { return "WSL 内 docker daemon 未启动" }
    return "docker 不可用（退出码 $($probe.ExitCode)）"
}

function Get-MiddlewareHealth {
    # 现查现判：容器名 → 健康状态（未创建的容器不会出现在结果里）。
    $fmt = ConvertTo-BashSingleQuoted "{{.Name}}={{.State.Health.Status}}"
    $names = $script:MwContainers -join ' '
    $probe = Invoke-WslBash -BashCommand "docker inspect --format $fmt $names 2>/dev/null"
    $map = @{}
    foreach ($line in ($probe.Output -split "`r?`n")) {
        $text = $line.Trim()
        if ($text -match '^/([^=]+)=(.*)$') { $map[$Matches[1]] = $Matches[2] }
    }
    return [pscustomobject]@{ Map = $map; Raw = $probe.Output }
}

function Format-MiddlewareStatus {
    param($Health)
    # 统一呈现形态，避免各处各写一份拼接而漂移。
    return (($script:MwContainers | ForEach-Object {
        $state = $Health.Map[$_]
        if (-not $state) { $state = '未创建' }
        "$_=$state"
    }) -join ' ')
}

function Wait-MiddlewareHealthy {
    param([int]$TimeoutSec)
    # 有界等待：轮询至全部 healthy 或超时（超时返回 $false 由调用方报错）。
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ($true) {
        $health = Get-MiddlewareHealth
        $unhealthy = @($script:MwContainers | Where-Object { $health.Map[$_] -ne 'healthy' })
        if ($unhealthy.Count -eq 0) { return $true }
        if ((Get-Date) -ge $deadline) { return $false }
        Write-Host "       等待中间件就绪（未就绪：$($unhealthy -join '、')）..." -ForegroundColor DarkGray
        Start-Sleep -Seconds $script:MwPollIntervalSec
    }
}

function Invoke-SeedImport {
    param([string]$WslRepoRoot)
    # 幂等导入种子数据。文件由 bash 侧重定向读入（不经 Windows → WSL 的
    # stdin 传递），避免编码转换引入静默损坏。
    $sqlPath = "$WslRepoRoot/sql/init-data.sql"
    $command = "docker exec -i amao-mysql mysql -u$script:MwMysqlUser -p$script:MwMysqlPwd < $(ConvertTo-BashSingleQuoted $sqlPath)"
    return Invoke-WslBash -BashCommand $command
}

function Get-ScalarCount {
    param([string]$Sql)
    # 执行只返回单个数字的查询；查询失败返回 $null（调用方据此判"失败"
    # 而不是把 0 当成"通过"——$null 与 0 语义不同，不可混用）。
    $db = ConvertTo-BashSingleQuoted $script:MwDbName
    $command = "docker exec amao-mysql mysql -u$script:MwMysqlUser -p$script:MwMysqlPwd -N -B -e $(ConvertTo-BashSingleQuoted $Sql) $db"
    $probe = Invoke-WslBash -BashCommand $command
    if ($probe.ExitCode -ne 0) { return $null }
    foreach ($line in ($probe.Output -split "`r?`n")) {
        $text = $line.Trim()
        if ($text -match '^\d+$') { return [int]$text }
    }
    return $null
}

function Pause-IfInteractive {
    # 暂停包装必须调用真正的 Read-Host；禁止写成调用自身（自递归只在
    # 错误分支触发，会冲掉真正的报错）。
    if ($Host.Name -eq "ConsoleHost" -and -not $env:CI) {
        Read-Host "按回车退出" | Out-Null
    }
}

# ===================== 模式与阶段选择 =====================
# 默认只读：不写文件、不起容器、不导数据。执行需显式（-Apply / -Stage）。
$script:AllStages = @('Maven', 'Skills', 'Middleware', 'Data')
# -Check 是"只读体检"的显式写法，与不传参数等价；与执行类参数互斥，避免
# "以为在体检、实际在写盘"的组合歧义。
if ($Check -and ($Apply -or $Stage)) {
    throw "-Check（只读体检）与 -Apply / -Stage（执行）互斥：请只选一种。"
}
$script:ReadOnly = (-not $Apply) -and (-not $Stage)
$script:SelectedStages = @()
if ($Stage) { $script:SelectedStages = @($Stage | Select-Object -Unique) }
elseif ($Apply) { $script:SelectedStages = $script:AllStages }
$script:IssueCount = 0

function Test-StageSelected {
    param([string]$Name)
    # 加法式选择：-Stage 未给且非只读（即 -Apply）时为全选；只读时不选任何
    # 执行动作（各阶段走"体检报告"分支）。
    return ($script:SelectedStages -contains $Name)
}

function Get-ModeLabel {
    if ($script:ReadOnly) { return '体检（只读，无副作用）' }
    if ($script:SelectedStages.Count -eq $script:AllStages.Count) { return '执行（全部阶段）' }
    return "执行（阶段：$($script:SelectedStages -join '、')）"
}

function Add-ReportedIssue {
    param([string]$Label, [string]$Message)
    # 体检模式：记为失败项并继续——体检的目标是给出全貌，不是死在第一项；
    # 执行模式：直接失败（失败即停，与既有契约一致）。
    if ($script:ReadOnly) {
        $lines = @($Message -split "`n")
        Write-Host "       [失败] ${Label}：$($lines[0])" -ForegroundColor Red
        # 首行给结论，其余行给"成因/自查/处置"——体检报告必须自足，否则拿到
        # 失败结论还要回去翻代码才知道怎么修。
        for ($i = 1; $i -lt $lines.Count; $i++) {
            Write-Host "              $($lines[$i].Trim())" -ForegroundColor Red
        }
        $script:IssueCount++
        return $false
    }
    throw $Message
}

try {
    . (Join-Path $Root "scripts\local-env.ps1")

    Write-Host "==> A-Mao 本机开发环境（$(Get-ModeLabel)）" -ForegroundColor Cyan
    if ($script:ReadOnly) {
        Write-Host "    只读体检：不写文件、不起容器、不导数据。要执行：-Apply（全部）或 -Stage <名>（按需）。" -ForegroundColor DarkGray
    }

    # ---- [env] 读取本机私有配置（.env）----
    # 判据：.env 是本机私有事实的唯一权威（开发环境搭建 §5），缺它无法判定任何路径类条件。
    $local = Import-LocalDevEnv -Root $Root
    $envFile = Join-Path $Root ".env"

    if (-not $local.EnvFileExists) {
        $example = Join-Path $Root ".env.example"
        if (-not (Test-Path -LiteralPath $example -PathType Leaf)) {
            throw "缺少 .env 与 .env.example：请确认仓库完整检出后再执行。"
        }
        if (-not $script:ReadOnly) {
            Copy-Item -LiteralPath $example -Destination $envFile
            Write-Host "  已由 .env.example 生成 .env。" -ForegroundColor Yellow
        }
        Write-Host "  请填写 $envFile 中的 JDK_HOME 与 MAVEN_REPO_LOCAL 后重试。" -ForegroundColor Yellow
        Write-Host "  逐项说明见 docs\开发环境搭建.md 与 .env.example 内注释。" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "  [env] 已读取本机配置：$envFile" -ForegroundColor DarkGray

    # ---- [jdk] 必填项 + JDK 校验（硬性条件：项目工具链锁定 JDK 25）----
    # 这一项无论选哪个阶段都执行：它是"硬性条件"里最基础的一条（开发规范 §1）。
    # 体检模式不因单项失败中断（要给出全貌），执行模式失败即停。
    $missing = @()
    if ($local.JdkHome -eq '') { $missing += 'JDK_HOME' }
    if ($local.MavenRepoLocal -eq '') { $missing += 'MAVEN_REPO_LOCAL' }
    if ($missing.Count -gt 0) {
        [void](Add-ReportedIssue -Label '必填项' -Message "必填项缺失：$($missing -join '、')。请在 $envFile 中补齐后重试。")
    }

    $jdkIssue = ''
    $javaExe = ''
    if ($local.JdkHome -eq '') {
        $jdkIssue = 'JDK_HOME 未配置，无法校验 JDK（见上方必填项）'
    } else {
        $javaExe = Join-Path $local.JdkHome "bin\java.exe"
        if (-not (Test-Path -LiteralPath $javaExe -PathType Leaf)) {
            $jdkIssue = "JDK_HOME 下未找到 bin\java.exe：$($local.JdkHome)（应填 JDK 安装根目录，不要带 \bin）"
        } elseif (-not (Test-JdkVersion -JavaExe $javaExe -ExpectedVersion "25")) {
            $jdkIssue = "JDK 版本不符：$javaExe 不是 25（项目工具链锁定 JDK 25，开发规范 §1）"
        }
    }
    if ($jdkIssue -ne '') {
        [void](Add-ReportedIssue -Label 'JDK 25' -Message $jdkIssue)
    } else {
        Write-Host "  [jdk] JDK 25 校验通过：$javaExe" -ForegroundColor DarkGray
    }

    # Maven 阶段的"写动作"（建目录 / 渲染 settings）只在"非只读且已选中 Maven"时发生；
    # 其余情况一律只报告现状——这保证只读模式真的零副作用（纪律 5）。
    $mavenActionable = (-not $script:ReadOnly) -and (Test-StageSelected 'Maven')
    if ((-not $script:ReadOnly) -and (-not $mavenActionable)) {
        Write-Host "  [maven] 未选中（-Stage 未含 Maven）：跳过建目录与 settings 写动作，仅报告现状" -ForegroundColor DarkYellow
    }

    # ---- [maven] 落点目录 ----
    $pendingDirs = @()
    foreach ($dir in @($local.MavenUserHome, $local.MavenRepoLocal)) {
        if ($dir -eq '') { continue }
        if (Test-Path -LiteralPath $dir) { continue }
        $pendingDirs += $dir
        if ($mavenActionable) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    if ($pendingDirs.Count -gt 0) {
        $verb = if ($mavenActionable) { "已创建" } else { "待创建" }
        Write-Host "  [maven] $verb 落点目录数 $($pendingDirs.Count)" -ForegroundColor DarkGray
    } else {
        Write-Host "  [maven] 落点目录均已存在" -ForegroundColor DarkGray
    }

    # ---- [maven] 渲染 settings.xml ----
    $template = Join-Path $Root "scripts\settings.template.xml"
    if (-not (Test-Path -LiteralPath $template -PathType Leaf)) {
        throw "缺少渲染模板：$template"
    }

    $target = ''
    $skipRender = $false
    if ($local.MavenSettings -ne '') {
        # 显式指定即完全托管：不生成、不探测，由用户自行维护。
        $target = $local.MavenSettings
        $skipRender = $true
        Write-Host "  [maven] 已配置 MAVEN_SETTINGS，跳过生成（由你自行维护）：$target" -ForegroundColor DarkGray
    } else {
        if ($local.MavenUserHome -ne '') {
            $target = Join-Path $local.MavenUserHome "settings.xml"
        } elseif ($env:USERPROFILE) {
            $target = Join-Path $env:USERPROFILE ".m2\settings.xml"
            Write-Host "  提示：未配置 MAVEN_USER_HOME，settings 将落在用户主目录（C 盘）；" -ForegroundColor DarkYellow
            Write-Host "        建议在 .env 中配置 MAVEN_USER_HOME，连同分发包一起移出 C 盘。" -ForegroundColor DarkYellow
        } else {
            throw "无法定位 settings.xml 落点：请在 .env 配置 MAVEN_USER_HOME 或 MAVEN_SETTINGS。"
        }
    }

    if (-not $skipRender) {
        $content = New-SettingsContent -TemplatePath $template -MavenRepoLocal $local.MavenRepoLocal -MavenMirrorUrl $local.MavenMirrorUrl

        if (Test-Path -LiteralPath $target -PathType Leaf) {
            $existing = [System.IO.File]::ReadAllText($target)
            if ($existing -eq $content) {
                Write-Host "  [maven] settings 已就绪（与模板渲染结果一致）：$target" -ForegroundColor Green
            } elseif ($script:ReadOnly) {
                # 体检模式不在此处退出：把它记为失败项并继续，其余判据照常给出。
                [void](Add-ReportedIssue -Label 'settings' -Message "settings 已存在且内容不同（未做任何改动）：$target。该文件可能含既有私服凭据，故不覆盖；处置：备份后删除该文件再重跑 -Apply，或手工把 localRepository 改为 $($local.MavenRepoLocal)")
            } else {
                Write-Host "  [maven] settings 已存在且内容不同，未做任何改动：$target" -ForegroundColor Yellow
                Write-Host "        该文件可能含既有私服凭据，故不覆盖；如需采用本脚本版本，" -ForegroundColor Yellow
                Write-Host "        请先备份并删除该文件后重跑，或手工把 localRepository 改为：" -ForegroundColor Yellow
                Write-Host "        $($local.MavenRepoLocal)" -ForegroundColor Yellow
                Pause-IfInteractive
                exit 2
            }
        } elseif (-not $mavenActionable) {
            Write-Host "  [maven] （未动作）将生成 settings：$target" -ForegroundColor DarkGray
        } else {
            [System.IO.File]::WriteAllText($target, $content, [System.Text.UTF8Encoding]::new($false))
            Write-Host "  [maven] 已生成 settings（无 BOM UTF-8）：$target" -ForegroundColor Green
        }
    }

    # ---- 前置探测：调试窗口宿主依赖（PowerShell 7）----
    # 不阻断 Maven 链路，但技能桥接阶段（[5/8]）以它为宿主，缺失时该阶段
    # 跳过并告警；dev.ps1 阶段 2b 的调试窗口同样依赖它。
    $pwshPath = Test-Pwsh7
    if ($pwshPath) {
        Write-Host "       PowerShell 7 已就绪：$pwshPath" -ForegroundColor DarkGray
    } else {
        Write-Host "       未检测到 PowerShell 7（pwsh.exe），技能桥接与 dev.ps1 调试窗口需要它：" -ForegroundColor Yellow
        Write-Host "       winget install --id Microsoft.PowerShell --source winget" -ForegroundColor Yellow
    }

    # ---- [skills] 跨 Agent 技能桥接 ----
    $currentStage = '技能桥接'
    $skillsStatus = '未选中'
    if ($script:ReadOnly) {
        # 委托 setup_skills.ps1 -Check 做判定：桥接状态的判据只有那一处实现，
        # 这里只负责转述它的结论（架构规范 §4.1，纪律 11）。
        if (-not $pwshPath) {
            Write-Host "  [skills] （体检）无法判定：缺少 PowerShell 7 宿主（见上方安装命令）" -ForegroundColor Yellow
            $skillsStatus = '无法判定'
        } else {
            $setupScript = Join-Path $Root ".agents\setup_skills.ps1"
            & $pwshPath -NoProfile -File $setupScript -Check | Out-Host
            if ($LASTEXITCODE -eq 2) {
                # 与执行模式一致：冲突只告警、不计失败项（纪律 10）。
                $skillsStatus = '冲突（需人工）'
            } else {
                $skillsStatus = '体检（见上方逐项）'
            }
        }
    } elseif (-not (Test-StageSelected 'Skills')) {
        Write-Host "  [skills] 未选中（-Stage 未含 Skills）：跳过" -ForegroundColor DarkYellow
    } elseif (-not $pwshPath) {
        Write-Host "  [5/8] 技能桥接：跳过（缺少 PowerShell 7 宿主，见上方安装命令）" -ForegroundColor Yellow
    } else {
        # 必须子进程调用：setup_skills.ps1 内部使用 exit，直接 & 调用会终止本会话。
        $setupScript = Join-Path $Root ".agents\setup_skills.ps1"
        if (-not (Test-Path -LiteralPath $setupScript -PathType Leaf)) {
            throw "缺少技能桥接脚本：$setupScript（请确认仓库完整检出）"
        }
        & $pwshPath -NoProfile -File $setupScript | Out-Host
        if ($LASTEXITCODE -ne 0) {
            # 有意不阻断（纪律 8）：junction 冲突只影响 AI Agent 读取技能，
            # 与"环境可用"无关，报错并给人工处理指引即可。
            Write-Host "  [5/8] 技能桥接未完全成功（退出码 $LASTEXITCODE）：冲突项需人工处理（见上方逐项状态），不影响后续阶段。" -ForegroundColor Red
            $skillsStatus = '冲突（需人工）'
        } else {
            $skillsStatus = '完成'
        }
    }

    # ---- [middleware] 开发中间件就绪（WSL + docker compose）----
    $currentStage = '中间件就绪'
    $mwStatus = '未选中'
    $wslRepoRoot = Get-WslPath $Root
    # 端口配置自洽性（结构判据，不需要 WSL/容器）：先拦配置错误，再谈运行时。
    $mwPortIssue = Get-MiddlewarePortConfigIssue
    $effectivePorts = Get-MiddlewareEffectivePorts
    if ((-not $script:ReadOnly) -and (-not (Test-StageSelected 'Middleware'))) {
        Write-Host "  [middleware] 未选中（-Stage 未含 Middleware）：跳过" -ForegroundColor DarkYellow
    } elseif ($mwPortIssue -ne '') {
        [void](Add-ReportedIssue -Label '中间件端口配置' -Message $mwPortIssue)
        $mwStatus = '不可判定'
    } elseif ($wslRepoRoot -eq '') {
        [void](Add-ReportedIssue -Label '中间件' -Message "无法把仓库路径映射到 WSL：$Root。本脚本仅支持盘符路径（如 D:\dev\A-Mao）；若仓库位于 WSL 文件系统内，请在 WSL 中直接执行 docker compose up -d。")
        $mwStatus = '不可判定'
    } elseif (-not (Test-WslAvailable)) {
        [void](Add-ReportedIssue -Label '中间件' -Message "未检测到可用的 WSL：本项目中间件（MySQL/Redis/Nacos）运行在 WSL2 内。`n  安装：wsl --install，随后按 docs\开发环境搭建.md §3.1 执行。")
        $mwStatus = '不可判定'
    } else {
        $dockerIssue = Get-WslDockerIssue
        if ($dockerIssue -ne '') {
            [void](Add-ReportedIssue -Label '中间件' -Message "WSL 内 docker 不可用：$dockerIssue。`n  修复命令：wsl -u root service docker start`n  尚未安装 docker：见 docs\开发环境搭建.md §3.1 步骤 ③")
            $mwStatus = '不可判定'
        } elseif ($script:ReadOnly) {
            Write-Host "  [middleware] （体检）容器：$(Format-MiddlewareStatus (Get-MiddlewareHealth))" -ForegroundColor DarkGray
            $unreachableCheck = Get-UnreachableMiddleware
            if ($unreachableCheck.Count -gt 0) {
                $detail = ($unreachableCheck | ForEach-Object { "$($_.Name)(端口 $($_.Port))" }) -join "、"
                [void](Add-ReportedIssue -Label '中间件宿主可达性' -Message "容器 healthy 但宿主不可达：$detail。`n  成因：WSL2 localhost 转发需 Windows 侧绑定该端口，WinNAT/Hyper-V 动态保留区间会吞掉端口（踩坑 通-17；区间随重启变化）。`n  自查：netsh interface ipv4 show excludedportrange protocol=tcp`n  处置：把被吞端口改到区间外，并三处同步——docker\docker-compose.yml 的 ports、对应 boot 模块的 application.yaml、docs\开发环境搭建.md")
                $mwStatus = '体检（宿主不可达）'
            } else {
                Write-Host "       [通过] 中间件宿主可达性：MySQL=$($effectivePorts['MYSQL_HOST_PORT']) / Redis=$($effectivePorts['REDIS_HOST_PORT']) / Nacos=$($effectivePorts['NACOS_HTTP_PORT']) / gRPC=$($effectivePorts['NACOS_GRPC_PORT']) 全部可达" -ForegroundColor DarkGray
                $mwStatus = '体检'
            }
        } else {
            # 生成 docker\.env（compose 在项目目录自动加载）：让 compose、判据与 Spring
            # 三方拿到同一组显式端口值，消掉"compose 的 ${VAR:-默认}"这条第二来源。
            # 必须是 LF 行尾（Linux 侧 compose 读它），故不用 Set-Content（踩坑 通-13 同源）。
            [System.IO.File]::WriteAllText((Join-Path $Root "docker\.env"), (New-MiddlewareComposeEnvContent), [System.Text.UTF8Encoding]::new($false))
            Write-Host "  [middleware] 已生成 docker\.env（MySQL=$($effectivePorts['MYSQL_HOST_PORT']) / Redis=$($effectivePorts['REDIS_HOST_PORT']) / Nacos=$($effectivePorts['NACOS_HTTP_PORT']) gRPC=$($effectivePorts['NACOS_GRPC_PORT'])）" -ForegroundColor DarkGray
            Write-Host "  [middleware] 启动中间件（wsl docker compose up -d；端口有变会重建容器）..." -ForegroundColor DarkGray
            $up = Invoke-WslBash -BashCommand "cd $(ConvertTo-BashSingleQuoted "$wslRepoRoot/docker") && docker compose up -d"
            if ($up.ExitCode -ne 0) {
                throw "中间件启动失败（退出码 $($up.ExitCode)）。`n$($up.Output)`n  排查：wsl -e bash -c `"cd '$wslRepoRoot/docker' && docker compose logs --tail 50`""
            }
            if (-not (Wait-MiddlewareHealthy -TimeoutSec $script:MwHealthyTimeoutSec)) {
                throw "中间件在 $($script:MwHealthyTimeoutSec)s 内未全部 healthy：$(Format-MiddlewareStatus (Get-MiddlewareHealth))。`n  排查：wsl -e bash -c `"cd '$wslRepoRoot/docker' && docker compose logs --tail 50`"`n  提示：WSL 重启后需先执行 wsl -u root service docker start"
            }
            # 容器 healthy 只说明"WSL 内服务起来了"，**不等于**"Windows 侧的应用
            # 连得上"：WSL2 的 localhost 转发要求 Windows 能绑定该端口，而
            # WinNAT/Hyper-V 动态保留区间会静默吞掉端口（踩坑 通-9）。此处做宿主
            # 可达性复核，把"healthy 但不可达"这种表面就绪挡在初始化阶段，
            # 而不是留给登录时的 500。
            $unreachable = Get-UnreachableMiddleware
            if ($unreachable.Count -gt 0) {
                $detail = ($unreachable | ForEach-Object { "$($_.Name)(端口 $($_.Port))" }) -join "、"
                throw "中间件容器 healthy 但**宿主不可达**：$detail。`n  成因：WSL2 localhost 转发需 Windows 侧绑定该端口，WinNAT/Hyper-V 动态保留区间会吞掉端口（踩坑 通-9）。`n  自查：netsh interface ipv4 show excludedportrange protocol=tcp（核对目标端口是否落在区间内）`n  处置：把被吞的宿主端口改到区间外，并**三处同步**——docker\docker-compose.yml 的 ports 映射、对应 boot 模块的 application.yaml、docs\开发环境搭建.md；改完重跑本脚本。"
            }
            $mwStatus = '就绪'
            Write-Host "       中间件就绪（容器 healthy + 宿主可达）：$(Format-MiddlewareStatus (Get-MiddlewareHealth))；端口 MySQL=$($effectivePorts['MYSQL_HOST_PORT']) / Redis=$($effectivePorts['REDIS_HOST_PORT']) / Nacos=$($effectivePorts['NACOS_HTTP_PORT'])" -ForegroundColor DarkGray
        }
    }

    # ---- [data] 种子数据幂等导入 ----
    # sql\init-data.sql 自带 DELETE 清理段，任何卷状态都可安全重复执行。
    # 适用性前置校验（架构规范 §4.7）：导入与校验都依赖中间件容器；未就绪时
    # 明确指引"先做哪一步"，不静默自动串联（纪律 6）。
    $currentStage = '种子数据导入'
    $seedStatus = '未选中'
    $dataInScope = $script:ReadOnly -or (Test-StageSelected 'Data')
    if ($dataInScope) {
        $mwHealth = Get-MiddlewareHealth
        $notHealthy = @($script:MwContainers | Where-Object { $mwHealth.Map[$_] -ne 'healthy' })
        if ($notHealthy.Count -gt 0) {
            [void](Add-ReportedIssue -Label '数据阶段前置' -Message "数据阶段需要中间件容器就绪，当前未就绪：$(Format-MiddlewareStatus $mwHealth)。`n  先执行：.\init.ps1 -Stage Middleware（或 .\init.ps1 -Apply 全跑）")
            $seedStatus = '不可判定'
        } elseif ($script:ReadOnly) {
            $adminNow = Get-ScalarCount "select count(*) from t_sys_user where username='admin'"
            if ($null -eq $adminNow) {
                Write-Host "  [data] （体检）种子现状：查询失败" -ForegroundColor DarkYellow
            } else {
                Write-Host "  [data] （体检）种子现状：t_sys_user(admin)=$adminNow（期望 1）" -ForegroundColor DarkGray
            }
            $seedStatus = '体检'
        } else {
            $import = Invoke-SeedImport -WslRepoRoot $wslRepoRoot
            if ($import.ExitCode -ne 0) {
                throw "种子数据导入失败（退出码 $($import.ExitCode)）。`n$($import.Output)`n  文件：sql\init-data.sql（幂等，可重复执行）"
            }
            Write-Host "  [data] 种子数据已同步（sql\init-data.sql，幂等：先清理后写入）" -ForegroundColor DarkGray
            $seedStatus = '完成'
        }
    } else {
        Write-Host "  [data] 未选中（-Stage 未含 Data）：跳过" -ForegroundColor DarkYellow
    }

    # ---- [data] 数据层机械校验（现查现判，不采信缓存）----
    # 判据见 docs\开发环境搭建.md §4「硬性条件」；服务启动后才能验的项（端口
    # 监听、端到端登录）不在此假装验证，由汇总处打印现成命令。
    $currentStage = '数据层校验'
    if ($dataInScope -and $seedStatus -ne '不可判定') {
        $checks = @(
            @{ Name   = '建表：t_sys_* 表数 = 7'
               Sql    = "select count(*) from information_schema.tables where table_schema='$script:MwDbName' and table_name like 't_sys\_%'"
               Expect = 7
               Hint   = 'DDL 仅在数据卷首次创建时执行；需重建时：cd docker; docker compose down -v 后重跑 .\init.ps1 -Apply（会清空数据）' },
            @{ Name   = '种子：admin 账号可用（status=1 且 deleted=0）'
               Sql    = "select count(*) from t_sys_user where username='admin' and status=1 and deleted=0"
               Expect = 1
               Hint   = '种子 SQL 见 sql\init-data.sql（由本脚本 [data] 阶段导入）' },
            @{ Name   = '种子：demo_status 启用字典值 = 2'
               Sql    = "select count(*) from t_sys_dict_value where dict_key='demo_status' and status=1"
               Expect = 2
               Hint   = '种子 SQL 见 sql\init-data.sql（由本脚本 [data] 阶段导入）' }
        )
        $failed = @()
        # 注：循环变量禁止命名为 $check——它与脚本参数 [switch]$Check 同名
        # （PowerShell 变量名大小写不敏感），把哈希表元素赋给它会被参数的
        # [switch] 类型约束强制转换并抛「无法将 Hashtable 转换为 SwitchParameter」。
        # 同因先例见 dev.ps1 的 $unit/$Unit（踩坑记录 通-5，此处为同类第二次出现）。
        foreach ($item in $checks) {
            $got = Get-ScalarCount $item.Sql
            if ($got -eq $item.Expect) {
                Write-Host "       [通过] $($item.Name)" -ForegroundColor DarkGray
            } else {
                $shown = '查询失败'
                if ($null -ne $got) { $shown = $got }
                Write-Host "       [失败] $($item.Name)：期望 $($item.Expect)，实际 $shown" -ForegroundColor Red
                $failed += "$($item.Name)（$($item.Hint)）"
            }
        }
        if ($failed.Count -gt 0) {
            [void](Add-ReportedIssue -Label '数据层校验' -Message "数据层校验未通过（$($failed.Count) 项）：`n  - $($failed -join "`n  - ")")
        } else {
            Write-Host "  [data] 数据层校验通过（建表 + 种子）" -ForegroundColor DarkGray
        }
    }

    # ---- 汇总与下一步 ----
    Write-Host ""
    if ($script:ReadOnly) {
        if ($script:IssueCount -gt 0) {
            Write-Host "==> 体检完成：$($script:IssueCount) 项未通过（详见上方 [失败] 行）" -ForegroundColor Red
        } else {
            Write-Host "==> 体检完成：硬性条件全部满足（未写文件、未起容器、未导数据）" -ForegroundColor Green
        }
        Write-Host "  要执行（写盘 / 起容器 / 导数据）：.\init.ps1 -Apply" -ForegroundColor Cyan
        Write-Host "  或按需只做某几段：.\init.ps1 -Stage <Maven|Skills|Middleware|Data>（可逗号并列）" -ForegroundColor DarkGray
    } else {
        Write-Host "==> 执行完成：$(Get-ModeLabel)" -ForegroundColor Green
    }
    Write-Host "  依赖仓库 : $($local.MavenRepoLocal)" -ForegroundColor DarkGray
    if ($local.MavenUserHome -ne '') {
        Write-Host "  分发包   : $($local.MavenUserHome)\wrapper\dists" -ForegroundColor DarkGray
    } else {
        Write-Host "  分发包   : $env:USERPROFILE\.m2\wrapper\dists（未配置 MAVEN_USER_HOME，仍在 C 盘）" -ForegroundColor DarkGray
    }
    if ($target -ne '') { Write-Host "  settings : $target" -ForegroundColor DarkGray }
    Write-Host "  技能桥接 : $skillsStatus" -ForegroundColor DarkGray
    Write-Host "  中间件   : $mwStatus" -ForegroundColor DarkGray
    Write-Host "  种子数据 : $seedStatus" -ForegroundColor DarkGray

    Write-Host ""
    Write-Host "  下一步：" -ForegroundColor Cyan
    Write-Host "    1) 构建验证   : .\mvnw.cmd -s '$target' -B verify"
    Write-Host "    2) 源码调试   : .\dev.ps1 -Module amao-boot/amao-boot-user-service"
    Write-Host "    3) IDEA 同步  : Settings → Build Tools → Maven → User settings file 指向上面 settings；" -ForegroundColor DarkGray
    Write-Host "                    Local repository 留空（随 settings 的 localRepository 生效）" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  端到端校验（双服务都启动后执行；判据见 docs\开发环境搭建.md §4 第 11 条）：" -ForegroundColor Cyan
    Write-Host '    登录：Invoke-RestMethod -Method Post -Uri http://127.0.0.1:9101/api/auth/login -ContentType application/json -Body ''{"username":"admin","password":"123456"}''' -ForegroundColor DarkGray
    Write-Host '    字典：$t = (Invoke-RestMethod -Method Post -Uri http://127.0.0.1:9101/api/auth/login -ContentType application/json -Body ''{"username":"admin","password":"123456"}'').data.tokenValue' -ForegroundColor DarkGray
    Write-Host '          Invoke-RestMethod -Method Post -Uri http://127.0.0.1:9100/api/dict/listDictValues -ContentType application/json -Headers @{Authorization = "Bearer $t"} -Body ''{"dictKey":"demo_status"}''' -ForegroundColor DarkGray

    # 旧仓库处理提示：仅在 C 盘存在既有仓库、且与本次配置的仓库不同时给出。
    # 提示按目标仓库「是否已有内容」分流——目标为空（新设备）适合整体搬走；
    # 目标已是大仓库时再 /MOVE 只做无谓合并，故改为「先比对再决定删源」。
    # 前置：MAVEN_REPO_LOCAL 非空——体检模式下必填项可能缺失，空值会让
    # Test-Path/Get-ChildItem 的 -LiteralPath 参数绑定直接报错。
    if ($env:USERPROFILE -and $local.MavenRepoLocal -ne '') {
        $legacyRepo = Join-Path $env:USERPROFILE ".m2\repository"
        $targetRepo = $local.MavenRepoLocal
        if ((Test-Path -LiteralPath $legacyRepo) -and ($legacyRepo.TrimEnd('\') -ine $targetRepo.TrimEnd('\'))) {
            $targetHasContent = @(Get-ChildItem -LiteralPath $targetRepo -Force -Directory -ErrorAction SilentlyContinue).Count -gt 0
            Write-Host ""
            if ($targetHasContent) {
                Write-Host "  检测到 C 盘既有仓库，且配置的仓库已有内容：" -ForegroundColor DarkYellow
                Write-Host "    C 盘：$legacyRepo" -ForegroundColor DarkYellow
                Write-Host "    目标：$targetRepo" -ForegroundColor DarkYellow
                Write-Host "  若目标仓库已含所需依赖，直接删除 C 盘那份即可（勿盲目 /MOVE 合并）：" -ForegroundColor DarkYellow
                Write-Host "    Remove-Item `"$legacyRepo`" -Recurse -Force" -ForegroundColor DarkYellow
                Write-Host "  不确定时先比对两边顶层目录：名称都出现在目标仓库才可删" -ForegroundColor DarkYellow
            } else {
                Write-Host "  检测到 C 盘既有仓库，目标仓库为空，可整体搬走以免重新下载：" -ForegroundColor DarkYellow
                Write-Host "    robocopy `"$legacyRepo`" `"$targetRepo`" /MOVE /E" -ForegroundColor DarkYellow
            }
        }
    }

    # 退出码：体检模式也把"存在未通过项"表达为 3，便于 Agent/CI 机械判定，
    # 不必去解析输出文本。
    if ($script:IssueCount -gt 0) { exit 3 }
    exit 0
}
catch {
    # catch 内必须先降 ErrorActionPreference：EAP=Stop 下 Write-Error 自身会抛
    # 终止性错误，后面的退出码判定被整段跳过，脚本会以默认码 1 结束（退出码
    # 契约失效）。这与 Test-JdkVersion 里"native stderr 在 Stop 下变
    # NativeCommandError"是同一条坑的不同侧面。
    $ErrorActionPreference = 'Continue'

    # 报错必须能定位到脚本行：只打印异常本身时看不出是哪个阶段、哪条语句
    # 失败，排查只能靠猜（与「异常现场自落盘」同一动机）。
    $stageLabel = '前置（env / JDK / Maven）'
    if ($currentStage) { $stageLabel = $currentStage }
    $activity = $_.CategoryInfo.Activity
    if ($_.CategoryInfo.TargetName) { $activity = "$activity → $($_.CategoryInfo.TargetName)" }
    Write-Host ""
    Write-Host "==> 初始化失败（阶段：$stageLabel）" -ForegroundColor Red
    Write-Host "  出错位置：init.ps1:$($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host "  失败命令：$activity" -ForegroundColor Red
    Write-Host "  出错语句：$(($_.InvocationInfo.Line).Trim())" -ForegroundColor DarkGray
    Write-Host "  原因    ：$($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.InvocationInfo.PositionMessage -ForegroundColor DarkGray
    Write-Error $_
    Pause-IfInteractive
    # 退出码契约：中间件/种子/数据阶段失败 → 3；其余需用户动作 → 1。
    if ($stageLabel -in @('中间件就绪', '种子数据导入', '数据层校验')) { exit 3 }
    exit 1
}
