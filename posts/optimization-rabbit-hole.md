+++
date = "1/14/2023"
title = "Optimization rabbit hole in python"
tags = ["crypto", "software", "trading"]
rss_description = "Speeding up backtesting for the freqtrade crypto trading bot."
+++

[Freqtrade](https://github.com/freqtrade/freqtrade) Is a crypto trading bot in python.
I used to play with a fork for a while, fixing some bugs and some behaviour that I didn't like.
Listing the bugs here would be boring so I will instead talk about the things that I think are interesting.

# How freqtrade (FQT) works, on a high level
FQT is not event based, it is loop based. What does this mean? We could be talking about the executor (live operation) or the backtester. In this case they are both loop based. 

### Short detour here. What do I prefer? Loops or Events?
- Loops are generally simpler and easier to reason with, compared to events. Events OTOH can model the real world better. Loops are also easier to parallelize compared to events, and perform generally faster.
- Loop based backtesting can be run side by side with the live executor. This means that backward evaluation becomes part of your trading strategy. Running an event based backtesting system *live* seems like a mess to me. That's because events require a notion of time, but during live trading you only have the present, so what would you simulate anyway and how?



...returning to FQT, in live mode, it processes orders on a loop. Every X seconds it queries the exchange for updates. It keeps tracks of:
- the pairslist which holds all the last prices of all the assets (for exchanges that support it)
- fresh OHLCV data
- status of open orders

### Ruh-roh
Loop based live execution has an obvious problem. It is synchronous. If you process to many pairs execution will be less responsive, and iterate less often, lagging behind the unfolding of price action. So despite the fact that I prefer loops for backtesting, I prefer events for live execution. 

The downside? If you use events for one thing and loop for the other, it is easier for models or parameters of the strategy to diverge and not match reality. 

My defense argument against this is that constantly running self evaluation (backtesting) and live execution obviates this problem because they will *eventually* align.

FQT has many configuration parameters and many time the distinction between the bot and the strategy would turn greyish as the strategy can't control how the orders are executed by the bot.
The bot handles "roi" which is a grid of take-profit price limits and "trailing stoploss" the same but on the downside. The strategy only provides the parameters and the bot does the rest. I was not a fan of this.

Callbacks for buy and sell signals. Trades would happen based on signals returned by callbacks that would compute signal on a dataframe. The problem with this is that signal are static; you could just dynamically compute a 1 row dataframe, and feed that to the bot, but it wouldn't be backtestable. This is fine if you don't value backtesting that much, to each their own.

# Patchworks
What I modified in FQT to try to make it behave to my likining.
- [More pairlist filters](https://github.com/orehunt/freqtrade/tree/canary/freqtrade/plugins/pairlist). By reducing the number of pairs to process on each iteration, you would reduce the load at the cost of some reactivity. You would still process all the assets for which there were open trades, and a limited number of new ones. So I built
  - A [shuffling filter](https://github.com/orehunt/freqtrade/blob/canary/freqtrade/plugins/pairlist/ShuffleFilter.py) to just pick pairs at random.
  - A round robin filter to iterate on pairs little by little.
  - A static list, to load from storage
- Data formats: I added support for hdf, [parquet](https://github.com/orehunt/freqtrade/blob/canary/freqtrade/data/history/parquetdatahandler.py) and [zarr](https://github.com/orehunt/freqtrade/blob/canary/freqtrade/data/history/zarrdatahandler.py). 
  Of these I found myself using zarr, thanks to its builtin fast de/compression of data. Easier than parquet and more ergonomic.
There are a bunch of other tweaks, like parallel signals evaluation that I eventually gutted out as I focused more on build fast signals, and tweaks for plotting and config options, but they are not noteworthy.

# The quest for _vectorized_ backtest
I tried many version of backtesting to speed it up. It was all, not at all, worth it.
Computing logic between buy and sell operation using numpy arrays. It is like playing tetris with your brain. I mean where the blocks are made of your grey matter, and you try to put them together.
Here we list them
- [Chunked backtest](https://github.com/orehunt/freqtrade/blob/canary/freqtrade/optimize/backtest_engine_loop_ranges.py). In this one we would try to collapse trades using only numpy arrays. Juggling between the correct flow of execution of buy/sell,signals,stoplosses,trailing stoplosses,roi grid calculation, time weighted roi calculations. All with numpy arrays, it was quite a mess.
- [VBT based](https://github.com/orehunt/freqtrade/blob/canary/freqtrade/optimize/vbt.py) This version tried to leverage [vectorbt](https://github.com/polakowo/vectorbt) numba based python library to execute the backtest. Surprisingly it was not much faster then the numpy version. It was because there had to be a lot of type conversions into VBT compatible types, so whatever speed was gained from the execution was lost there.
- [Looping over ranges](https://github.com/orehunt/freqtrade/blob/canary/freqtrade/optimize/backtest_engine_loop_ranges.py) This was the first attempt at using numba myself. Because numba can natively call numpy functions, I adapted my numpy based backtest framework to work under numba. The gain were very small. The cost of putting everything into numpy arrays was the bottleneck. The gains achieved afterwards were minimal since after numpy conversion, the numpy execution is already fast.
- [Looping over candles](https://github.com/orehunt/freqtrade/blob/canary/freqtrade/optimize/backtest_nb.py#L571) This was and rightfully so the last one. It was the implementation that performed the best. That's because it was "simple" iteration over candles, all performed within numba jitted functions. The concept was simple, but implementing all roi, and stoploss logic while dealing with numba bugs was not nice. It worked quite well in the end, but it was after a mountain of numba incompatibilities that I had to climb.
We added also some additional features to the backtest, like [spread and liquidity](https://github.com/orehunt/freqtrade/blob/98a7e702ed906d9fa42405ef875e2dbe4d324217/freqtrade/optimize/hyperopt_backtest.py#L520) calculation, and the previously mentioned time weighted roi.

# The quest for _parallel_ optimization
Why did I want a fast backtester? Because I want to run many of them such that I can find the bestest of the best parameter config...of course, disregarding any concept of over-fitting, over-parametrization, lack-of-focus, etc... Let's list what I worked on:
- Dispatching jobs to other workers (processes) [as fast as possible](https://github.com/orehunt/freqtrade/blob/98a7e702ed906d9fa42405ef875e2dbe4d324217/freqtrade/optimize/hyperopt.py#LL633C15-L633C15). 
  The first improvement was changing the way jobs were dispatched. From dispatch N jobs and waiting for all of them to finish, I changed the process to feed new jobs as soon as the previous ones were done. There was a problem with this approach however. Optimization is many times sequential. You can't know which points of the parameter space to observe, without having finished computing the previous ones. This is true at least for bayesian optimization. This means that if we sample new trials continuously we wouldn't improve the search that much between optimization, but the search would be more robust.
  
  We could use another optimizer not based on bayesian optimization, like [this one](https://github.com/eyounx/ZOOpt). Or run N independent optimizers, such that each process/optimizer would query for new jobs using its own history, or optionally the history shared with all the others (although this would make all the optimizers converge after some time, which could have been a nice property, or not, depending on the case).

  Sharing observations between all the processes was a total disaster. Pickling and unpikling large lists of floats is very slow. As the search progresses, the number of observations grows, and the whole process become slower and slower to the point where serialization takes more time than the observation evaluation. It was slow both using a manager process, plain files, or mem-mapped ones. The best *bang for the buck* approach therefore turned out to be to run separate optimizers and never share observations among them, keep everything in memory.

- Keeping track of optimization state. Imagine running an optimization for hours, then something crashes and you loose everything. Of course we wanted to avoid that, so we added logic to [save periodically](https://github.com/orehunt/freqtrade/blob/98a7e702ed906d9fa42405ef875e2dbe4d324217/freqtrade/optimize/hyperopt_data.py#LL203C16-L203C16). This was the main driver for adding zarr storage support, saving state with zarr improved things considerably.
- Visualization of performed optimization. FQT already had good visualization for running optimization. I improved upon it. I had to create an [object](https://github.com/orehunt/freqtrade/blob/98a7e702ed906d9fa42405ef875e2dbe4d324217/freqtrade/optimize/hyperopt_backend.py#L59) to represent every observation. Then I could run additional post processing like [normalization](https://github.com/orehunt/freqtrade/blob/98a7e702ed906d9fa42405ef875e2dbe4d324217/freqtrade/optimize/hyperopt_data.py#L635) and [filtering](https://github.com/orehunt/freqtrade/blob/98a7e702ed906d9fa42405ef875e2dbe4d324217/freqtrade/optimize/hyperopt_data.py#L528)
- For [Cross Validation](https://github.com/orehunt/freqtrade/blob/canary/freqtrade/optimize/hyperopt_cv.py) we have to split the data, and apply the backtesting over different ranges. Thanks to our efforts in optimization state tracking, we could use the output from cross validation as seed for another more refined optimization process...to overfit...of course.
- Additional optimization logic. To achieve max *churn* we also had to account for some problems:
  - Sometimes a parameter config might simply fail, and the optimizer might get stuck, so we had to keep tracking of failed observations, and eventually restart one, or all the optimizers.
  - Because we were running multiple optimizers, we had to keep track of which optimizer produced which observation.
  - Thanks to our fast backtester, and our parallel optimizer, we were running lots of observations, FQT would print each observation as it completed. We had to batch the observations before printing them, such that we would print a ["tableful"](https://github.com/orehunt/freqtrade/blob/98a7e702ed906d9fa42405ef875e2dbe4d324217/freqtrade/optimize/hyperopt_out.py#L167) of them instead of only one observation at a time, since IO operations are expensive.
  - [Exploration/exploitation](https://github.com/orehunt/freqtrade/blob/98a7e702ed906d9fa42405ef875e2dbe4d324217/freqtrade/optimize/hyperopt_multi.py#L699) balance. Some runs could get stuck into minima, or converge to slowly, so we added the ability to modify the search space **in-flight**. This would help normalize the pace of the search.
  - A better progress bar. Running optimizers on multiple processes required synchronization to update the progress bar from multiple workers. And there was a library just for [that](https://github.com/Rockhopper-Technologies/enlighten), which allowed us to also add [more information](https://github.com/orehunt/freqtrade/blob/98a7e702ed906d9fa42405ef875e2dbe4d324217/freqtrade/optimize/hyperopt_out.py#L355) to the running state of the optimization.
  - Because we were running multiple optimizers, we also added support to give different loss functions to different optimizers, which would allow us to see which loss function performed the best.
- To run the optimizations, we implements a [cli script](https://github.com/orehunt/freqtrade/blob/canary/scripts/ho.py) to run the optimization with different configuration parameters, resume from a previous state, or just show and filter saved trials.
- We were running independent optimizers with different loss functions, then, why not run *different optimizers* on *different loss functions*? Mind blown. So we implemented an [abstraction](https://github.com/orehunt/freqtrade/blob/canary/freqtrade/optimize/optimizer.py) for optimizers such that we could (with a bit of plumbing) magically swap the optimization method. This also required modifying the optimization [interface](https://github.com/orehunt/freqtrade/blob/canary/freqtrade/optimize/hyperopt_interface.py) such that "hyperopt" could understand the optimizer. Then we re-implemented [scikit-optimize](https://github.com/orehunt/freqtrade/blob/canary/freqtrade/optimize/opts/skopt.py) as an instance of our optimizer abstraction. While also plugging in [ax](https://github.com/facebook/Ax), [emukit](https://github.com/EmuKit/emukit) and [sherpa](https://github.com/sherpa-ai/sherpa).

# Conclusions
We cranked FQT backtesting *to 11*. But we never really used it *in production* :). 

Slightly after the *numbification* of the backtester, additional callbacks were added to the strategy that broke the separation between backtesting and strategy evaluation, which meant that to keep the thing fast, you had to also write your strategy in numba! But I got fed up with the shaky mix of python/numpy/numba gotchas and because I didn't like the live execution of FQT, I dropped the whole thing anyway, for greener (or shall I say [pinker!](https://github.com/untoreh/JuBot.jl)) pastures.

Anyway...optimization is crack.
