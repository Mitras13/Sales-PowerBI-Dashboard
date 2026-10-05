let
    Source = Excel.Workbook(File.Contents("D:\MITRA\داشبورد ها\داشبورد فروش 5040\excel_5040.xlsx"), null, true),
    Data_Sheet = Source{[Item="Data",Kind="Sheet"]}[Data],
    #"Promoted Headers" = Table.PromoteHeaders(Data_Sheet, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{ {"تعداد پاسخ داد", Int64.Type},  {"ماه", type text}}),
    #"Filtered Rows" = Table.SelectRows(#"Changed Type", each ([کارشناس] <> 5040 and [کارشناس] <> "(تست اپراتور جدید)")),
    #"Filtered Rows1" = Table.SelectRows(#"Filtered Rows", each [کارشناس] <> null and [کارشناس] <> "")
in
    #"Filtered Rows1"
