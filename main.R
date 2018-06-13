# Procedure to compare performance to historical data on an hourly basis

# Redirect stdout to logfile
scriptLog <- file("scriptLog", open = "wt")
sink(scriptLog, type = "message")

# Load required libs
library(config)
library(here)
library(ggplot2)
library(dplyr)
library(lubridate)

# Quit if sysdate == weekend ------------------------------------------------------------
stopifnot(!(strftime(Sys.Date(), '%u') == 7 | hour(Sys.time()) >= 18))

# Create default dirs
dir.create(here::here("Reports"), showWarnings = FALSE)
dir.create(here::here("SQL"), showWarnings = FALSE)

##########################################################################################
# Extract Data ###########################################################################
##########################################################################################

# Set JAVA_HOME, set max. memory, and load rJava library
Sys.setenv(JAVA_HOME = "C:\\Program Files\\Java\\jre1.8.0_171")
options(java.parameters = "-Xmx2g")
library(rJava)

# Output Java version
.jinit()
print(.jcall("java/lang/System", "S", "getProperty", "java.version"))

# Load RJDBC library
library(RJDBC)

# Create connection driver and open connection
jdbcDriver <-
  JDBC(driverClass = "oracle.jdbc.OracleDriver", classPath = "C:\\Users\\PoorJ\\Desktop\\ojdbc7.jar")

# Get Kontakt credentials
kontakt <-
  config::get("kontakt",
              file = "C:\\Users\\PoorJ\\Projects\\config.yml")

# Open connection
jdbcConnection <-
  dbConnect(
    jdbcDriver,
    url = kontakt$server,
    user = kontakt$uid,
    password = kontakt$pwd
  )


# Run queries
t_prop_pace <- dbGetQuery(jdbcConnection, "select * from t_prop_pace")

# Close connection
dbDisconnect(jdbcConnection)


#########################################################################################
# Data Transformation ###################################################################
#########################################################################################

# Gen hourly aggregates
t_hour <- t_prop_pace %>%
  mutate(
    NAP = floor_date(ymd_hms(F_INT_BEGIN), "day"),
    ZART_ORA = hour(ymd_hms(ZART_ORA)),
    LOGIN_TERM = paste0(LOGIN, "_", F_TERMCSOP)) %>%
  group_by(NAP, ZART_ORA, LOGIN_TERM, POOL) %>%
  summarize(IDO = sum(CKLIDO)) %>%
  ungroup() %>%
  arrange(NAP, ZART_ORA, LOGIN_TERM)


# Filter for current hour
t_hour_curr <- t_hour %>% 
                filter(ZART_ORA == hour(Sys.time())) %>% 
                select(-ZART_ORA) 


# Gen vector space
t_vec <-  t_hour_curr %>% tidyr::spread(LOGIN_TERM, IDO) 


