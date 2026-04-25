#' ---------------------------------------------------------------
#' VIX (CBOE Volatility Index)
#' Source: FRED (VIXCLS)
#' ---------------------------------------------------------------

download_vix <- function(from = "1990-01-01", to = Sys.Date()) {

  cat(">> Downloading VIX from FRED...\n")

  vix_daily <- tidyquant::tq_get(
    "VIXCLS",
    get  = "economic.data",
    from = from,
    to   = as.character(to)
  )

  # aggregate to monthly (end-of-month close)
  vix <- vix_daily |>
    tidyr::drop_na(price) |>
    dplyr::mutate(
      month = lubridate::month(date),
      year  = lubridate::year(date)
    ) |>
    dplyr::group_by(year, month) |>
    dplyr::summarise(vix = dplyr::last(price), .groups = "drop") |>
    dplyr::mutate(
      yyyymm = as.numeric(paste0(year, sprintf("%02d", month)))
    ) |>
    dplyr::select(yyyymm, year, month, vix)

  vix
}
