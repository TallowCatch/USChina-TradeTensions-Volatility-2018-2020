# Load Required Libraries
library(dplyr)
library(tidyr)
library(broom)
library(ggplot2)
library(gridExtra)
library(rugarch)
library(xts)
library(zoo)
library(stats)
library(ggcorrplot)

# Read and Preprocess Data
stock_prices_file <- "big_tech_stock_prices.csv"
market_data_file <- "SPX.csv"

data <- read.csv(stock_prices_file)
data$date <- as.Date(data$date, format = "%Y-%m-%d")
data <- data %>%
  arrange(stock_symbol, date) %>%
  mutate(Daily_Return = (adj_close / lag(adj_close, default = first(adj_close)) - 1)) %>%
  filter(!is.na(Daily_Return))

# Event Data Creation
events <- data.frame(
  date = as.Date(c("2018-07-06", "2019-05-10", "2020-01-15")),
  event_description = c("Tariffs on $34B Chinese Goods", "25% Tariffs on $200B Goods", "US-China Phase One Agreement"),
  color = c("red", "blue", "green")
)

# Event Study Analysis
event_window <- 30
results <- list()

for(i in seq_along(events$date)) {
  event <- events$date[i]
  event_data <- data %>%
    filter(date >= (event - event_window) & date <= (event + event_window)) %>%
    arrange(date) %>%
    mutate(Abnormal_Return = Daily_Return - mean(Daily_Return, na.rm = TRUE))
}

# AAPL Cumulative Returns Analysis
aapl_data <- filter(data, stock_symbol == "AAPL")
aapl_data <- aapl_data %>%
  mutate(Cumulative_Return = cumprod(1 + Daily_Return) - 1)

# Risk-Return Profile Analysis
stats_by_stock <- data %>%
  group_by(stock_symbol) %>%
  summarise(
    Average_Return = mean(Daily_Return, na.rm = TRUE),
    Volatility = sd(Daily_Return, na.rm = TRUE)
  )

# Stock Price and Volatility Analysis
data_filtered <- data %>%
  filter(date >= as.Date("2018-01-01") & date <= as.Date("2021-12-31"))

data_filtered <- data_filtered %>%
  group_by(stock_symbol) %>%
  mutate(Rolling_Volatility = rollapply(Daily_Return, width = 30, FUN = sd, fill = NA, align = "right"))

# Market Data Integration and Beta Calculation
market_data_path <- 'data/SPX.csv'
market_data <- read.csv(market_data_path, stringsAsFactors = FALSE)
market_data$Date <- as.Date(market_data$Date, format = "%Y-%m-%d")
market_data$Market_Return <- with(market_data, (Close - lag(Close)) / lag(Close))

combined_data <- data %>%
  left_join(market_data, by = c("date" = "Date"))

combined_data_filtered <- combined_data %>%
  filter(date >= as.Date("2018-01-01") & date <= as.Date("2020-12-31")) %>%
  na.omit()

beta_results <- combined_data_filtered %>%
  group_by(stock_symbol) %>%
  do(model = lm(Daily_Return ~ Market_Return, data = .)) %>%
  summarize(beta = coef(model)["Market_Return"])
write.csv(beta_results, "Tech_Stock_Beta_Values.csv")

# Correlation Matrix
trade_tension_start <- as.Date("2018-01-01")
trade_tension_end <- as.Date("2020-12-31")
trade_tension_data <- data %>%
  filter(date >= trade_tension_start & date <= trade_tension_end,
         stock_symbol %in% c('AAPL', 'ADBE', 'AMZN', 'CRM', 'CSCO', 'GOOGL', 'IBM', 'INTC', 'META', 'MSFT', 'NFLX', 'NVDA', 'ORCL', 'TSLA'))

daily_returns <- trade_tension_data %>%
  select(date, stock_symbol, Daily_Return) %>%
  spread(stock_symbol, Daily_Return)

correlation_matrix <- cor(daily_returns[-1], use = "pairwise.complete.obs")

# Portfolio Simulation
portfolio_returns <- data_filtered %>%
  group_by(date) %>%
  summarize(Portfolio_Return = mean(Daily_Return, na.rm = TRUE))

# Price Range and Volume Analysis as Proxies for Liquidity and Volatility
data <- data %>%
  mutate(Price_Range = high - low)

# Summary Statistics Calculation
summary_stats <- data %>%
  group_by(stock_symbol) %>%
  summarise(Mean_Return = mean(Daily_Return, na.rm = TRUE),
            Volatility = sd(Daily_Return, na.rm = TRUE),
            Mean_Volume = mean(volume, na.rm = TRUE),
            Max_Volume = max(volume, na.rm = TRUE)) %>%
  ungroup()

# GARCH Model Fitting
garch_fits <- lapply(split(data, data$stock_symbol), function(stock_data) {
  stock_data <- stock_data[order(stock_data$date), ]
  log_returns <- diff(log(stock_data$adj_close))
  dates <- stock_data$date[-1]
  dates <- as.Date(dates)
  log_returns_xts <- xts(log_returns, order.by = dates)
  garch_spec <- ugarchspec(variance.model = list(garchOrder = c(1, 1)),
                           mean.model = list(armaOrder = c(0, 0), include.mean = FALSE))
  tryCatch({
    garch_fit <- ugarchfit(spec = garch_spec, data = log_returns_xts)
    return(garch_fit)
  }, warning = function(w) {
    warning("Solver failed to converge for ", stock_data$stock_symbol[1], ": ", w)
    return(NULL)
  }, error = function(e) {
    stop("Error fitting GARCH model for ", stock_data$stock_symbol[1], ": ", e)
  })
})

# Comparative Analysis Between Companies
data_filtered <- data %>%
  filter(date >= as.Date("2018-01-01") & date <= as.Date("2020-12-31"))
company1 <- "AAPL"
company2 <- "MSFT"
subset_data <- data_filtered %>%
  filter(stock_symbol %in% c(company1, company2))
if(all(table(subset_data$stock_symbol) >= 2)) {
  daily_returns_company1 <- subset_data %>%
    filter(stock_symbol == company1) %>%
    pull(Daily_Return)
  daily_returns_company2 <- subset_data %>%
    filter(stock_symbol == company2) %>%
    pull(Daily_Return)
  t_test_result <- t.test(daily_returns_company1, daily_returns_company2)
  print(t_test_result)
}

# Rolling Volatility Calculation
data <- data %>%
  group_by(stock_symbol) %>%
  mutate(Rolling_Volatility = rollapply(Daily_Return, width = 30, FUN = sd, fill = NA, align = "right")) %>%
  ungroup()

data$Period <- with(data, ifelse(date < as.Date("2018-01-01"), "Before",
                                 ifelse(date <= as.Date("2020-12-31"), "During", "After")))

data <- data %>%
  filter(!is.na(Rolling_Volatility))

mean_volatility_by_period <- data %>%
  group_by(stock_symbol, Period) %>%
  summarise(Mean_Rolling_Volatility = mean(Rolling_Volatility, na.rm = TRUE)) %>%
  ungroup()

anova_result_simplified <- aov(Mean_Rolling_Volatility ~ Period + stock_symbol, data = mean_volatility_by_period)
print(summary(anova_result_simplified))
