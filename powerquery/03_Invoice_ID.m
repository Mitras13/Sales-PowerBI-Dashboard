// جایگزین کوئری Invoice_ID — نسخه‌ی چهارم.
// چرا برگشت خورد به vw_INV_SAL_54: نسخه‌ی قبلی از Fact_Invoice_5040 (به‌خاطر ستون آماده‌ی
// DateKey) استفاده می‌کرد، ولی تست مستقیم نشان داد محاسبه‌ی DateKey/ProvinceID داخل تعریف آن
// ویو به‌شدت سنگین است: همان فیلتر ساده از پشت Fact_Invoice_5040 حدود ۸۸ ثانیه طول کشید، در
// حالی که از پشت vw_INV_SAL_54 فقط ۱۸.۷ ثانیه شد. پس منطق «مبنای پرداخت»/ماه دوباره همان‌جا
// که قبلاً بود (native SQL Query با CASE WHEN) انجام می‌شود.
//
// نسخه‌ی چهارم — سه ستون اضافه شد: بررسی گزارش (Report/Layout داخل خود pbix) نشان داد سه
// اسلایسر در صفحه‌های «فروش» و «Duplicate of فروش» به [سرپرست سازنده فاکتور]،
// [سوپروایزران سازنده فاکتور] و [مدیر سازنده فاکتور] از همین کوئری Invoice_ID وصل بودند، ولی
// این سه ستون در نسخه‌ی قبلی این کوئری نبودند (فقط در Invoice_Item بودند) — یعنی آن سه
// اسلایسر بعد از Apply خالی/خراب می‌شدند. چون این سه ستون در همان ویوی vw_INV_SAL_54 هست،
// اضافه کردنشان اینجا هزینه‌ی محسوسی ندارد (Invoice_ID سطح فاکتور است، نه سطح آیتم).
//
// نسخه‌ی پنجم — ستون [مبلغ فاکتور] اضافه شد: مژر sum_new_customer به
// SUM(Invoice_ID[مبلغ فاکتور]) نیاز داشت (عمداً از Invoice_ID خونده می‌شه نه Invoice_Item،
// چون Invoice_Item به‌خاطر STRING_SPLIT کد محصولات ممکنه چند ردیف به ازای یک فاکتور داشته
// باشه و SUM از آن‌جا مبلغ فاکتور رو چندبار می‌شمرد؛ Invoice_ID سطح یک‌ردیف-به‌ازای-فاکتور
// را حفظ می‌کنه). این ستون قبلاً این‌جا نبود، برای همین آن مژر خراب شده بود.

let
    Source = Sql.Database("127.0.0.1", "Mitra_sarkhosh", [Query="
SELECT
    [شماره مشتری],
    [نام مشتری],
    [استان],
    [شهر],
    [نوع فاکتور],
    [کد هدایا],
    [مبلغ فاکتور],
    [سرپرست سازنده فاکتور],
    [سوپروایزران سازنده فاکتور],
    [مدیر سازنده فاکتور],
    CASE WHEN [نوع پرداخت] = N'کارت به کارت' THEN [تاریخ ثبت اطلاعات پرداختی] ELSE [تاریخ پرداخت] END AS [مبنای پرداخت],
    TRY_CAST(SUBSTRING(CASE WHEN [نوع پرداخت] = N'کارت به کارت' THEN [تاریخ ثبت اطلاعات پرداختی] ELSE [تاریخ پرداخت] END, 6, 2) AS int) AS [ایندکس ماه]
FROM dbo.vw_INV_SAL_54
WHERE TRY_CAST(SUBSTRING(CASE WHEN [نوع پرداخت] = N'کارت به کارت' THEN [تاریخ ثبت اطلاعات پرداختی] ELSE [تاریخ پرداخت] END, 6, 2) AS int) BETWEEN 1 AND 12
ORDER BY [شماره مشتری] DESC;
"]),
    #"Changed Type" = Table.TransformColumnTypes(Source, {{"شماره مشتری", Int64.Type}, {"نام مشتری", type text}, {"استان", type text}, {"شهر", type text}, {"نوع فاکتور", type text}, {"کد هدایا", type text}, {"مبلغ فاکتور", Int64.Type}, {"سرپرست سازنده فاکتور", type text}, {"سوپروایزران سازنده فاکتور", type text}, {"مدیر سازنده فاکتور", type text}, {"ایندکس ماه", Int64.Type}}),
    #"Added ماه" = Table.AddColumn(#"Changed Type", "ماه", each {"فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور", "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"}{[ایندکس ماه] - 1}, type text),
    #"Merged Province" = Table.NestedJoin(#"Added ماه", {"استان"}, Dim_Province, {"استان"}, "Dim_Province", JoinKind.LeftOuter),
    #"Expanded Province" = Table.ExpandTableColumn(#"Merged Province", "Dim_Province", {"province"}, {"province"}),
    #"Changed Type1" = Table.TransformColumnTypes(#"Expanded Province", {{"province", type text}})
in
    #"Changed Type1"
