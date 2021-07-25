+++
date = "6/25/2021"
title = "swiping with thumbs"
tags = ["lightbulbs", "tech"]
rss_description = "An smartphone keyboard interface for swiping with thumbs"
+++

There are different keyboard input methods for smartphones:
- Normal typing
- Thumb typing
- Normal swiping
- Compact (T9) typing

Double input swiping has been explored very little. The only keyboard that I have found to implement a good working solution is [keyboard69].

Why is it so uncommon?
- Implementation is hard. Multiple input means there are async processes filling an input buffer that has to be queried for completion candidates on each new event.
- It requires some learning from the user, this make it unattractive, since the higher the learning curve the lesser the user retention.

[keyboard69]: https://play.google.com/store/apps/details?id=com.jormy.sixtynine&hl=en&gl=US
