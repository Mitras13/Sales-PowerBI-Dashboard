let
    Source = Excel.Workbook(File.Contents("D:\MITRA\داشبورد ها\داشبورد فروش 5040\vosool-province-3.xlsx"), null, true),
    target_Sheet = Source{[Item="target",Kind="Sheet"]}[Data],
    #"Promoted Headers" = Table.PromoteHeaders(target_Sheet, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"ماه", type text}, {"وصول", type number}, {"تارگت", Int64.Type}})
in
    #"Changed Type"
