# =====================================================================
# local-env.ps1 — 本机私有配置共享库（非入口脚本）
#
# 注意：本文件含中文注释，必须保存为 UTF-8 with BOM 编码——Windows
#       PowerShell 5.1 会把无 BOM 的 UTF-8 按 ANSI 读取，中文直接
#       破坏语法解析（开发规范 §2）。
#
# 定位：由 dev.ps1 / build.ps1 / init.ps1 以 dot-source 方式引入，
#       承载「读 .env → 注入环境变量 → 解析 settings 优先级 → 前置
#       依赖探测」的公共逻辑，避免三个入口各写一份而漂移。三个入口
#       脚本各自仍是所在场景的唯一入口，本文件只提供函数、不做动作。
#
# 兼容性：必须在 Windows PowerShell 5.1 与 PowerShell 7 下行为一致，
#       故只使用两者交集语法。原因：mvnw.cmd 内部固定调用 PS 5.1
#       （取 $HOME 算分发包目录），而 dev.ps1 阶段 2b 的调试窗口固定
#       用 pwsh 7，两条链路共存。
#
# 对照关系（三把钥匙各管一处，不可混用）：
#   MAVEN_USER_HOME   → 只影响 wrapper 分发包落点（mvnw.cmd 读它）
#   MVNW_REPOURL      → 只影响 wrapper 下载 Maven 分发包的源
#   MAVEN_REPO_LOCAL  → 依赖仓库落点，只经 settings.xml 的
#                       <localRepository> 生效（Maven 3.9 不认
#                       MAVEN_USER_HOME，那是 Maven 4 的语义）
# =====================================================================

function Read-LocalEnvFile {
    param([string]$Path)

    # 逐行解析 KEY=VALUE：
    #   - 跳过空行与 # 开头的注释行
    #   - 按「第一个 =」切分（值可能是含 = 的 URL）
    #   - 剥掉值两端成对引号
    #   - File::ReadAllLines 默认 UTF-8 且会检测并剥离 BOM
    $map = @{}
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $map }

    foreach ($raw in [System.IO.File]::ReadAllLines($Path)) {
        $line = ($raw -replace '^\uFEFF', '').Trim()
        if ($line -eq '' -or $line.StartsWith('#')) { continue }

        $idx = $line.IndexOf('=')
        if ($idx -lt 1) { continue }

        $key = $line.Substring(0, $idx).Trim()
        $value = $line.Substring($idx + 1).Trim()

        if ($value.Length -ge 2) {
            $first = $value.Substring(0, 1)
            $last = $value.Substring($value.Length - 1, 1)
            if (($first -eq '"' -and $last -eq '"') -or ($first -eq "'" -and $last -eq "'")) {
                $value = $value.Substring(1, $value.Length - 2)
            }
        }

        if ($key -ne '') { $map[$key] = $value }
    }
    return $map
}

function Add-PathPrefix {
    param([string]$Directory)

    # 把目录前置进 PATH，先判重：避免重复 dot-source / 重复执行造成叠加。
    if ([string]::IsNullOrWhiteSpace($Directory)) { return }
    foreach ($entry in ($env:Path -split ';')) {
        if ($entry.Trim() -eq '') { continue }
        if ($entry.TrimEnd('\') -ieq $Directory.TrimEnd('\')) { return }
    }
    $env:Path = "$Directory;$env:Path"
}

function Import-LocalDevEnv {
    param([string]$Root)

    # 读 $Root\.env 并注入环境变量，返回配置哈希表供调用方判断与使用。
    # .env 缺失时不注入任何变量、也不报错（返回 EnvFileExists=$false），
    # 使未配置设备的入口行为与引入本机制之前保持一致。
    $result = @{
        EnvFileExists  = $false
        JdkHome        = ''
        MavenUserHome  = ''
        MavenRepoLocal = ''
        MavenMirrorUrl = ''
        MavenSettings  = ''
        MavenHome      = ''
        MvnwRepoUrl    = ''
        Values         = @{}
    }

    $envFile = Join-Path $Root ".env"
    if (-not (Test-Path -LiteralPath $envFile -PathType Leaf)) { return $result }

    $map = Read-LocalEnvFile -Path $envFile
    $result.Values = $map
    $result.EnvFileExists = $true
    $result.JdkHome = [string]$map["JDK_HOME"]
    $result.MavenUserHome = [string]$map["MAVEN_USER_HOME"]
    $result.MavenRepoLocal = [string]$map["MAVEN_REPO_LOCAL"]
    $result.MavenMirrorUrl = [string]$map["MAVEN_MIRROR_URL"]
    $result.MavenSettings = [string]$map["MAVEN_SETTINGS"]
    $result.MavenHome = [string]$map["MAVEN_HOME"]
    $result.MvnwRepoUrl = [string]$map["MVNW_REPOURL"]

    # JDK：注入 JAVA_HOME（mvnw.cmd 内部靠它定位 java）并把 bin 前置进 PATH
    # （工具链候选与 IDE 外的手工 mvn 调用都受益）。
    if ($result.JdkHome -ne '') {
        $env:JAVA_HOME = $result.JdkHome
        Add-PathPrefix -Directory (Join-Path $result.JdkHome "bin")
    }
    # Maven 相关：仅在配置了非空值时才注入，留空即保持 Wrapper/Maven 默认行为。
    if ($result.MavenUserHome -ne '') { $env:MAVEN_USER_HOME = $result.MavenUserHome }
    if ($result.MavenHome -ne '') { $env:MAVEN_HOME = $result.MavenHome }
    if ($result.MvnwRepoUrl -ne '') { $env:MVNW_REPOURL = $result.MvnwRepoUrl }

    return $result
}

function Get-MavenSettingsArgs {
    param([hashtable]$LocalEnv, [string]$Root)

    # 解析 settings.xml 路径，返回给 mvnw 的 -s 参数（含引号），无命中返回空串。
    # 优先级（从高到低）：
    #   1) .env 的 MAVEN_SETTINGS（用户显式指定，不探测不生成）
    #   2) MAVEN_USER_HOME\settings.xml（init.ps1 生成，推荐路径）
    #   3) MAVEN_HOME\conf\settings.xml（沿用踩坑 通-10 的既有修复）
    #   4) %USERPROFILE%\.m2\settings.xml（最后兜底）
    # 路径统一用单引号包裹：路径含空格时，Start-Process / Invoke-Expression
    # 的字符串拼接不会被截断（PS 5.1 经典坑，见 dev.ps1 既有注释）。
    $candidates = @()
    if ($LocalEnv -and $LocalEnv.MavenSettings -ne '') { $candidates += $LocalEnv.MavenSettings }
    if ($LocalEnv -and $LocalEnv.MavenUserHome -ne '') { $candidates += (Join-Path $LocalEnv.MavenUserHome "settings.xml") }
    if ($env:MAVEN_HOME) { $candidates += (Join-Path $env:MAVEN_HOME "conf\settings.xml") }
    if ($env:USERPROFILE) { $candidates += (Join-Path $env:USERPROFILE ".m2\settings.xml") }

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return "-s '$candidate'"
        }
    }
    return ""
}

function Test-Pwsh7 {
    # 返回 pwsh.exe 的绝对路径；未找到返回 $null。
    # 用途：dev.ps1 阶段 2b 的调试窗口固定用 PowerShell 7 起（与 mvnw.cmd
    # 内部固定用 PS 5.1 是两件事）。缺失时必须由调用方给出安装指引，
    # 否则 Start-Process 只会抛笼统的「启动失败」，真因被埋掉。
    $cmd = Get-Command "pwsh.exe" -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    # PATH 未刷新时的兜底探测（PowerShell 7 的默认安装位置）。
    foreach ($path in @("$env:ProgramFiles\PowerShell\7\pwsh.exe", "$env:LOCALAPPDATA\Microsoft\WindowsApps\pwsh.exe")) {
        if ($path -and (Test-Path -LiteralPath $path -PathType Leaf)) { return $path }
    }
    return $null
}

function Test-JdkVersion {
    param([string]$JavaExe, [string]$ExpectedVersion)

    # 回读 java 版本并复核主版本号，供 dev.ps1 / build.ps1 共用同一套判据。
    # java -version 输出走 stderr：在 $ErrorActionPreference='Stop' 下用
    # PowerShell 的 2>&1 会把 stderr 包装成 ErrorRecord 并抛
    # NativeCommandError（PS 5.1 经典坑），故经 cmd /c 合并后取纯文本。
    if ([string]::IsNullOrWhiteSpace($JavaExe)) { return $false }
    if (-not (Test-Path -LiteralPath $JavaExe -PathType Leaf)) { return $false }

    $versionOutput = (cmd /c "`"$JavaExe`" -version 2>&1") | Out-String
    return ($versionOutput -match ('version "?' + [regex]::Escape($ExpectedVersion) + '\b'))
}
