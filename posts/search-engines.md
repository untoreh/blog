+++
date = "10/25/2021"
title = "Search engines"
tags = ["programming", "opinions"]
rss_description = "AMP pages, turbo pages, indexing...the good, the bad..."
+++

# Gotta go fast!

For a while google has been pushing for AMP pages. Because data says that _page load times_ affect user experience...obviously. It has gone through some [rough patches] but the [open source project] keeps going. 
But at time of writing is still experimental.

# Do Not Repeat Yourself
AMP basically redefines a bunch of HTML tags, and restricts what attributes you can use. Now imagine, you have a webpage, and you want to offer an AMP version. This is not something that can be done **programmatically**, so you would have to go through all the pages, find out what the AMP specs support and adjust the page accordingly...too much hassle, this is if you want to provide a consistent experience between the default page and the AMP page.

I decided not to. So I just treat AMP pages as text plus CSS. Everything else I strip away. This is surely not what the AMP devs had in mind with the goal of improving user experience...But at least I can generate them automatically.

Ideally you would want to publish your website/s with AMP in mind from the start, such that you keep things consistent. But if you are writing for AMP, your are **only** writing for AMP, which is not nice as it feels like a walled garden. Having to deal with HTML and *ampHTML* is a lot of churn to maintain. Some AMP *web components* have made it back to the [W3] standards. But most of it is still *experimental* and who knows if AMP will become a standard or just a google thing. On the good note [baidu] seems to support it (along with its [MIP] pages...although they don't look well maintained...). 

All these files are _cached_ on the search engine's servers. This also doesn't look alright to me. The AMP open source project should at least offer a _self host-able_ server for the web pages, even if just for development purposes.

# Yandex
[Yandex] also has its own spin...turbo pages, which are even stricter, since you can't include custom CSS in the page, but you have to set it from the Yandex webmasters dashboard. Also turbo pages aren't actually pages. You provide an RSS feed, or a huge YAML file with all the pages you want to offer in their _turbo_ form. And Yandex slurps it and serves it on their search pages...so much for a crawlable web...

# What's the goal?
Fast pages that look good? ADS that load fast? Tracking at the source? The pattern to me looks like vertical integration of all the components that go from the user, the search page, and the content, right into the search engine. The direction is to build more and more around highly optimized walled gardens (_shivers_). 

Hopefully I am wrong. I would like to see amp dissolve into what would be HTML6 or something like that, I am surely not adopting experimental components. Most of the website is browsed from mobile. Making a distinction between "desktop" and "mobile" in term of speed can be detrimental if today people upgrade their phones faster than their desktops and laptops, such that their phone can end up being their fastest device. Pages should be designed for usability all the time, the "responsive" approach, which can burden website development quite a lot, is still a better trade-off then chaotic multi versioned web pages.

# There is also gemini
If you want lightweight web pages, the [gemini] protocol can serve those, will major browsers support it? Probably not...since it can't serve ads..

[gemini]: https://gemini.circumlunar.space/
[Yandex]: https://yandex.com
[MIP]: https://github.com/mipengine/mip2
[baidu]: http://www.baidu.com/
[W3]: https://www.w3.org/standards/
[rough patches]: https://web.archive.org/web/20210711194256/https://www.theregister.com/2020/12/19/google_amp_resignation/
[open source project]: https://github.com/ampproject/amphtml
