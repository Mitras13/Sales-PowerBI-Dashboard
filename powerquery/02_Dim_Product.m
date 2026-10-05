// جایگزین کوئری Dim_Product: خواندن از ویوی SQL به‌جای اکسل
// ستون‌ها دقیقاً همنام با نسخه اکسل هستند، پس هیچ Measure/رابطه‌ای نمی‌شکند.

let
    Source = Sql.Database("127.0.0.1", "Mitra_sarkhosh"),
    dbo_vw_Dim_Product = Source{[Schema = "dbo", Item = "vw_Dim_Product"]}[Data],
    #"Filtered Rows" = Table.SelectRows(dbo_vw_Dim_Product, each ([کد محصول] <> null)),
    // یک ردیف خراب در دیتابیس هست (کد محصول = "oj6o5hmaea" برای "چای سبز ترکیبی") که عدد نیست؛
    // قبل از تبدیل نوع، همچین ردیف‌هایی را کنار می‌گذاریم تا کل کوئری با ارور متوقف نشود.
    #"Filtered Numeric Codes" = Table.SelectRows(#"Filtered Rows", each not (try Number.From([کد محصول]))[HasError]),
    #"Changed Type" = Table.TransformColumnTypes(#"Filtered Numeric Codes", {{"کد محصول", type number}, {"قیمت واحد", type number}, {"تعداد", type number}, {"قیمت پک", type number}}),
    #"Removed Other Columns" = Table.SelectColumns(#"Changed Type", {"کد محصول", "محصول", "قیمت واحد", "تعداد", "قیمت پک", "محصول2", "دسته بندی محصول"}),
    #"Renamed Columns" = Table.RenameColumns(#"Removed Other Columns", {{"تعداد", "تعداد محصول در پک"}, {"قیمت واحد", "قیمت واحد محصول"}})
in
    #"Renamed Columns"
