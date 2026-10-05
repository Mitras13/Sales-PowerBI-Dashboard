// جایگزین کامل کوئری Dim_Date
// این نسخه به‌جای ده‌ها شرط دستی (که فقط فروردین تا خرداد ۱۴۰۴ را پوشش می‌داد)
// تقویم شمسی را ریاضی و پویا از ۱۳۹۷ تا ۱۴۱۰ می‌سازد؛ یعنی دیگر هیچ‌وقت "تمام" نمی‌شود.
//
// نکته مهم: ستون "تعطیل رسمی" اینجا فقط جمعه‌ها را تعطیل می‌زند (چون تعطیلات رسمی/مناسبتی
// در هیچ منبع دیگری موجود نیست). اگر تعطیلات ملی/مذهبی هم لازم است در گزارش لحاظ شود،
// باید یک جدول کوچک override (تاریخ‌های تعطیل خاص) جدا نگه داشت و اینجا merge کرد.
//
// نحوه استفاده: روی کوئری Dim_Date در Power Query راست‌کلیک > Advanced Editor > کل محتوا
// را با متن زیر (از let تا in ... انتها) جایگزین کنید.

let
    fnG2J = (gy as number, gm as number, gd as number) as record =>
        let
            g_days = {31,28,31,30,31,30,31,31,30,31,30,31},
            j_days = {31,31,31,31,31,31,30,30,30,30,30,29},
            gy2 = if gm > 2 then gy + 1 else gy,
            daysSumRaw = List.Sum(List.FirstN(g_days, gm - 1)),
            daysSum = if daysSumRaw = null then 0 else daysSumRaw,
            days0 = 355666 + (365 * gy) + Number.RoundDown((gy2 + 3) / 4) - Number.RoundDown((gy2 + 99) / 100) + Number.RoundDown((gy2 + 399) / 400) + gd + daysSum,
            jy0 = -1595 + (33 * Number.RoundDown(days0 / 12053)),
            days1 = Number.Mod(days0, 12053),
            jy1 = jy0 + (4 * Number.RoundDown(days1 / 1461)),
            days2 = Number.Mod(days1, 1461),
            jyFinal = if days2 > 365 then jy1 + Number.RoundDown((days2 - 1) / 365) else jy1,
            daysFinal = if days2 > 365 then Number.Mod(days2 - 1, 365) else days2,
            jmd = List.Accumulate(
                {1..12},
                [remaining = daysFinal, month = 1, day = daysFinal + 1, found = false],
                (state, m) =>
                    if state[found] then state
                    else
                        let dim = j_days{m - 1}
                        in
                            if state[remaining] < dim then
                                [remaining = state[remaining], month = m, day = state[remaining] + 1, found = true]
                            else
                                [remaining = state[remaining] - dim, month = state[month], day = state[day], found = false]
            )
        in
            [Year = jyFinal, Month = jmd[month], Day = jmd[day]],

    StartDate = #date(2018, 3, 1),
    EndDate = #date(2031, 12, 31),
    DateList = List.Dates(StartDate, Duration.Days(EndDate - StartDate) + 1, #duration(1, 0, 0, 0)),
    Base = Table.FromList(DateList, Splitter.SplitByNothing(), {"GregorianDate"}),
    AddJalali = Table.AddColumn(Base, "Jalali", each fnG2J(Date.Year([GregorianDate]), Date.Month([GregorianDate]), Date.Day([GregorianDate]))),
    Expanded = Table.ExpandRecordColumn(AddJalali, "Jalali", {"Year", "Month", "Day"}, {"سال", "ایندکس ماه", "روز عدد"}),
    AddDateText = Table.AddColumn(Expanded, "تاریخ", each Text.From([سال]) & "/" & Text.PadStart(Text.From([ایندکس ماه]), 2, "0") & "/" & Text.PadStart(Text.From([روز عدد]), 2, "0"), type text),
    MonthNames = {"فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور", "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"},
    AddMonthName = Table.AddColumn(AddDateText, "ماه", each MonthNames{[ایندکس ماه] - 1}, type text),
    WeekdayNames = {"دوشنبه", "سه شنبه", "چهارشنبه", "پنجشنبه", "جمعه", "شنبه", "یکشنبه"},
    WeekdayIndex = {3, 4, 5, 6, 7, 1, 2},
    AddWeekday = Table.AddColumn(AddMonthName, "روز", each WeekdayNames{Date.DayOfWeek([GregorianDate], Day.Monday)}, type text),
    AddDayIndex = Table.AddColumn(AddWeekday, "ایندکس روز", each WeekdayIndex{Date.DayOfWeek([GregorianDate], Day.Monday)}, Int64.Type),
    AddHoliday = Table.AddColumn(AddDayIndex, "تعطیل رسمی", each if [روز] = "جمعه" then "تعطیل" else null, type text),
    // GregorianDate نگه داشته می‌شود تا کوئری‌هایی که منبعشان Fact_Invoice_5040 است (که DateKey میلادی واقعی دارد)
    // بتوانند روی تاریخ میلادی merge بزنند، نه روی رشته‌ی متنی تاریخ شمسی (سریع‌تر و بدون ریسک ناهماهنگی فرمت متن).
    FinalCols = Table.SelectColumns(AddHoliday, {"GregorianDate", "تاریخ", "روز", "تعطیل رسمی", "ایندکس روز", "ماه", "ایندکس ماه"})
in
    FinalCols
