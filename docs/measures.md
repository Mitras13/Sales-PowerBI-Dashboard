# مژرهای DAX

> این فهرست بر اساس کارهای انجام‌شده نوشته شده. قبل از انتشار، هر فرمول با نسخه‌ی فعلی `.pbix` مقایسه شود.

## مژرهای اصلی
| مژر | کاربرد |
|---|---|
| `zarib_vosoli_kol` | ضریب وصولی کل (تومان/هزار تومان به‌ازای هر تماس پاسخ‌داده) |
| `تارگت_وصول` | جمع تارگت ماهانه از جدول `target` |
| `درصد_تحقق_هدف` | وصول کل ÷ تارگت ماه |
| `Growth_MoM_%` | رشد نسبت به ماه قبل |
| `Growth_MoM_Label` | همان رشد با فلش ▲/▼ برای نمایش |
| `Achievement_Label` | درصد تحقق هدف با فلش |
| `province_share` | سهم دوره‌ی فیلترشده از کل |

## نمونه: رشد ماهانه
```dax
Growth_MoM_% =
VAR CurrentSeq = MAX(Dim_Date[سال]) * 12 + MAX(Dim_Date[ایندکس ماه])
VAR PrevSeq = CurrentSeq - 1
VAR CurrentSales = CALCULATE([vosool_Bn], FILTER(ALL(Dim_Date), Dim_Date[سال] * 12 + Dim_Date[ایندکس ماه] = CurrentSeq))
VAR PrevSales = CALCULATE([vosool_Bn], FILTER(ALL(Dim_Date), Dim_Date[سال] * 12 + Dim_Date[ایندکس ماه] = PrevSeq))
RETURN DIVIDE(CurrentSales - PrevSales, PrevSales)
```

## نمونه: ضریب وصولی
```dax
zarib_vosoli_kol =
DIVIDE(
    SUM(Vosool_Agent[مبلغ وصولی کارتابلی]) * 10000000,
    SUM(Vosool_Agent[تعداد پاسخ داد کارتابلی])
)
```
> توجه: این فرمول با تغییر مقیاس `Vosool_Agent` (تقسیم بر ۱۰٬۰۰۰٬۰۰۰ در SQL) باید بازبینی شود.
