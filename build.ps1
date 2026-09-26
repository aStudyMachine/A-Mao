# =====================================================================
# build.ps1 — 打包/构建唯一入口（A-Mao 后端单元）
#
# 注意：本文件含中文注释，必须保存为 UTF-8 with BOM 编码——Windows
#       PowerShell 5.1 会把无 BOM 的 UTF-8 按 ANSI 读取，中文直接
#       破坏语法解析。
#
# 定位：构建指令完全收敛至本脚本。仅在用户明确要求打包/构建时执行。
#
# 构建模块：由 -Module 显式指定（仓库内相对路径），脚本不绑定任何具
#       体模块——新增/删除启动模块无需改脚本；未指定或模块不存在即报
#       错并列出 amao-boot 下的可用模块。
#
# 单元形态：当前仅 backend（Maven 多模块单仓）。前端 Vue 3 工程建立
#       后，在 $Builds 数组追加 frontend 单元即可（npm run build、
#       输出 dist、首屏 bundle 体积上限）。
#
# 纪律（为什么存在这些检查）：
#   1. 构建环境保持最小依赖：只装构建必需项，混装无关库会使产物
#      膨胀——产物体积在构建后打印出来供观察（不设上限，见开发规范 §1）。
#   2. 构建工具日志可能走 stderr，被终端显示为红字"失败"——
#      成败只看退出码 $LASTEXITCODE，不看输出颜色。
#   3. 构建产物目录不入库（见 .gitignore），产出即交付物。
#
# 用法：
#   .\build.ps1 -Module amao-boot/amao-boot-user-service    # 构建该模块 + 产物体积打印
#   .\build.ps1 -Module amao-boot/amao-boot-user-service -Check  # 仅环境检查，不构建
#
#   -Module 必填：不传即报错并列出可用模块（本脚本不做任何模块的默认假设）。
# =====================================================================
param(
    [string]$Module,
    [switch]$Check
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot

# ---- 本机私有配置（.env）加载 ----
# 与 dev.ps1 共用同一套解析逻辑（scripts\local-env.ps1）：本机 JDK 注入
# JAVA_HOME、settings.xml 路径解析。改造前本脚本完全不带 -s，打包时依赖会
# 落到 Maven 默认仓库（C 盘），故此处必须与 dev.ps1 同源。
. (Join-Path $Root "scripts\local-env.ps1")
$script:LocalEnv = Import-LocalDevEnv -Root $Root

# ---- 模块解析（-Module 必填；脚本不绑定任何具体构建模块）----
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
        throw "必须指定构建模块：-Module <模块路径>（仓库内相对路径，如 amao-boot/amao-boot-user-service）。可用模块：$(Get-AvailableModules)"
    }
    $modulePom = Join-Path (Join-Path $Root $ModulePath) "pom.xml"
    if (-not (Test-Path $modulePom)) {
        throw "构建模块不存在：$ModulePath（未找到 $modulePom）。可用模块：$(Get-AvailableModules)"
    }
    return $ModulePath
}

# ---- 单元配置（每栈一个构建单元；当前仅 backend）----
# 字段说明：
#   Name               单元名（日志/报错标识）
#   CommandTemplate    打包构建命令模板（{module} 由 -Module 代入；
#                      {settings} 由本机 settings.xml 解析结果代入）
#   OutputDirTemplate  构建输出目录模板（{module} 由 -Module 代入）
$Builds = @(
    @{
        Name = "backend"
        CommandTemplate = ".\mvnw.cmd {settings} -pl {module} -am package"
        OutputDirTemplate = "{module}/target"
    }
)

function Pause-IfInteractive {
    # 暂停包装必须调用真正的 Read-Host；禁止写成调用自身。
    if ($Host.Name -eq "ConsoleHost" -and -not $env:CI) {
        Read-Host "按回车退出" | Out-Null
    }
}

try {
    # ---- 阶段 0：-Module 前置校验（先于任何有副作用的动作）----
    $Module = Resolve-Module -ModulePath $Module

    # ---- 阶段 0.5：本机私有配置校验 + settings 解析 ----
    # JDK 判据与 dev.ps1 同源（scripts\local-env.ps1::Test-JdkVersion）：.env 显式
    # 声明了 JDK_HOME 时就以它为准，不再接受 PATH 里的其他 JDK。
    if ($script:LocalEnv.JdkHome -ne '') {
        $javaExe = Join-Path $script:LocalEnv.JdkHome "bin\java.exe"
        if (-not (Test-JdkVersion -JavaExe $javaExe -ExpectedVersion "25")) {
            throw "JDK 校验失败：$javaExe 不存在或不是 25。请核对 .env 的 JDK_HOME（应填安装根目录）。"
        }
        Write-Host "==> JDK 校验通过：$javaExe" -ForegroundColor DarkGray
    }

    $script:MvnSettingsArgs = Get-MavenSettingsArgs -LocalEnv $script:LocalEnv -Root $Root
    if ($script:MvnSettingsArgs -eq '') {
        Write-Host "  提示：未找到 settings.xml，本次不带 -s（依赖落 Maven 默认仓库且无镜像加速）。" -ForegroundColor DarkYellow
        Write-Host "        执行 .\init.ps1 可生成带 localRepository 与镜像的 settings。" -ForegroundColor DarkYellow
    } else {
        Write-Host "==> settings：$script:MvnSettingsArgs" -ForegroundColor DarkGray
    }

    # ---- 逐单元创建输出目录 ----
    foreach ($build in $Builds) {
        $outputPath = Join-Path $Root $build.OutputDirTemplate.Replace("{module}", $Module)
        if (-not (Test-Path $outputPath)) {
            New-Item -ItemType Directory -Path $outputPath | Out-Null
        }
    }

    if ($Check) {
        Write-Host "==> 环境检查通过（共 $($Builds.Count) 个构建单元）。" -ForegroundColor Green
        exit 0
    }

    # ---- 逐单元顺序构建 + 产物体积打印 ----
    foreach ($build in $Builds) {
        $command = $build.CommandTemplate.Replace("{module}", $Module).Replace("{settings}", $script:MvnSettingsArgs)
        $outputRel = $build.OutputDirTemplate.Replace("{module}", $Module)
        Write-Host "==> [$($build.Name)] 开始构建（模块 $Module）：$command" -ForegroundColor Cyan
        Push-Location $Root
        try {
            Invoke-Expression $command
            if ($LASTEXITCODE -ne 0) {
                # 成败只看退出码；stderr 的红字不是判据。
                throw "[$($build.Name)] 构建失败：$command 退出码 $LASTEXITCODE"
            }
        }
        finally {
            Pop-Location
        }

        $outputPath = Join-Path $Root $outputRel
        $files = Get-ChildItem $outputPath -Recurse -File
        if (-not $files) {
            throw "[$($build.Name)] 构建结束后未在 $outputRel 发现产物，请核对输出目录配置。"
        }
        $sizeMB = [math]::Round((($files | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)
        Write-Host "==> [$($build.Name)] 产物体积：$sizeMB MB" -ForegroundColor DarkGray
    }

    Write-Host "==> 全部单元构建完成。" -ForegroundColor Green
    exit 0
}
catch {
    # catch 内必须先降 ErrorActionPreference：EAP=Stop 下 Write-Error 自身即终止性
    # 错误，其后的 Pause-IfInteractive 永远不执行——失败时窗口直接关掉，用户看不到
    # 报错内容。同因见踩坑记录 通-16。
    $ErrorActionPreference = 'Continue'
    Write-Error $_
    Pause-IfInteractive
    exit 1
}
