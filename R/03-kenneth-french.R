#' ---------------------------------------------------------------
#' Kenneth French: FF5 factors, Momentum, Short-Term Reversal
#' Source: Ken French Data Library (mba.tuck.dartmouth.edu)
#' ---------------------------------------------------------------

download_kenneth_french <- function() {

  cat(">> Downloading Kenneth French factors...\n")

  base_url <- paste0(
    "https://mba.tuck.dartmouth.edu",
    "/pages/faculty/ken.french/ftp"
  )

  # helper: download zip, extract, read lines
  read_french_lines <- function(zip_name) {
    url <- paste0(base_url, "/", zip_name)
    tmp_zip <- tempfile(fileext = ".zip")
    download.file(
      url, tmp_zip, mode = "wb", quiet = TRUE
    )
    csv_file <- unzip(tmp_zip, exdir = tempdir())
    on.exit({
      unlink(tmp_zip)
      unlink(csv_file)
    })
    readLines(
      csv_file[1], warn = FALSE, encoding = "latin1"
    )
  }

  # helper: parse monthly CSV block
  # French files are comma-separated with a header
  # row like ",Mkt-RF,SMB,..." followed by data rows
  # like "196307,  -0.39, ..."
  parse_french_monthly <- function(lines) {
    # find rows starting with 6-digit date
    idx <- grep("^\\s*\\d{6},", lines)
    if (length(idx) == 0) return(NULL)

    # monthly block: consecutive matching lines
    start <- idx[1]
    # find where block ends (gap in indices)
    diffs <- diff(idx)
    gap <- which(diffs > 1)[1]
    if (is.na(gap)) {
      end_pos <- idx[length(idx)]
    } else {
      end_pos <- idx[gap]
    }
    block <- lines[start:end_pos]

    utils::read.csv(
      text = paste(block, collapse = "\n"),
      header = FALSE, strip.white = TRUE
    )
  }

  # --- Fama-French 5 Factors ---
  cat("   FF5 factors...\n")
  ff5_lines <- read_french_lines(
    "F-F_Research_Data_5_Factors_2x3_CSV.zip"
  )
  ff5_raw <- parse_french_monthly(ff5_lines)
  colnames(ff5_raw) <- c(
    "yyyymm", "mkt_rf", "smb", "hml",
    "rmw", "cma", "rf"
  )

  ff5 <- ff5_raw |>
    tibble::as_tibble() |>
    dplyr::mutate(
      yyyymm = as.numeric(yyyymm),
      dplyr::across(
        mkt_rf:rf, ~ as.numeric(.) / 100
      )
    ) |>
    dplyr::rename(mkt = mkt_rf) |>
    dplyr::mutate(
      year  = as.numeric(
        stringr::str_sub(yyyymm, 1, 4)
      ),
      month = as.numeric(
        stringr::str_sub(yyyymm, -2)
      )
    ) |>
    dplyr::select(
      yyyymm, year, month,
      mkt, smb, hml, rmw, cma
    )

  # --- Momentum ---
  cat("   Momentum factor...\n")
  mom_lines <- read_french_lines(
    "F-F_Momentum_Factor_CSV.zip"
  )
  mom_raw <- parse_french_monthly(mom_lines)
  colnames(mom_raw) <- c("yyyymm", "mom")

  mom <- mom_raw |>
    tibble::as_tibble() |>
    dplyr::mutate(
      yyyymm = as.numeric(yyyymm),
      mom    = as.numeric(mom) / 100,
      year   = as.numeric(
        stringr::str_sub(yyyymm, 1, 4)
      ),
      month  = as.numeric(
        stringr::str_sub(yyyymm, -2)
      )
    ) |>
    dplyr::select(yyyymm, year, month, mom)

  # --- Short-Term Reversal ---
  cat("   Short-term reversal factor...\n")
  str_lines <- read_french_lines(
    "F-F_ST_Reversal_Factor_CSV.zip"
  )
  str_raw <- parse_french_monthly(str_lines)
  colnames(str_raw) <- c("yyyymm", "st_rev")

  str_fct <- str_raw |>
    tibble::as_tibble() |>
    dplyr::mutate(
      yyyymm = as.numeric(yyyymm),
      str    = as.numeric(st_rev) / 100,
      year   = as.numeric(
        stringr::str_sub(yyyymm, 1, 4)
      ),
      month  = as.numeric(
        stringr::str_sub(yyyymm, -2)
      )
    ) |>
    dplyr::select(yyyymm, year, month, str)

  # merge
  kf_pred <- ff5 |>
    dplyr::left_join(
      mom, by = c("yyyymm", "year", "month")
    ) |>
    dplyr::left_join(
      str_fct, by = c("yyyymm", "year", "month")
    ) |>
    dplyr::select(
      yyyymm, year, month,
      mkt, smb, hml, mom, rmw, cma, str
    )

  kf_pred
}
