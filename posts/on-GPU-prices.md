+++
date = "7/11/2021"
title = "on GPU prices"
tags = ["crypto", "tech"]
rss_description = "What does MSRP even mean?"
+++

With the increase in appreisal of crypto currencies GPU prices have climbed to 2-4x their [MSRP]. Some have blamed covid and the lockdown that forced people at home for increase in demand for home appliances; however the _almost_ 1:1 correlation between historical prices of gpus and cryptos makes covid almost irrelevant.

## What about machine learning?
In comparison, machine learning (or particularly, deep learning) only saturates the very high-end price range because it requires [FP] precision, which is a more niche requirement, where as a crypto [GPU pow] tries to leverage the _whole_ GPU instructions set, therefore the full products range of the GPU market is appealing for mining.

## Can we expect GPU prices to ever go back to MSRP?
No. The GPU market has been eaten by crypto mining and will never recover.
- GPUs are _stackable_ which means that your average miner buys at least 4 GPUs where-as your average consumer only needs 1 GPU most of the times
- If the major cryptocurrencies switch to _POS_ (like [ETH]), other crypto currencies will take it's hashing power, a much sharper price correction has to happen to cause a sudden GPU sell-off by miners.
- Miners are fine switching mining equipement on and off depending on the reward ratio between electricity cost and cryptocurrency prices, they won't sell the hardware at the first dip.

## What do?
The only GPUs at time of writing with reasonable prices are the integrated ones, and the laptops that ship with GPUs (in the _mobile_ versions). If manufacturers want to re-open the GPU market to average users they have to offer integrated solutions that are __more competitive__ against dedicated ones. Or design a different kind of GPU that is half-way between a dedicated and integrated; how? by thinking about tightly coupled CPUs and GPUs that are yet modular (and therefore swappable, but not stackable!).

[MSRP]: https://en.wikipedia.org/wiki/List_price
[covid]: https://en.wikipedia.org/wiki/COVID-19
[ETH]: https://ethereum.org
[FP]: https://en.wikipedia.org/wiki/Double-precision_floating-point_format
[GPU pow]: https://eips.ethereum.org/EIPS/eip-1057
