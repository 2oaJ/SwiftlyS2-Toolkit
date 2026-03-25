<#
.SYNOPSIS
    Sync SwiftlyS2-Toolkit files from ZombiEden workspace to the public toolkit repo.

.DESCRIPTION
    Called automatically by ZombiEden's post-commit git hook when toolkit-related
    files are changed. Also safe to run manually at any time.

    Syncs:
      .github/agents/SwiftlyS2-*.agent.md
      .github/prompts/SwiftlyS2-Toolkit-*.prompt.md
      .github/skills/SwiftlyS2-Toolkit/ (full tree)

.PARAMETER CommitRef
    The commit ref to diff against (default: HEAD~1).
    Pass "MANUAL" to skip diff detection and do a full sync.
#>

param(
    [string]$CommitRef = "HEAD~1"
)

$ErrorActionPreference = "Stop"

# Derive all paths from $PSScriptRoot to avoid encoding issues with non-ASCII paths
$dstRoot  = $PSScriptRoot                                      # .../SwiftlyS2-Toolkit
$zeRoot   = Join-Path (Split-Path $dstRoot -Parent) "ZombiEden"
$srcRoot  = Join-Path $zeRoot ".github"

# ── Toolkit file patterns (relative to ZombiEden repo root) ──────────────────
$toolkitPatterns = @(
    "^\.github/agents/SwiftlyS2-.*\.agent\.md$",
    "^\.github/prompts/SwiftlyS2-Toolkit-.*\.prompt\.md$",
    "^\.github/skills/SwiftlyS2-Toolkit/"
)

# ── Detect changed toolkit files in this commit ───────────────────────────────
if ($CommitRef -eq "MANUAL") {
    Write-Host "[sync-toolkit] Manual mode: performing full sync."
    $toolkitChanged = $true
    $changedFiles   = @("(manual)")
    $changedAgents  = $true
    $changedPrompts = $true
    $changedSkills  = $true
} else {
    # git diff: files changed between CommitRef and HEAD
    try {
        $allChanged = git -C $zeRoot diff $CommitRef HEAD --name-only 2>$null
    } catch {
        # Likely the initial commit with no parent. Full sync.
        $allChanged = git -C $zeRoot show --name-only --format="" HEAD 2>$null
    }

    $changedFiles = $allChanged | Where-Object {
        $file = $_
        $toolkitPatterns | Where-Object { $file -match $_ }
    }

    if (-not $changedFiles) {
        Write-Host "[sync-toolkit] No toolkit files changed. Skipping."
        exit 0
    }

    $toolkitChanged = $true
    $changedAgents  = $changedFiles | Where-Object { $_ -match "agents/" }
    $changedPrompts = $changedFiles | Where-Object { $_ -match "prompts/" }
    $changedSkills  = $changedFiles | Where-Object { $_ -match "skills/" }
}

Write-Host "[sync-toolkit] Detected toolkit changes:"
$changedFiles | ForEach-Object { Write-Host "  $_" }

# ── Sync files ─────────────────────────────────────────────────────────────────
if ($changedAgents -or $CommitRef -eq "MANUAL") {
    Copy-Item "$srcRoot\agents\SwiftlyS2-*.agent.md" "$dstRoot\agents\" -Force
    Write-Host "[sync-toolkit] Synced: agents/"
}

if ($changedPrompts -or $CommitRef -eq "MANUAL") {
    Copy-Item "$srcRoot\prompts\SwiftlyS2-Toolkit-*.prompt.md" "$dstRoot\prompts\" -Force
    Write-Host "[sync-toolkit] Synced: prompts/"
}

if ($changedSkills -or $CommitRef -eq "MANUAL") {
    Copy-Item "$srcRoot\skills\SwiftlyS2-Toolkit" "$dstRoot\skills\" -Recurse -Force
    Write-Host "[sync-toolkit] Synced: skills/SwiftlyS2-Toolkit/"
}

# ── Build commit message ───────────────────────────────────────────────────────
$scopeParts = @()
if ($changedAgents)  { $scopeParts += "agents" }
if ($changedPrompts) { $scopeParts += "prompts" }
if ($changedSkills)  { $scopeParts += "skills" }
$scope = if ($scopeParts) { $scopeParts -join ", " } else { "toolkit" }

# Determine change type from scope for prefix
$prefix = switch -Regex ($scope) {
    "agents.*prompts.*skills" { "sync" }
    "agents"                  { "sync(agents)" }
    "prompts"                 { "sync(prompts)" }
    "skills"                  { "sync(skills)" }
    default                   { "sync" }
}

# Get source commit subject for traceability
if ($CommitRef -ne "MANUAL") {
    $srcSubject = git -C $zeRoot log -1 --pretty=format:"%s" HEAD 2>$null
    if (-not $srcSubject) { $srcSubject = "(unknown commit)" }
} else {
    $srcSubject = "manual sync"
}

$srcHash = git -C $zeRoot rev-parse --short HEAD 2>$null
if (-not $srcHash) { $srcHash = "unknown" }

$commitMsg = "$prefix`: update $scope from ZombiEden

Source: $srcSubject ($srcHash)
Changed:
$(($changedFiles | ForEach-Object { "  - $_" }) -join "`n")"

# ── Commit to SwiftlyS2-Toolkit repo ──────────────────────────────────────────
Push-Location $dstRoot
try {
    git add .
    $status = git status --porcelain
    if ($status) {
        git commit -m $commitMsg
        Write-Host "[sync-toolkit] ✓ Committed to SwiftlyS2-Toolkit: [$scope]"
        Write-Host "[sync-toolkit]   Run 'git push' in $dstRoot to publish."
    } else {
        Write-Host "[sync-toolkit] Nothing new to commit (files already in sync)."
    }
} finally {
    Pop-Location
}
