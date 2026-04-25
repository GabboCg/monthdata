#' ---------------------------------------------------------------
#' Datastream variable proxies from FRED and Yahoo Finance
#' Original source: Datastream (proprietary)
#' Free proxies used here:
#'   - ordm/orda: AMTMNO (Manufacturers' New Orders, FRED)
#'   - infa:      CPIAUCSL (CPI, FRED)
#'   - msci:      MSCI World ETF via Yahoo Finance (URTH)
#'   - crb:       PALLFNFINDEXM (Global Commodity Price Index)
#'   - pmi:       BSCICP02USM460S (OECD Mfg Confidence, FRED)
#'   - pmbb:      GACDFSA066MSFRBPHI (Philly Fed Business)
#'   - conf:      CSCICP03USM665S (OECD Consumer Confidence)
#'   - ted:       TB3MS (3M T-Bill, FRED)
#'   - diff:      USPHCI (Philly Fed coincident index)
#' ---------------------------------------------------------------

download_datastream_proxies <- function(
    from = "1959-01-01",
    to = Sys.Date()) {

  cat(">> Downloading Datastream proxy variables",
      "from FRED & Yahoo...\n")

  # helper: safe single-ticker FRED download
  safe_fred <- function(ticker, from, to) {
    tryCatch({
      tidyquant::tq_get(
        ticker,
        get  = "economic.data",
        from = from,
        to   = as.character(to)
      ) |>
        dplyr::select(date, price) |>
        dplyr::rename(!!ticker := price)
    }, error = function(e) {
      cat("   WARNING:", ticker, "failed.\n")
      NULL
    })
  }

  # download each FRED series individually
  tickers <- c(
    "AMTMNO", "CPIAUCSL", "PALLFNFINDEXM",
    "BSCICP02USM460S", "GACDFSA066MSFRBPHI",
    "CSCICP03USM665S", "TB3MS", "USPHCI"
  )

  fred_list <- purrr::compact(
    purrr::map(tickers, safe_fred, from, to)
  )

  # merge all FRED series by date
  fred_raw <- purrr::reduce(
    fred_list, dplyr::full_join, by = "date"
  ) |>
    dplyr::arrange(date) |>
    janitor::clean_names()

  # --- MSCI World from Yahoo Finance (URTH ETF) ---
  msci_raw <- tryCatch({
    tidyquant::tq_get(
      "URTH",
      get  = "stock.prices",
      from = from,
      to   = as.character(to)
    ) |>
      dplyr::mutate(
        month = lubridate::month(date),
        year  = lubridate::year(date)
      ) |>
      dplyr::group_by(year, month) |>
      dplyr::summarise(
        msci_close = dplyr::last(close),
        .groups = "drop"
      ) |>
      dplyr::mutate(
        date = as.Date(paste0(
          year, "-", sprintf("%02d", month), "-01"
        ))
      ) |>
      dplyr::select(date, msci_close)
  }, error = function(e) {
    cat("   WARNING: MSCI download failed.\n")
    NULL
  })

  # compute derived variables
  ds <- fred_raw |>
    dplyr::mutate(
      ordm = log(amtmno / dplyr::lag(amtmno, 1)),
      orda = log(amtmno / dplyr::lag(amtmno, 12)),
      infa = log(
        cpiaucsl / dplyr::lag(cpiaucsl, 12)
      ),
      crb = log(
        pallfnfindexm / dplyr::lag(pallfnfindexm, 1)
      ),
      pmi  = bscicp02usm460s,
      pmbb = gacdfsa066msfrbphi,
      conf = (cscicp03usm665s -
        dplyr::lag(cscicp03usm665s, 1)) /
        dplyr::lag(cscicp03usm665s, 1),
      ted  = tb3ms / 1200,
      diff = usphci
    )

  # add MSCI if available
  if (!is.null(msci_raw)) {
    ds <- ds |>
      dplyr::left_join(msci_raw, by = "date") |>
      dplyr::mutate(
        msci = log(
          msci_close / dplyr::lag(msci_close, 1)
        )
      ) |>
      dplyr::select(-msci_close)
  } else {
    ds <- ds |>
      dplyr::mutate(msci = NA_real_)
  }

  ds <- ds |>
    dplyr::mutate(
      month  = as.numeric(strftime(date, "%m")),
      year   = lubridate::year(date),
      yyyymm = as.numeric(
        paste0(year, sprintf("%02d", month))
      )
    ) |>
    dplyr::select(
      yyyymm, year, month, ordm, orda,
      infa, msci, crb, pmi, pmbb, conf,
      ted, diff
    )

  # report coverage
  na_pct <- colMeans(is.na(ds)) * 100
  has_na <- na_pct[na_pct > 0]
  if (length(has_na) > 0) {
    cat("   NA% per variable:\n")
    for (v in names(has_na)) {
      cat("     ", v, ":",
          sprintf("%.1f%%", has_na[v]), "\n")
    }
  }

  ds
}
