+++
date = "4/2/2021"
title = "Paroodise"
tags = ["tools", "hosting"]
rss_description = "A small utility for live modification of file systems"
+++

When I was first settling on what linux distribution use for my remote servers I needed a way to quickly install different root file systems on a target host, so I wrote [paroodise].

To be able to flash a booted block device you need to _unmount_. You can only unmount if you stop using it. To stop using it you need to restart your services in place, from another root file system. This is akin to what the [initramfs] does when it boots a linux based OS, the kernel executes a boot image which setups the file system from where the true [init] service is launched.

To achieve this on an _already running_ system we have to be careful how we restart our processes. We can't kill ssh unless we are sure our script will run until successful.

The whole process is much easier on non systemd based distros, since systemd hooks deeply into the linux kernel, mangling with its processes recklessly can cause kernel panics...in fact on more recent distributions that's what usually happens :)

When I wrote this mini utility it seems I didn't know stable ways to spawn processes that outlived the original ssh sessions, It should be rewritten with more consistent methods.

The whole process consists of

- copying the minimal files required to re-bootstrap the file system on memory
- moving (or recreating) the kernel mount points (`/dev`, `/proc`, `/sys`)
- killing previous services spawned by the standing systemd process tree
- re-executing systemd unto the new pivoted file-system, [`systemctl daemon-reexec`][reexec]

If everything completes successfully it is possible at this point to spawn a new ssh service and login into a session where the original mount points are available for modifications.

[initramfs]: https://en.wikipedia.org/wiki/Initial_ramdisk
[init]: https://en.wikipedia.org/wiki/Init
[reexec]: https://www.freedesktop.org/software/systemd/man/systemctl.html#Manager%20State%20Commands
[parooside]: https://github.com/untoreh/paroodise
