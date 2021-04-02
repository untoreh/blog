+++
date = "4/2/2021"
title = "Minor tools"
tags = ["tools"]
rss_description = "Collection of small utilities done to scratch some itches..."
+++

## action5

[Action5] is a bare-bone tool to spot modified files through checksums in a directory.
There are a gazillion tools that do this, so I am not sure (remember) why I wrote it.

- recurse over a folder, dump a tree of checksums (the index)..
- ..repeat to see what changed

A key point of this tools is that it is just shell commands, so you can plug in any check-summing command that you prefer, by default it uses `md5`.

[action5]: https://github.com/untoreh/action5

## bash-utils

The purpose of [bashutils] is to mostly rely on bash to do some operations on processes.

- Reading a file inside a variable (`gobbler`), requires making sure that the file does not contain nulls, so it must be stored with an null free encoding format. Note: carefree usage of quotes in bash, (in places where not required) can cause a lot of memory to be wasted.
- Monitoring cpu in a linux system, requires to read `/proc`, pause without forking, and calculate statistics with just shell operations (`$(())`)
- Limiting a process requires continuously sending `SIGSTOP` and `SIGSTOP` signals, this is very slow in bash :) since it is a loop, and software might behave unexpectedly when constantly paused and resumed, since programmers don't usually expect their software to work intermittently!

[bashutils]: https://github.com/untoreh/bashutils

## dist-haproxy

A [build script] for [haproxy], the best tool to forward connections, it is lightweight, and having a statically linked version is very useful.

[haproxy]: http://www.haproxy.org/
[build script]: https://github.com/untoreh/dist-haproxy
