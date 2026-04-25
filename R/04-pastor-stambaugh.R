#' ---------------------------------------------------------------
#' Pastor-Stambaugh Aggregate Liquidity Factor
#' Source: Lubos Pastor, Chicago Booth
#' ---------------------------------------------------------------

download_pastor_stambaugh <- function() {

  cat(">> Downloading Pastor-Stambaugh liquidity factor...\n")

  url <- "https://faculty.chicagobooth.edu/-/media/faculty/lubos-pastor/data/liq_data_1962_2024.txt"
  tmp <- tempfile(fileext = ".txt")
  download.file(url, tmp, mode = "w", quiet = TRUE)

  # read skipping comment lines (start with %)
  lines <- readLines(tmp)
  unlink(tmp)

  data_lines <- lines[!grepl("^%", lines) & trimws(lines) != ""]
  df <- utils::read.table(text = data_lines, header = FALSE, fill = TRUE)
  colnames(df) <- c("yyyymm", "agg_liq", "innov_liq", "traded_liq")

  pastor <- df |>
    tibble::as_tibble() |>
    dplyr::mutate(
      yyyymm = as.numeric(yyyymm),
      ps     = as.numeric(innov_liq),
      year   = as.numeric(stringr::str_sub(yyyymm, 1, 4)),
      month  = as.numeric(stringr::str_sub(yyyymm, -2))
    ) |>
    dplyr::mutate(ps = dplyr::if_else(ps == -99, NA_real_, ps)) |>
    dplyr::select(yyyymm, year, month, ps)

  pastor
}
