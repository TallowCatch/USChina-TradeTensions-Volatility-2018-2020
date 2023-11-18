# Market Volatility Analysis: US-China Trade Tensions (2018-2020)

## Overview

This R project is designed to explore market volatility in the context of US-China trade tensions between 2018 and 2020. It provides a comprehensive analysis of 14 technology stocks, highlighting the geopolitical impact on market performance.

## Data Sources

Datasets used in this analysis are:

- S&P 500 historical data: [Kaggle](https://www.kaggle.com/datasets/henryhan117/sp-500-historical-data).
- Big Tech stock prices: [Kaggle](https://www.kaggle.com/datasets/evangower/big-tech-stock-prices).

## Components

- **Event Studies**: Analysis of stock performance surrounding key trade tension events.
- **Risk-Return Analysis**: Examines return patterns across different stocks.
- **Volatility Measurements**: Utilizes GARCH models for market risk assessment.
- **Liquidity Analysis**: Investigates market liquidity changes due to trade events.
- **Portfolio Simulation**: Analyzes overall performance of a tech stock portfolio.

## Prerequisites

Ensure R is installed with packages: `dplyr`, `tidyr`, `ggplot2`, `xts`, `rugarch`, etc.

## Running the Analysis

1. Clone/download the repository.
2. Load datasets into R from Kaggle.
3. Execute the R scripts in the presented order.

## Key Visualizations

### Event Study Analysis

Abnormal returns around trade-related events:  

![Event Study](Visualizations/stock_price_movements_2018_2021_with_events.png)

### Cumulative Returns

Cumulative returns for a tech stock, highlighting trade tension impacts: 

![Cumulative Returns](Visualizations/AAPL_Cumulative_Returns.png)

### Rolling Volatility

Displays tech stocks' rolling volatility from 2018 to 2022:

![Rolling-Volatility](Visualizations/rolling_volatility_2018_2021.png)

*NOTE: Generated rolling volatility extends beyond project scope to verify plot functionality.*

## GARCH Model Usage

For GARCH modeling, here's an example, using AAPL stock data:

```R
# Load the rugarch package
library(rugarch)

# Filter AAPL data, run GARCH Model, plot volatility
aapl_data <- filter(data, stock_symbol == "AAPL")
garch_fit_aapl <- runGarchModel(aapl_data)
plotVolatility(garch_fit_aapl)
```

Here's how it should look like:

![GARCH-Model](Visualizations/AAPL_volatility_white_bg.png)

## Deployment

* Execute analysis on any R-enabled machine. No special deployment steps required unless integrating into a Shiny app or similar platforms.

