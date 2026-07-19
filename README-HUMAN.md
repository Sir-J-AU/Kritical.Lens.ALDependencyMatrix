# [LENS-ENGINE] Kritical.Lens.ALDependencyMatrix — README (human)

> The **AL dependency-matrix** member of the Kritical Lens family. Maps every AL object to
> every other object it references — the dependency/cycle view that sits on top of the raw
> call-graph from `Kritical.Lens.CodeGraph`.

| | |
|---|---|
| **Module** | `Kritical.Lens.ALDependencyMatrix` |
| **Category** | `language` |
| **Public surface** | `Invoke-KriticalLensALDependencyMatrix` |
| **Depends on** | `Krit.OmniFramework`, `Kritical.Lens.CodeGraph` |
| **Wave** | `.5177` · testable |

## What it does
Walks every `.al` file in an AL project and produces a **dependency matrix** — object → every
object it references — enabling cross-app dependency mapping and **cycle detection**.

**Audits:** `al-object-dependency-graph`, `al-cross-app-dependency`, `al-cycle-detection`.

## Relation to CodeGraph
`Kritical.Lens.CodeGraph` extracts the raw AL object/procedure graph; this module consumes that
to build the **matrix + cycle view**. So it's a layer *above* CodeGraph, not a duplicate — the
"what depends on what, and where are the loops" question.

## Layout
```
src/Public/Invoke-KriticalLensALDependencyMatrix.ps1   entry
src/meta.json   Lens contract (category=language, wave .5177)
Install.ps1 · tests/ · docs/
```
Output: `ALBrain/contracts/al-dependency-matrix-<utc>.json` (disk, 90-day retention).

## Family
Child of the `Kritical.Lens` umbrella; sits on `Kritical.Lens.CodeGraph`. Ingests via the
umbrella emitter-registry contract.

---
*Companion machine doc: `README-AI.md` (`kritical-readme-ai/v1`). Generated from live `meta.json`
+ psd1 + source — new files only, does not touch `README.md`.*
