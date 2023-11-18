# ---------------------------------------------------------
# Load Required Libraries
# ---------------------------------------------------------
library(dplyr)
library(tidyr)
library(broom)
library(ggplot2)
library(gridExtra)
library(rugarch)
library(xts) # for time series objects
library(zoo)
library(stats)
library(ggcorrplot)

# ---------------------------------------------------------
# Read and Preprocess Data
# ---------------------------------------------------------
stock_prices_file <- "big_tech_stock_prices.csv"
market_data_file <- "SPX.csv"

data <- read.csv(stock_prices_file)
data$date <- as.Date(data$date, format = "%Y-%m-%d")

data <- data %>%
  arrange(stock_symbol, date) %>%
  mutate(Daily_Return = (adj_close / lag(adj_close, default = first(adj_close)) - 1)) %>%
  filter(!is.na(Daily_Return))

# ---------------------------------------------------------
# Event Data Creation
# ---------------------------------------------------------
events <- data.frame(
  date = as.Date(c("2018-07-06", "2019-05-10", "2020-01-15")),
  event_description = c("Tariffs on $34B Chinese Goods",
                        "25% Tariffs on $200B Goods",
                        "US-China Phase One Agreement"),
  color = c("red", "blue", "green")
)

# ---------------------------------------------------------
# Event Study Analysis
# ---------------------------------------------------------
event_window <- 30  # 30 days before and after the event
results <- list()

for(i in seq_along(events$date)) {
  event <- events$date[i]
  event_description <- events$event_description[i]
  
  event_data <- data %>%
    filter(date >= (event - event_window) & date <= (event + event_window)) %>%
    arrange(date) %>%
    mutate(Abnormal_Return = Daily_Return - mean(Daily_Return, na.rm = TRUE))
  
  plot <- ggplot(event_data, aes(x = date, y = Abnormal_Return, color = stock_symbol)) +
    geom_line() +
    geom_vline(xintercept = as.numeric(event), linetype = "longdash", color = "red") +
    labs(title = paste("Abnormal Returns Around", event_description, "Event Date:", event),
         x = "Date",
         y = "Abnormal Return") +
    theme_minimal() +
    theme(plot.background = element_rect(fill = "white", colour = NA),
          panel.background = element_rect(fill = "white", colour = NA),
          legend.position = "bottom")
  
  results[[event_description]] <- plot
}
# ---------------------------------------------------------
# AAPL Cumulative Returns Analysis
# ---------------------------------------------------------

# Filter data for AAPL
aapl_data <- filter(data, stock_symbol == "AAPL")

# Calculate Cumulative Returns
aapl_data <- aapl_data %>%
  mutate(Cumulative_Return = cumprod(1 + Daily_Return) - 1)

# Define Trade Tension Period
start_trade_tension <- as.Date("2018-01-01")
end_trade_tension <- as.Date("2020-12-31")

# Create the plot
aapl_plot <- ggplot(aapl_data, aes(x = date, y = Cumulative_Return)) +
  geom_line() +
  geom_vline(xintercept = as.numeric(start_trade_tension), color = "red", linetype = "dashed") +
  geom_vline(xintercept = as.numeric(end_trade_tension), color = "purple", linetype = "dashed") +
  labs(title = "AAPL Cumulative Returns with Trade Tension Period Highlighted",
       x = "Date",
       y = "Cumulative Return") +
  theme_minimal() +
  theme(panel.background = element_rect(fill = "white"),
        plot.background = element_rect(fill = "white", color = NA))

# ---------------------------------------------------------
# Risk-Return Profile Analysis
# ---------------------------------------------------------

library(dplyr)
library(ggplot2)

# Calculate the average return and volatility for each stock
stats_by_stock <- data %>%
  group_by(stock_symbol) %>%
  summarise(
    Average_Return = mean(Daily_Return, na.rm = TRUE),
    Volatility = sd(Daily_Return, na.rm = TRUE)
  ) %>%
  ungroup()  # Remove grouping

# Now create the scatter plot
risk_return_plot <- ggplot(stats_by_stock, aes(x = Volatility, y = Average_Return)) +
  geom_point(aes(color = stock_symbol), size = 4) +
  geom_text(aes(label = stock_symbol), vjust = 1.5, hjust = 0.5) +
  labs(
    title = "Risk-Return Profile for Stocks",
    x = "Volatility (Risk)",
    y = "Average Return (Return)"
  ) +
  theme_minimal() +
  theme(legend.position = "none",  # Hide legend because we use text labels
        panel.background = element_rect(fill = "white"),
        plot.background = element_rect(fill = "white", color = NA))

# ---------------------------------------------------------
# Stock Price and Volatility Analysis
# ---------------------------------------------------------
data_filtered <- data %>%
  filter(date >= as.Date("2018-01-01") & date <= as.Date("2021-12-31"))

stock_plot_filtered <- ggplot(data_filtered, aes(x = date, y = adj_close, color = stock_symbol, group = stock_symbol)) +
  geom_line() +
  geom_vline(data = events, aes(xintercept = date, color = event_description), linetype = "dashed") +
  scale_color_manual(name = "Events", values = setNames(events$color, events$event_description)) +
  labs(title = "Daily Stock Price Movements (2018-2021) with US-China Trade Tension Events",
       x = "Date",
       y = "Adjusted Close Price") +
  theme_minimal() +
  theme(plot.background = element_rect(fill = "white", colour = NA),
        panel.background = element_rect(fill = "white", colour = NA),
        legend.position = "bottom")

data_filtered <- data_filtered %>%
  group_by(stock_symbol) %>%
  mutate(Rolling_Volatility = rollapply(Daily_Return, width = 30, FUN = sd, fill = NA, align = "right")) %>%
  ungroup()

ggplot(data_filtered, aes(x = date, y = Rolling_Volatility, color = stock_symbol)) +
  geom_line() +
  labs(title = "30-Day Rolling Volatility of Stock Returns (2018-2021)",
       x = "Date",
       y = "Rolling Volatility",
       color = "Stock Symbol") +
  theme_minimal() +
  theme(plot.background = element_rect(fill = "white", colour = NA),
        panel.background = element_rect(fill = "white", colour = NA))

# ---------------------------------------------------------
# Market Data Integration and Beta Calculation
# ---------------------------------------------------------
market_data_path <- '/Users/ameerfiras/Dropbox/Stock_Market_Project/SPX.csv'
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
  summarize(beta = coef(model)["Market_Return"]) %>%
  ungroup()
write.csv(beta_results, "Tech_Stock_Beta_Values.csv")

# ---------------------------------------------------------
# Correlation Matrix
# ---------------------------------------------------------
# Define the trade tension period
trade_tension_start <- as.Date("2018-01-01")
trade_tension_end <- as.Date("2020-12-31")

# Filter data to include only the trade tension period and the tech stocks you're interested in
trade_tension_data <- data %>%
  filter(date >= trade_tension_start & date <= trade_tension_end,
         stock_symbol %in% c('AAPL', 'ADBE', 'AMZN', 'CRM', 'CSCO', 'GOOGL', 'IBM', 'INTC', 'META', 'MSFT', 'NFLX', 'NVDA', 'ORCL', 'TSLA'))

# Calculate daily returns for each stock
daily_returns <- trade_tension_data %>%
  select(date, stock_symbol, Daily_Return) %>%
  spread(stock_symbol, Daily_Return) # Spreads the data into a wide format where each stock is a column

# Calculate the correlation matrix for the tech stocks
correlation_matrix <- cor(daily_returns[-1], use = "pairwise.complete.obs") # Excludes the first column (date)

# Visualize the correlation matrix
corrplot <- ggcorrplot(correlation_matrix, 
                       hc.order = TRUE, 
                       type = "lower", 
                       lab = TRUE,
                       lab_size = 3, # Adjust label size as needed
                       tl.cex = 0.6, # Adjust text size for the correlation coefficients
                       tl.srt = 45, # Rotate text for better legibility
                       title = "Correlation of Tech Stocks During Trade Tension Period")

# Ensure that the axes and axis labels show up
corrplot + theme(
  axis.text.x = element_text(angle = 45, hjust = 1),
  axis.text.y = element_text(angle = 45, vjust = 1),
  panel.background = element_blank(), # Set panel background to blank (white)
  plot.background = element_blank(),  # Set plot background to blank (white)
  panel.grid.major = element_blank(), # Remove major grid lines
  panel.grid.minor = element_blank()  # Remove minor grid lines
)

# Save the plot with a white background
ggsave("Correlation_Matrix_Plot.png", plot = last_plot(), bg = "white", width = 10, height = 6, dpi = 300)
# ---------------------------------------------------------
# Portfolio Simulation
# ---------------------------------------------------------
portfolio_returns <- data_filtered %>%
  group_by(date) %>%
  summarize(Portfolio_Return = mean(Daily_Return, na.rm = TRUE))

portfolio_plot <- ggplot(portfolio_returns, aes(x = date, y = Portfolio_Return)) +
  geom_line() +
  labs(title = "Tech Stock Portfolio Performance (2018-2020)",
       x = "Date",
       y = "Daily Portfolio Return") +
  theme_minimal() +
  theme(plot.background = element_rect(fill = "white", colour = NA),
        panel.background = element_rect(fill = "white", colour = NA))

# ---------------------------------------------------------
# Price Range and Volume Analysis as Proxies for Liquidity and Volatility
# ---------------------------------------------------------
data <- data %>%
  mutate(Price_Range = high - low)

average_price_range <- data_trade_tension %>%
  group_by(stock_symbol) %>%
  summarize(Average_Price_Range = mean(Price_Range, na.rm = TRUE))

average_volume <- data_trade_tension %>%
  group_by(stock_symbol) %>%
  summarize(Average_Volume = mean(volume, na.rm = TRUE))

price_range_plot <- ggplot(data_trade_tension, aes(x = date, y = Price_Range, color = stock_symbol)) +
  geom_line() +
  labs(title = "Price Range Over Time",
       x = "Date",
       y = "Price Range") +
  theme_minimal() +
  theme(plot.background = element_rect(fill = "white", colour = NA),
        panel.background = element_rect(fill = "white", colour = NA))

volume_plot <- ggplot(data_trade_tension, aes(x = date, y = volume, color = stock_symbol)) +
  geom_line() +
  labs(title = "Trading Volume Over Time",
       x = "Date",
       y = "Volume") +
  theme_minimal() +
  theme(plot.background = element_rect(fill = "white", colour = NA),
        panel.background = element_rect(fill = "white", colour = NA))

# ---------------------------------------------------------
# Summary Statistics Calculation
# ---------------------------------------------------------
summary_stats <- data %>%
  group_by(stock_symbol) %>%
  summarise(Mean_Return = mean(Daily_Return, na.rm = TRUE),
            Volatility = sd(Daily_Return, na.rm = TRUE),
            Mean_Volume = mean(volume, na.rm = TRUE),
            Max_Volume = max(volume, na.rm = TRUE)) %>%
  ungroup()

# ---------------------------------------------------------
# GARCH Model Fitting
# ---------------------------------------------------------
garch_fits <- lapply(split(data, data$stock_symbol), function(stock_data) {
  stock_data <- stock_data[order(stock_data$date), ]
  log_returns <- diff(log(stock_data$adj_close))
  dates <- stock_data$date[-1]
  dates <- as.Date(dates)
  
  if(length(log_returns) != length(dates)) {
    stop("Length mismatch between log returns and dates.")
  }
  
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

# Example Plotting for a Specific Stock (e.g., AAPL)
garch_fit_aapl <- garch_fits[['AAPL']]
if (!is.null(garch_fit_aapl)) {
  sigma_t <- as.numeric(sigma(garch_fit_aapl))
  forecast_aapl <- ugarchforecast(garch_fit_aapl, n.ahead = 40)
  forecast_sigma <- as.numeric(forecast_aapl@forecast$sigmaFor)
  
  dates <- as.Date(index(sigma(garch_fit_aapl)))
  forecast_dates <- seq(from = max(dates) + 1, by = "days", length.out = length(forecast_sigma))
  
  combined_data <- data.frame(
    Date = c(dates, forecast_dates),
    Sigma = c(sigma_t, forecast_sigma),
    Type = c(rep("Historical", length(dates)), rep("Forecast", length(forecast_sigma)))
  )
  
  vol_plot <- ggplot(combined_data, aes(x = Date, y = Sigma, color = Type)) +
    geom_line() +
    labs(title = "Historical and Forecasted Volatility for AAPL",
         x = "Date",
         y = "Volatility (Sigma)") +
    theme_minimal() +
    scale_color_manual(values = c("Historical" = "blue", "Forecast" = "red"))
} else {
  warning("GARCH model fitting for AAPL failed, so no plot can be generated.")
}

# ---------------------------------------------------------
# Comparative Analysis Between Companies
# ---------------------------------------------------------
data_filtered <- data %>%
  filter(date >= as.Date("2018-01-01") & date <= as.Date("2020-12-31"))

# Subset data for two specific companies during the trade tension period
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
} else {
  stop("Not enough observations for one of the groups.")
}

# ---------------------------------------------------------
# Rolling Volatility Calculation
# ---------------------------------------------------------
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

# Note that the plots will be saved in the current working directory.
