+++
date = "5/23/2021"
title = "Make Windows Bearable"
tags = ["software", "tools"]
rss_description = "A list of tools to make Windows feel more like Linux"
+++

Since I [switched to windows 10 with WSL](/posts/OS-Hopping) I figured I'd make a list of software that I had to use to bring windows closer to my usual linux workflow. Let's make it clear that Windows UI sucks, it is stuck in the _90s_ and everything is supposed to be clicked and dragged with your mouse pointer. 
I don't know if it is a _culture_ thing (windows devs must like the mouse very much), or for _target demographic_ ("click at that thing!" is easy to explain), or because of _security best practice_ (if we give too much control to the user, malware will exploit it) or just the _Windows Shell_ being made of a pile of technological debt which makes it harder to add functionality for advanced users. The fact is that simple things in Linux need convoluted solutions in Windows.

## Virtual Desktops
In linux every windows manager has some form of virtual desktop, windows got built virtual desktops fairly recently with W10. The thing is that at the time of writing you can only cycle left and right with hotkeys, and there aren't hotkeys to go to desktop X. There is this [vd library](https://github.com/Grabacr07/VirtualDesktop) but I haven't found software that makes use of it, instead only AHK[^AHK] scripts with poor implementations like "loop until we are at the correct VD". 

The lack of proper shortcuts for windows built-in virtual desktops made me force to use 3rd party software, of which there are many, I chose [dexpot](https://dexpot.de/) as it does all the things I would need and more (I would be happy with just `go to X` and `move window to X` shortcuts). The only problem was that dexpot isn't able to bind already bound keys...somewhat AHK is able to override keys used by other applications, whereas dexpot doesn't, I assume it is because it relies on a different windows API (or [dll]). Workaround is to remap shortcuts the I wanted (e.g. `Win+1`) with a free shortcut that could be set on dexpot (e.g. `Win+Shift+F1`)

## Keyboard mapping
[Powertoys](https://github.com/microsoft/PowerToys) allows to map keys, and shortcuts, such that I can map CapsLock->LeftControl and RightControl->LeftControl. And shortcuts like `Win+hjkl` to arrows. Too bad `Win+l` is a windows default shortcut for locking the screen and can't be remapped...a registry key overrides the shortcuts and fixes this...until you update windows...so you have to apply the fix at each boot!

## Launcher
The apps launcher provided by powertoys is instead quite featureful, doesn't use much more memory than KRunner and is fast and responsive. The only complaint is that from time to time it looses focus, but this is most likely a problem with Windows sick (as in perverted) control of which window is supposed to be focused at any given time.

## Tiling
I switched from sway to KDE on Linux, so I wasn't that much of a tiled windows lover. Powertoys has FancyZones which is a slight improvement over basic windows Snaps that window offers, as it gives you _gaps_ and _layouts_. Yet it is still lacking the most important thing that make tiling useful, that is _rules_ to apply to matching windows, but this would also need support for virtual desktops...and we have already mentioned their current state. In Comparison KWin allows you to match windows with very complex definitions. FancyZones works around the rules issue by preserving windows positions across sessions, but I haven't investigated how well this works with different virtual desktops.

## Dragging windows
Windows can only be dragged from the titlebar, and an additional [utility](https://github.com/RamonUnch/AltDrag) needs to be used to move them with a shortcut combination.

## System monitor
With KDE you have plasma widgets to display system informations, although plasma widgets tend to consume a lot of memory so I didn't use them that much. With Windows there isn't a built-in utility for this, after trying a few utilities I settled on [Traffic Monitor](https://github.com/zhongyang219/TrafficMonitor) which gives network, cpu, memory, and just recently were added GPU and temps. The result is a nice low-profile rectangle displayed within the taskbar:

\fig{/assets/posts/img/trafficmonitor.png}

Bonus point for Windows is that my UPS is recognized and is shown in the tray area, so doesn't need additional configuration, whereas in linux [NUT](https://networkupstools.org/) there are [drivers problems](https://github.com/networkupstools/nut/issues/300).

## System Services
Many didn't like systemd when it came along into the linux kernel..With Windows I instead started missing it..Windows Services [is not really something oriented towards users](https://stackoverflow.com/questions/7629813/is-there-windows-analog-to-supervisord) like systemd. Windows has the **Task Scheduler** to deal with things that look like `one-shot` unit files, but again its interface (or lack thereof) is dreadful. Lucky us we don't really need custom daemons in windows, since most of the windows applications we use are supposed are just _run at startup_ kind of logic, and don't need more advanced configurations. In fact, apart the litter of tools (_sigh_) to make windows work like a modern environment, then only other native windows applications in use are the browser ([firefox](https://www.mozilla.org/en-US/firefox/new/)) since browser GPU acceleration is bad within WSL (well even on native linux...) and the video player ([mpv](https://mpv.io/))..and games of course...

## Packages
I don't like [chocolatey](https://chocolatey.org) as it requires administrator privileges, I always look first for scoop packages as those are installed in the user folder, which is more convenient and more consistent, and simplifies backups.

## WSL/g
I was induced to switch to windows from the recent [WSLg](https://github.com/microsoft/wslg) update. Which required mesa drivers compiled with the `d3d12`backend support for `opengl`. Windows provides a community preview ubuntu layer, but I opted for [arch linux](https://github.com/yuk7/ArchWSL) since there was already an AUR package for [mesa with d3d12](https://aur.archlinux.org/packages/mesa-d3d12/).
Since WSL currently doesn't support systemd, I ended up using [supervisor](https://github.com/Supervisor/supervisor/) to manage a few services. To make sure supervisor is active there is a check in the shell profile for a lock file that should be created on `tmpfs` if supervisor has been previously started.

WSL supports only `ext4` file systems, to use other file systems, you have to mount the partition (or the disk) directly insider the WSL VM. However they have to be mounted manually _as administrator_ from windows. To automate this we can use the task scheduler that allows to bypass UAC prompt by running tasks _with the highest priviledge_. We can run a wsl `--mount` command to mount our desired disks/partitions and then run mount the filesystem from within linux. Because my `/home/` resisde in a mounted `btrfs` filesystem I have to mount it automatically, so we use `/etc/fstab` to map our partition (by `LABEL`) to `/home`. Because we use nix with `nix-env` we need to bind mount our nix store to `/nix` on every wsl startup, and because `/tmp` is not on `tmpfs` we have to create an overlay mount which mounts `tmpfs` over the existing `/tmp` directory, to preserve important files, specifically the X11 files, required to talk to the X server.

These mounts are execute with a script, which should be run _after_ we have mounted the disk inside linux. We need a task that runs after the mount task is completed, and because WSL uses different VMs for different windows users the script must be run NOT with highest priviledges (oterwise it would mount on the Administrator VM).

To ensure WSLg works, we have to make sure the XDG_RUNTIME_DIR is set, since it is different and located (by default) at `/mnt/wlsg/runtime-dir`. This is how windows under wayland look, you can see that since with wayland window decorations can be drawn by either the compositor or the application, they keep the configuration of your GTK/QT theming, so you end up with a native linux theme looking window inside a Windows shell...which is a little bit disorienting at first.

@@wslgemacs
~~~<style> .wslgemacs img { width: 100%; } </style>~~~
\fig{/assets/posts/img/wslgemacs.png    }
@@

## Terminal emulator
On linux I was using [kitty](https://github.com/kovidgoyal/kitty), since it was one of the newer terminal emulators with GPU acceleration [^whygpu] and a somewhat stable daemon mode which allows multiple windows with the same instance. However on windows, I dabbled with a few windows based terminals like Windows Terminal, fluent terminal, wsltty, conemu, but eventually I switched to [wezterm](https://github.com/wez/wezterm). Despite being a more recent terminal it has all the features you would want from a terminal emulator:
- tabs and panes, such that you don't need tmux
- a multiplexing (remote headless mode), such that you don't need tmux
- text copy mode with vi keybindings, such that you don't need tmux
- quick select, an hint mode to quickly select text objects from the scrollback
- default commands for new tabs
- Very good keymaps customization, apart the fact that you can't use Left/Right Shift/Ctrl/Alt as different modifiers.
With Windows I also modified my workflow a bit such that I don't need a terminal with daemon mode that supports multiple separate windows, by using a dropdown terminal. To make wezterm _drop down_ after tried many drop-down AHK scripts, eventually I found [one](https://github.com/lonepie/mintty-quake-console) that worked fairly well. A better alternative however would be [windows-terminal-quake](https://github.com/flyingpie/windows-terminal-quake), but I have had problem with it misbehaving with the virtual desktops managed by dexpot, whereas mitty-quake-console seems to be compatible with dexpot virtual desktops. Most likely when the built-in Windows virtual desktops experience improves, I will switch to windows-terminal-quake.
WezTerm is also cross-platform which means, I can keep using it with a native linux installation. It has been a really fortunate finding for this Windows+WSL switch, since Kitty doesn't yet support Windows, and the other terminal alternatives, had some failry major annoyances that _I couldn't come to terms with_.

[^AHK]: AutoHotKey
[^dll]: https://en.wikipedia.org/wiki/Dynamic-link_library
[^whygpu]: why again do I need gpu acceleration in the terminal?
