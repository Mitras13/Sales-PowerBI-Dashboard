// جایگزین کوئری Invoice_Item — نسخه‌ی سوم، برگشت به vw_INV_SAL_54.
// چرا برگشت خورد: Fact_Invoice_5040 (که نسخه‌ی قبلی از آن استفاده می‌کرد) محاسبه‌ی
// DateKey/ProvinceID داخلی‌اش خیلی سنگین است — تست مستقیم نشان داد همان فیلتر ساده از پشت
// این ویو ۸۸ ثانیه طول می‌کشد در برابر ۱۸.۷ ثانیه از پشت vw_INV_SAL_54. اضافه کردن
// ROW_NUMBER با ORDER BY متنی روی vw_INV_SAL_54 عملاً هزینه‌ی اضافه‌ی محسوسی ندارد (۱۹.۴
// ثانیه در تست) — پس نیازی به پیچیده‌تر کردن کوئری برای این بخش نبود؛ گلوگاه واقعی فقط
// انتخاب ویوی درست بود.
//
// نسخه‌ی چهارم — کاهش ستون‌ها: بعد از STRING_SPLIT این کوئری حدود ۳.۶ میلیون ردیف تولید
// می‌کند؛ گلوگاه کندی‌اش دیگر SQL Server نبود بلکه حجم انتقال/پردازش ۴۸ ستون (خیلی‌هاشان
// nvarchar(MAX)) برای این همه ردیف در سمت Power BI بود. ۱۲ ستونی که داده‌ی لجستیک/ممیزی
// عملیاتی به‌نظر می‌رسیدند (نه چیزی که معمولاً در یک داشبورد فروش/KPI نمایش داده شود) حذف
// شدند: آدرس، کدپستی، شماره پیگیری، تاریخ وضعیت مالی، بررسی کننده مالی، تعیین وضعیت نماینده،
// تعداد تماس نمایندگی، تاریخ ورود به نمایندگی، ورود به کارتابل بررسی پست، ورود به کارتابل
// پست، زمان گرفتن بارکدپستی، چهار رقم شماره کارت (این آخری هم به‌خاطر حساسیت داده‌ی کارت
// بانکی). این یک حدس مبتنی بر نام ستون‌هاست، نه بررسی واقعی ویژوال‌های گزارش — اگر بعد از
// Apply یک ویژوال به یکی از این ستون‌ها نیاز داشت (ارور Column not found)، همان ستون را از
// هر دو SELECT (در CTE و در SELECT نهایی) برگردانید.

let
    Source = Sql.Database("127.0.0.1", "Mitra_sarkhosh", [Query="
WITH Filtered AS (
    SELECT
        [سریال فاکتور], [شماره مشتری], [نام مشتری], [استان], [شهر],
        [کد محصولات], [مبلغ فاکتور], [نوع فاکتور], [نوع پرداخت], [وضعیت فاکتور], [وضعیت پرداخت],
        [تاریخ پرداخت], [موعد واریزی], [تاریخ ثبت اطلاعات پرداختی], [وضعیت مالی],
        [نوع ثبت فاکتور], [تاریخ ثبت], [نمایندگی],
        [تعداد تماس پیگیری], [ثبت کننده], [فاکتور برگشتی], [تاریخ برگشت فاکتور], [روش ارسال],
        [تاریخ تحویل],
        [سوپروایزران سازنده فاکتور], [سرپرست سازنده فاکتور], [مدیر سازنده فاکتور],
        [زمان لغو فاکتور], [درگاه پرداخت],
        CASE WHEN [نوع پرداخت] = N'کارت به کارت' THEN [تاریخ ثبت اطلاعات پرداختی] ELSE [تاریخ پرداخت] END AS [مبنای پرداخت]
    FROM dbo.vw_INV_SAL_54
    WHERE [کد محصولات] <> '111111(1)'
),
Ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY [شماره مشتری] ORDER BY [مبنای پرداخت] ASC) AS Purchase_Rank,
        TRY_CAST(SUBSTRING([مبنای پرداخت], 6, 2) AS int) AS [ایندکس ماه ]
    FROM Filtered
),
Split AS (
    SELECT r.*, LTRIM(RTRIM(s.value)) AS [_item]
    FROM Ranked r
    CROSS APPLY STRING_SPLIT(r.[کد محصولات], ',') s
),
Extracted AS (
    SELECT *,
        CASE WHEN CHARINDEX('(', [_item]) > 0 THEN LTRIM(RTRIM(LEFT([_item], CHARINDEX('(', [_item]) - 1))) ELSE LTRIM(RTRIM([_item])) END AS [_کد محصول متن],
        CASE WHEN CHARINDEX('(', [_item]) > 0 AND CHARINDEX(')', [_item]) > CHARINDEX('(', [_item])
             THEN SUBSTRING([_item], CHARINDEX('(', [_item]) + 1, CHARINDEX(')', [_item]) - CHARINDEX('(', [_item]) - 1)
             ELSE NULL END AS [_تعداد متن]
    FROM Split
)
SELECT
    e.[سریال فاکتور],
    TRY_CAST(e.[_کد محصول متن] AS float) AS [کد محصول],
    TRY_CAST(e.[_تعداد متن] AS float) AS [تعداد محصول از کد محصول],
    p.[محصول] AS [محصولات لول 3],
    p.[قیمت پک],
    p.[محصول2] AS [محصولات لول 2],
    p.[دسته بندی محصول] AS [محصولات لول 1],
    p.[تعداد] AS [تعداد محصول در پک],
    e.[شماره مشتری], e.[نام مشتری], e.[استان], e.[شهر],
    e.[مبلغ فاکتور], e.[نوع فاکتور], e.[نوع پرداخت], e.[وضعیت فاکتور], e.[وضعیت پرداخت],
    e.[تاریخ پرداخت], e.[موعد واریزی], e.[تاریخ ثبت اطلاعات پرداختی],
    e.[وضعیت مالی], e.[نوع ثبت فاکتور], e.[تاریخ ثبت],
    e.[نمایندگی], e.[تعداد تماس پیگیری], e.[ثبت کننده], e.[فاکتور برگشتی], e.[تاریخ برگشت فاکتور],
    e.[روش ارسال],
    e.[تاریخ تحویل], e.[سوپروایزران سازنده فاکتور], e.[سرپرست سازنده فاکتور], e.[مدیر سازنده فاکتور],
    e.[زمان لغو فاکتور], e.[درگاه پرداخت],
    e.[مبنای پرداخت], e.Purchase_Rank, e.[ایندکس ماه ]
FROM Extracted e
LEFT JOIN dbo.vw_Dim_Product p ON TRY_CAST(e.[_کد محصول متن] AS float) = TRY_CAST(p.[کد محصول] AS float)
ORDER BY e.[سریال فاکتور] DESC;
"]),
    #"Changed Type" = Table.TransformColumnTypes(Source, {{"سریال فاکتور", Int64.Type}, {"کد محصول", type number}, {"تعداد محصول از کد محصول", type number}, {"قیمت پک", type number}, {"تعداد محصول در پک", type number}, {"شماره مشتری", Int64.Type}, {"مبلغ فاکتور", Int64.Type}, {"Purchase_Rank", Int64.Type}, {"ایندکس ماه ", Int64.Type}}),
    #"Inserted Division" = Table.AddColumn(#"Changed Type", "تعداد پک", each if [تعداد محصول در پک] = null or [تعداد محصول در پک] = 0 then null else [تعداد محصول از کد محصول] / [تعداد محصول در پک], type number),
    #"Added قیمت کل" = Table.AddColumn(#"Inserted Division", "قیمت کل", each if [کد محصول] = null then [مبلغ فاکتور] else [قیمت پک] * [تعداد پک], type number),
    #"Added ماه" = Table.AddColumn(#"Added قیمت کل", "ماه", each if [#"ایندکس ماه "] <> null and [#"ایندکس ماه "] >= 1 and [#"ایندکس ماه "] <= 12 then {"فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور", "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"}{[#"ایندکس ماه "] - 1} else "", type text),
    #"Replaced Value" = Table.ReplaceValue(#"Added ماه", null, "سایت", Replacer.ReplaceValue, {"محصولات لول 3", "محصولات لول 2", "محصولات لول 1"}),
    #"Filtered ماه" = Table.SelectRows(#"Replaced Value", each [ماه] <> ""),
    #"Merged Province" = Table.NestedJoin(#"Filtered ماه", {"استان"}, Dim_Province, {"استان"}, "Dim_Province", JoinKind.LeftOuter),
    #"Expanded Province" = Table.ExpandTableColumn(#"Merged Province", "Dim_Province", {"province"}, {"province"}),
    #"Added تاریخ" = Table.AddColumn(#"Expanded Province", "مبنای پرداخت - تاریخ", each Text.BeforeDelimiter([مبنای پرداخت], " "), type text),
    #"Added ساعت" = Table.AddColumn(#"Added تاریخ", "مبنای پرداخت - ساعت", each Text.AfterDelimiter([مبنای پرداخت], " "), type text),
    #"Merged Dim_Date" = Table.NestedJoin(#"Added ساعت", {"مبنای پرداخت - تاریخ"}, Dim_Date, {"تاریخ"}, "Dim_Date", JoinKind.LeftOuter),
    #"Expanded Dim_Date" = Table.ExpandTableColumn(#"Merged Dim_Date", "Dim_Date", {"روز", "تعطیل رسمی", "ایندکس روز"}, {"روز", "تعطیل رسمی", "ایندکس روز"}),
    #"Changed Type Time" = Table.TransformColumnTypes(#"Expanded Dim_Date", {{"مبنای پرداخت - ساعت", type time}}),
    #"Start of Hour" = Table.TransformColumns(#"Changed Type Time", {{"مبنای پرداخت - ساعت", Time.StartOfHour, type time}})
in
    #"Start of Hour"
