+++
date = "5/26/2021"
title = "grapes for winetricks"
tags = ["lightbulbs", "linux"]
rss_description = "A layer based setup for winetricks recipes"
+++

[Wine] is used to run windows programs on linux. The runtime works by re-implementing [dlls](https://en.wikipedia.org/wiki/Dynamic-link_library) to be linux compatible. However software doesn't just need the base libraries, there are dependencies that need to be installed for every piece of software.

Wine supports different windows versions...(all of them?), therefore it is necessary to use different environments to ensure compatibility between software and windows versions.

Some dependencies might also be incompatible with each other, therefore the usage of _wine prefixes_. Using wine prefixes means that usually every application has its own environment, (like containers), which means that _all dependencies_ have to be reinstalled _for every new program_. You don't have too, different programs can share the same environment, but as stated, problems difficult to debug might arise.

Winetricks automates the installation of dependencies (like .NET and DirectX packages), yet, even if scripted, setups can still take quite some time.

* Proposal
[Ostree] is used to checkout _versions_ of _operative systems_. And even though its main use case is to enable atomic upgrades for OSes installed on bare-metal, it could be used to build _wine prefixes_ with preinstalled collections of dependencies, like flatpak uses the same method to share runtimes between different applications, effectively there could be different flatpak _wine runtimes_ for families of software that share the bulk of the dependencies; the only question left is if there are any license problems distributing such kind of runtimes with what would effectively be _preinstalled windows software_. :S


[Wine]: https://www.winehq.org/
[Ostree]: https://github.com/ostreedev/ostree
