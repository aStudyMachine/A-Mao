# =====================================================================
# build.ps1 — 打包/构建唯一入口（A-Mao 后端单元）
#
# 注意：本文件含中文注释，必须保存为 UTF-8 with BOM 编码——Windows
#       PowerShell 5.1 会把无 BOM 的 UTF-8 按 ANSI 读取，中文直接
#       破坏语法解析。
#
# 定位：构建指令完全收敛至本脚本。仅在用户明确要求打包/构建时执行。
#
# 单元形态：当前仅 backend（Maven 多模块单仓）。前端 Vue 3 工程建立
#       后，在 $Builds 数组追加 frontend 单元即可（npm run build、
#       输出 dist、首屏 bundle 体积上限）。
#
# 纪律（为什么存在这些检查）：
#   1. 构建环境保持最小依赖：只装构建必需项，混装无关库会使产物
#      膨胀——给产物体积立一条可度量的红线并在此自动校验。
#   2. 构建工具日志可能走 stderr，被终端显示为红字"失败"——
#      成败只看退出码 $LASTEXITCODE，不看输出颜色。
#   3. 构建产物目录不入库（见 .gitignore），产出即交付物。
#
# 用法：
#   .\build.ps1             # 构建 + 产物体积校验
#   .\build.ps1 -Check      # 仅环境检查，不构建
# =====================================================================
param(
    [switch]$Check
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot

# ---- 单元配置（每栈一个构建单元；当前仅 backend）----
# 字段说明：
#   Name        单元名（日志/报错标识）
#   Command     打包构建命令
#   OutputDir   构建输出目录（相对项目根）
#   SizeLimitMB 产物体积上限（MB；后端 fat jar ≤100）
$Builds = @(
    @{
        Name = "backend"
        Command = ".\mvnw.cmd -pl amao-boot/amao-boot-example -am package"
        OutputDir = "amao-boot/amao-boot-example/target"
        SizeLimitMB = 100
    }
)

function Pause-IfInteractive {
    # 暂停包装必须调用真正的 Read-Host；禁止写成调用自身。
    if ($Host.Name -eq "ConsoleHost" -and -not $env:CI) {
        Read-Host "按回车退出" | Out-Null
    }
}

try {
    # ---- 逐单元创建输出目录 ----
    foreach ($build in $Builds) {
        $outputPath = Join-Path $Root $build.OutputDir
        if (-not (Test-Path $outputPath)) {
            New-Item -ItemType Directory -Path $outputPath | Out-Null
        }
    }

    if ($Check) {
        Write-Host "==> 环境检查通过（共 $($Builds.Count) 个构建单元）。" -ForegroundColor Green
        exit 0
    }

    # ---- 逐单元顺序构建 + 产物体积红线校验 ----
    foreach ($build in $Builds) {
        Write-Host "==> [$($build.Name)] 开始构建：$($build.Command)" -ForegroundColor Cyan
        Push-Location $Root
        try {
            Invoke-Expression $build.Command
            if ($LASTEXITCODE -ne 0) {
                # 成败只看退出码；stderr 的红字不是判据。
                throw "[$($build.Name)] 构建失败：$($build.Command) 退出码 $LASTEXITCODE"
            }
        }
        finally {
            Pop-Location
        }

        $outputPath = Join-Path $Root $build.OutputDir
        $files = Get-ChildItem $outputPath -Recurse -File
        if (-not $files) {
            throw "[$($build.Name)] 构建结束后未在 $($build.OutputDir) 发现产物，请核对输出目录配置。"
        }
        $sizeMB = [math]::Round((($files | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)
        Write-Host "==> [$($build.Name)] 产物体积：$sizeMB MB（上限 $($build.SizeLimitMB) MB）" -ForegroundColor DarkGray
        if ($sizeMB -gt $build.SizeLimitMB) {
            Write-Warning "[$($build.Name)] 产物体积 $sizeMB MB 超过上限 $($build.SizeLimitMB) MB（体积红线见 docs/开发规范.md §1）。"
            exit 2
        }
    }

    Write-Host "==> 全部单元构建完成。" -ForegroundColor Green
    exit 0
}
catch {
    Write-Error $_
    Pause-IfInteractive
    exit 1
}
