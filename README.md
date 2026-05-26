# monthdata

Scripts to **download and update the dataset** used in:

> Diaz, J.D., Hansen, E., & Cabrera, G. (2024). "Machine-Learning Stock Market Volatility: Predictability, Drivers, and Economic Value." *International Review of Financial Analysis*, 94, 103286.

## Purpose

Data collection only. Downloads and organizes the 179 monthly predictors listed in Table D.1 of the paper from their original sources, extended to the latest available observation.

## Quick Start

```bash
git clone https://github.com/GabboCg/monthdata.git
cd monthdata
Rscript download_data.R
```

**Requirements:** R >= 4.0, C++ compiler (for FRED-MD factor estimation), and the following R packages:

```r
install.packages(c(
  "tidyquant", "dplyr", "tidyr", "purrr", "lubridate",
  "readxl", "stringr", "janitor", "magrittr", "openxlsx",
  "readr", "TTR", "PerformanceAnalytics", "Rcpp",
  "RcppArmadillo", "googledrive"
))
```

On first run, the script clones the [`fredmd`](https://github.com/GabboCg/fredmd) repository for FRED-MD processing (includes C++ compilation).

## Data Sources

| Module | Source | Variables |
|--------|--------|-----------|
| `R/01-sp500.R` | Yahoo Finance | S&P 500 prices, realized volatility, squared returns |
| `R/02-goyal-welch.R` | [Amit Goyal](https://sites.google.com/view/agoyal145) | DP, EP, TB, LTR, TS, DEF, RTB, RBR, INFM (+ ERP, Rfree in separate sheet) |
| `R/03-kenneth-french.R` | [Ken French Data Library](https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html) | MKT, SMB, HML, MOM, RMW, CMA, STR |
| `R/04-pastor-stambaugh.R` | [Lubos Pastor](https://faculty.chicagobooth.edu/lubos-pastor/data) | PS (aggregate liquidity) |
| `R/05-fred-api.R` | [FRED](https://fred.stlouisfed.org/) | IPM, IPA, M1M, M1A, CAP, EMPL, SENT, HS |
| `R/06-fred-md.R` | [FRED-MD](https://www.stlouisfed.org/research/economists/mccracken/fred-databases) + [`fredmd`](https://github.com/GabboCg/fredmd) | 113 transformed macro series (whitelisted to Table D.1; MZMSL pulled directly from FRED) |
| `R/07-datastream-proxies.R` | FRED + Yahoo Finance | ORDM, ORDA, INFA, MSCI, CRB, PMI, PMBB, CONF, TED, DIFF |
| `R/08-uncertainty.R` | Multiple (see below) | EPU, RABEX, UNCBEX, GPRH, GPRHT, GPRHA, FINUNC, MACROUNC, REALUNC, USMPU |
| `R/09-vix.R` | [FRED](https://fred.stlouisfed.org/series/VIXCLS) | VIX |
| `R/10-cochrane-piazzesi.R` | Computed from FRED yields | CP |
| `R/11-usrec.R` | [FRED](https://fred.stlouisfed.org/series/USREC) | USREC |
| `R/12-technical-indicators.R` | Computed from S&P 500 | 6 MA, 2 MOM, 6 VOL, 5 RV signals |

### Uncertainty sources

| Variable | Source |
|----------|--------|
| EPU | [FRED (USEPUINDXM)](https://fred.stlouisfed.org/series/USEPUINDXM) |
| RABEX, UNCBEX | [Bekaert, Engstrom & Xu (2022)](https://www.nancyxu.net/risk-aversion-index) |
| GPRH, GPRHT, GPRHA | [Caldara & Iacoviello (2022)](https://www.matteoiacoviello.com/gpr.htm) |
| FINUNC, MACROUNC, REALUNC | [Jurado, Ludvigson & Ng (2015)](https://www.sydneyludvigson.com/macro-and-financial-uncertainty-indexes) |
| USMPU | [Husted, Rogers & Sun (2020)](https://www.policyuncertainty.com/media/US_MPU_Monthly.xlsx) |

## Proxy Variables and Data Limitations

Several variables in the original paper were sourced from **Datastream (Refinitiv)**, a proprietary database. Since Datastream is not freely available, this repository uses the closest free alternatives:

| Paper Variable | Original Source | Proxy Used | FRED Ticker / Source | Notes |
|---|---|---|---|---|
| ORDM, ORDA (Orders) | Datastream | Manufacturers' New Orders | `AMTMNO` | Starts Feb 1992 (original starts earlier) |
| INFA (Inflation YoY) | Datastream (CPI) | CPI for All Urban Consumers | `CPIAUCSL` | Equivalent measure |
| MSCI (MSCI World) | Datastream | iShares MSCI World ETF | Yahoo: `URTH` | Starts Jan 2012 (original starts earlier) |
| CRB (Commodity Index) | Datastream | IMF Global Commodity Price Index | `PALLFNFINDEXM` | Different composition than CRB |
| PMI (ISM PMI) | Datastream | OECD Manufacturing Confidence | `BSCICP02USM460S` | Proxy, not identical to ISM PMI |
| PMBB (Chicago Business Barometer) | Datastream | Philly Fed General Activity | `GACDFSA066MSFRBPHI` | Different survey, same concept |
| CONF (Consumer Confidence) | Datastream | OECD Consumer Confidence | `CSCICP03USM665S` | OECD-normalized, not Conference Board |
| TED (TED Spread) | Datastream (LIBOR - T-Bill) | T-Bill rate proxy | `TB3MS` | LIBOR discontinued Dec 2023; simplified proxy |
| DIFF (Diffusion Index) | Philadelphia Fed | Philly Fed Coincident Index | `USPHCI` | Proxy for the original diffusion index |
| CP (Cochrane-Piazzesi) | Academic dataset | Computed from FRED yield curve | `GS1, GS2, GS5, GS10` | Approximation using available maturities |

**Users with Datastream access** can replace these proxies with the original series for exact replication of the paper's results.

## Variable Counts

The pipeline produces the 179 predictors listed in Table D.1 of the paper across two samples:

| Sample | Period | Predictors | Description |
|--------|--------|------------|-------------|
| Short | 1990–present | 179 | All Table D.1 predictors (includes variables only available from 1990 onwards) |
| Long  | 1960–present | 157 | Excludes the 22 variables flagged in Table D.1 as available only from 1990 |

The 22 short-sample-only variables (Table D.1 footnote `a`) dropped from the long sample:

```
MSCI, RMW, CMA, CP, PS, TED, TWEXMMTH, CAP, SENT, CONF, DIFF, PMBB,
ANDENOX, VXOCLSX, VIX, RABEX, UNCBEX, EPU, FINUNC, MACROUNC, REALUNC, USMPU
```

**Naming conventions.** FRED-MD legacy codes are renamed to the Table D.1 abbreviations: `WPSFD49207 -> PPIFGS`, `WPSFD49502 -> PPIFCG`, `WPSID61 -> PPIITM`, `WPSID62 -> PPICRM`, `TWEXAFEGSMTHx -> TWEXMMTH`, `VIXCLSx -> VXOCLSX`. `MZMSL` was removed from recent FRED-MD vintages, so it is pulled directly from FRED and transformed with FRED-MD tcode 6 (second log difference). The EM imputation in the `fredmd` package handles missing values across the rest of the panel.

## Output

The pipeline produces:

```
data/
  short/
    PredictorData.xlsx   # 1990-present, 179 predictors
  long/
    PredictorData.xlsx   # 1960-present, 157 predictors
```

Each Excel workbook contains five sheets:

| Sheet | Contents |
|-------|----------|
| `predictors` | Table D.1 predictors, keyed by `yyyymm` |
| `square-returns` | Monthly sum of squared daily S&P 500 log-returns |
| `daily-returns` | Daily squared log-returns |
| `erp-rfree` | Equity risk premium and risk-free rate |
| `recession` | NBER recession dummy (`USREC`) |

Excel files are also uploaded to Google Drive (`monthdata/short/` and `monthdata/long/`).

## References

- Diaz, J.D., Hansen, E., & Cabrera, G. (2024). Machine-learning stock market volatility: Predictability, drivers, and economic value. *International Review of Financial Analysis*, 94, 103286.
- McCracken, M.W. & Ng, S. (2016). FRED-MD: A monthly database for macroeconomic research. *Journal of Business & Economic Statistics*, 34(4), 574-589.
- Goyal, A. & Welch, I. (2008). A comprehensive look at the empirical performance of equity premium prediction. *Review of Financial Studies*, 21(4), 1455-1508.
