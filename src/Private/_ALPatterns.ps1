# AL table-reference patterns.  Each pattern captures a table identifier —
# either a numeric ID (`Database::72677586`), a quoted name (`Record "MDC
# Pax8 Product"`), or a bare name (`Record ItemVariant`).

$script:KriticalLensAlPatterns = @(
    @{
        Name    = 'RecordType'
        # `Record <name>` or `Record "<name>"` — variable declarations
        # .5231 (lens-hunt): allow bare names (e.g. `Record Customer`), not just quoted/numeric.
        Regex   = 'Record\s+(?<t>"[^"]+"|\d+|\w+)'
        Kind    = 'RecordDecl'
    }
    @{
        Name    = 'RecordRefOpen'
        # `RecordRef.Open(Database::<id>)` or `RRef.Open(Database::"<name>")`
        Regex   = '\.Open\s*\(\s*Database::(?<t>"[^"]+"|\d+)'
        Kind    = 'RecordRefOpen'
    }
    @{
        Name    = 'DatabaseLiteral'
        # `Database::<id-or-name>` on its own (e.g. inside enum values,
        # SetView, GetTableView, integration events)
        Regex   = 'Database::(?<t>"[^"]+"|\d+)'
        Kind    = 'DatabaseLiteral'
    }
    @{
        Name    = 'TableRelation'
        # `TableRelation = <name>.<field>` or `TableRelation = "<name>"."<field>"`
        Regex   = 'TableRelation\s*=\s*(?<t>"[^"]+"|\w+)\s*\.'
        Kind    = 'TableRelation'
    }
    @{
        Name    = 'SourceTable'
        # `SourceTable = <name-or-id>;` — page / query / report source table
        Regex   = 'SourceTable\s*=\s*(?<t>"[^"]+"|\d+)\s*;'
        Kind    = 'SourceTable'
    }
    @{
        Name    = 'PageActionRunObject'
        # `RunObject = page "<name>";` etc. — for cross-object references
        # Kept as separate class so it can be filtered off.
        Regex   = 'RunObject\s*=\s*(page|codeunit|report|query|table)\s+(?<t>"[^"]+"|\d+)'
        Kind    = 'RunObject'
    }
)

function _KriticalLensAlNormalizeTable {
    param([string]$Raw)
    if ([string]::IsNullOrEmpty($Raw)) { return '' }
    $t = $Raw.Trim().Trim('"')
    return $t
}
