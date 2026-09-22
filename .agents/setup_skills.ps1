# =====================================================================
# setup_skills.ps1 — 跨 Agent Skills 共享桥接脚本（幂等）
#
# 作用：将项目根目录 .agents/skills/（唯一技能源）通过 Windows 目录
#       联接（junction，无需管理员权限）桥接到各 AI 编码 Agent 的项目
#       级 skills 目录，实现"一份技能，所有 Agent 共用"。
#
# 用法：
#   .\.agents\setup_skills.ps1            # 创建缺失的 junction（幂等，可重复执行）
#   .\.agents\setup_skills.ps1 -Remove    # 拆除本脚本创建的全部 junction
#
# 说明：
#   - 原生识别 .agents/skills/ 的 Agent（Codex / Copilot / Gemini CLI
#     等）无需桥接；其余 Agent 由本脚本建立 junction。
#   - 本脚本仅适用于 Windows；macOS/Linux 环境请用符号链接等效实现
#     （ln -s .agents/skills <agent>/skills）。
#   - $Targets 列表按团队实际使用的 Agent 增删。
# =====================================================================
param(
    [switch]$Remove
)

$ErrorActionPreference = "Stop"

$Root   = $PSScriptRoot | Split-Path -Parent   # 项目根（本脚本位于 .agents/ 下）
$Source = Join-Path $Root ".agents\skills"

# 各 Agent 专属项目级 skills 目录（junction 目标，按需增删）
$Targets = @(
    ".codebuddy\skills",   # CodeBuddy
    ".claude\skills",      # Claude Code
    ".zcode\skills",       # ZCode
    ".opencode\skills",    # OpenCode
    ".mimocode\skills"     # MiMo Desktop
)

function Test-IsJunctionTo {
    param([string]$Path, [string]$ExpectedTarget)

    try {
        $item = Get-Item -LiteralPath $Path -Force
    } catch {
        return $false
    }
    if ($item.LinkType -ne "Junction") { return $false }

    # 比较 junction 指向与预期源（路径归一化后比对）
    $linked = [System.IO.Path]::GetFullPath($item.Target)
    $expect = [System.IO.Path]::GetFullPath($ExpectedTarget)
    return ($linked.TrimEnd('\') -ieq $expect.TrimEnd('\'))
}

if ($Remove) {
    Write-Host "==> 拆除 Skills junction..." -ForegroundColor Cyan
    foreach ($rel in $Targets) {
        $path = Join-Path $Root $rel
        if (Test-IsJunctionTo -Path $path -ExpectedTarget $Source) {
            # 只删除 junction 本身，不动源目录内容
            [System.IO.Directory]::Delete($path, $false)
            Write-Host "  [已拆除] $rel" -ForegroundColor Yellow
        } elseif (Test-Path -LiteralPath $path) {
            Write-Host "  [跳过]   $rel（存在但不是指向技能源的 junction，请人工确认）" -ForegroundColor DarkYellow
        } else {
            Write-Host "  [跳过]   $rel（不存在）" -ForegroundColor DarkGray
        }
    }
    Write-Host "==> 完成。" -ForegroundColor Green
    exit 0
}

# ---------- 安装模式 ----------
if (-not (Test-Path -LiteralPath $Source)) {
    Write-Host "错误：技能源目录不存在：$Source" -ForegroundColor Red
    Write-Host "请先确认 .agents/skills/ 已随仓库检出。" -ForegroundColor Red
    exit 1
}

Write-Host "==> 技能源：$Source" -ForegroundColor Cyan
Write-Host "==> 开始桥接各 Agent skills 目录..." -ForegroundColor Cyan

$created = 0; $skipped = 0; $conflict = 0

foreach ($rel in $Targets) {
    $path = Join-Path $Root $rel

    if (Test-IsJunctionTo -Path $path -ExpectedTarget $Source) {
        Write-Host "  [已存在] $rel （junction 指向正确）" -ForegroundColor DarkGray
        $skipped++
    }
    elseif (Test-Path -LiteralPath $path) {
        $item = Get-Item -LiteralPath $path -Force
        if ($item.LinkType) {
            Write-Host "  [冲突]   $rel （已被其他链接占用，指向：$($item.Target)，未改动）" -ForegroundColor DarkYellow
        } else {
            Write-Host "  [冲突]   $rel （已存在真实目录，为避免覆盖用户数据未改动，请人工处理）" -ForegroundColor Yellow
        }
        $conflict++
    }
    else {
        # 确保父目录存在
        $parent = Split-Path $path -Parent
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent | Out-Null
        }
        New-Item -ItemType Junction -Path $path -Value $Source | Out-Null
        Write-Host "  [已创建] $rel -> .agents\skills" -ForegroundColor Green
        $created++
    }
}

Write-Host ""
Write-Host "==> 完成：新建 $created 个，已存在 $skipped 个，冲突 $conflict 个。" -ForegroundColor Green
if ($conflict -gt 0) {
    Write-Host "    存在冲突项，请根据上方日志人工确认。" -ForegroundColor Yellow
    exit 2
}
