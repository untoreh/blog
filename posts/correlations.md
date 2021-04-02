+++
date = "4/2/2021"
title = "Correlations"
tags = ["stats", "trading"]
rss_description = "A list of correlation metrics"
+++

## From scipy.stats

- Pearson (`pearsonr`)
- Spearman (`spearmanr`)
- Kendall (`kendalltau`, `weightedtau`)
- Theil-Sen (`theilslopes`)
- Siegel (`siegelslopes`)

## From Shannon

- joint entropy
- conditional entropy
- information gain

## Others

- quotient correlation (`(max(y, x) + max(x, y) - 2) / (max(y, x) * max(x, y) - 1)`)
- Cohen (SO)
- autocorrelation (`np.correlate`)
