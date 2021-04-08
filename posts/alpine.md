+++
date = "4/5/21"
title = "Alpine"
tags = ["tools"]
rss_description = "Pine, Alpine linux based on OSTree"
+++

Choosing what [OS] runs on your servers is a matter of convenience and familiarity. Convenience means you want something that gives you as less troubles as possible, familiarity means that you would prefer _not_ to learn additional things if you don't have to.

My servers are [pets] so I am ok manually issuing a few commands every once in a while, and don't require complete automation.

After trying out [CoreOS] for a year I switched to my own simplified [distro] based on alpine and [ostree].

## Goals

This version of alpine takes cues from [flatcar] and [project-atomic] and is supposed to be installed as a read-only root file-system with updates happening atomically, that is, either they succeed or the system swaps back to the previous state. For this to be possible to system has to always have at least **two snapshots** of the released file-system version, available on storage.

## Targets

In what environments will the system run? I targeted [OVZ] and [KVM], but in general you can say _containers_ and _virtual machines_ with the main difference being that containers don't run their own kernel, in particular they don't have a boot process, they call directly into the _init_ system (which for example in a `[Dockerfile]` it would be defined by the `CMD` or `ENTRYPOINT` statements), which is responsible to manage the tree of prcesses that will keep the container running (just like a normal session, if the init process dies, the container terminates). Also containers can't configure system knobs, and can have additional restrictions on capabilities.

## Bisecting the build process

How is the image built?

### Dependencies

The `prepare.sh` script handles dependencies, most of which are the packages to offer common cli tools like `coreutils`, `util-linux`, `binutils`, utilities to operate with block devices like `blkid`, `sfdisk`, `multipath-tools` and file systems with `xfsprogs` and `e2fsprogs`. The `squashfs-tools` package is used at the end to compress the built root file system. A `glib` compatibility package is also installed by default because alpine is based on `[musl]`, the compatibility package works by providing some libraries built against .

### The tree

File trees for both VMs and containers are build with respectively `make.sh` and `make_ovz.sh`. This is a simplified description of the steps

- set the version to be built according to repository tag
- create a directory for the new tree and clear the environment
- create base target directories and directories required by ostree, like `sysroot`
- create symlinks to conform with the [filesystem hierarchy standard]
- copy custom services and custom configs
- setup chroot with mounted system directories
- bootstrap an alpine rootfs with base packages
- apply minimal configuration to the rootfs like credentials, timezone, hostname.
- copy services to be started by init
- setup the boot configuration with the specified kernel image
- optionally add custom kernel modules
- perform cleanups
- commit the rootfs [^rootfs] to the ostree repository

For containers, the sequence is the same, but configuration changes, because with a system not booted from a [bootloader] ostree has troubles verifying the environment, we have to apply some [workarounds](https://github.com/untoreh/pine/blob/e65f12be70fd91edfd935e3ae9854c7be555ec73/make_ovz.sh#L73) and setup some devices which are usually handled by the [initramfs] step. This is how [OVZ] or [LXC] templates are configured.

### Packaging

Once we have our ostree committed files tree `build.sh` or `build-update.sh` takes care of producing the artifact that will be distributed. The difference between the scripts is that the update version starts from a previous ostree repository, and _also_ produces a delta artifact that a running system can apply on its ostree instance to perform upgrades. This is a simplified description of the build steps

- if new build
  - create new partitions on a new image mounted as a loop device
- else
  - mount sysroot and boot partitions of previous build
- clean up previous ostree deployments (link farms) on mounted build
- commit new built tree on mounted build
- verify integrity and checksums
- create new delta for upgrades
- execute ostree deployment to regenerate boot configuration
- remove old ostree commits
- verify boot partition integrity
- unmount new updated build image
- generate image checksum and compress it (with `squashfs` for containers)

The partitions configuration is applied with a fdisk `layout.cfg` file which defines the partition sizes, we have one partition for the rootfs (`~430M`), the boot partition (`~40M`) and a swap partition (`~40M`). With containers with just skip mounting the previous build over a loop device, and just pull the new ostree commit over the old (extracted) ostree repository.

## Customizations

What am I bundling in this image (apart from installed packages)?

- A small lib in `functions.sh` for common tasks executed within the shell
- ostree based upgrade scripts with locking mechanism based on KV store
- monitoring scripts for IO both local (`iomon`) and network (`tcpmon`)
- setup scripts for container runtimes other than `bubblewrap`: `podman`, `toolbox`

What used to be and isn't anymore

- `sup`: [Sup] was used for orchestration (deploy containers) and configuration of the host machine, but then I switched to [ansible] because there were long standing bugs in sup that were lacking a fix, I did not choose ansible from the start because I didn't want a python dependency to install on every server, eventually I settled with a secondary alpine [chroot] on the host machines, located in `/opt/alp` were I install additional less critical software. Today, however, I would again switch from ansible to [pyinfra], because
  - it is python without boilerplate (ansible has pseudo `DSL` that causes more headaches than the ones it solves)
  - it executes its recipes with plain ssh commands, so there isn't a python dependency requirement on target hosts
- `containerpilot`: The use case for container pilot is to manage complex dependencies between containers without shell scripts...it stopped getting updates from [joyent] and was put in maintenance mode, I also didn't like the memory requirements and memory usage would happen to constantly increase for long period of uptime. I switched it for simple shell scripts with [consul], I might look into more proper alternatives if shell scripts start to grow too much. Heavier solutions like [kubernetes], [swarm] or [nomad] were discarded from the get-go.
- `beegfs`: I used to ship the kernel module necessary for [beegfs] but after a while it broke compatibility, and the fact that there wasn't a properly supported [fuse] module made be drop it altogether, I am currently not running a [DFS] on my servers, but the possibility of having a ready to go file-system to plug in a network is still appealing.
- [`trees`]: I played for a while with managing what was basically my own implementation of a [flatpak] like container registry (based on github releases) where I would distribute the ostree images of containers to be run directly with [runc]. I didn't want Docker itself as a dependency because it is hard to run docker itself within a container, so I couldn't seamlessly support both KVM and OVZ (OVZ has support for docker since `7.0`). Today I use [bubblewrap], or if I want better support for [OCI] images there is [podman] which is daemon-less.

## Installation

To install the image you can either upload it to the hosting provider and install from VNC, in case of virtual machines, but I usually hijack an existing installation, because it is always possible, well as long I have tested the setup script against version of the linux distribution, generally I use debian-8 or ubuntu-14, haven't tested other ones since these I have always found these to be available. The setup steps follows

- ensure https support for downloads
- download a busybox version
- install a busybox link-farm
- determine ipv4/ipv6 addresses for network config
- ensure chroot capabilities
- download the pine image and extract it
- if VM
  - flash over target device
  - mount over a loop device
- write the local network configuration over the _to be flashed_ rootfs
- if container
  - copy the init service (for containers) over the main root mount point `/sbin/init`
- if VM
  - partition the left over disk with standard (`xfs`) partitions
  - unmount
  - verify partitions integrity
- reboot

## Conclusions

I made [pine] 5 years from time of writing and I am still using it, and I see no reasons to switch to anything else. Alpine as a linux distro is great, simple, and I have never experienced breakage. I can easily deploy on [NATed] servers which tend to offer ultra-low resources, actually I have a box running with just `64M` of RAM, and still have all the features I need.

<!-- prettier-ignore-start -->
[NATed]: https://en.wikipedia.org/wiki/Network_address_translation
[pine]: https://github.com/untoreh/pine
[consul]: https://www.consul.io/ 
[nomad]: https://www.nomadproject.io/
[swarm]: https://docs.docker.com/engine/swarm/ 
[kubernetes]: https://kubernetes.io/
[trees]: https://github.com/untoreh/pine/blob/master/trees.sh
[flatpak]: https://en.wikipedia.org/wiki/Flatpak
[OCI]: https://github.com/opencontainers/image-spec/blob/master/spec.md
[podman]: https://github.com/containers/podman
[bubblewrap]: https://github.com/containers/bubblewrap/
[runc]: https://github.com/opencontainers/runc
[fuse]: https://en.wikipedia.org/wiki/Filesystem_in_Userspace
[beegfs]: https://en.wikipedia.org/wiki/BeeGFS
[joyent]: https://github.com/joyent/containerpilot
[DSL]: https://en.wikipedia.org/wiki/Domain-specific_language
[pyinfra]: https://github.com/Fizzadar/pyinfra
[chroot]: https://en.wikipedia.org/wiki/Chroot
[ansible]: https://www.ansible.com/
[Sup]: https://github.com/pressly/sup/
[OS]: https://en.wikipedia.org/wiki/Operating_system
[pets]: https://devops.stackexchange.com/questions/653/what-is-the-definition-of-cattle-not-pets
[CoreOS]: https://en.wikipedia.org/wiki/Container_Linux
[distro]: https://en.wikipedia.org/wiki/Linux_distribution
[flatcar]: https://kinvolk.io/flatcar-container-linux/
[project-atomic]: https://www.projectatomic.io/
[Dockerfile]: https://en.wikipedia.org/wiki/Docker_(software)
[musl]: https://musl.libc.org/
[filesystem hierarchy standard]: https://www.freedesktop.org/software/systemd/man/file-hierarchy.html
[^rootfs]: root file system
[bootloader]: https://en.wikipedia.org/wiki/Bootloader
[initramfs]: https://en.wikipedia.org/wiki/Initial_ramdisk
[OVZ]: https://en.wikipedia.org/wiki/OpenVZ
[LXC]: https://en.wikipedia.org/wiki/LXC
[ostree]: https://en.wikipedia.org/wiki/OSTree
<!-- prettier-ignore-end -->
