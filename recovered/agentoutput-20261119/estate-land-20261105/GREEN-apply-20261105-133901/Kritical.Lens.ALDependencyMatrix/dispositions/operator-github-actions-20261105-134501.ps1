# REGENERATE: Invoke-KritEstateDispositionCycle -GithubRoot C:\NoOneDrive\Github -OutputDir <dir> -FetchPrs
# OPERATOR SCRIPT -- generated 2026-11-05T02:45:05.8751682Z UTC by New-KritOperatorGitHubActionScript (lane psgh-disposition-lane-20261003).
# 2 action(s). DRY-RUN by default; pass -Execute to act. Run it yourself: agents never push or mutate GitHub.
#requires -Version 7.0
[CmdletBinding()]
param([switch]$Execute, [switch]$AcknowledgeActiveWorkflows)
$ErrorActionPreference = 'Stop'
$script:failed = 0; $script:done = 0; $script:skipped = 0
$ActionsSwitch = 'C:\NoOneDrive\Github\Kritical.PS.GitHub\src\Manage-KritGitHubActionsSwitch.ps1'

# ---- STEP 0: Actions-switch check (no runner minutes may be triggered by a merge) -------------
$swOut = (& $ActionsSwitch -Action List -Repo 'Kritical.Lens.ALDependencyMatrix' *>&1 | Out-String)
if ($swOut -notmatch '(\d+)\s+ACTIVE after this run') { Write-Host 'ABORT: could not read the Actions-switch SUMMARY (fail closed).' -ForegroundColor Red; exit 2 }
$activeWf = [int]$Matches[1]
if ($activeWf -gt 0 -and -not $AcknowledgeActiveWorkflows) { Write-Host "ABORT: $activeWf workflow(s) are ACTIVE in the affected repos; a merge could bill runner minutes. Disable them or pass -AcknowledgeActiveWorkflows." -ForegroundColor Red; exit 2 }
if (-not $Execute) { Write-Host 'DRY-RUN: nothing will be changed. Re-run with -Execute to act.' -ForegroundColor Cyan }

function Invoke-Op {
    param([string]$Show, [scriptblock]$Do)
    if (-not $Execute) { Write-Host "  DRY-RUN  $Show"; return }
    Write-Host "  RUN      $Show"
    try { $r = & $Do; if ($r -eq 'SKIP') { $script:skipped++ } elseif ($LASTEXITCODE -ne 0) { $script:failed++; Write-Host "  FAILED   exit $LASTEXITCODE" -ForegroundColor Red } else { $script:done++ } }
    catch { $script:failed++; Write-Host "  FAILED   $($_.Exception.Message)" -ForegroundColor Red }
}

# ===== Sir-J-AU/Kritical.Lens.ALDependencyMatrix =====
# EVIDENCE: remote branch daily/20261030: merged into default (ahead=0); tip 73fc66f7702a735206d22726349bdf5607040860 recorded
# recreate if ever needed: git push origin 73fc66f7702a735206d22726349bdf5607040860:refs/heads/daily/20261030
Invoke-Op -Show 'gh api -X DELETE repos/Sir-J-AU/Kritical.Lens.ALDependencyMatrix/git/refs/heads/daily/20261030 (tip must equal 73fc66f7702a735206d22726349bdf5607040860)' -Do { $tip = (& gh api 'repos/Sir-J-AU/Kritical.Lens.ALDependencyMatrix/git/ref/heads/daily/20261030' --jq .object.sha); if ($LASTEXITCODE -ne 0 -or "$tip".Trim() -ne '73fc66f7702a735206d22726349bdf5607040860') { Write-Host '  SKIP     server tip is not the reviewed tip -- not deleting'; return 'SKIP' }; & gh api -X DELETE 'repos/Sir-J-AU/Kritical.Lens.ALDependencyMatrix/git/refs/heads/daily/20261030' }
# EVIDENCE: remote branch integrate/clean-batch-20261030-125354: merged into default (ahead=0); tip 1941b58202df4dfae2f1b975b13f1a9ea48da54f recorded
# recreate if ever needed: git push origin 1941b58202df4dfae2f1b975b13f1a9ea48da54f:refs/heads/integrate/clean-batch-20261030-125354
Invoke-Op -Show 'gh api -X DELETE repos/Sir-J-AU/Kritical.Lens.ALDependencyMatrix/git/refs/heads/integrate/clean-batch-20261030-125354 (tip must equal 1941b58202df4dfae2f1b975b13f1a9ea48da54f)' -Do { $tip = (& gh api 'repos/Sir-J-AU/Kritical.Lens.ALDependencyMatrix/git/ref/heads/integrate/clean-batch-20261030-125354' --jq .object.sha); if ($LASTEXITCODE -ne 0 -or "$tip".Trim() -ne '1941b58202df4dfae2f1b975b13f1a9ea48da54f') { Write-Host '  SKIP     server tip is not the reviewed tip -- not deleting'; return 'SKIP' }; & gh api -X DELETE 'repos/Sir-J-AU/Kritical.Lens.ALDependencyMatrix/git/refs/heads/integrate/clean-batch-20261030-125354' }

Write-Host ("SUMMARY: done={0} skipped={1} failed={2} (Execute={3})" -f $script:done, $script:skipped, $script:failed, $Execute.IsPresent)
if ($script:failed -gt 0) { exit 1 }
exit 0
