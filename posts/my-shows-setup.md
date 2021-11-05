+++
date = "10/27/2021"
title = "My Shows Setup"
tags = ["software", "opinions", "media"]
rss_description = "Mostly how I deal with animes and tv shows.."
+++

# What I did in the beginning
I used to just browse [trakt], and manage a list of _watching_ shows, and _dropped_ TV shows for what I didn't like. Then I chose what to watch on a daily basis and either streamed it or preemptively downloaded it (since the internet connection was slow I had to do it in the morning, like a routine :P).

# What I switched to after a while
I used [kodi] with a bunch of plugins, but it was always a bug fest, inconsistencies, constant plugins upgrades, high memory usage, unsolvable issues that were caused by the releases iterations and the fact that plugins targeted different kodi versions...Kodi is a huge beast and you have to learn how to deal with it..and I couldn't be bothered..it is probably the best choice for TV, but subpar if your environment is a standard desktop.
After kodi, I decided to try the _microservices_ approach to automate the routine. I started using quite a lot of services...
- [Sonarr] for searching releases
- [Flexget] for updating trakt lists
- [qbt] or [deluge] for downloads
- [bazaar] for subtitles
- [jackett] for sources aggregation
- Something for watching.
I never settled on a good app for watching episodes, so I just watched with [mpv], scrobbling to trakt using at first [https://github.com/StareInTheAir/mpv-trakt-sync-daemon] and then switched to [https://github.com/iamkroot/trakt-scrobbler] which was more stable.

The setup was running inside a docker container, in a monolithic fashion. I wasn't adopting docker compose to run everything containerized, like [this]; where the advantage is that you can updated apps separately...the disadvantage is everything else. The whole thing is meant to be run locally anyway so the benefit of namespace separation is pointless because there aren't scaling problems (it takes at worst 2GB of RAM). In fact I was running it on my everyday PC without noticing any slowdowns. Although afterwards I switched to a _mule_ server such that I could have more freedom and less hassles in rebooting my pc when I needed to.

# What I ended up with
But It was too many processes and things would break too often. So I decided to reduce the bugs surface :) . The  config is:
- [medusa]: handles releases, subtitles
- [transmission]: executes downloads
- [jackett]
- [jellyfin] and [jellyfin-media-player]: as the interface media access.
There is still an additional _cleanup_ jobs because jellyfin doesn't have yet a functionality to remove watched media so I will have to use another [script]. That's still too many services! ouch. Fortunately jellyfin and transmission can be considered pretty stable software. The only one that breaks more often is medusa, while jackett hasn't given any issues as of lately.

# Can this be simplified even further?
Of course. I would prefer to claim defeat in using a gui for releases handling and just stick things together myself. I acknowledge that I still need the _downloader_ (transmission) and the _player_ (jellyfin), but I could drift away from using medusa, or maybe just the interface. I could use the medusa python modules as a framework to build my own (ultra-simplified) logic that fits my needs. Flexget is also a choice in this regard.

# Do I still manage trakt lists?
Nope I switched to simkl. It is superior to trakt in every way.
- It is faster in loading pretty much everything
- The UI is cleaner and with a lot of thought behind it. It is hard to pin point exactly what is better but the features that I need are always easy to find out compared to trakt.
- Bucketing shows is straightforward compared to trakt that has "collections", "watchlist" and "watched" as default lists. With trakt I had to manage a "dropped" list for shows I didn't like, whereas with simkl I just set them as "not interesting", which automatically removes them from the "airing next" calendar. Also, scrobbling automatically considers a show as "watching", such that a "watchlist" is not needed.
- Fast-forwarding watched status is easy, again thanks to the UI and the import features that allow migrating from other services or from CSV or JSON lists.
- Discovery of new shows is also simpler. Before I either had to go through the trakt calendar to find out new shows look up the IMDB database by date. Simkl differentiates between premieres of returning shows, and premieres of new shows automatically.
There still isn't a good self-hosted solution for tracking tv-shows, [flox] lacks many things I use simkl for. Shows discovery is not something that I can just script around, as I still need a solid interface to help me make my choices, so looks like I will use simkl for the time being. 

# Anime, TV Shows, or Movies?
Most of this setup is useful for tv shows and animes. I don't really watch many movies, apart from some popular ones from which I don't expect much except some nice CGI. I find movies either too fast or too empty in their content, sometimes they try to tell you something but do so all at once and it ends up either over the top, or missing the mark. 

TV shows instead are more slow paced, and things do sediment better, however I would be lying if I said I didn't binge watch some shows, and binge watching a TV shows feels like watching a _very_ long movie. Yet the expanded format with hard breaks between episodes gives pace in its own right, even if you watch all at once. When making shows channels know before hand how many hours they got, (which is usually at least 10), so they have more wiggle room to adapt screen play to the story. With movies everything is scruffily cramped between 1h30m and 2h, and very rarely to 3h. Proper cutting of scenes with a limited time budgets most of the times ends up with a chaotic series of events that it is hard to keep track of, because there isn't enough _weight_ behind them.

And yet...TV shows nowadays are frequently filled with a political agenda, which makes them __much less enjoyable__. The way TV shows (and movies) are produced requires an audience, a target demographic. And if the shows doesn't define one then it is not even considered. 

Here comes animes. To me animes have not yet lost the artistic vein, either because most of them are manga adaptations, or because there isn't an assumption on what demographic to target. Maybe the reduced costs of making an anime compared to TV shows allows for _fast iteration_ on different ideas. Whatever the reason, I find myself watching animes, and animated shows more and more over TV shows, because the latter keep failing my expectations, over and over.

PS: The wording here is a bit messy. You can have animated shows in TV shows form and Movies too, but most of the time I intend as anime, animated series with a ~20m episode duration, whereas TV shows have a ~40m duration (at least dramas, whereas comedies are often in the 20m form).

[flox]: https://github.com/devfake/flox
[simkl]: https://simkl.com/
[jackett]: https://github.com/Jackett/Jackett
[kodi]: https://kodi.tv/
[script]: https://github.com/clara-j/media_cleaner
[jellyfin-media-player]: https://github.com/jellyfin/jellyfin-media-player
[jellyfin]: https://jellyfin.org/
[transmission]: https://transmissionbt.com/
[medusa]: https://github.com/pymedusa/Medusa
[this]: https://github.com/cristianmiranda/mediabox
[mpv]: https://mpv.io/
[Flexget]: https://flexget.com/
[bazaar]: https://github.com/morpheus65535/bazarr
[deluge]: https://github.com/deluge-torrent/deluge
[qbt]: https://github.com/qbittorrent/qBittorrent
[trakt]: https://trakt.tv/
