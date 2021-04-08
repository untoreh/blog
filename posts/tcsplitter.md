+++
date = "4/2/2021"
title = "TCSplitter"
tags = ["net", "about"]
rss_description = "A tunnel to split TCP or UDP connection across multiple TCP connections"
+++

## Goal

When would you want to split one TCP connection into multiple ones? Usually you use a [tunnel] to achieve _the exact opposite_. My use case was circumventing bandwidth limitations in a mobile network, so tests were performed with a sim card with no more data left on its plan [^redirects].

## How does it work

The [tunnel](https://github.com/untoreh/tcsplitter) was written in [golang] since it is fast enough, and commonly used for network tooling. The cli is barely usable since most of the options were reworked as I tested different methods.

Initially there were "flings" and "lassos", to split the number of connections for outgoing (flinged) and incoming (lassoed), but this was a needless abstraction since it is better to tag packets with their destination, although the main intention was to offer different rate limits for outgoing and incoming connections, so an higher level separation between up/down seemed practical.

The client has to instantiate all the connections since we assume that the server cannot open outgoing connections. When the clients receive a connection from a user application, it sets up the required pool of connections with the server, and whatever data it receives, it splits it among the dedicated connections, according to a user defined limit.

The packets are then sent to the server, which has to reconstruct them into the correct order, because different TCP connections can finish the data stream at any time (sent order is not respected, _because routing_), and then forwarded to the receiving app.

Connections are closed and new ones opened as the configured data limit per connection is reached, akin to how [shadowsocks] proxies tunnel data across different stream with the goal of masking the behavior of data streams, except that our tunnel is doing that as frequently as possible.

## Why does it work

The intention here is to control how much data every connection should handle. For our purposes, it was never beyond was usually is the [MTU] window size. You can think of the MTU as the upper bound of a piece of data that passes whole across the network, and it was our target because we wanted to bypass the bandwidth rate limits of a gated network. To limit how much data a client can pass through, you need to _count_ it, right? If your logic works with something like a `do-while`

- receive `packet`
  - if `received_packets` + `packet` > `user_limit`
    - drop connection
  - else
    - keep streaming

Then you need to _at least_ receive a `packet`. I am not sure if this is what actually happens, or the reason my tunnel works is another one. Maybe it is totally possible to check even the first packet, but from a design perspective, that would mean you would have to check _every_ single connection, which would make the system weaker to DOS attacks, and yes my tunnel could be easily used as an efficient DOS/Stress tool, since you can split the data to very small packets (which means TCP connections will have a high recycle pressure) and have a pool of connections as large as you like.

Testing over different ports also showed that it was possible only over _some_ ports, and that the limit was constantly different between ports, with `443` giving one of the higher windows, around `20kb`, guessing because `TLS` handshakes require more data, and that these rate-limits would change based on time of day [^nighttime].

## Results

I tried erasure coding in the hopes of increasing data throughput. By using a erasure coding library and enc/decoding the data itself, and also by overlaying the [KCP] protocol over my splitting protocol. Trying out KCP might seem a backwards approach, since it trades better latency for lower throughput, but my initial assumption was that my bottleneck was in connections dropped mid-transmission, which would cause a lot of corrupted packets, so I could have achieved an higher throughput with error correction.

It turned out it was just a rate-limit over how many TCP connections a client can send over the network, so just a DOS protection that I can't do anything about. After X amounts of connections any `SYN` attempts stop receiving their due `ACK`, filling the backlog and eventually making the tunnel stall. Trial and error showed that it was possible between `4-8`[^clientlimits] connections open at any given time, and with a MTU of `500-1000` bytes you could keep a steady stream around at least `128kbps`, if a constant stream wasn't a requirement, you could achieve higher speeds over a shorter time period by _bursting_ many connections on demand.

In contrast, a (true) `DNS` tunnel can barely push `56kbps` and can quickly get throttled because I think a high number of DNS requests looks more suspicious then TCP requests. We have to specify that a _true_ DNS tunnel encodes (outgoing) data over bogus subdomains and decodes (incoming) data received by querying DNS records, whereas sometimes a DNS tunnel can be thought to be a raw UDP connection over the DNS port, which probably sometime in the past, DNS servers allowed and forwarded correctly.

## Conclusions

I am not sure I reached my goal _utility_ wise, since running such kind of tunnel can make you phone quite hot, and waste a lot of battery, but having it as a backup connection can be reassuring...if I actually bothered to make it stable enough :)

<!-- prettier-ignore-start-->
[^redirects]: usually when a sim card has no more data to browse the web, web requests redirect to the capture gateway (to tell you to buy more data)
[^nighttime]: mobile data plans can provide a better connection during night hours
[^clientlimits]: This number, somewhat aligned to common core counts, might induce you to suspect that the kernel is limiting connections somehow, the scenario of opened connections of our tunnel is definitely unusual, but tuning linux knobs never gave better results on my end.
[tunnel]: https://en.wikipedia.org/wiki/Tunneling_protocol
[golang]: https://en.wikipedia.org/wiki/Go_(programming_language)
[MTU]: https://en.wikipedia.org/wiki/Maximum_transmission_unit
[KCP]: https://github.com/skywind3000/kcp
[shadowsocks]: https://shadowsocks.org/en/index.html
<!-- prettier-ignore-end-->
