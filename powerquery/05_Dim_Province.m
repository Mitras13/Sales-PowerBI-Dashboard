let
    Source = Excel.Workbook(File.Contents("D:\MITRA\داشبورد ها\داشبورد فروش 5040\vosool-province-3.xlsx"), null, true),
    Dim_Province_Sheet = Source{[Item="Dim_Province",Kind="Sheet"]}[Data],
    #"Changed Type" = Table.TransformColumnTypes(Dim_Province_Sheet,{{"Column1", type text}, {"Column2", type text}}),
    #"Promoted Headers" = Table.PromoteHeaders(#"Changed Type", [PromoteAllScalars=true]),
    #"Changed Type1" = Table.TransformColumnTypes(#"Promoted Headers",{{"استان", type text}, {"province", type text}})
in
    #"Changed Type1"
