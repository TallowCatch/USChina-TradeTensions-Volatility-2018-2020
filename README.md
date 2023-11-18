# Tech Stock Analysis Project

## Overview

This project analyzes the impact of US-China trade tensions on the volatility and performance of technology stocks from 2018 to 2020. It includes event studies around significant trade events, risk-return profiling, and liquidity analysis, offering insights into the intricate dynamics of the stock market during geopolitical fluctuations.

## Data Sources

The datasets used for this analysis include:

- S&P 500 historical data from [Kaggle](https://www.kaggle.com/datasets/henryhan117/sp-500-historical-data).
- Big Tech stock prices from [Kaggle](https://www.kaggle.com/datasets/evangower/big-tech-stock-prices).

## Components

- **Event Studies** reveal the stock performance around key trade tension events.
- **Risk-Return Analysis** profiles the return patterns of various stocks.
- **Volatility Measurements** use GARCH models to quantify market risks.
- **Liquidity Analysis** examines how trade events affected market liquidity.
- **Portfolio Simulation** evaluates the collective performance of tech stocks.

## Visualizations

Below are some of the key visualizations generated from the analysis. These visuals aid in understanding the market trends, stock performance, and impacts of geopolitical events on tech stocks.

### Cumulative Returns

This graph shows the cumulative returns of a selected tech stock over a specific period, highlighting the impact of trade tensions.

![Cumulative Returns](/path/to/AAPL_Cumulative_Returns_With_Trade_Tension_Period.png)

### Risk-Return Profile

This visualization provides a risk-return profile of various tech stocks, allowing for a comparative analysis of their performances.

![Risk-Return Profile](/path/to/Risk-Return_Profile_for_Stocks.png)

### Event Study Analysis

This plot represents the event study around a specific trade-related event, showing its immediate impact on tech stock prices.

![Event Study](/path/to/event_study_Tariffs_on_$34B_Chinese_Goods.png)

## Prerequisites

Before running the analysis, ensure you have R installed along with the following packages: `dplyr`, `tidyr`, `ggplot2`, `xts`, `rugarch`, and others mentioned in the script comments.

## Running the Analysis

To run the scripts:

1. Clone or download the repository to your local machine.
2. Load the datasets into R from the specified Kaggle sources.
3. Execute the R scripts in the order they are presented.

## Using the GARCH Model

The GARCH model script can be adapted for personal use. Here's an example using AAPL stock data:

```R
# Load the rugarch package
library(rugarch)

# Assuming 'data' is your dataframe and contains AAPL stock data
# Filter data for AAPL
aapl_data <- filter(data, stock_symbol == "AAPL")

# Run the GARCH Model
garch_fit_aapl <- runGarchModel(aapl_data)

# Plot the volatility
plotVolatility(garch_fit_aapl)
```

## Deployment

The analysis can be executed on any machine with R and the required packages installed. No specific deployment steps are required unless integrated into a Shiny app or other interactive platforms.
