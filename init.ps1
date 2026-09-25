# =====================================================================
# init.ps1 — 本机开发环境一次性初始化（A-Mao 后端单元）
#
# 注意：本文件含中文注释，必须保存为 UTF-8 with BOM 编码——Windows
#       PowerShell 5.1 会把无 BOM 的 UTF-8 按 ANSI 读取，中文直接
#       破坏语法解析（开发规范 §2）。
#
# 定位：把「本机私有路径声明」（项目根 .env）落成可用的构建环境。
#       只处理 Maven / JDK 链路；中间件（docker compose）与 Agent
#       技能桥接不在本脚本范围。
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
#
# 用法：
#   .\init.ps1          # 初始化（幂等，可重复执行）
#   .\init.ps1 -Check   # 只体检：不建目录、不写文件
#
# 退出码：0 成功；1 需用户动作（缺 .env / 必填项缺失 / JDK 不符）；
#         2 settings 已存在且内容不同（未做任何改动）。
# =====================================================================
param(
    [switch]$Check
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

function Pause-IfInteractive {
    # 暂停包装必须调用真正的 Read-Host；禁止写成调用自身（自递归只在
    # 错误分支触发，会冲掉真正的报错）。
    if ($Host.Name -eq "ConsoleHost" -and -not $env:CI) {
        Read-Host "按回车退出" | Out-Null
    }
}

try {
    . (Join-Path $Root "scripts\local-env.ps1")

    Write-Host "==> A-Mao 本机环境初始化（Maven / JDK）" -ForegroundColor Cyan

    # ---- 阶段 1：读取本机私有配置（.env）----
    $local = Import-LocalDevEnv -Root $Root
    $envFile = Join-Path $Root ".env"

    if (-not $local.EnvFileExists) {
        $example = Join-Path $Root ".env.example"
        if (-not (Test-Path -LiteralPath $example -PathType Leaf)) {
            throw "缺少 .env 与 .env.example：请确认仓库完整检出后再执行。"
        }
        if (-not $Check) {
            Copy-Item -LiteralPath $example -Destination $envFile
            Write-Host "  已由 .env.example 生成 .env。" -ForegroundColor Yellow
        }
        Write-Host "  请填写 $envFile 中的 JDK_HOME 与 MAVEN_REPO_LOCAL 后重新执行本脚本。" -ForegroundColor Yellow
        Write-Host "  逐项说明见 docs\开发环境搭建.md 与 .env.example 内注释。" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "  [1/4] 已读取本机配置：$envFile" -ForegroundColor DarkGray

    # ---- 阶段 2：必填项校验（缺一即失败，不回退）----
    $missing = @()
    if ($local.JdkHome -eq '') { $missing += 'JDK_HOME' }
    if ($local.MavenRepoLocal -eq '') { $missing += 'MAVEN_REPO_LOCAL' }
    if ($missing.Count -gt 0) {
        throw "必填项缺失：$($missing -join '、')。请在 .env 中补齐后重试。"
    }

    # ---- 阶段 3：JDK 校验（存在性 + 主版本回读）----
    $javaExe = Join-Path $local.JdkHome "bin\java.exe"
    if (-not (Test-Path -LiteralPath $javaExe -PathType Leaf)) {
        throw "JDK_HOME 下未找到 bin\java.exe：$($local.JdkHome)（应填 JDK 安装根目录，不要带 \bin）"
    }
    if (-not (Test-JdkVersion -JavaExe $javaExe -ExpectedVersion "25")) {
        throw "JDK 版本不符：$javaExe 不是 25。本项目工具链锁定 JDK 25（开发规范 §3）。"
    }
    Write-Host "  [2/4] JDK 25 校验通过：$javaExe" -ForegroundColor DarkGray

    # ---- 阶段 4：创建落点目录 ----
    $pendingDirs = @()
    foreach ($dir in @($local.MavenUserHome, $local.MavenRepoLocal)) {
        if ($dir -eq '') { continue }
        if (Test-Path -LiteralPath $dir) { continue }
        $pendingDirs += $dir
        if (-not $Check) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    if ($pendingDirs.Count -gt 0) {
        $verb = if ($Check) { "待创建" } else { "已创建" }
        Write-Host "  [3/4] $verb 目录数 $($pendingDirs.Count)" -ForegroundColor DarkGray
    } else {
        Write-Host "  [3/4] 落点目录均已存在" -ForegroundColor DarkGray
    }

    # ---- 阶段 5：渲染 settings.xml ----
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
        Write-Host "  [4/4] 已配置 MAVEN_SETTINGS，跳过生成（由你自行维护）" -ForegroundColor DarkGray
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
                Write-Host "  [4/4] settings 已就绪（与模板渲染结果一致）：$target" -ForegroundColor Green
            } else {
                Write-Host "  [4/4] settings 已存在且内容不同，未做任何改动：$target" -ForegroundColor Yellow
                Write-Host "        该文件可能含既有私服凭据，故不覆盖；如需采用本脚本版本，" -ForegroundColor Yellow
                Write-Host "        请先备份并删除该文件后重跑，或手工把 localRepository 改为：" -ForegroundColor Yellow
                Write-Host "        $($local.MavenRepoLocal)" -ForegroundColor Yellow
                Pause-IfInteractive
                exit 2
            }
        } elseif ($Check) {
            Write-Host "  [4/4] （体检）将生成 settings：$target" -ForegroundColor DarkGray
        } else {
            [System.IO.File]::WriteAllText($target, $content, [System.Text.UTF8Encoding]::new($false))
            Write-Host "  [4/4] 已生成 settings（无 BOM UTF-8）：$target" -ForegroundColor Green
        }
    }

    # ---- 阶段 6：调试窗口宿主依赖探测（PowerShell 7）----
    # 不阻断：pwsh 7 只影响 dev.ps1 阶段 2b 的调试窗口，与 Maven 链路无关，
    # 但缺失时必须提前告知，否则届时只会看到笼统的「启动失败」。
    $pwshPath = Test-Pwsh7
    if ($pwshPath) {
        Write-Host "       PowerShell 7 已就绪：$pwshPath" -ForegroundColor DarkGray
    } else {
        Write-Host "       未检测到 PowerShell 7（pwsh.exe），dev.ps1 起调试窗口时需要它：" -ForegroundColor Yellow
        Write-Host "       winget install --id Microsoft.PowerShell --source winget" -ForegroundColor Yellow
    }

    # ---- 汇总与下一步 ----
    Write-Host ""
    if ($Check) {
        Write-Host "==> 体检完成（未写入任何文件）" -ForegroundColor Green
    } else {
        Write-Host "==> 初始化完成" -ForegroundColor Green
    }
    Write-Host "  依赖仓库 : $($local.MavenRepoLocal)" -ForegroundColor DarkGray
    if ($local.MavenUserHome -ne '') {
        Write-Host "  分发包   : $($local.MavenUserHome)\wrapper\dists" -ForegroundColor DarkGray
    } else {
        Write-Host "  分发包   : $env:USERPROFILE\.m2\wrapper\dists（未配置 MAVEN_USER_HOME，仍在 C 盘）" -ForegroundColor DarkGray
    }
    if ($target -ne '') { Write-Host "  settings : $target" -ForegroundColor DarkGray }

    Write-Host ""
    Write-Host "  下一步：" -ForegroundColor Cyan
    Write-Host "    1) 构建验证   : .\mvnw.cmd -s '$target' -B verify"
    Write-Host "    2) 源码调试   : .\dev.ps1 -Module amao-boot/amao-boot-user-service"
    Write-Host "    3) IDEA 同步  : Settings → Build Tools → Maven → User settings file 指向上面 settings；" -ForegroundColor DarkGray
    Write-Host "                    Local repository 留空（随 settings 的 localRepository 生效）" -ForegroundColor DarkGray

    # 旧仓库处理提示：仅在 C 盘存在既有仓库、且与本次配置的仓库不同时给出。
    # 提示按目标仓库「是否已有内容」分流——目标为空（新设备）适合整体搬走；
    # 目标已是大仓库时再 /MOVE 只做无谓合并，故改为「先比对再决定删源」。
    if ($env:USERPROFILE) {
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

    exit 0
}
catch {
    Write-Error $_
    Pause-IfInteractive
    exit 1
}
