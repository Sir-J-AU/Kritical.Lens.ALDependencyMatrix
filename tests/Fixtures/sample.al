// Fixture AL file for Kritical.Lens.ALDependencyMatrix tests.
// Exercises RecordDecl / RecordRefOpen / DatabaseLiteral / TableRelation /
// SourceTable / RunObject patterns.

table 50999 "Sample Table" {
    fields {
        field(1; "Entry No."; Integer) { }
        field(2; "Item No."; Code[20]) {
            TableRelation = "Item"."No.";
        }
        field(3; "Vendor No."; Code[20]) {
            TableRelation = "Vendor"."No.";
        }
    }
}

codeunit 50999 "Sample Codeunit" {
    procedure DoStuff()
    var
        Item: Record "Item";
        Cust: Record Customer;
        RRef: RecordRef;
    begin
        RRef.Open(Database::"Item");
        RRef.Open(Database::Customer);
        if Cust.FindFirst() then
            Message('OK');
    end;
}

page 50999 "Sample Page" {
    PageType = List;
    SourceTable = "Sample Table";

    actions {
        area(Processing) {
            action(OpenItems) {
                RunObject = page "Item List";
            }
        }
    }
}
