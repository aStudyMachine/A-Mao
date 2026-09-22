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
# 单元形态：当前仅 backend（Java 后端，Maven 多模块单仓）。前端
#       Vue 3 工程建立后，在 $Units 数组追加 frontend 单元即可
#       （工具链 node、环境 node_modules、启动 npm run dev）。
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
#   .\dev.ps1           # 环境检查 + 启动源码调试
#   .\dev.ps1 -Check    # 仅做环境检查，不启动
# =====================================================================
param(
    [switch]$Check
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot

# ---- 单元配置（每栈一个单元；当前仅 backend）----
# 字段说明：
#   Name                 单元名（日志/报错标识，如 backend / frontend）
#   ToolchainCandidates  工具链候选解析顺序（真实持久安装路径）
#   ExpectedVersion      期望主版本（用于回读复核）
#   EnvDir               依赖环境目录（相对项目根；为空表示该单元无项目内依赖目录，跳过目录检查）
#   LockFile             依赖锁定文件（相对项目根）
#   StartCommand         源码调试启动命令
$Units = @(
    @{
        Name = "backend"
        ToolchainCandidates = @("java")
        ExpectedVersion = "25"
        EnvDir = ""
        LockFile = "pom.xml"
        StartCommand = ".\mvnw.cmd -pl amao-boot/amao-boot-example -am spring-boot:run"
    }
)

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
    throw "[$UnitName] 未找到版本 $ExpectedVersion 的工具链，请先安装或补充 dev.ps1 中的候选列表。"
}

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
    Invoke-Expression "& '$Root\mvnw.cmd' -f `"$(Join-Path $Root $LockFile)`" -U dependency:resolve"
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
    # ---- 阶段 1：逐单元解析工具链 + 环境就绪检查/重建 ----
    foreach ($unit in $Units) {
        $tool = Resolve-Toolchain -Candidates $unit.ToolchainCandidates -ExpectedVersion $unit.ExpectedVersion -UnitName $unit.Name
        Write-Host "==> [$($unit.Name)] 工具链：$tool" -ForegroundColor DarkGray
        if (-not (Test-EnvReady -UnitName $unit.Name -EnvDir $unit.EnvDir -LockFile $unit.LockFile)) {
            Ensure-Env -UnitName $unit.Name -LockFile $unit.LockFile
        }
    }

    if ($Check) {
        Write-Host "==> 全部单元环境就绪。" -ForegroundColor Green
        exit 0
    }

    # ---- 阶段 2：逐单元并行启动调试进程；任一失败则停止全部已启动进程 ----
    $started = @()
    foreach ($unit in $Units) {
        Write-Host "==> [$($unit.Name)] 启动源码调试：$($unit.StartCommand)" -ForegroundColor Cyan
        try {
            $cmd = '"' + $unit.StartCommand + '"'
            $proc = Start-Process -FilePath "powershell.exe" -ArgumentList @("-NoExit", "-Command", $cmd) -WorkingDirectory $Root -PassThru
            $started += $proc
            Write-Host "  [$($unit.Name)] 已启动，PID=$($proc.Id)" -ForegroundColor DarkGray
        }
        catch {
            foreach ($p in $started) {
                try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch {}
            }
            throw "[$($unit.Name)] 启动失败：$($unit.StartCommand)"
        }
    }

    Write-Host "==> 全部单元已启动。关闭对应调试窗口即停止；PID：$($started.Id -join ', ')" -ForegroundColor Green
    exit 0
}
catch {
    Write-Error $_
    Pause-IfInteractive
    exit 1
}
