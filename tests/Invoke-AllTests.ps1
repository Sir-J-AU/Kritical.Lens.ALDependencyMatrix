#requires -Version 7.0
[CmdletBinding()] param()
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot

Import-Module (Join-Path $repo 'src/Kritical.Lens.ALDependencyMatrix.psd1') -Force

$pass = 0; $fail = 0
function Assert-True {
    param([bool]$C,[string]$M)
    if ($C) { $script:pass++ } else { $script:fail++; Write-Host ("  FAIL: {0}" -f $M) -Foreground Red }
}

Write-Host "== Kritical.Lens.ALDependencyMatrix tests ==" -ForegroundColor Cyan

$fx = Join-Path $PSScriptRoot 'Fixtures'
$r  = Invoke-KriticalLensALDependencyMatrix -Root $fx

Assert-True ($null -ne $r) 'Returns result'
Assert-True ($r.TotalSites -gt 0) ("TotalSites > 0 (got {0})" -f $r.TotalSites)
Assert-True ($r.DistinctTables -ge 4) ("DistinctTables >= 4 (got {0})" -f $r.DistinctTables)

$itemRows = @($r.Rows | Where-Object { $_.Table -eq 'Item' })
Assert-True ($itemRows.Count -ge 3) ("Item table has >= 3 refs (got {0})" -f $itemRows.Count)

$kinds = @($r.Rows | Select-Object -ExpandProperty Kind -Unique)
Assert-True ('RecordDecl' -in $kinds) 'RecordDecl kind detected'
Assert-True ('RecordRefOpen' -in $kinds) 'RecordRefOpen kind detected'
Assert-True ('TableRelation' -in $kinds) 'TableRelation kind detected'
Assert-True ('SourceTable' -in $kinds) 'SourceTable kind detected'
Assert-True ('RunObject' -in $kinds) 'RunObject kind detected'

# Filter mode
$r2 = Invoke-KriticalLensALDependencyMatrix -Root $fx -FilterTablePattern '^Item$'
$itemOnly = @($r2.Rows | Where-Object { $_.Table -ne 'Item' })
Assert-True ($itemOnly.Count -eq 0) ("Filter '^Item$' returns only Item rows (got {0} non-Item)" -f $itemOnly.Count)

# Mapping enrichment
$mapPath = Join-Path $fx 'mapping.json'
$r3 = Invoke-KriticalLensALDependencyMatrix -Root $fx -MappingPath $mapPath
$withFix = @($r3.Rows | Where-Object { $_.FixPath -eq 'Krit Sample Item Mirror' })
Assert-True ($withFix.Count -ge 1) ("Mapping enrichment produced at least one FixPath for Item (got {0})" -f $withFix.Count)

# Output emit
$md   = Join-Path $env:TEMP ('kal-{0}.md'   -f (Get-Random))
$json = Join-Path $env:TEMP ('kal-{0}.json' -f (Get-Random))
$null = Invoke-KriticalLensALDependencyMatrix -Root $fx -MappingPath $mapPath -OutputMd $md -OutputJson $json
Assert-True (Test-Path $md)   ('Markdown emitted ' + $md)
Assert-True (Test-Path $json) ('JSON emitted ' + $json)
if (Test-Path $md) {
    Assert-True ((Get-Content -Raw $md) -match 'AL dependency matrix') 'Markdown carries title'
    Remove-Item $md -Force -ErrorAction SilentlyContinue
}
if (Test-Path $json) {
    $j = Get-Content -Raw $json | ConvertFrom-Json
    Assert-True ($j.Generator -eq 'Kritical.Lens.ALDependencyMatrix') 'JSON identifies generator'
    Remove-Item $json -Force -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host ("Passes: {0}  Fails: {1}" -f $pass, $fail) -ForegroundColor $(if ($fail) {'Red'} else {'Green'})
if ($fail) { exit 1 }
