+++
date = "2/2/2022"
title = "Julia Backtesting framework"
tags = ["crypto", "tools", "trading"]
rss_description = "Trading cryptocurrencies with julia."
+++

[Backtest.jl](https://github.com/untoreh/Backtest.jl) is a julia project that I wrote to do stuff with cryptocurrencies trading. Currently it hooks to the [ccxt](https://github.com/ccxt/ccxt/) python library to connect to exchanges apis, for now just to fetch ohlcv data.

## A rough list of features
- OHLCV data is sanitized and saved using [Zarr.jl](https://github.com/meggart/Zarr.jl)
- There are methods to filter _pairs_ which is what I call the markets that you trade with, composed of the base currency and quote currency, like `BTC/USDT`
- It is possible to resample (downsample) the ohlcv data from smaller timeframes to larger ones.
- A simple CLI allows to download and resample the data such that a cron job can be setup to download data perioadically.
- There are some basic plotting utilities based on the [echarts](https://echarts.apache.org/en/index.html) library through the [pycharts](https://pyecharts.org/) python wrapper. There is also [Echarts.jl](https://randyzwitch.com/ECharts.jl/) but had some issues with it. I might just work with just creating the echarts js configurations my self in the future depending on how pyecharts progresses.
- I played a little with some orderbook data ,and orderbook imbalance, through the OrderBook module.
- The `Analysis` module instead deals with indicators and feature filtering. It is backed by `Indicators.jl` package, and the `CausalityTools.jl` package for correlations.
- Other funny indicators which I transposed from a _book you can easily find on the web_ are provided by the modules `MVP`, `Violations` for shorting and `Considerations` for longing.
