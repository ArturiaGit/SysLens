# scripts/governance/handoff.ps1
# SysLens 双 Agent 机械交接门禁 CLI

param (
    [Parameter(Position=0, Mandatory=$true)]
    [ValidateSet("begin", "finish", "accept", "status")]
    [string]$Command,

    [Parameter(Mandatory=$false)]
    [string]$Task,

    [Parameter(Mandatory=$false)]
    [ValidateSet("antigravity", "pi-desktop", "user")]
    [string]$Role,

    [Parameter(Mandatory=$false)]
    [string]$Phase,

    [Parameter(Mandatory=$false)]
    [string]$Summary,

    [Parameter(Mandatory=$false)]
    [string]$HandoffEvent,

    [Parameter(Mandatory=$false)]
    [string]$Digest
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$handoffDir = Join-Path $PSScriptRoot "../../governance/handoffs"
if (-not (Test-Path $handoffDir)) {
    New-Item -ItemType Directory -Path $handoffDir -Force | Out-Null
}

function Get-HandoffFilePath($taskId) {
    return Join-Path $handoffDir "$taskId.json"
}

function Get-SHA256($inputString) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($inputString)
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $hasher.ComputeHash($bytes)
    return -join ($hashBytes | ForEach-Object { "{0:x2}" -f $_ })
}

if ($Command -eq "begin") {
    if (-not $Task -or -not $Role -or -not $Phase) {
        Write-Error "缺少必填参数: Task, Role, Phase"
    }

    $filePath = Get-HandoffFilePath $Task
    $chain = @()
    if (Test-Path $filePath) {
        $content = Get-Content $filePath -Raw | ConvertFrom-Json
        $chain = @($content)
    }

    $prevDigest = "INITIAL_GENESIS_DIGEST"
    if ($chain.Count -gt 0) {
        $prevItem = $chain[-1]
        $prevDigest = Get-SHA256 ($prevItem | ConvertTo-Json -Compress)
    }

    $eventId = "EVT-" + [Guid]::NewGuid().ToString("N").Substring(0, 8).ToUpper()
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    $newEvent = [PSCustomObject]@{
        event_id = $eventId
        timestamp = $timestamp
        task_id = $Task
        action = "begin"
        role = $Role
        phase = $Phase
        prev_digest = $prevDigest
        summary = "Stage started: $Phase by $Role"
    }

    $chain += $newEvent
    $chain | ConvertTo-Json -Depth 10 | Set-Content $filePath -Encoding utf8
    Write-Host "[Handoff] Phase '$Phase' BEGUN by $Role for Task '$Task'. Event: $eventId (Digest: $prevDigest)" -ForegroundColor Green
}
elseif ($Command -eq "finish") {
    if (-not $Task -or -not $Role) {
        Write-Error "缺少必填参数: Task, Role"
    }
    $filePath = Get-HandoffFilePath $Task
    if (-not (Test-Path $filePath)) {
        Write-Error "找不到任务 $Task 的交接链"
    }
    $chain = @(Get-Content $filePath -Raw | ConvertFrom-Json)
    $prevItem = $chain[-1]
    $prevDigest = Get-SHA256 ($prevItem | ConvertTo-Json -Compress)
    $eventId = "EVT-" + [Guid]::NewGuid().ToString("N").Substring(0, 8).ToUpper()
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    $newEvent = [PSCustomObject]@{
        event_id = $eventId
        timestamp = $timestamp
        task_id = $Task
        action = "finish"
        role = $Role
        phase = $prevItem.phase
        prev_digest = $prevDigest
        summary = $Summary
    }

    $chain += $newEvent
    $chain | ConvertTo-Json -Depth 10 | Set-Content $filePath -Encoding utf8
    $currentDigest = Get-SHA256 ($newEvent | ConvertTo-Json -Compress)

    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "[Handoff FINISH] Task: $Task | Role: $Role | Phase: $($prevItem.phase)" -ForegroundColor Green
    Write-Host "Event ID: $eventId" -ForegroundColor Yellow
    Write-Host "Digest (SHA256): $currentDigest" -ForegroundColor Yellow
    Write-Host "Summary: $Summary"
    Write-Host "============================================================" -ForegroundColor Cyan
}
elseif ($Command -eq "accept") {
    if (-not $Task -or -not $Role -or -not $HandoffEvent) {
        Write-Error "缺少必填参数: Task, Role, HandoffEvent"
    }
    $filePath = Get-HandoffFilePath $Task
    if (-not (Test-Path $filePath)) {
        Write-Error "找不到任务 $Task 的交接链"
    }
    $chain = @(Get-Content $filePath -Raw | ConvertFrom-Json)
    $lastEvent = $chain[-1]
    if ($lastEvent.action -ne "finish") {
        Write-Error "前序事件不是 finish 状态，无法 accept"
    }
    if ($lastEvent.event_id -ne $HandoffEvent) {
        Write-Error "Event ID 不匹配: 传入 $HandoffEvent, 实际 $($lastEvent.event_id)"
    }

    $eventId = "EVT-" + [Guid]::NewGuid().ToString("N").Substring(0, 8).ToUpper()
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $prevDigest = Get-SHA256 ($lastEvent | ConvertTo-Json -Compress)

    $newEvent = [PSCustomObject]@{
        event_id = $eventId
        timestamp = $timestamp
        task_id = $Task
        action = "accept"
        role = $Role
        phase = $lastEvent.phase
        accepted_event = $HandoffEvent
        prev_digest = $prevDigest
        summary = "Handoff accepted by $Role"
    }

    $chain += $newEvent
    $chain | ConvertTo-Json -Depth 10 | Set-Content $filePath -Encoding utf8
    Write-Host "[Handoff ACCEPT] Event $HandoffEvent ACCEPTED by $Role for Task $Task." -ForegroundColor Green
}
elseif ($Command -eq "status") {
    if (-not $Task) {
        Write-Error "缺少必填参数: Task"
    }
    $filePath = Get-HandoffFilePath $Task
    if (-not (Test-Path $filePath)) {
        Write-Host "任务 $Task 尚无交接记录" -ForegroundColor Yellow
        return
    }
    $chain = @(Get-Content $filePath -Raw | ConvertFrom-Json)
    Write-Host "=== Task $Task Handoff Chain ===" -ForegroundColor Cyan
    foreach ($evt in $chain) {
        Write-Host "[$($evt.timestamp)] $($evt.action.ToUpper()) by $($evt.role) | Phase: $($evt.phase) | ID: $($evt.event_id) - $($evt.summary)"
    }
}
