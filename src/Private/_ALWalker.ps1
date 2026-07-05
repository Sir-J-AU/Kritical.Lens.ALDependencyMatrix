function _KriticalLensAlWalkFile {
    <#
    .SYNOPSIS
        Walks a single .al file and emits one row per table reference site,
        each row carrying { File; Line; Column; Table; Kind }.
    #>
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$RepoRoot
    )
    if (-not (Test-Path -LiteralPath $Path)) { return @() }

    $rows = @()
    # .5231 (lens-hunt): force array so single-line files iterate by line, not by character.
    $lines = @(Get-Content -LiteralPath $Path)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        # Skip comment-only lines and blank lines for perf.
        if ($line -match '^\s*//') { continue }
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        foreach ($p in $script:KriticalLensAlPatterns) {
            $ms = [regex]::Matches($line, $p.Regex)
            foreach ($m in $ms) {
                $t = _KriticalLensAlNormalizeTable $m.Groups['t'].Value
                if ([string]::IsNullOrEmpty($t)) { continue }
                # Skip common non-table keywords that survive the pattern
                if ($t -in @('Record','Rec','xRec','var','Object','Codeunit','Page','Table','Report','Query')) { continue }

                $rel = if ($RepoRoot) {
                    try { (Resolve-Path -LiteralPath $Path).Path.Substring((Resolve-Path -LiteralPath $RepoRoot).Path.Length + 1) }
                    catch { $Path }
                } else { $Path }

                $rows += [pscustomobject]@{
                    File   = $rel
                    Line   = $i + 1
                    Column = $m.Index + 1
                    Table  = $t
                    Kind   = $p.Kind
                }
            }
        }
    }
    return $rows
}

function _KriticalLensAlWalkDir {
    <#
    .SYNOPSIS
        Walks every .al file under a directory, emits every table reference.
        Skips .bak.* files, files in .alpackages/, files in archive/.
    #>
    param(
        [Parameter(Mandatory)][string]$Root,
        [string[]]$ExcludeDir = @('.alpackages','archive','_attic','node_modules','.git')
    )

    $files = Get-ChildItem -Path $Root -Recurse -Filter '*.al' -File | Where-Object {
        $keep = $true
        foreach ($ex in $ExcludeDir) {
            if ($_.FullName -like "*$([IO.Path]::DirectorySeparatorChar)$ex$([IO.Path]::DirectorySeparatorChar)*") {
                $keep = $false; break
            }
        }
        $keep -and ($_.Name -notlike '*.bak.*')
    }

    $all = @()
    foreach ($f in $files) {
        $all += _KriticalLensAlWalkFile -Path $f.FullName -RepoRoot $Root
    }
    return $all
}
