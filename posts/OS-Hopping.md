+++
date = "5/19/2021"
title = "OS Hopping"
tags = ["software"]
rss_description = "A brief summary of operative systems that I have used"
+++

@@hops
~~~ <style> .hops img{float: right; display: block;} </style> ~~~
\fig{/assets/scripts/os-hops}
@@

When I got my first personal computer it came with Windows XP (age 13y). After a few mess ups had to learn how to reinstall windows...It wasn't as plug and play as today...
My first experience with linux was with PCLinuxOS which is apparently [still going](https://www.pclinuxos.com/) as it offered a full graphical installation. After that I went straight into [Arch Linux](https://archlinux.org/). I played with Arch Linux for a while (like making the gnome UI look like MacOS or Windows Vista through [gnome look mods](https://www.gnome-look.org/)), then went back to Windows because games..
From Windows I managed some personal linux servers for a while running centos/debian. After some years went back to Linux, first I tried [Alpine](https://alpinelinux.org), but its repositories weren't (yet?) satisfactory for a desktop experience (pulseaudio was still in the _testing_ repo).

Then I tried [Void Linux](https://voidlinux.org/) for a while, but I was using the [musl](https://musl.libc.org/) based version which didn't have good support packages wise, so I was running void linux plus apps in containers on a [i3wm](https://i3wm.org/) based environment. But containerized graphical applications weren't yet widespread, solutions like flatpak snapd or firejail weren't yet widespread or even stable, so I switched to Ubuntu, and setup a ZFS RAID-Z (_living dangerously_) root installation. As desktop environments I still kept i3wm, then went to [swaywm](https://swaywm.org/) cause wayland, and then KDE plasma because I couldn't bother anymore with the litter of systemd unit files that have to be _user_ managed just to get the minimal working expected setup with any of the tiling WMs.

KDE is great, and I consider it the bleeding edge of desktop environments, however it is also big, and with a lot of apps lacking good maintenance, so my advice is to not try too hard to stick to a K\* only GUI environment and just use what works, KDE has good support for GTK styling. KWin has very good customization options and you can bind hotkeys to make it behave very close to a _float-first_ tiling WM. If you want a _tile-first_ tiling WM then there are a couple of extensions, which however don't work quite well on wayland (at time of writing).

Lately I have switched back to Windows (10).._again_, not primarily _because games_ as I yet have to find time and motivation to play again, but somewhat out of curiosity for a [WSL](https://docs.microsoft.com/en-us/windows/wsl/install-win10) based linux environment coupled with good integration for graphical apps ([WSLg](https://github.com/microsoft/wslg)). At time of writing, sadly Windows 10 experience is a de-facto downgrade from linux KDE. Windows with its _mouse centric_ UX doesn't appear to have anything oriented towards deep keyboard shortcuts customization. It is unclear if by _Windows culture_ shortcuts are frowned up, as seen as a security hole or it is just a severe limitation of the windows shell, that forces customizations through registry overrides. [Powertoys](https://github.com/microsoft/PowerToys/) still has a long way to go to satisfy all the needs of a person looking to fit their environment to their habits (not sure I can be considered a power user..). Nonetheless I can be quite flexible and with a couple of third party programs the environment has become somewhat acceptable.
