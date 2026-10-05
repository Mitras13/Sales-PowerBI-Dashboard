// جایگزین کوئری Dim_karshenas — نسخه‌ی نهایی و ساده.
// یک جدول dimension آماده و کوچک به اسم Dim_Karshenas_5040 در دیتابیس پیدا شد (فقط ۴۸۹۴
// ردیف) که دقیقاً وضعیت/گروه/سرپرست/سوپروایزر/مدیر هر کارشناس را دارد — نیازی به ROW_NUMBER
// یا خواندن جدول بزرگ SaleR_54 نیست. چون حجمش خیلی کم است، پاور بی‌آی هیچ‌وقت برایش سنگین
// نمی‌شود.

let
    Source = Sql.Database("127.0.0.1", "Mitra_sarkhosh"){[Schema = "dbo", Item = "Dim_Karshenas_5040"]}[Data],
    #"Filtered Rows" = Table.SelectRows(Source, each
        [وضعیت] = "فعال"
        and [نام کارشناس] <> null
        and Text.Trim([نام کارشناس]) <> ""
        and not Text.Contains([نام کارشناس], "تست")
        and not Text.Contains(Text.Lower([نام کارشناس]), "test")
        and [نام کارشناس] <> "5040"),
    #"Renamed Columns" = Table.RenameColumns(#"Filtered Rows", {{"نام کارشناس", "کارشناسان"}, {"سرپرست", "سرپرستان"}, {"سوپروایزر", "سوپروایزران"}})
in
    #"Renamed Columns"
