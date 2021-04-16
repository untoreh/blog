+++
date = "4/9/21"
title = "On Containers"
tags = ["opinions", "about"]
rss_description = "Using containers, what and why"
+++

## What are containers

[Containers] is a name given to restricted environments, made possible by a collection of subsystems within linux like [`cgroups`] and [`namespaces`]. Although the wiki page uses the word _virtualization_ I think the word _isolation_ is more appropriate, since virtualization means that there is a layer of translation in-between, while what cgroups and namespaces do is to separate, and contextualize processes.

Cgroups are used to define allocation policies for resources, usually `RAM` and `CPU`, while namespaces control the contexts like mount-points, networking and users. [Apparmor] instead provides a way to restrict capabilities for containers environments as a whole, whereas apparmor without containers is, as written in wikipedia, program-based.

Tools like [flatpak] and [firejail] use containers, to constrain the access surface of user applications.
[Windows] containers implements equivalent systems, and also offer support for linux containers through [WSL].

## But why?

- Sometimes for security, however in that case, full virtualization gives better assurances.
- To achieve reproducibility of execution, and portability, such that applications relying on particular environments configurations can run without troubling the user for additional setup steps.
- Scheduling, orchestration software like kubernetes uses [container runtimes] to move services across hosts seamlessly and to abstract execution logic.

## Too much?

When I started building [pine], I experimented a bit with shipping my own container images, distributed from github releases. The main script (`trees`) commands were

```sh
Usage: trees APP [FLAGS]...
'APP'               Install apps through ostree deltas checkouts.
    -b, --base      base image (alp,trub...)
    -n, --name      same as APP (etcd,hhvm...)
    -f, --force     clear before install
    -d, --delete    clear checkout and prune ostree repo
ck, check           make sure the apps repo is mounted
co, checkout        builds the trees of links for the specified APP
    -t 	            optional path where to build the tree
```

It was similar to flatpak, as I was shipping an ostree static delta based on the main pine image, and [checking out] the new app based rootfs, and then launching a container instance on top of it. OpenVZ had lots of issues before v7 for running container (since you know...you were running a _nested_ container on a container-based [VPS], and the kernel was a fork of `v2.6` (!))...it was a **huge** waste of time.

## When?

My attempt was to get a minimal container runtime without requiring `docker` or more beefier software, as docker is probably the most lightweight, and [docker swarm], being built-in shares a lot of functionality and provides you the most useful features for orchestration, which makes it the most lean on host system requirements compared to [k8s] or [nomad].

Despite containers being a feature you might want most of the times, orchestration isn't. I think _loosely targeted_ advertising campaigns attract the _un-intended_ target audience for such software, making one believe that it can be useful _to them_, without emphasizing the premise that you **really** need to scale a lot(!) to justify the complexity cost of such setups. The number of [convenience tooling] built around k8s to aid the bootstrapping process of a k8s cluster should be enough evidence...

## Conclusions

Orchestrations tools end up crowding the place for solutions to manage multi host machines when users can't tell the difference between pet and cattle servers. On many occasions, software like ansible, pyinfra or even [cssh] or [assh] is all one ever needs.

<!-- prettier-start-ignore -->

[assh]: https://github.com/moul/assh
[cssh]: https://github.com/duncs/clusterssh
[convenience tooling]: https://reddit.com/r/kubernetes/comments/be0415/k3s_minikube_or_microk8s/el2xy5r/
[docker swarm]: https://docs.docker.com/engine/swarm/
[k8s]: https://docs.kublr.com/installation/hardware-recommendation/
[nomad]: https://www.nomadproject.io/docs/install/production/requirements
[vps]: https://en.wikipedia.org/wiki/Virtual_private_server
[ostree-checkout]: https://manpages.debian.org/testing/ostree/ostree-checkout.1.en.html
[pine]: /posts/alpine/
[kubernetes]: https://kubernetes.io/docs/setup/production-environment/container-runtimes/
[wsl]: https://docs.microsoft.com/en-us/windows/wsl/about
[windows]: https://docs.microsoft.com/en-us/virtualization/windowscontainers/about/
[firejail]: https://github.com/netblue30/firejail
[flatpak]: https://en.wikipedia.org/wiki/Flatpak
[containers]: https://en.wikipedia.org/wiki/List_of_Linux_containers
[cgroups]: https://en.wikipedia.org/wiki/Cgroups
[namespaces]: https://en.wikipedia.org/wiki/Linux_namespaces

<!-- prettier-end-ignore -->
