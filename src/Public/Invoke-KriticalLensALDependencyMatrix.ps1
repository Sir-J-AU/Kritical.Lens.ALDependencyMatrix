function Invoke-KriticalLensALDependencyMatrix {
<#
.SYNOPSIS
    Walks every .al file in an AL project and produces a dependency matrix:
    every external-table reference site grouped by table, with per-site
    file + line + column and (optionally) the mechanical fix-path when a
    replacement-table mapping is provided.

.DESCRIPTION
    Purpose-built for rip-out programmes.  When you want to remove a
    third-party AL dependency from your project, this cmdlet answers:

      * Which tables from the dependency are you actually still using?
      * How many sites in your code reference each one?
      * Which files hold the references?
      * If you supply a `-MappingPath` file that maps
        `<external-table-id-or-name> -> <replacement-table-name>`, the
        report also lists the mechanical fix at every site.

    Convention: reads `.al` files under `-Root`, applies a small set of
    regex patterns for the common AL table-reference forms (Record,
    RecordRef.Open, Database:: literal, TableRelation, SourceTable,
    RunObject).  No AL compiler required.

.PARAMETER Root
    Path to the AL project root (the folder that contains `app.json`).

.PARAMETER FilterTablePattern
    Optional regex that filters the report to matching tables only.
    Handy when investigating one dependency — for example
    `^72677\d{3}$` scopes to MDC Nordic Pax8 Connector tables.

.PARAMETER MappingPath
    Optional JSON file mapping external table IDs / names to replacement
    table names.  Shape:

        {
          "72677586": "Krit Pax8 Product Mirror",
          "72677589": "Krit Pax8 Product Pricing Mirror"
        }

    When supplied, the report emits a per-site "FixPath" column with the
    suggested rewrite.

.PARAMETER OutputMd
    Optional Markdown report path.

.PARAMETER OutputJson
    Optional JSON detail path.

.PARAMETER ExcludeDir
    Directory names to skip.  Defaults to `.alpackages`, `archive`,
    `_attic`, `node_modules`, `.git`.

.OUTPUTS
    PSCustomObject with fields TotalSites, ByTable, Rows, MdPath, JsonPath.
#>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$Root,
        [string]$FilterTablePattern,
        [string]$MappingPath,
        [string]$OutputMd,
        [string]$OutputJson,
        [string[]]$ExcludeDir = @('.alpackages','archive','_attic','node_modules','.git')
    )

    if (-not (Test-Path -LiteralPath $Root)) {
        throw "AL project root does not exist: $Root"
    }

    Write-Verbose ("Kritical.Lens.ALDependencyMatrix: walking {0}" -f $Root)
    $rows = _KriticalLensAlWalkDir -Root $Root -ExcludeDir $ExcludeDir
    Write-Verbose ("Kritical.Lens.ALDependencyMatrix: {0} raw reference sites" -f $rows.Count)

    # Optional filter
    if ($FilterTablePattern) {
        $rows = @($rows | Where-Object { $_.Table -match $FilterTablePattern })
        Write-Verbose ("Kritical.Lens.ALDependencyMatrix: {0} sites after filter '{1}'" -f $rows.Count, $FilterTablePattern)
    }

    # Optional mapping enrichment
    $mapping = @{}
    if ($MappingPath -and (Test-Path -LiteralPath $MappingPath)) {
        # .5231 (lens-hunt): guard mapping read/parse so malformed JSON fails with a clear message.
        try {
            $mapObj = Get-Content -LiteralPath $MappingPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        } catch {
            throw "Failed to read or parse mapping file '$MappingPath': $($_.Exception.Message)"
        }
        foreach ($p in $mapObj.PSObject.Properties) {
            $mapping[$p.Name] = $p.Value
        }
        Write-Verbose ("Kritical.Lens.ALDependencyMatrix: {0} mappings loaded" -f $mapping.Count)
        # Add FixPath to every row
        $rows = @($rows | ForEach-Object {
            $fix = $mapping[$_.Table]
            $_ | Add-Member -MemberType NoteProperty -Name FixPath -Value $fix -PassThru
        })
    }

    $byTable = $rows | Group-Object Table | Sort-Object Count -Descending | ForEach-Object {
        $mapped = $null
        if ($mapping.Count -gt 0) { $mapped = $mapping[$_.Name] }
        [pscustomobject]@{
            Table       = $_.Name
            Count       = $_.Count
            Replacement = $mapped
            Kinds       = @($_.Group | Group-Object Kind | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ' '
        }
    }

    if ($OutputMd) {
        # .5231 (lens-hunt): escape pipe chars so table/file identifiers can't break the Markdown table structure.
        $esc = { param($v) if ($null -eq $v) { '' } else { ([string]$v) -replace '\|', '\|' } }
        $md = New-Object System.Text.StringBuilder
        $null = $md.AppendLine('# Kritical Lens — AL dependency matrix')
        $null = $md.AppendLine('')
        $null = $md.AppendLine(('- Root: `{0}`' -f $Root))
        if ($FilterTablePattern) { $null = $md.AppendLine(('- Filter: `{0}`' -f $FilterTablePattern)) }
        $null = $md.AppendLine(('- Total reference sites: **{0}**' -f $rows.Count))
        $null = $md.AppendLine(('- Distinct external tables: **{0}**' -f $byTable.Count))
        $null = $md.AppendLine('')
        $null = $md.AppendLine('## By table')
        $null = $md.AppendLine('')
        $null = $md.AppendLine('| Table | Sites | Replacement | Kinds |')
        $null = $md.AppendLine('|---|---:|---|---|')
        foreach ($t in $byTable) {
            $repl = if ($t.Replacement) { & $esc $t.Replacement } else { '&mdash;' }
            $null = $md.AppendLine(('| `{0}` | {1} | {2} | {3} |' -f (& $esc $t.Table), $t.Count, $repl, (& $esc $t.Kinds)))
        }
        $null = $md.AppendLine('')
        $null = $md.AppendLine('## First 200 sites')
        $null = $md.AppendLine('')
        $null = $md.AppendLine('| File | Line | Col | Kind | Table | FixPath |')
        $null = $md.AppendLine('|---|---:|---:|---|---|---|')
        $take = [Math]::Min($rows.Count, 200)
        for ($i = 0; $i -lt $take; $i++) {
            $r = $rows[$i]
            $fix = if ($r.PSObject.Properties['FixPath'] -and $r.FixPath) { & $esc $r.FixPath } else { '&mdash;' }
            $null = $md.AppendLine(('| `{0}` | {1} | {2} | {3} | `{4}` | {5} |' -f (& $esc $r.File), $r.Line, $r.Column, (& $esc $r.Kind), (& $esc $r.Table), $fix))
        }
        Set-Content -LiteralPath $OutputMd -Value $md.ToString() -Encoding utf8
    }

    if ($OutputJson) {
        $obj = [ordered]@{
            Generator = 'Kritical.Lens.ALDependencyMatrix'
            Version   = '1.0.0'
            Utc       = (Get-Date).ToUniversalTime().ToString('o')
            Root      = $Root
            Filter    = $FilterTablePattern
            Totals    = @{ Sites = $rows.Count; DistinctTables = $byTable.Count }
            ByTable   = @($byTable)
            Rows      = @($rows)
        }
        # .5231 (lens-hunt): surface write failures (read-only / disconnected path) instead of silently continuing.
        try {
            $obj | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputJson -Encoding utf8 -ErrorAction Stop
        } catch {
            throw "Failed to write JSON output to '$OutputJson': $($_.Exception.Message)"
        }
    }

    [pscustomobject]@{
        TotalSites     = $rows.Count
        DistinctTables = $byTable.Count
        ByTable        = @($byTable)
        Rows           = @($rows)
        MdPath         = $OutputMd
        JsonPath       = $OutputJson
    }
}
