@{
    RootModule           = 'Kritical.Lens.ALDependencyMatrix.psm1'
    ModuleVersion        = '1.0.0'
    GUID                 = 'f8d2b9a1-c4e3-4a5b-b8f2-9c1e7d3a5b6f'
    Author               = 'Joshua Finley'
    CompanyName          = 'Kritical Pty Ltd'
    Copyright            = '(c) 2026 Kritical Pty Ltd. All rights reserved.'
    Description          = 'Kritical Lens — Business Central AL dependency matrix. Walks every .al file in an AL project and reports every external-table reference (Record, RecordRef.Open, TableRelation) grouped by table ID, with per-site file + line + column. Produces the mechanical fix-path list for rip-out programmes (e.g. moving off a third-party connector to a native implementation). Second slice of the Kritical Lens family.'

    PowerShellVersion    = '7.0'
    CompatiblePSEditions = @('Core')

    FunctionsToExport = @(
        'Invoke-KriticalLensALDependencyMatrix'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags         = @('Kritical','Lens','BusinessCentral','AL','Dependency','Audit','PowerShell','PSGallery')
            LicenseUri   = 'https://github.com/Sir-J-AU/Kritical.Lens.ALDependencyMatrix/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/Sir-J-AU/Kritical.Lens.ALDependencyMatrix'
            IconUri      = 'https://kritical.net/assets/horizontal_logo.png'
            ReleaseNotes = @'
1.0.0 — Initial public release.
  * Invoke-KriticalLensALDependencyMatrix — walks .al files, extracts every
    external-table reference (Record, RecordRef.Open, TableRelation, page
    SourceTable), groups by table ID, emits Markdown + JSON + optional
    fix-path list keyed off a mapping table.
  * Second slice of the Kritical Lens family.  Purpose-built to feed
    "rip out third-party dependency X" programmes by producing the
    mechanical fix-list of AL sites that need editing.
'@
        }
    }
}
