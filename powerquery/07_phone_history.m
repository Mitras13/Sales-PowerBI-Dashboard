let
    Source = Excel.Workbook(File.Contents("D:\MITRA\داشبورد ها\داشبورد فروش 5040\vosool-province-3.xlsx"), null, true),
    #"phone history_Sheet" = Source{[Item="phone history",Kind="Sheet"]}[Data],
    #"Changed Type" = Table.TransformColumnTypes(#"phone history_Sheet",{{"Column1", Int64.Type}, {"Column2", type logical}})
in
    #"Changed Type"
