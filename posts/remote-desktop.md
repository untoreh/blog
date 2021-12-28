+++
date = "12/26/2021"
title = "Methods for accessing a remote desktop from an android tablet."
tags = ["apps", "software", "tech", "tools"]
rss_description = "Streaming qualities, inputs configuration and hotkeys overrides..."
+++

# Goal
have an usable environment on the tablet to program (with emacs).

# The obvious(?) solution
Use the tablet as a thin client for the proper desktop setup.

## Available protocols
- [VNC](https://en.wikipedia.org/wiki/Virtual_Network_Computing) and [RDP](https://en.wikipedia.org/wiki/Remote_Desktop_Protocol) seem quite slow, but should be the most battery friendly, RDP should be strictly better on Windows at least.
- [Splashtop](https://www.splashtop.com/) seems somewhere in the middle, not great latency and low framerate, but good input controls.
- [NOMachine](https://www.nomachine.com/) (NX protocol) seems slightly better than splashtop, is more configurable and flexible than splashtop.
- [Moonlight (client)](https://github.com/moonlight-stream/moonlight-android) and [sunshine (server)](https://github.com/loki-47-6F-64/sunshine) (I have an old AMD R9 290) appears to work ok-ish at 30FPS, whereas at 60FPS it has considerable latency.
- [Parsec](https://parsec.app/). This one seems to have the best latency (at 60FPS) but I have not tested the battery usage, currently it is the one I am using.

# Stand
I use a tablet /w mechanical keyboard because laptops with good mechanical keyboards don't really exist...do they? Or if they exist, they are expensive and the keyboard is _flat_ anyway. 
Keeping the screen at the correct viewing angle requires a stand, or one of those holders with a bendable rod, with magnetic grips or clamps.

# Input controls
I attach a mechanical keyboard to the tablet, with an [OTG converter](https://en.wikipedia.org/wiki/USB_On-The-Go). Bluetooth would be fine too...
The problem is android maps some _quite common_ shortcuts that are used on windows, that use either `META` (`ALT`) or `META` (the windows key). And doesn't provide a way to disable them.
[KeyMapper](https://github.com/sds100/keymapper) partially works, in that it can disable the action from the android side, but I still can't forward the keycombinations.

# Remote or native?
Is using a remote client all the good though? Maybe using emacs directly on android and using emacs remote capabilities is a more compatible setup? 
To install emacs on android you have to use chroots. [UserLand](https://userland.tech/) makes it easy to create chroots of common distributions and directly start an XServer. However having a proper emacs experience requires still a lot of configuration. Would emacs-nox on termux be better then emacs-gtk through userland/VNC? Termux has support for [x11 apps](https://github.com/termux/termux-x11). It uses Xwayland to provide X11 support for apps, it appears to be much faster than xsdl x11 server, because (I guess) it uses shared memory for stream buffering (instead of TCP or unix sockets). There is still no HW acceleration support, my tablet carries a POWERVR GPU anyways which still hasn't any form of open source drivers (but apparently it is schedule to be released somewhere in Q2 2022).
I have also successfully run a [linuxdeploy](https://github.com/meefik/linuxdeploy) configured chroot which doesn't have the overhead of proot on top of the termux-x11 server. However the chroot must match the wayland version (and maybe mesa too) of termux.

# Conclusions
Considering the configuration costs of running emacs on the android tablet, at this point in time a remote session is still more convenient. If the X11 termux efforts plus the eventual release of a powervr driver end up being successfull the balance might shift towards a native setup.

If emacs had support for the android graphics stack It wouldn't be much of a choice anymore, but that's not the case, and there is apparently zero interest in it, (there is also zero interest in a touch interface too, so the best option for using emacs on handheld devices without a proper keyboard at this point would be [emacspeak](http://tvraman.github.io/emacspeak/manual/)). 

[NixOnDroid](https://github.com/t184256/nix-on-droid) could ease the configuration pains for adding all the tooling required by emacs, either that or the upcoming nix support for `arm64`.

There is still the problem of some keyboard shortcuts not passing through, to which common workaround is to map them to other shortcuts, thankfully there is a very powerful [keymapping app for android](https://github.com/sds100/keymapper).
I will have to check on parsec battery consuption, and if it is too high I will consider either plain RDP, or simple a remote ssh session with emacsi in the terminal.
