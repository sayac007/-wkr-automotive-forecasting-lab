# Run from repository root: Rscript tests/test_calendar_de.R
# Constructed date/period cases test rules; they are not acquired holiday observations.
source("R/generate_calendar_de.R")

checks <- 0L
expect <- function(ok) {
  checks <<- checks + 1L
  if (!isTRUE(ok)) stop("Calendar check failed: ", checks)
}
reject <- function(expr) {
  expect(inherits(tryCatch({ force(expr); NULL }, error = identity), "error"))
}
period <- function(start, end = start, state = "Berlin") {
  data.frame(Bundesland = state, startDate = start, endDate = end,
             source = "unit-test rule case; not an acquired source")
}
public_2023 <- period(c("2023-01-01", "2023-04-07", "2023-04-10", "2023-05-01",
                       "2023-05-18", "2023-05-29", "2023-10-03",
                       "2023-12-25", "2023-12-26", "2024-01-01"))
build <- function(start, end, public = public_2023, school = empty_periods(),
                  extra = empty_periods()) {
  build_calendar_de(start, end, "Berlin", public, school, extra)
}
flag <- function(d, day, name) d[[name]][d$Datum == format(iso_date(day), "%d.%m.%Y")]

expect(as.character(calendar_easter(2023)) == "2023-04-09")
expect(as.character(calendar_easter(2026)) == "2026-04-05")
reject(iso_date("2023-02-30"))
reject(iso_date("2023-1-01"))
reject(calendar_easter(2023.5))

# Christmas shopping in KW51 in 2023, not Christmas holiday week KW52.
christmas <- build("2023-12-18", "2023-12-31")
expect(flag(christmas, "2023-12-23", "Weihnachten") == 1L)
expect(flag(christmas, "2023-12-24", "Weihnachten") == 0L)
expect(flag(christmas, "2023-12-25", "Verkaufstag") == 0L)
w <- weekly_calendar_de(christmas)
expect(w$Weihnachten[w$KW == 51L] == 1L)
expect(w$Weihnachten[w$KW == 52L] == 0L)
expect(all(w$Kalendertage == 7L))
expect(all(w$VollstaendigeWoche))

# Monday 24 December is still a shopping day.
christmas_monday <- build("2018-12-17", "2018-12-30",
                          public = period(c("2018-12-25", "2018-12-26", "2019-01-01")))
expect(flag(christmas_monday, "2018-12-24", "Weihnachten") == 1L)
expect(flag(christmas_monday, "2018-12-24", "Verkaufstag") == 1L)

# Labour Day Monday -> preceding Saturday/week; Tuesday -> Monday in same week.
may <- build("2023-04-24", "2023-05-07")
expect(flag(may, "2023-04-29", "ErsterMai") == 1L)
w <- weekly_calendar_de(may)
expect(w$ErsterMai[w$KW == 17L] == 1L)
expect(w$ErsterMai[w$KW == 18L] == 0L)
may_tuesday <- build("2018-04-23", "2018-05-06", public = period("2018-05-01"))
expect(flag(may_tuesday, "2018-04-30", "ErsterMai") == 1L)

# Regional closures, not Sunday alone, determine the final possible shopping day.
expect(as.character(last_shopping_day(iso_date("2023-05-02"),
                                      iso_date("2023-05-01"))) == "2023-04-29")
easter <- build("2023-04-03", "2023-04-10")
expect(flag(easter, "2023-04-06", "Karfreitag") == 1L)
expect(flag(easter, "2023-04-08", "Karfreitag") == 1L)

# Shopping events use the last eligible day BEFORE the event, just like holidays.
# Monday Halloween -> prior week; Tuesday/Saturday/Sunday -> same ISO week.
for (case in list(
  c("2022-10-24", "2022-11-06", "2022-10-29", "Halloween", "43", "44"),
  c("2023-10-23", "2023-11-05", "2023-10-30", "Halloween", "44", "43"),
  c("2020-10-26", "2020-11-01", "2020-10-30", "Halloween", "44", "45"),
  c("2021-10-25", "2021-10-31", "2021-10-30", "Halloween", "43", "44"),
  c("2022-02-07", "2022-02-20", "2022-02-12", "Valentinstag", "6", "7"),
  c("2023-02-06", "2023-02-19", "2023-02-13", "Valentinstag", "7", "6"),
  c("2021-02-08", "2021-02-14", "2021-02-13", "Valentinstag", "6", "7")
)) {
  event <- build(case[1], case[2], public = empty_periods())
  expect(flag(event, case[3], case[4]) == 1L)
  expect(sum(event[[case[4]]]) == 1L)
  week <- weekly_calendar_de(event)
  expect(week[[case[4]]][week$KW == as.integer(case[5])] == 1L)
  expect(all(week[[case[4]]][week$KW == as.integer(case[6])] == 0L))
}
# Reformation Day can coincide with Halloween, but Halloween is not a new legal holiday.
halloween <- build("2022-10-24", "2022-11-06", public = period("2022-10-31"))
expect(flag(halloween, "2022-10-29", "Halloween") == 1L)
expect(flag(halloween, "2022-10-31", "Halloween") == 0L)
expect(flag(halloween, "2022-10-31", "Feiertag") == 1L)
valentine <- build("2023-02-13", "2023-02-14", public = empty_periods())
expect(flag(valentine, "2023-02-14", "Feiertag") == 0L)

# A documented local Monday off + Tuesday public holiday makes a four-day break.
bridge <- build("2023-09-25", "2023-10-08", extra = period("2023-10-02"))
expect(flag(bridge, "2023-09-30", "Ferien") == 1L)
expect(flag(bridge, "2023-10-01", "Ferien") == 1L)
expect(flag(bridge, "2023-10-02", "Zusatzferien") == 1L)
expect(flag(bridge, "2023-09-30", "Schulferien") == 0L)
expect(flag(bridge, "2023-10-03", "Feiertag") == 1L)
days <- as.Date(bridge$Datum, "%d.%m.%Y")
expect(sum(bridge$Schulfrei[days >= iso_date("2023-09-30") &
                           days <= iso_date("2023-10-03")]) == 4L)
w <- weekly_calendar_de(bridge)
expect(w$Ferientage[w$KW == 39L] == 2L)
expect(abs(w$Ferienanteil[w$KW == 39L] - 2 / 7) < 1e-15)

# Tuesday school-holiday start, public-holiday Monday -> Sat/Sun/Mon extension.
tuesday <- build("2023-04-24", "2023-05-07", school = period("2023-05-02", "2023-05-05"))
expect(flag(tuesday, "2023-04-29", "Ferien") == 1L)
expect(flag(tuesday, "2023-04-30", "Ferien") == 1L)
expect(flag(tuesday, "2023-05-01", "Ferien") == 1L)
expect(flag(tuesday, "2023-05-01", "Schulferien") == 0L)
# A Tuesday start without a Monday public holiday does not create an extra weekend.
plain_tuesday <- build("2023-06-01", "2023-06-11",
                        school = period("2023-06-06", "2023-06-09"))
expect(flag(plain_tuesday, "2023-06-03", "Ferien") == 0L)

# Friday end includes Saturday, unless that Saturday is a public holiday.
expect(flag(tuesday, "2023-05-06", "Ferien") == 1L)
expect(flag(tuesday, "2023-05-06", "Schulferien") == 0L)
friday <- build("2021-04-26", "2021-05-02", public = period("2021-05-01"),
                school = period("2021-04-26", "2021-04-30"))
expect(flag(friday, "2021-05-01", "Ferien") == 0L)
# Sunday after a Friday end is not silently added to the holiday index.
expect(flag(tuesday, "2023-05-07", "Ferien") == 0L)

# Extension crosses year boundaries; ISO week-year can differ from calendar year.
boundary <- build("2023-12-25", "2024-01-07",
                    school = period("2024-01-01", "2024-01-05"))
expect(flag(boundary, "2023-12-30", "Ferien") == 1L)
expect(flag(boundary, "2023-12-31", "Ferien") == 1L)
iso <- weekly_calendar_de(build("2021-01-01", "2021-01-03",
                                public = period("2021-01-01")))
expect(iso$ISO_Jahr == 2020L && iso$KW == 53L)
expect(iso$Kalendertage == 3L && !iso$VollstaendigeWoche)
leap <- build("2024-02-28", "2024-03-01", public = empty_periods())
expect(nrow(leap) == 3L && "29.02.2024" %in% leap$Datum)

# One state's school days do not mark another state as being on holiday.
regional <- build_calendar_de("2023-09-30", "2023-10-03",
                               c("Berlin", "Niedersachsen"), public_2023,
                               period("2023-10-02"))
expect(nrow(regional) == 8L)
expect(regional$Ferien[regional$Bundesland == "Berlin" &
                       regional$Datum == "30.09.2023"] == 1L)
expect(regional$Ferien[regional$Bundesland == "Niedersachsen" &
                       regional$Datum == "30.09.2023"] == 0L)

# Invalid dates, missing rows, duplicates, nonbinary flags and unproven periods fail.
reject(build("2023-01-02", "2023-01-01"))
reject(build("2023-01-01", "2023-01-02", school = period("2023-02-01", "2023-01-01")))
bad <- period("2023-01-02"); bad$source <- ""
reject(build("2023-01-01", "2023-01-03", extra = bad))
reject(validate_calendar_de(christmas[-1, ], iso_date("2023-12-18"),
                             iso_date("2023-12-31"), "Berlin"))
reject(validate_calendar_de(rbind(christmas, christmas[1, ]), iso_date("2023-12-18"),
                             iso_date("2023-12-31"), "Berlin"))
bad <- christmas; bad$Ferien[1] <- 0.5
reject(validate_calendar_de(bad, iso_date("2023-12-18"), iso_date("2023-12-31"), "Berlin"))
bad <- christmas; bad$Datum[1] <- "not-a-date"
reject(validate_calendar_de(bad, iso_date("2023-12-18"), iso_date("2023-12-31"), "Berlin"))

# Same inputs produce identical frames; comparison never overwrites the reference.
expect(identical(christmas, build("2023-12-18", "2023-12-31")))
generated <- christmas[christmas$Verkaufstag == 1L, CALENDAR_COLUMNS]
reference <- generated
comparison <- compare_calendar_de(generated, reference, iso_date("2023-12-18"),
                                   iso_date("2023-12-31"), "Berlin")
expect(comparison$summary$Weihnachten$mismatches == 0L)
changed <- generated; changed$Weihnachten[1] <- 1L - changed$Weihnachten[1]
comparison <- compare_calendar_de(changed, reference, iso_date("2023-12-18"),
                                   iso_date("2023-12-31"), "Berlin")
expect(comparison$summary$Weihnachten$mismatches == 1L)
expect(identical(reference, generated))
# Historical references lack the new event columns: report unavailable, never fake zeros.
old_shape <- reference[LEGACY_CALENDAR_COLUMNS]
comparison <- compare_calendar_de(generated, old_shape, iso_date("2023-12-18"),
                                   iso_date("2023-12-31"), "Berlin")
expect(setequal(comparison$summary$not_in_reference, c("Halloween", "Valentinstag")))
expect(is.null(comparison$summary$Halloween) && is.null(comparison$summary$Valentinstag))
expect(comparison$summary$Weihnachten$mismatches == 0L)
comparison <- compare_calendar_de(generated[-1, ], reference, iso_date("2023-12-18"),
                                   iso_date("2023-12-31"), "Berlin")
expect(comparison$summary$legacy_only_rows == 1L)
expect(nrow(comparison$row_differences) == 1L &&
         comparison$row_differences$Presence == "legacy_only")
reject(compare_calendar_de(generated, rbind(reference, reference[1, ]),
                             iso_date("2023-12-18"), iso_date("2023-12-31"), "Berlin"))

cat("Passed", checks, "R calendar checks.\n")
