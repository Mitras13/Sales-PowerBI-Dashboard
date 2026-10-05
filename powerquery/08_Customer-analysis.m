// جایگزین کوئری Customer-analysis — نسخه‌ی سوم، برگشت به vw_INV_SAL_54.
// چرا برگشت خورد: مثل Invoice_ID/Invoice_Item، Fact_Invoice_5040 به‌خاطر محاسبه‌ی سنگین
// DateKey/ProvinceID حدود ۸۰ برابر کندتر از vw_INV_SAL_54 است (تست مستقیم: ۸۸ ثانیه در
// برابر ۱۸.۷ ثانیه). پس ستون first_paid دوباره از رشته‌ی متنی «مبنا پرداخت» ساخته می‌شود
// (مثل نسخه‌ی اول)، نه از DateKey.
// تنها منبع اکسلی باقی‌مانده اینجا "phone history" است.
// نکته‌ی سرعت: Grouped Rows (جمع‌بندی هر مشتری: تعداد خرید، جمع مبلغ، اولین تاریخ پرداخت،
// استان) قبلاً با Table.Group روی ۳.۵ میلیون ردیف داخل خود Power Query (لوکال) انجام می‌شد —
// همین preview/Apply را برای چند دقیقه معطل نگه می‌داشت. حالا GROUP BY مستقیم داخل خود SQL
// Server انجام می‌شود (کاری که پایگاه‌داده برایش ساخته شده و خیلی سریع‌تر انجامش می‌دهد)،
// و Power Query فقط نتیجه‌ی نهایی (یک ردیف به ازای هر مشتری) را دریافت می‌کند.

let
    Source = Sql.Database("127.0.0.1", "Mitra_sarkhosh", [Query="
SELECT
    [شماره مشتری],
    COUNT(*) AS num_phone_purchased,
    SUM([مبلغ فاکتور]) AS sum_phone_purchased,
    MIN(CASE WHEN [نوع پرداخت] = N'کارت به کارت' THEN [تاریخ ثبت اطلاعات پرداختی] ELSE [تاریخ پرداخت] END) AS first_paid,
    MIN([استان]) AS [Invoice_ID.استان]
FROM dbo.vw_INV_SAL_54
WHERE [سریال فاکتور] IS NOT NULL
GROUP BY [شماره مشتری];
"]),
    #"Changed Type" = Table.TransformColumnTypes(Source, {{"شماره مشتری", Int64.Type}, {"num_phone_purchased", Int64.Type}, {"sum_phone_purchased", type nullable number}, {"first_paid", type text}, {"Invoice_ID.استان", type nullable text}}),
    #"Merged Queries" = Table.NestedJoin(#"Changed Type", {"شماره مشتری"}, #"phone history", {"Column1"}, "phone history", JoinKind.LeftOuter),
    #"Expanded phone history" = Table.ExpandTableColumn(#"Merged Queries", "phone history", {"Column2"}, {"Column2"}),
    #"Replaced Value" = Table.ReplaceValue(#"Expanded phone history", null, false, Replacer.ReplaceValue, {"Column2"}),
    #"Renamed Columns" = Table.RenameColumns(#"Replaced Value", {{"Column2", "phone_history_check"}}),
    #"Added Custom" = Table.AddColumn(#"Renamed Columns", "customer_label", each if [num_phone_purchased] > 1 then "مشتریان قدیمی"
else if [num_phone_purchased] = 1 then
    if [phone_history_check] = true then "مشتریان قدیمی"
    else "مشتریان جدید"
else "مشتریان جدید"),
    #"Changed Type1" = Table.TransformColumnTypes(#"Added Custom", {{"customer_label", type text}, {"sum_phone_purchased", type number}})
in
    #"Changed Type1"
