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
        MysqlHostPort  = ''
        RedisHostPort  = ''
        NacosHttpPort  = ''
        NacosGrpcPort  = ''
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
    $result.MysqlHostPort = [string]$map["MYSQL_HOST_PORT"]
    $result.RedisHostPort = [string]$map["REDIS_HOST_PORT"]
    $result.NacosHttpPort = [string]$map["NACOS_HTTP_PORT"]
    $result.NacosGrpcPort = [string]$map["NACOS_GRPC_PORT"]

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

    # 中间件宿主端口：同样是**本机私有事实**——哪几个端口在本机可用取决于
    # WinNAT/Hyper-V 动态保留区间（踩坑 通-17），各设备不同，故允许 .env 覆盖。
    # 留空即不注入，运行时落回 compose / application.yaml 里的默认值。
    # Spring 侧以 ${VAR:默认值} 占位符消费同名环境变量。
    if ($result.MysqlHostPort -ne '') { $env:MYSQL_HOST_PORT = $result.MysqlHostPort }
    if ($result.RedisHostPort -ne '') { $env:REDIS_HOST_PORT = $result.RedisHostPort }
    if ($result.NacosHttpPort -ne '') { $env:NACOS_HTTP_PORT = $result.NacosHttpPort }
    if ($result.NacosGrpcPort -ne '') { $env:NACOS_GRPC_PORT = $result.NacosGrpcPort }

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
    # 返回 pwsh.exe 的绝对路径；未找到或版本不是 7+ 返回 $null。
    # 用途：Windows 下执行本项目 .ps1 脚本的**统一宿主**（见开发规范 §1 环境
    # 纪律），以及 dev.ps1 阶段 2b 的调试窗口宿主。缺失/版本不符时必须由
    # 调用方给出安装指引，否则 Start-Process 只会抛笼统的「启动失败」，真因
    # 被埋掉。
    #
    # 「存在」不等于「可用」（本函数的核心判据）：
    #   1. 只验路径存在会命中 0 字节的 App Execution Alias（商店版 PowerShell
    #      未安装时 WindowsApps\pwsh.exe 就是这种占位符，执行后转发到
    #      Windows PowerShell 5.1），属「探测通过、实际拿不到 7」的假阳性。
    #   2. 商店版 PowerShell 安装在 C:\Program Files\WindowsApps\<包名>\，
    #      是受保护目录，传统的 Program Files\PowerShell\7 探测看不见它；
    #      故 Get-Command（走 PATH/别名）是第一优先，目录探测仅作兜底。
    #   3. 版本必须**实际执行回读**，不能靠文件属性推断。
    #
    # 版本复核经实际执行 pwsh -Command 取 $PSVersionTable.PSVersion.Major，
    # 与 Test-JdkVersion 的「回读复核」同源思路（环境就绪判据不能只看存在性）。
    $cmd = Get-Command "pwsh.exe" -ErrorAction SilentlyContinue
    $candidates = @()
    if ($cmd) { $candidates += $cmd.Source }

    # PATH 未刷新时的兜底探测。注意商店版落在 WindowsApps（受保护目录），
    # 传统 Program Files\PowerShell\7 仅覆盖 MSI 安装形态，故两者都列。
    foreach ($path in @("$env:ProgramFiles\PowerShell\7\pwsh.exe", "$env:LOCALAPPDATA\Microsoft\WindowsApps\pwsh.exe")) {
        if ($path -and (Test-Path -LiteralPath $path -PathType Leaf)) { $candidates += $path }
    }
    # 去重（Get-Command 命中的往往就是 WindowsApps 那个）
    $candidates = @($candidates | Select-Object -Unique)

    foreach ($candidate in $candidates) {
        $major = Get-PwshMajorVersion -PwshExe $candidate
        if ($major -ge 7) { return $candidate }
    }
    return $null
}

function Get-PwshMajorVersion {
    param([string]$PwshExe)

    # 实际执行回读 PowerShell 主版本号；不可执行或非数字输出返回 -1。
    # 经 cmd /c 合并 stderr，避免 $ErrorActionPreference='Stop' 下把 stderr
    # 包装成 ErrorRecord 抛 NativeCommandError（PS 5.1 经典坑，与
    # Test-JdkVersion 同因）。-NoProfile/-NonInteractive 保证输出干净。
    if ([string]::IsNullOrWhiteSpace($PwshExe)) { return -1 }

    $output = (cmd /c "`"$PwshExe`" -NoProfile -NonInteractive -Command `"`$PSVersionTable.PSVersion.Major`" 2>&1") | Out-String
    $text = $output.Trim()
    $major = 0
    if ([int]::TryParse($text, [ref]$major)) { return $major }
    return -1
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

function Get-MiddlewareDefaultPorts {
    # 宿主端口**默认值**的权威定义点。docker\docker-compose.yml 的 `${VAR:-默认}`
    # 与两个 application.yaml 的同名占位符默认值必须与本表一致（改默认值须同轮
    # 改这三处；不一致会被结构判据当场发现，见 Get-MiddlewarePortConfigIssue）。
    #
    # 为什么允许 .env 覆盖：端口可用性取决于本机 WinNAT/Hyper-V **动态**保留区间
    # （踩坑 通-17/通-9），每台设备不同——属机器私有事实，不该硬编码进仓库。
    return [ordered]@{
        MYSQL_HOST_PORT = 13306
        REDIS_HOST_PORT = 16379   # 6379 曾被本机保留区间 6290-6389 吞掉（通-17）
        NACOS_HTTP_PORT = 18848
        NACOS_GRPC_PORT = 19848   # 不变式：= NACOS_HTTP_PORT + 1000（nacos-client 规则）
    }
}

function Get-MiddlewareEffectivePorts {
    # 有效端口 = .env 覆盖值（Import-LocalDevEnv 已注入为同名环境变量）或默认值。
    $ports = Get-MiddlewareDefaultPorts
    foreach ($key in @($ports.Keys)) {
        $envValue = [System.Environment]::GetEnvironmentVariable($key)
        if (-not [string]::IsNullOrWhiteSpace($envValue)) { $ports[$key] = $envValue }
    }
    return $ports
}

function Get-MiddlewarePortConfigIssue {
    # 返回空串 = 端口配置自洽；否则返回一句话问题（含处置），供调用方直接报出。
    # 这是**结构判据**：只看配置本身是否自洽，不依赖运行时（无需容器在跑）。
    $ports = Get-MiddlewareEffectivePorts
    $keys = @('MYSQL_HOST_PORT', 'REDIS_HOST_PORT', 'NACOS_HTTP_PORT', 'NACOS_GRPC_PORT')
    $issues = @()
    foreach ($key in $keys) {
        $value = "$($ports[$key])"
        if ($value -notmatch '^\d+$') {
            $issues += "$key=$value 不是合法端口（应为 1-65535 的整数）"
        } elseif ([int]$value -lt 1 -or [int]$value -gt 65535) {
            $issues += "$key=$value 超出端口范围 1-65535"
        }
    }
    if ($issues.Count -eq 0) {
        # nacos-client 以「server-addr 端口 + 1000」连 gRPC，两个端口必须成对；
        # 错配时**端口探测会通过而应用注册失败**（ErrCode:-401，踩坑 通-9），
        # 属"探测绿、实际坏"的假阴性，必须在此拦掉。
        if ([int]$ports['NACOS_GRPC_PORT'] -ne ([int]$ports['NACOS_HTTP_PORT'] + 1000)) {
            $issues += "NACOS_GRPC_PORT($($ports['NACOS_GRPC_PORT'])) 必须等于 NACOS_HTTP_PORT($($ports['NACOS_HTTP_PORT'])) + 1000（nacos-client 规则，踩坑 通-9）"
        }
    }
    if ($issues.Count -gt 0) {
        return ($issues -join '；') + "。请在项目根 .env 修正（或删除对应键以落回默认值）后重跑。"
    }
    return ''
}

function Get-MiddlewareProbePorts {
    # 探测清单（名称 → 有效端口）。gRPC 单列：踩坑 通-9 的形态是"Nacos HTTP 通而
    # gRPC 不通"，此时应用注册会以 ErrCode:-401 失败。
    # 非法值回退默认值：结构问题由 Get-MiddlewarePortConfigIssue 明确报出，
    # 此处不让它把探测过程本身炸掉（否则只剩笼统异常）。
    $ports = Get-MiddlewareEffectivePorts
    $defaults = Get-MiddlewareDefaultPorts
    $toInt = {
        param($raw, $fallback)
        $n = 0
        if ([int]::TryParse("$raw", [ref]$n)) { return $n }
        return [int]$fallback
    }
    return @(
        @{ Name = "MySQL";      Port = (& $toInt $ports['MYSQL_HOST_PORT'] $defaults['MYSQL_HOST_PORT']) },
        @{ Name = "Redis";      Port = (& $toInt $ports['REDIS_HOST_PORT'] $defaults['REDIS_HOST_PORT']) },
        @{ Name = "Nacos HTTP"; Port = (& $toInt $ports['NACOS_HTTP_PORT'] $defaults['NACOS_HTTP_PORT']) },
        @{ Name = "Nacos gRPC"; Port = (& $toInt $ports['NACOS_GRPC_PORT'] $defaults['NACOS_GRPC_PORT']) }
    )
}

function New-MiddlewareComposeEnvContent {
    # 生成 docker\.env（compose 在项目目录自动加载它）——目的是消掉"compose 的
    # ${VAR:-默认} 与项目根 .env 双源"：正常路径下 compose 拿到的是**显式值**，
    # 与判据、与 Spring 三方同源。
    # 行尾必须 LF：这是给 Linux 侧 compose 读的文件。
    $ports = Get-MiddlewareEffectivePorts
    $lines = @(
        '# 由 init.ps1 自项目根 .env 生成（本机私有事实，勿手工维护、不入库）',
        '# 端口默认值定义处：scripts\local-env.ps1::Get-MiddlewareDefaultPorts',
        '# 覆盖方式：改项目根 .env 的 MYSQL_HOST_PORT / REDIS_HOST_PORT / NACOS_HTTP_PORT / NACOS_GRPC_PORT',
        "MYSQL_HOST_PORT=$($ports['MYSQL_HOST_PORT'])",
        "REDIS_HOST_PORT=$($ports['REDIS_HOST_PORT'])",
        "NACOS_HTTP_PORT=$($ports['NACOS_HTTP_PORT'])",
        "NACOS_GRPC_PORT=$($ports['NACOS_GRPC_PORT'])",
        ''
    )
    return ($lines -join "`n")
}

function Test-TcpPort {
    param([int]$Port, [string]$TargetHost = "127.0.0.1", [int]$TimeoutMs = 1500)

    # 有界探测：连接被拒/超时统一返回 $false（不透出异常，由调用方汇总报道）。
    # 为什么需要它：**容器 healthy ≠ 宿主可达**。WSL2 的 localhost 转发依赖
    # Windows 侧能绑定该端口，而 WinNAT/Hyper-V 动态保留区间会静默吞掉端口
    # （踩坑 通-9），于是"容器健康"与"应用连得上"相互分离——就绪判据不能只看
    # 表面状态（开发规范 §1 环境纪律同源）。
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $task = $client.ConnectAsync($TargetHost, $Port)
        if (-not $task.Wait($TimeoutMs)) { return $false }
        return $client.Connected
    } catch {
        return $false
    } finally {
        $client.Dispose()
    }
}

function Get-UnreachableMiddleware {
    param([object[]]$ProbePorts)

    # 返回不可达项数组（每项含 Name/Port）；空数组表示全部可达。
    if (-not $ProbePorts) { $ProbePorts = Get-MiddlewareProbePorts }
    return @($ProbePorts | Where-Object { -not (Test-TcpPort -Port $_.Port) })
}
