# ---------------------------------------------------------------
# Technical Indicators on the S&P 500
# Source: Computed from S&P 500 monthly prices, volume, and
#         realized volatility (built upstream in 01-sp500.R)
#
# Following Neely, Rapach, Tu & Zhou (2014), each function returns
# a tibble of binary {0, 1} signals keyed by yyyymm:
#   - get_ma:  moving-average crossover signals
#   - get_mom: price-momentum signals
#   - get_vol: on-balance-volume crossover signals
#   - get_voa: lagged realized-volatility signals
# ---------------------------------------------------------------

# moving-average crossover signals 
get_ma <- function(y_t, s_i, l_i) {
  
  n_0_ma <- 1 * 11 # in-sample period, 1927:01 - 1927:11
  
  ma_param <- expand.grid(x = s_i, y = l_i) %>% arrange(x)
  
  s_ma <- matrix(0, nrow = nrow(y_t) - n_0_ma, ncol = nrow(ma_param)) # 1927:12 - 2011:12
  
  date_t <- rownames(y_t)
  
  for (t in 1:nrow(s_ma)) {
    
    for (i in 1:nrow(ma_param)) {
      
      short <- mean(y_t[(n_0_ma + t - (ma_param[i, 1] - 1)):(n_0_ma + t),])
      long <- mean(y_t[(n_0_ma + t - (ma_param[i, 2] - 1)):(n_0_ma + t),])
      
      if (short > long) {
        
        s_ma[t, i]  <-  1
        
      }
      
    }
    
  }
  
  colnames(s_ma) <- paste0("ma(", ma_param[,1], ",", ma_param[,2], ")")
  rownames(s_ma) <- date_t[12:length(date_t)]
  
  s_ma <- as_tibble(s_ma, rownames = "date") %>%
    mutate(date = as.numeric(date))
  
  return(s_ma)
  
}


# price-momentum signals
get_mom <- function(y_t, m_i) {
  
  n_0_mom <- 1 * 12
  
  mom_param <- m_i
  
  s_mom <- matrix(0, nrow = nrow(y_t) - n_0_mom, ncol = length(mom_param)) # 1928:01 - 2011:12
  
  date_t <- rownames(y_t)
  
  for (t in 1:nrow(s_mom)) {
    
    for (i in 1:length(mom_param)) {
      
      p_difference <- y_t[(n_0_mom + t),] - y_t[(n_0_mom + t - mom_param[i]),]
      
      if (p_difference >= 0) {
        
        s_mom[t, i] <- 1
        
      }
      
    }
    
  }
  
  colnames(s_mom) <- paste0("mom(", m_i, ")")
  rownames(s_mom) <- date_t[13:length(date_t)]
  
  s_mom <- as_tibble(s_mom, rownames = "date") %>%
    mutate(date = as.numeric(date))
  
  return(s_mom)
  
}


# on-balance-volume signals -----------------------------------------------

get_vol <- function(y_t, volume, s_i, l_i) {
  
  t_vol <- nrow(volume)
  
  n_0_vol <- 1 * 12 - 1 # 1950:01 - 1950:11
  
  vol_short <- s_i
  vol_long <- l_i
  
  vol_param <- expand.grid(x = s_i, y = l_i) %>% arrange(x)
  
  obv <- matrix(0, nrow = t_vol, 1)
  
  date_t <- rownames(y_t)
  
  for (t in 2:t_vol) {
    
    p_change <- y_t[(nrow(y_t) - t_vol + t),] - y_t[(nrow(y_t) - t_vol + t - 1),]
    
    if (p_change >= 0) {
      
      obv[t] <- volume[t,]
      
    } else {
      
      obv[t] <- -1 * volume[t,]
      
    }
    
  }
  
  obv <- cumsum(obv) # 1950:01 - 2011:12
  
  s_vol <- matrix(0, nrow = t_vol - n_0_vol, ncol = nrow(vol_param))
  
  for (t in 1:nrow(s_vol)) {
    
    for (i in 1:nrow(vol_param)) {
      
      short <- mean(obv[(n_0_vol + t - (vol_param[i, 1] - 1)):(n_0_vol + t)])
      long <- mean(obv[(n_0_vol + t - (vol_param[i, 2] - 1)):(n_0_vol + t)])
      
      if (short > long) {
        
        s_vol[t, i] <- 1
        
      }
      
    }
    
  }
  
  colnames(s_vol) <- paste0("vol(", vol_param[,1], ",", vol_param[,2], ")")
  rownames(s_vol) <- date_t[12:length(date_t)]
  
  s_vol <- as_tibble(s_vol, rownames = "date") %>%
    mutate(date = as.numeric(date))
  
  return(s_vol)
  
}


# lagged realized-volatility signals
get_voa <- function (y_t, m_i) {
  
  n_0_voa <- 1 * 12
  
  voa_param <- m_i
  
  s_voa <- matrix(0,  nrow = nrow(y_t) - n_0_voa, ncol = length(voa_param))
  
  date_t <- rownames(y_t)
  
  for (t in 1:nrow(s_voa )) {
    
    for (i in 1:length(voa_param)) {
      
      p_difference <- y_t[(n_0_voa + t),] - y_t[(n_0_voa + t - voa_param[i]),]
      
      if (p_difference > 0) {
        
        s_voa[t, i] <- 1
        
      }
      
    }
    
  }
  
  colnames(s_voa) <- paste0("rv(", m_i, ")")
  rownames(s_voa) <- date_t[13:length(date_t)]
  
  s_voa <- as_tibble(s_voa, rownames = "date") %>%
    mutate(date = as.numeric(date))
  
  return(s_voa)
  
}
