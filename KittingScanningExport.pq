let
    Source = Excel.Workbook(File.Contents("C:\Users\Peiran Quan\Desktop\Power BI\Scanny Data W49-W01.xlsx"), null, true),
    Sheet1_Sheet = Source{[Item="Sheet1",Kind="Sheet"]}[Data],
    #"Promoted Headers" = Table.PromoteHeaders(Sheet1_Sheet, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"Start Time", type datetime}, {"Finish Time", type datetime}, {"Activity", type text}, {"Seq Code", type text}, {"Recipe Name", type text}, {"Break Reasons", type text}, {"Missing Ingredients", type text}, {"Kitting Line", type text}, {"Assembly Batch", type text}, {"Event Shift", type text}, {"Team Leader", type text}, {"Pickers Count", Int64.Type}, {"Time Consumption", type number}, {"Week", type text}}),
    #"Filtered Rows" = Table.SelectRows(#"Changed Type", each ([Activity] <> "Factory Closed" and [Activity] <> "TBD") and ([Break Reasons] <> "move to other line" and [Break Reasons] <> "shift break")),
    #"Replaced Value" = Table.ReplaceValue(#"Filtered Rows",null,each if [#"Activity"] = "Break" then "Unselected" else [#"Break Reasons"],Replacer.ReplaceValue,{"Break Reasons"}),
    #"Added adjusted time consumption" = Table.AddColumn(#"Replaced Value", "Time Consumption (Adjusted)", each if [#"Break Reasons"] = "clean up" and 
[#"Time Consumption"] >20
then 20
else 
if [#"Break Reasons"] = "10 mins break" and 
[#"Time Consumption"] > 15
then 15
else
if [#"Break Reasons"] = "30 mins break" and 
[#"Time Consumption"] > 40
then 40
else
if [#"Break Reasons"] = "machine down" and 
[#"Time Consumption"] > 60
then 60
else
if [#"Break Reasons"] = "no dolly/crate" and 
[#"Time Consumption"] > 60
then 60
else
if [#"Break Reasons"] = "missing products" and 
[#"Time Consumption"] > 240
then 20
else
if [#"Break Reasons"] = "rework previous mks" and 
[#"Time Consumption"] > 240
then 240
else
if [#"Break Reasons"] = "Unselected" and 
[#"Time Consumption"] > 30
then 30
else
if [#"Break Reasons"] = "shortage of staff" and 
[#"Time Consumption"] > 30
then 30
else 
if [#"Activity"] = "Production" and [#"Time Consumption"] > 20 
then 20
else 
if [#"Activity"] = "Preparation/Changeover" and [#"Time Consumption"] > 30 
then 30
else 
[#"Time Consumption"]),
    #"Added ""Activity Details"" Conditional Column" = Table.AddColumn(#"Added adjusted time consumption", "Activity Detail", each if [Activity] = "Break" then [Break Reasons] else [Activity]),
    #"Inserted Merged Column" = Table.AddColumn(#"Added ""Activity Details"" Conditional Column", "Primary Key", each Text.Combine({[Kitting Line],  Text.From([Start Time], "en-US"), Text.From([Finish Time], "en-US"), [Activity Detail]}, " "), type text),
    #"Inserted Merged Column1" = Table.AddColumn(#"Inserted Merged Column", "Week/Recipe", each Text.Combine({[Week], [Recipe Name]}, " "), type text)
in
    #"Inserted Merged Column1"
