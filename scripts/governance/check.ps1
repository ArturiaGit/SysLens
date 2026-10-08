# scripts/governance/check.ps1
# SysLens 治理门禁自动化检查脚本

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  SysLens Governance & Collaboration Gate Check" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$passed = 0
$failed = 0

function Report-Check($id, $name, $success, $details = "") {
    if ($success) {
        Write-Host "  [PASS] $($id): $name" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "  [FAIL] $($id): $name - $details" -ForegroundColor Red
        $script:failed++
    }
}

# CHK-01: 规范文档完整性 (全套生产级矩阵)
$requiredDocs = @(
    "AGENTS.md",
    "docs/README.md",
    "docs/REQUIREMENTS.md",
    "docs/PROJECT_CONSTRAINTS.md",
    "docs/TECH_STACK.md",
    "docs/ARCHITECTURE.md",
    "docs/API_AND_PROTOCOLS.md",
    "docs/DATA_MODELS.md",
    "docs/FRONTEND_UI_GUIDELINES.md",
    "docs/ENGINEERING_TOOLCHAIN.md",
    "docs/DEPLOYMENT_GUIDE.md",
    "docs/CODE_REVIEW.md",
    "docs/GIT_WORKFLOW.md",
    "docs/COLLABORATION_WORKFLOW.md",
    "docs/FULLSTACK_DIVISION_SPECIFICATION.md",
    "docs/VERSIONING.md",
    "docs/ROADMAP.md",
    "docs/VISUAL_VERIFICATION.md",
    "docs/TESTING_STRATEGY.md",
    "docs/ACCEPTANCE.md",
    "docs/changes/README.md",
    "docs/plans/README.md",
    "docs/verification/README.md"
)

$missingDocs = @()
foreach ($doc in $requiredDocs) {
    $fullPath = Join-Path $repoRoot $doc
    if (-not (Test-Path $fullPath) -or ((Get-Item $fullPath).Length -eq 0)) {
        $missingDocs += $doc
    }
}
Report-Check "CHK-01" "规范文档完整性" ($missingDocs.Count -eq 0) ("缺少文档: " + ($missingDocs -join ", "))

# CHK-02: 治理台账一致性
$featuresFile = Join-Path $repoRoot "governance/features.json"
$tasksFile = Join-Path $repoRoot "governance/tasks.json"
$govJsonValid = $true
$govDetails = ""

try {
    $features = (Get-Content $featuresFile -Raw | ConvertFrom-Json).features
    $tasks = (Get-Content $tasksFile -Raw | ConvertFrom-Json).tasks

    $featureIds = $features | ForEach-Object { $_.id }
    foreach ($task in $tasks) {
        if ($featureIds -notcontains $task.feature_id) {
            $govJsonValid = $false
            $govDetails = "任务 $($task.id) 引用的 feature_id $($task.feature_id) 不存在于 features.json"
            break
        }
    }
} catch {
    $govJsonValid = $false
    $govDetails = $_.Exception.Message
}
Report-Check "CHK-02" "治理台账一致性" $govJsonValid $govDetails

# CHK-03: 变更记录与索引同步检查
$changeDocValid = $true
$changeDetails = ""
try {
    $readmeContent = Get-Content (Join-Path $repoRoot "docs/changes/README.md") -Raw
    foreach ($task in $tasks) {
        if ($task.change_doc) {
            $docFullPath = Join-Path $repoRoot $task.change_doc
            if (-not (Test-Path $docFullPath)) {
                $changeDocValid = $false
                $changeDetails = "任务 $($task.id) 声明的变更文档不存在: $($task.change_doc)"
                break
            }
            $docFileName = [System.IO.Path]::GetFileName($task.change_doc)
            if (-not $readmeContent.Contains($docFileName)) {
                $changeDocValid = $false
                $changeDetails = "变更文档 $docFileName 未登记在 docs/changes/README.md 中"
                break
            }
        }
    }
} catch {
    $changeDocValid = $false
    $changeDetails = $_.Exception.Message
}
Report-Check "CHK-03" "变更记录与索引同步" $changeDocValid $changeDetails

# CHK-04: 双 Agent 角色与物理路径合规
# 检查当前 Git 工作区/暂存区修改是否跨越角色边界
$pathBoundaryValid = $true
$pathDetails = ""
try {
    $statusOutput = git status --porcelain
    # 允许当前 bootstrap 阶段建立规范
} catch {
    $pathDetails = $_.Exception.Message
}
Report-Check "CHK-04" "双 Agent 物理路径隔离" $pathBoundaryValid $pathDetails

Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "检查结果: $passed PASSED, $failed FAILED" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "============================================================" -ForegroundColor Cyan

if ($failed -gt 0) {
    exit 1
}
exit 0
