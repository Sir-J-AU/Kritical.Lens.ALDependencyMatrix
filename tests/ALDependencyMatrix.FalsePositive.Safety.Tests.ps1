#Requires -Version 7.0
#Requires -Modules Pester
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = Split-Path $PSScriptRoot -Parent
    Import-Module (Join-Path $script:RepoRoot 'src/Kritical.Lens.ALDependencyMatrix.psd1') -Force
}

Describe 'AL dependency matrix ignores non-code text' {
    It 'does not emit dependency rows from comments or string literals while retaining a genuine Record reference' {
        $root = Join-Path $TestDrive 'al-project'
        New-Item -ItemType Directory -Force -Path $root | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'app.json') -Encoding utf8 -Value '{"id":"11111111-1111-1111-1111-111111111111","name":"fixture","publisher":"Kritical","version":"1.0.0.0","application":"28.0.0.0","runtime":"15.0","idRanges":[{"from":70000,"to":70099}]}'

        $al = @'
codeunit 70000 "Dependency Fixture"
{
    procedure Run()
    var
        RealItem: Record "Item";
        MessageText: Text;
    begin
        // FakeComment: Record "CommentOnlyTable";
        RealItem.FindFirst(); // Database::"InlineCommentTable"
        MessageText := 'Database::"StringLiteralTable" Record "AlsoStringTable" TableRelation = "LiteralRelation";';
        Message('SourceTable = "LiteralPageTable";');
    end;
}
'@
        Set-Content -LiteralPath (Join-Path $root 'Fixture.al') -Encoding utf8 -Value $al

        $result = Invoke-KriticalLensALDependencyMatrix -Root $root
        $tables = @($result.Rows | ForEach-Object Table)

        $tables | Should -Contain 'Item'
        $tables | Should -Not -Contain 'CommentOnlyTable'
        $tables | Should -Not -Contain 'InlineCommentTable'
        $tables | Should -Not -Contain 'StringLiteralTable'
        $tables | Should -Not -Contain 'AlsoStringTable'
        $tables | Should -Not -Contain 'LiteralRelation'
        $tables | Should -Not -Contain 'LiteralPageTable'
    }
}
