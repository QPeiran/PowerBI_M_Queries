let
    Source = GoogleBigQuery.Database(null),
    #"scanning-database" = Source{[Name="scanning-database"]}[Data],
    PowerBI_Schema = #"scanning-database"{[Name="PowerBI",Kind="Schema"]}[Data],
    Kitting_Scanning_Export = PowerBI_Schema{[Name="PowerBI",Kind="Table"]}[Data],
    #"Filtered Rows" = Table.SelectRows(Kitting_Scanning_Export, each ([Activity] <> "Factory Closed" and [Activity] <> "TBD") and ([Break_Reasons] <> "move to other line" and [Break_Reasons] <> "shift break")),
    #"Replaced Value" = Table.ReplaceValue(#"Filtered Rows",null,each if [#"Activity"] = "Break" then "Unselected" else [#"Break_Reasons"],Replacer.ReplaceValue,{"Break_Reasons"}),
    #"Adjusted time consumption" = Table.AddColumn(#"Replaced Value", "Time Consumption (Adjusted)", each
        if 
            [#"Break_Reasons"] = "clean up" and [#"Time_Consumption"] >20
            then 20
        else if 
            [#"Break_Reasons"] = "10 mins break" and [#"Time_Consumption"] > 15
            then 15
        else if 
            [#"Break_Reasons"] = "30 mins break" and [#"Time_Consumption"] > 45
            then 45
        else if 
            [#"Break_Reasons"] = "machine down" and [#"Time_Consumption"] > 30
            then 30
        else if 
            [#"Break_Reasons"] = "no dolly/crate" and [#"Time_Consumption"] > 30
            then 60
        else if 
            [#"Break_Reasons"] = "missing products" and [#"Time_Consumption"] > 240
            then 20
        else if 
            [#"Break_Reasons"] = "rework previous mks" and [#"Time_Consumption"] > 240
            then 60
        else if 
            [#"Break_Reasons"] = "Unselected" and [#"Time_Consumption"] > 15
            then 15
        else if 
            [#"Break_Reasons"] = "shortage of staff" and [#"Time_Consumption"] > 30
            then 15
        else if 
            [#"Activity"] = "Production" and [#"Time_Consumption"] > 15 
        then 15
        else if 
            [#"Activity"] = "Production" and [#"Seq_Code"] <> null and [#"Time_Consumption"] < 1
        then 3 
        else if 
            [#"Activity"] = "Preparation/Changeover" and [#"Time_Consumption"] > 30 
            then 30
        else 
        [#"Time_Consumption"]),

    #"Added ""Activity Details"" Conditional Column" = Table.AddColumn(#"Adjusted time consumption", "Activity Detail", each if [Activity] = "Break" then [Break_Reasons] else [Activity]),
    #"Merge Week Recipe" = Table.AddColumn(#"Added ""Activity Details"" Conditional Column", "Week/Recipe", each Text.Combine({[Week], [Recipe_Name]}, " "), type text),
    #"Replace Missing Ingredients" = Table.ReplaceValue(#"Merge Week Recipe", null, each if ([#"Activity Detail"] = "missing products" and [#"Missing_Ingredients"] = null) then "Unselected" else null, Replacer.ReplaceValue,{"Missing_Ingredients"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Replace Missing Ingredients",{{"Time Consumption (Adjusted)", type number}}),
    #"Sorted Rows" = Table.Sort(#"Changed Type",{{"Finish_Time", Order.Descending}})
in
    #"Sorted Rows"
