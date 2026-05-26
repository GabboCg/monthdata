# ---------------------------------------------------------------
# Goyal & Welch (2008) equity premium predictors
# Source: Amit Goyal's Google Drive (PredictorData2024.xlsx)
# ---------------------------------------------------------------

download_goyal_welch <- function() {
  
  cat(">> Downloading Goyal-Welch predictors...\n")
  
  url <- "https://docs.google.com/spreadsheets/d/1OIZg6htTK60wtnCVXvxAujvG1aKEOVYv/export?format=xlsx"
  tmp <- tempfile(fileext = ".xlsx")
  download.file(url, tmp, mode = "wb", quiet = TRUE)
  
  gw_raw <- readxl::read_xlsx(tmp, sheet = "Monthly") |>
    dplyr::mutate(dplyr::across(dplyr::everything(), as.numeric)) |>
    janitor::clean_names()
  
  unlink(tmp)
  
  # predictors
  gw_pred <- gw_raw |>
    dplyr::filter(yyyymm >= 192512) |>
    dplyr::select(yyyymm, index, d12, e12, b_m, ntis, tbl, lty, ltr,
                  baa, aaa, corpr, infl, rfree) |>
    dplyr::mutate(
      dp    = log(d12 / index),
      ep    = log(e12 / index),
      de    = log(d12 / e12),
      dy    = log(d12 / dplyr::lag(index)),
      ts    = lty - tbl,
      def   = baa - aaa,
      dfr   = corpr - ltr,
      rtb   = tbl - TTR::SMA(tbl, 12),
      rbr   = lty - TTR::SMA(lty, 12),
      year  = as.numeric(stringr::str_sub(yyyymm, 1, 4)),
      month = as.numeric(stringr::str_sub(yyyymm, -2))
    ) |>
    dplyr::rename(tb = tbl, infm = infl) |>
    dplyr::select(yyyymm, year, month, dp, ep, tb, ltr, ts, def, rtb, rbr, infm)
  
  # equity risk premium and risk free
  erp_rfree <- gw_raw |>
    dplyr::filter(yyyymm >= 192512) |>
    dplyr::select(yyyymm, index, rfree) |>
    dplyr::mutate(
      erp   = log(index / dplyr::lag(index, 1)) - log(1 + dplyr::lag(rfree, 1)),
      year  = as.numeric(stringr::str_sub(yyyymm, 1, 4)),
      month = as.numeric(stringr::str_sub(yyyymm, -2))
    ) |>
    dplyr::select(yyyymm, year, month, erp, rfree)
  
  list(
    gw_pred   = gw_pred,
    erp_rfree = erp_rfree
  )
  
}
