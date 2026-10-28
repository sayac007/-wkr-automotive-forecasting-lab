#!/usr/bin/env Rscript
# German shopping-calendar features, not holiday-week flags.
# Core calculation/tests use base R. API/cache JSON parsing uses jsonlite.

WKR_STATES <- c(
  "DE-BE" = "Berlin", "DE-BB" = "Brandenburg", "DE-HB" = "Bremen",
  "DE-NI" = "Niedersachsen", "DE-NW" = "Nordrhein-Westfalen",
  "DE-ST" = "Sachsen-Anhalt", "DE-TH" = "Thüringen"
)
LEGACY_CALENDAR_COLUMNS <- c(
  "Datum", "Bundesland", "Ferien", "Karfreitag", "Weihnachten",
  "Silvester", "ErsterMai", "Pfingsten", "Himmelfahrt"
)
CALENDAR_COLUMNS <- c(LEGACY_CALENDAR_COLUMNS, "Halloween", "Valentinstag")
EVENT_COLUMNS <- setdiff(CALENDAR_COLUMNS, c("Datum", "Bundesland", "Ferien"))

iso_date <- function(x) {
  x <- as.character(x)
  d <- suppressWarnings(as.Date(x, format = "%Y-%m-%d"))
  if (anyNA(x) || anyNA(d) || any(!grepl("^\\d{4}-\\d{2}-\\d{2}$", x)) ||
      any(format(d, "%Y-%m-%d") != x)) stop("Invalid ISO date")
  d
}

weekday_monday <- function(d) (as.POSIXlt(d, tz = "UTC")$wday + 6L) %% 7L

calendar_easter <- function(year) {
  if (length(year) != 1L || !is.finite(year) || year != as.integer(year) ||
      year < 1583L || year > 9998L) stop("Invalid Gregorian year")
  a <- year %% 19; b <- year %/% 100; c <- year %% 100
  d <- b %/% 4; e <- b %% 4; f <- (b + 8) %/% 25; g <- (b - f + 1) %/% 3
  h <- (19 * a + b - d - g + 15) %% 30; i <- c %/% 4; k <- c %% 4
  l <- (32 + 2 * e + 2 * i - h - k) %% 7; m <- (a + 11 * h + 22 * l) %/% 451
  z <- h + l - 7 * m + 114
  iso_date(sprintf("%04d-%02d-%02d", year, z %/% 31, z %% 31 + 1))
}

empty_periods <- function() {
  data.frame(Bundesland = character(), startDate = character(), endDate = character(),
             source = character(), stringsAsFactors = FALSE)
}

check_periods <- function(x, states) {
  required <- names(empty_periods())
  if (!is.data.frame(x) || !all(required %in% names(x))) {
    stop("Periods need Bundesland, startDate, endDate, source")
  }
  if (!nrow(x)) return(x)
  if (anyNA(x[required]) || any(!nzchar(trimws(as.character(x$source)))) ||
      any(!x$Bundesland %in% states)) stop("Unknown state or missing period evidence")
  if (any(iso_date(x$startDate) > iso_date(x$endDate))) stop("Reversed period")
  x
}

period_days <- function(x, state, start, end) {
  x <- x[x$Bundesland == state, , drop = FALSE]
  days <- as.Date(character())
  for (i in seq_len(nrow(x))) {
    a <- max(start, iso_date(x$startDate[i]))
    b <- min(end, iso_date(x$endDate[i]))
    if (a <= b) days <- c(days, seq.Date(a, b, by = "day"))
  }
  unique(days)
}

last_shopping_day <- function(holiday, public_days) {
  d <- holiday - 1L
  while (weekday_monday(d) == 6L || d %in% public_days) d <- d - 1L
  d
}

build_calendar_de <- function(start, end, states, public, school,
                              extra_school = empty_periods()) {
  start <- iso_date(start); end <- iso_date(end)
  if (length(start) != 1L || length(end) != 1L || start > end ||
      !length(states) || anyDuplicated(states) || any(!states %in% WKR_STATES)) {
    stop("Invalid calendar range/states")
  }
  public <- check_periods(public, states)
  school <- check_periods(school, states)
  extra_school <- check_periods(extra_school, states)
  # Padding preserves Saturday/Sunday before a Monday at the year boundary.
  grid <- seq.Date(start - 7L, end + 7L, by = "day")
  years <- seq(as.integer(format(start, "%Y")) - 1L,
               as.integer(format(end, "%Y")) + 1L)
  result <- list()
  for (state in states) {
    pub <- period_days(public, state, min(grid), max(grid))
    sch <- grid %in% period_days(school, state, min(grid), max(grid))
    extra <- grid %in% period_days(extra_school, state, min(grid), max(grid))
    original_school <- sch | extra
    extended <- original_school
    # Start/end detection uses the union of source + documented local school days.
    starts <- which(original_school & !c(FALSE, head(original_school, -1L)))
    ends <- which(original_school & !c(tail(original_school, -1L), FALSE))
    for (j in starts) {
      if (weekday_monday(grid[j]) == 0L) {
        extended <- extended | grid %in% (grid[j] - c(2L, 1L))
      } else if (weekday_monday(grid[j]) == 1L && (grid[j] - 1L) %in% pub) {
        # Tuesday start, Monday public holiday: continuous Sat..Tuesday break.
        extended <- extended | grid %in% (grid[j] - c(3L, 2L, 1L))
      }
    }
    for (j in ends) {
      saturday <- grid[j] + 1L
      if (weekday_monday(grid[j]) == 4L && !saturday %in% pub) {
        extended[grid == saturday] <- TRUE
      }
    }
    out <- data.frame(
      Datum = format(grid, "%d.%m.%Y"), Bundesland = state,
      Schulferien = as.integer(sch), Zusatzferien = as.integer(extra),
      Ferien = as.integer(extended), Feiertag = as.integer(grid %in% pub),
      Schulfrei = as.integer(original_school | grid %in% pub |
                              weekday_monday(grid) >= 5L),
      Verkaufstag = as.integer(weekday_monday(grid) != 6L & !grid %in% pub),
      stringsAsFactors = FALSE
    )
    for (name in EVENT_COLUMNS) out[[name]] <- 0L
    for (year in years) {
      e <- calendar_easter(year)
      anchors <- list(
        Karfreitag = c(e - 2L, e + 1L), # Friday + Easter Monday: Thu/Sat shopping.
        Weihnachten = iso_date(sprintf("%04d-12-%02d", year, c(25L, 26L))),
        Silvester = iso_date(sprintf("%04d-01-01", year)),
        ErsterMai = iso_date(sprintf("%04d-05-01", year)),
        Pfingsten = e + 50L, Himmelfahrt = e + 39L,
        Halloween = iso_date(sprintf("%04d-10-31", year)),
        Valentinstag = iso_date(sprintf("%04d-02-14", year))
      )
      for (name in names(anchors)) {
        for (i in seq_along(anchors[[name]])) {
          shopping <- last_shopping_day(anchors[[name]][i], pub)
          out[[name]][grid == shopping] <- 1L
        }
      }
    }
    out$Einkauf_vor_Feiertag <- 0L
    for (i in seq_along(pub)) {
      out$Einkauf_vor_Feiertag[grid == last_shopping_day(pub[i], pub)] <- 1L
    }
    result[[state]] <- out[grid >= start & grid <= end, , drop = FALSE]
  }
  daily <- do.call(rbind, result)
  rownames(daily) <- NULL
  validate_calendar_de(daily, start, end, states)
  daily
}

validate_calendar_de <- function(daily, start, end, states) {
  required <- c(CALENDAR_COLUMNS, "Schulferien", "Zusatzferien", "Feiertag",
                "Schulfrei", "Verkaufstag", "Einkauf_vor_Feiertag")
  if (!all(required %in% names(daily)) || anyNA(daily[required])) stop("Missing fields")
  text <- as.character(daily$Datum)
  dates <- suppressWarnings(as.Date(text, "%d.%m.%Y"))
  if (anyNA(dates) || any(format(dates, "%d.%m.%Y") != text)) stop("Invalid calendar date")
  keys <- paste(text, daily$Bundesland)
  expected <- length(seq.Date(start, end, by = "day")) * length(states)
  if (anyDuplicated(keys) || nrow(daily) != expected ||
      !setequal(unique(daily$Bundesland), states) ||
      any(dates < start | dates > end)) stop("Duplicate, missing or unexpected calendar rows")
  for (state in states) {
    if (!setequal(dates[daily$Bundesland == state], seq.Date(start, end, by = "day"))) {
      stop("State calendar has gaps")
    }
  }
  for (name in setdiff(required, c("Datum", "Bundesland"))) {
    if (any(!daily[[name]] %in% c(0L, 1L))) stop("Nonbinary calendar feature")
  }
  invisible(TRUE)
}

weekly_calendar_de <- function(daily) {
  dates <- as.Date(daily$Datum, "%d.%m.%Y")
  monday <- dates - weekday_monday(dates)
  groups <- split(seq_len(nrow(daily)), paste(daily$Bundesland, monday))
  rows <- lapply(groups, function(ii) {
    first <- monday[ii[1L]]
    year <- as.integer(format(first + 3L, "%Y")) # ISO year belongs to Thursday.
    jan4 <- iso_date(sprintf("%04d-01-04", year))
    first_monday <- jan4 - weekday_monday(jan4)
    out <- data.frame(
      Bundesland = daily$Bundesland[ii[1L]], Wochenbeginn = format(first),
      ISO_Jahr = year, KW = as.integer(first - first_monday) %/% 7L + 1L,
      Kalendertage = length(ii), VollstaendigeWoche = length(ii) == 7L,
      Schulferientage = sum(daily$Schulferien[ii]),
      Ferientage = sum(daily$Ferien[ii]),
      Ferienanteil = mean(daily$Ferien[ii]),
      Feiertage = sum(daily$Feiertag[ii]), Verkaufstage = sum(daily$Verkaufstag[ii]),
      stringsAsFactors = FALSE
    )
    for (name in c(EVENT_COLUMNS, "Einkauf_vor_Feiertag")) {
      out[[name]] <- max(daily[[name]][ii])
    }
    out
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out[order(out$Bundesland, out$Wochenbeginn), ]
}

compare_calendar_de <- function(generated, legacy, start, end, states) {
  if (!all(LEGACY_CALENDAR_COLUMNS %in% names(legacy))) stop("Legacy columns missing")
  comparison_columns <- intersect(CALENDAR_COLUMNS, names(legacy))
  dates <- suppressWarnings(as.Date(legacy$Datum, "%d.%m.%Y"))
  if (anyNA(dates) || any(format(dates, "%d.%m.%Y") != legacy$Datum) ||
      anyNA(legacy$Bundesland) || any(!nzchar(legacy$Bundesland)) ||
      anyDuplicated(paste(legacy$Datum, legacy$Bundesland))) {
    stop("Invalid/duplicate legacy calendar keys")
  }
  legacy <- legacy[dates >= start & dates <= end & legacy$Bundesland %in% states,
                   comparison_columns, drop = FALSE]
  for (name in setdiff(comparison_columns, c("Datum", "Bundesland"))) {
    if (anyNA(legacy[[name]]) || any(!legacy[[name]] %in% c(0, 1))) {
      stop("Invalid legacy indicator")
    }
  }
  keys <- c("Datum", "Bundesland")
  joined <- merge(legacy, generated, by = keys, suffixes = c("_legacy", "_generated"))
  summary <- list(generated_rows = nrow(generated), legacy_rows = nrow(legacy),
                  common_rows = nrow(joined))
  summary$not_in_reference <- setdiff(CALENDAR_COLUMNS, comparison_columns)
  summary$legacy_only_rows <- nrow(legacy) - nrow(joined)
  summary$generated_only_rows <- nrow(generated) - nrow(joined)
  details <- data.frame(Datum = character(), Bundesland = character(),
                        Variable = character(), Legacy = integer(), Generated = integer())
  for (name in setdiff(comparison_columns, keys)) {
    old <- as.integer(joined[[paste0(name, "_legacy")]])
    new <- as.integer(joined[[paste0(name, "_generated")]])
    different <- old != new
    summary[[name]] <- list(matches = sum(!different), mismatches = sum(different),
                           match_rate = if (length(old)) mean(!different) else NA_real_)
    if (any(different)) {
      details <- rbind(details, data.frame(
        Datum = joined$Datum[different], Bundesland = joined$Bundesland[different],
        Variable = name, Legacy = old[different], Generated = new[different]
      ))
    }
  }
  legacy_key <- paste(legacy$Datum, legacy$Bundesland)
  generated_key <- paste(generated$Datum, generated$Bundesland)
  only_old <- legacy[!legacy_key %in% generated_key, keys, drop = FALSE]
  only_new <- generated[!generated_key %in% legacy_key, keys, drop = FALSE]
  only_old$Presence <- rep("legacy_only", nrow(only_old))
  only_new$Presence <- rep("generated_only", nrow(only_new))
  list(summary = summary, mismatches = details, row_differences = rbind(only_old, only_new))
}

fetch_calendar_periods <- function(start, end, codes, output, cache = NULL) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Install jsonlite first")
  destination <- file.path(output, "sources")
  dir.create(destination)
  cache_manifest <- NULL
  if (!is.null(cache)) {
    cache_manifest <- read.csv(file.path(cache, "manifest.csv"), colClasses = "character")
  }
  manifest <- data.frame()
  periods <- list(PublicHolidays = empty_periods(), SchoolHolidays = empty_periods())
  from <- start - 7L; to <- end + 7L
  years <- seq(as.integer(format(from, "%Y")), as.integer(format(to, "%Y")))
  snapshot <- function(name, url) {
    path <- file.path(destination, name)
    if (is.null(cache)) {
      message("Fetching ", name)
      status <- download.file(url, path, quiet = TRUE, mode = "wb", method = "libcurl")
      if (status != 0L) stop("Download failed: ", url)
      accessed <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    } else {
      if (!all(c("file", "url", "retrieved_at_utc", "md5") %in% names(cache_manifest))) {
        stop("Invalid cache manifest")
      }
      record <- cache_manifest[cache_manifest$file == name, , drop = FALSE]
      source_path <- file.path(cache, name)
      if (nrow(record) != 1L || record$url != url || !file.exists(source_path) ||
          unname(tools::md5sum(source_path)) != record$md5) stop("Cache identity mismatch")
      if (!file.copy(source_path, path)) stop("Cache copy failed")
      accessed <- record$retrieved_at_utc
    }
    response <- jsonlite::fromJSON(path, simplifyVector = FALSE)
    if (!is.list(response) || !is.null(names(response))) stop("Expected API JSON array")
    manifest <<- rbind(manifest, data.frame(
      file = name, url = url, retrieved_at_utc = accessed,
      md5 = unname(tools::md5sum(path)), stringsAsFactors = FALSE
    ))
    write.csv(manifest, file.path(destination, "manifest.csv"), row.names = FALSE)
    response
  }
  # OpenHolidays returns no public holidays for 2017..2019. Use one explicit,
  # historical public-holiday source for ALL years, not silent empty-year zeros.
  for (year in years) {
    url <- paste0("https://date.nager.at/api/v3/PublicHolidays/", year, "/DE")
    response <- snapshot(paste0("Nager-DE-", year, ".json"), url)
    if (!length(response)) stop("Empty annual public-holiday response")
    for (item in response) {
      if (!all(c("date", "countryCode", "global", "counties", "types") %in% names(item)) ||
          !identical(item$countryCode, "DE") || !is.logical(item$global) ||
          length(item$global) != 1L || is.na(item$global)) stop("Invalid public-holiday identity")
      day <- iso_date(item$date)
      if (length(day) != 1L || as.integer(format(day, "%Y")) != year) {
        stop("Wrong public-holiday year")
      }
      if (!"Public" %in% unlist(item$types)) next
      for (code in codes) {
        if (!item$global && !code %in% unlist(item$counties)) next
        periods$PublicHolidays <- rbind(periods$PublicHolidays, data.frame(
          Bundesland = unname(WKR_STATES[code]), startDate = as.character(day),
          endDate = as.character(day), source = url, stringsAsFactors = FALSE
        ))
      }
    }
    # Reject incomplete years instead of manufacturing ordinary shopping days.
    e <- calendar_easter(year)
    national <- c(iso_date(sprintf("%04d-01-01", year)), e - 2L, e + 1L,
                  iso_date(sprintf("%04d-05-01", year)), e + 39L, e + 50L,
                  iso_date(sprintf("%04d-10-03", year)),
                  iso_date(sprintf("%04d-12-%02d", year, c(25L, 26L))))
    for (code in codes) {
      found <- periods$PublicHolidays$startDate[
        periods$PublicHolidays$Bundesland == WKR_STATES[code]]
      if (!all(as.character(national) %in% found)) stop("Missing national public holiday")
    }
  }
  for (code in codes) for (year in years) {
    a <- max(from, iso_date(sprintf("%04d-01-01", year)))
    b <- min(to, iso_date(sprintf("%04d-12-31", year)))
    url <- paste0("https://openholidaysapi.org/SchoolHolidays",
                  "?countryIsoCode=DE&subdivisionCode=", code,
                  "&languageIsoCode=DE&validFrom=", a, "&validTo=", b)
    response <- snapshot(paste0(code, "-SchoolHolidays-", year, ".json"), url)
    if (format(a, "%m-%d") == "01-01" && format(b, "%m-%d") == "12-31" &&
        !length(response)) stop("Empty whole-year school-holiday response")
    for (item in response) {
      if (!all(c("startDate", "endDate") %in% names(item))) stop("Invalid school response")
        row <- data.frame(Bundesland = unname(WKR_STATES[code]),
                          startDate = item$startDate, endDate = item$endDate,
                          source = url, stringsAsFactors = FALSE)
        check_periods(row, unname(WKR_STATES[codes]))
        periods$SchoolHolidays <- rbind(periods$SchoolHolidays, row)
    }
  }
  list(public = unique(periods$PublicHolidays), school = unique(periods$SchoolHolidays),
       manifest = manifest)
}

calendar_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  usage <- paste(
    "Rscript R/generate_calendar_de.R --start-year 2017 --end-year 2026",
    "--output NEW_DIRECTORY [--states DE-BE,DE-NI] [--extra-school CSV]",
    "[--source-cache PREVIOUS_OUTPUT/sources] [--legacy CSV]"
  )
  if ("--help" %in% args) { cat(usage, "\n"); return(invisible(NULL)) }
  allowed <- c("--start-year", "--end-year", "--output", "--states",
               "--extra-school", "--source-cache", "--legacy")
  if (!length(args) || length(args) %% 2L ||
      any(!args[seq(1L, length(args), 2L)] %in% allowed) ||
      anyDuplicated(args[seq(1L, length(args), 2L)])) stop(usage)
  opt <- as.list(args[seq(2L, length(args), 2L)])
  names(opt) <- args[seq(1L, length(args), 2L)]
  if (!all(c("--start-year", "--end-year", "--output") %in% names(opt))) stop(usage)
  years <- unlist(opt[c("--start-year", "--end-year")], use.names = FALSE)
  if (any(!grepl("^\\d{4}$", years))) stop("Years must be four-digit integers")
  years <- as.integer(years)
  if (years[1] < 1584L || years[2] > 9997L || years[1] > years[2]) stop("Invalid years")
  start <- iso_date(sprintf("%04d-01-01", years[1]))
  end <- iso_date(sprintf("%04d-12-31", years[2]))
  codes <- if (is.null(opt[["--states"]])) names(WKR_STATES) else
    strsplit(opt[["--states"]], ",", fixed = TRUE)[[1]]
  if (!length(codes) || anyDuplicated(codes) || any(!codes %in% names(WKR_STATES))) {
    stop("States must use the seven supported WKR subdivision codes")
  }
  output <- opt[["--output"]]
  if (file.exists(output)) stop("Output already exists; choose a new directory")
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Install jsonlite first")
  extra <- empty_periods()
  if (!is.null(opt[["--extra-school"]])) {
    extra <- read.csv(opt[["--extra-school"]], colClasses = "character",
                      check.names = FALSE, fileEncoding = "UTF-8")
    check_periods(extra, unname(WKR_STATES[codes]))
  }
  if (!dir.create(output, recursive = TRUE)) stop("Cannot create output directory")
  previous_timeout <- getOption("timeout")
  on.exit(options(timeout = previous_timeout), add = TRUE)
  options(timeout = max(60L, previous_timeout))
  input <- fetch_calendar_periods(start, end, codes, output, opt[["--source-cache"]])
  daily <- build_calendar_de(start, end, unname(WKR_STATES[codes]),
                             input$public, input$school, extra)
  legacy_shape <- daily[daily$Verkaufstag == 1L, CALENDAR_COLUMNS, drop = FALSE]
  weekly <- weekly_calendar_de(daily)
  write.csv2(daily, file.path(output, "calendar_daily.csv"), row.names = FALSE,
             fileEncoding = "UTF-8")
  write.csv2(legacy_shape, file.path(output, "datumlanderferienfeiertage.csv"),
             row.names = FALSE, fileEncoding = "UTF-8")
  write.csv2(weekly, file.path(output, "calendar_weekly.csv"), row.names = FALSE,
             fileEncoding = "UTF-8")
  if (!is.null(opt[["--extra-school"]])) {
    if (!file.copy(opt[["--extra-school"]], file.path(output, "extra_school_original.csv"))) {
      stop("Could not preserve additional school-day evidence")
    }
  }
  if (!is.null(opt[["--legacy"]])) {
    old <- read.csv2(opt[["--legacy"]], colClasses = "character", check.names = FALSE,
                     fileEncoding = "UTF-8")
    names(old) <- sub("^\ufeff", "", names(old))
    comparison <- compare_calendar_de(legacy_shape, old, start, end,
                                      unname(WKR_STATES[codes]))
    jsonlite::write_json(comparison$summary,
                         file.path(output, "calendar_comparison_summary.json"),
                         auto_unbox = TRUE, pretty = TRUE, na = "null", digits = NA)
    write.csv2(comparison$mismatches,
                file.path(output, "calendar_comparison_mismatches.csv"), row.names = FALSE)
    write.csv2(comparison$row_differences,
                file.path(output, "calendar_comparison_rows.csv"), row.names = FALSE)
  }
  files <- list.files(output, full.names = TRUE)
  files <- files[!dir.exists(files)]
  script <- grep("^--file=", commandArgs(), value = TRUE)
  generator_md5 <- if (length(script) == 1L) {
    unname(tools::md5sum(sub("^--file=", "", script)))
  } else NULL
  manifest <- list(
    rules_version = "1.1.0", start = as.character(start), end = as.character(end),
    generator_md5 = generator_md5,
    created_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    states = as.list(WKR_STATES[codes]), R_version = R.version.string,
    jsonlite_version = as.character(utils::packageVersion("jsonlite")),
    shopping_rule = "last preceding Mon-Sat excluding regional public holidays",
    school_rule = paste(
      "Monday start extends to Sat/Sun; Tuesday start with public-holiday Monday",
      "extends to Sat/Sun/Mon; Friday end extends to Saturday unless a public holiday."
    ),
    school_limitations = "Unlisted local movable days remain unknown; no national weighting.",
    attribution = paste("School holidays: OpenHolidays API (CC BY 4.0).",
                         "Public holidays: Nager.Date API. Own shopping/extension derivations."),
    source_policy = "Captured API bytes; MD5 detects byte changes, not source authenticity.",
    legacy_reference = if (!is.null(opt[["--legacy"]])) list(
      file = basename(opt[["--legacy"]]), md5 = unname(tools::md5sum(opt[["--legacy"]]))
    ) else NULL,
    sources = input$manifest, output_md5 = as.list(setNames(tools::md5sum(files), basename(files)))
  )
  jsonlite::write_json(manifest, file.path(output, "manifest.json"),
                       auto_unbox = TRUE, pretty = TRUE, digits = NA)
  message("Completed: ", nrow(daily), " daily rows; ", nrow(weekly), " regional weeks.")
  invisible(manifest)
}

if (sys.nframe() == 0L) calendar_main()
