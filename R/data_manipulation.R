gen_vector_space_by_prod <- function(df) {
  # Returns vector space for the target hour for days in the past 6 months plus current day
  # broken down by USER:PRODUCT touch-time aggregates
  # Pool field identifies vectors
  #   hist:   hour vectors (of previous days) to compare to
  #   curr: single hour vector (of current day) to compare to historic vectors
  df %>%
    mutate(
      DAY = floor_date(ymd_hms(F_INT_BEGIN), "day"),
      TARGET_HOUR = hour(ymd_hms(ZART_ORA)),
      USER_PROD = paste0(LOGIN, "_", F_TERMCSOP)
    ) %>%
    group_by(DAY, TARGET_HOUR, USER_PROD, POOL) %>%
    summarize(TOTAL_TIME = sum(CKLIDO)) %>%
    ungroup() %>%
    # Filter for current hour
    filter(TARGET_HOUR == hour(Sys.time())) %>%
    # Spread to wide format to align past days with current
    tidyr::spread(USER_PROD, TOTAL_TIME) %>% 
    replace(is.na(.), 0) %>% 
    arrange(DAY)
}


gen_vector_space_by_activity <- function(df) {
  # Returns vector space for the target hour for days in the past 6 months plus current day
  # broken down by USER::ACTIVITY touch-time aggregates
  # Pool field identifies vectors
  #   hist:   hour vectors (of previous days) to compare to
  #   curr: single hour vector (of current day) to compare to historic vectors
  df %>%
    mutate(
      DAY = floor_date(ymd_hms(F_INT_BEGIN), "day"),
      TARGET_HOUR = hour(ymd_hms(ZART_ORA)),
      USER_ACTIVITY = paste0(LOGIN, "_", TEVEKENYSEG, "_", F_OKA, "_", KIMENET)
    ) %>%
    group_by(DAY, TARGET_HOUR, USER_ACTIVITY, POOL) %>%
    summarize(TOTAL_TIME = sum(CKLIDO)) %>%
    ungroup() %>%
    # Filter for current hour
    filter(TARGET_HOUR == hour(Sys.time())) %>%
    # Spread to wide format to align past days with current
    tidyr::spread(USER_ACTIVITY, TOTAL_TIME) %>% 
    replace(is.na(.), 0) %>% 
    arrange(DAY)
}


get_similar_days <- function(vec_space, num_days = 10){
  # Returns vector of most similar days
  # Num of days to returned specified with num_days parameter
  
  # Current day as vector
  current_day <- vec_space %>% filter(POOL == "curr") %>% 
    select(-DAY, -POOL, -TARGET_HOUR) %>% 
    as.vector()
  
  # Past days as matrix
  past_days <- vec_space %>% filter(POOL == "hist") %>% 
    select(-DAY, -POOL, -TARGET_HOUR) %>% 
    as.matrix()
  
  # Compute Euclidean distance of vector from each matrix row
  euclidean_dist <- apply(past_days, 1, function(x)sqrt(sum((x - current_day)^2))) 
  
  # Return results as df
  t_distance <- data.frame(CURRENT_HOUR = floor_date(Sys.time(), "hour"),
                           SIMILAR_DAY = t_hour_vectors %>% filter(POOL == "hist") %>% select(DAY),
                           DIST = euclidean_dist) %>% 
                        arrange(DIST) %>% 
                        top_n(10, desc(DIST))
}