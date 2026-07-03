# Kritical.Lens.ALDependencyMatrix

> Second slice of the **Kritical Lens&trade;** family — a PowerShell 7 module
> that walks every `.al` file in a Business Central AL project and produces
> a dependency matrix: every external-table reference site grouped by
> table, with per-site file, line, and column, and (optionally) the
> mechanical fix-path when you supply a replacement-table mapping.

Made in Australia by **[Kritical Pty Ltd](https://kritical.net)** — a
Seriously Kritical&trade; Production.

<div align="center">

[![PowerShell 7+](https://img.shields.io/badge/PowerShell-7%2B-5391FE?logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![Windows • macOS • Linux](https://img.shields.io/badge/OS-Windows%20%C2%B7%20macOS%20%C2%B7%20Linux-13365C)](https://learn.microsoft.com/powershell/scripting/install/installing-powershell)
[![License MIT](https://img.shields.io/badge/License-MIT-15AFD1)](./LICENSE)
[![Tests 15/15](https://img.shields.io/badge/tests-15%2F15-15AFD1)](./tests/Invoke-AllTests.ps1)

</div>

---

## What it is

Purpose-built for **third-party-dependency rip-out programmes**. When you
want to remove a third-party AL dependency (a paid connector, a legacy
integration layer) from your project, this cmdlet answers the questions
that let you plan the work honestly:

- Which tables from the dependency are you actually still using?
- How many sites in your code reference each one?
- Which files hold those references?
- What's the mechanical fix at every site?

## Install

```powershell
Install-Module -Name Kritical.Lens.ALDependencyMatrix -Scope CurrentUser
Import-Module  Kritical.Lens.ALDependencyMatrix
```

Requires PowerShell 7 or later. No AL compiler required — the tool is
pure regex-driven and cross-platform.

---

## Quick start

```powershell
# Walk everything under the AL project
$r = Invoke-KriticalLensALDependencyMatrix -Root ./MyBcProject

$r.TotalSites        # total external-table reference sites in the code
$r.DistinctTables    # how many distinct external tables you touch
$r.ByTable           # per-table site count
$r.Rows              # every site — File, Line, Column, Table, Kind
```

Scope to a specific dependency:

```powershell
# For example, MDC Nordic Pax8 Connector tables sit in the 72677xxx range
Invoke-KriticalLensALDependencyMatrix `
    -Root ./MyBcProject `
    -FilterTablePattern '^72677' `
    -OutputMd ./reports/mdc-nordic-deps.md `
    -OutputJson ./reports/mdc-nordic-deps.json
```

Enrich with replacement-table hints so the report also shows the
mechanical fix at every site:

```powershell
# ./mapping.json:
# {
#   "72677586": "Krit Pax8 Product Mirror",
#   "72677589": "Krit Pax8 Product Pricing Mirror"
# }
Invoke-KriticalLensALDependencyMatrix `
    -Root ./MyBcProject `
    -FilterTablePattern '^72677' `
    -MappingPath ./mapping.json `
    -OutputMd ./reports/rip-out-plan.md
```

The Markdown report emits one row per site with a `FixPath` column,
which is exactly the plan you hand to the developer doing the rewrite.

---

## What it detects

The tool applies six regex patterns per line and emits one row per match:

| Kind | Pattern (essence) | Example |
|---|---|---|
| `RecordDecl` | `Record <name>` | `Item: Record "Item";` |
| `RecordRefOpen` | `.Open(Database::<name>)` | `RRef.Open(Database::"MDC Product");` |
| `DatabaseLiteral` | `Database::<name>` (anywhere) | `SetView('Database::72677586')` |
| `TableRelation` | `TableRelation = <name>.<field>` | field property |
| `SourceTable` | `SourceTable = <name>;` | page / query / report |
| `RunObject` | `RunObject = <type> <name>;` | action property |

Table identifiers are either numeric IDs, quoted names, or bare names.
The tool normalises quoted names by stripping quotes.

---

## Design principles

- **Zero dependencies beyond PowerShell 7.** No Pester, no
  `Microsoft.Dynamics.Nav.*` modules, no AL compiler. Cross-platform.
- **Regex-driven, not AST-driven.** Missing a semicolon or having a
  broken .al file doesn't stop the walk. The tool sees what's there,
  not what compiles.
- **Convention-driven output.** Two formats: Markdown for humans, JSON
  for machines. Return object for pipelining.
- **Rip-out ergonomics.** `-FilterTablePattern` narrows to one
  dependency at a time. `-MappingPath` produces per-site fix
  suggestions. That's the whole rip-out worksheet.

---

## The Kritical Lens family

Kritical.Lens.ALDependencyMatrix is the **second** standalone Lens
family slice. Individual Lens modules are extracted as standalone public
repositories as each hits a real 1.0.0 quality bar. The umbrella lives
at [Sir-J-AU/Kritical.Lens](https://github.com/Sir-J-AU/Kritical.Lens).

Sibling slice: [Sir-J-AU/Kritical.Lens.SchemaCompleteness](https://github.com/Sir-J-AU/Kritical.Lens.SchemaCompleteness)
— proves a Microsoft365DSC-compatible module set covers every schema
resource, parameter, and AllowedValue.

---

## License and credits

MIT. Copyright &copy; 2026 **Kritical Pty Ltd**. Author: **Joshua Finley**.

Built to feed the Kritical Business Central connector's V4 native-mode
rip-out programme — the milestone that removes the MDC Nordic Pax8
Connector dependency and lets a small business stop paying that
license.

---

<div align="center">

<sub>Kritical Pty Ltd &nbsp;·&nbsp; ABN 39 687 048 086 &nbsp;·&nbsp; Geelong VIC, Australia
<br/>+61 1300 274 655 &nbsp;·&nbsp; [sales@kritical.net](mailto:sales@kritical.net) &nbsp;·&nbsp; [kritical.net](https://kritical.net)</sub>

</div>
