{
  "schema": "kritical-readme-ai/v1",
  "generatedUtc": "2026-07-16",
  "generatedFrom": ["src/meta.json", "src/Kritical.Lens.ALDependencyMatrix.psd1", "src/Public/Invoke-KriticalLensALDependencyMatrix.ps1"],
  "repo": {
    "name": "Kritical.Lens.ALDependencyMatrix",
    "family": "Kritical.Lens",
    "category": "language",
    "wave": ".5177",
    "testable": true,
    "purpose": "AL project dependency matrix — walks every .al file and maps every object to every other object it references; supports cross-app dependency mapping and cycle detection.",
    "dependsOn": ["Krit.OmniFramework", "Kritical.Lens.CodeGraph"]
  },
  "publicApi": [
    { "name": "Invoke-KriticalLensALDependencyMatrix", "does": "walk .al files, produce dependency matrix (object -> referenced objects)" }
  ],
  "audits": ["al-object-dependency-graph", "al-cross-app-dependency", "al-cycle-detection"],
  "relationToCodeGraph": "CodeGraph extracts raw AL object/procedure graph; this builds the matrix + cycle view on top (layer above, not duplicate)",
  "output": { "pathTemplate": "ALBrain/contracts/al-dependency-matrix-<utc>.json", "sink": "disk", "retention": "days 90" },
  "family": { "umbrella": "Kritical.Lens", "sitsOn": "Kritical.Lens.CodeGraph" },
  "provenance": { "note": "New files only; README.md untouched.", "lane": "L4", "batch": "remaining Lens children (wake 29)" }
}
