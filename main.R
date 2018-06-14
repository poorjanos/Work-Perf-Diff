# Procedure to compare performance to historical data on an hourly basis
#   
#   The performance of the current hour is compared to the average performance of previous 
#   hours most similar to current hour
#   
#   Similar previous hours determined with Euclidean distances based on times spent by users
#   on different tasks


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
dir.create(here::here("R"), showWarnings = FALSE)
dir.create(here::here("Data"), showWarnings = FALSE)

# Import helper funcs
source(here::here("R", "data_manipulation.R"))

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

# Gen vector space for current hour
t_hour_vectors <- gen_vector_space_by_activity(t_prop_pace)

# Get most similar days
t_similar_days <- get_similar_days(t_hour_vectors, 10)






