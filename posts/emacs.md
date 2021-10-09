+++
date = "10/6/2021"
title = "Emacs"
tags = ["programming"]
rss_description = "Why emacs, and my personal emacs wishlist."
+++

# What is emacs? 
A [virtual machine] or interpreter for the [emacs] lisp programming language...kind of. The emacs lisp programming language (elisp) is general purpose, but has first class support for the actual text editor that runs it. The primitive types are focused around text editing, nonetheless you can write anything you want with pretty [decent performance](https://akrl.sdf.org/gccemacs.html) (recently thanks to the [jit compilation]) because it is a lisp descendant of [MACLISP] and a sibling of [common lisp]. However emacs lisp doesn't have a standard, and the specification is equivalent to the most popular implementation, that is GNU Emacs.

# Why emacs?
With the phrase "Emacs is a operative system" people mean that you can use it to do anything you would use a computer for. It falls short of being a literal operative system since the kernel, (usually linux) is still in charge of the hardware. [^kernelmacs]
It can however be easily called a desktop environment since it provides an environment to work with. It gives you the ability to write quick interactive code to interface with any application, it can be as dirty as shell scripts or well thought out to provide stable APIs. In fact many emacs functionalities are provided by packages. [^ccore]
Can other editors be as extendable as emacs? No. Why? Because other editors use a different user model, one where the user has to be restricted since it is considered  a "guest" of the running environment which is offering a "service" to the user. This is not the case with emacs, where the environment and the user become one and the same. In emacs, you have access to everything, and can modify almost all things through the same means those things were created, aka elisp. 

# Is it worth it?
The benefits accrue, it is investment, and like any investment, you should expect gains proportional to how much you put in, therefore you have to spend some time in learning and practicing how to use it.

# My GNU emacs wishlist
> Emacs is very good operative system, but a bad text editor.
...Or something along those lines. The GNU Emacs implementation, just like emacs, has its roots in the eighties, and many parts of its core show their age...
- The dicothomy between the graphical interface and the terminal interface. Since emacs is old it started as an application to run inside a terminal but with the advent of graphical interfaces in the nineties, it started to collect functionalities more geared toward _window based_ interactions and around year 2000 the support for the [X11] protocol was introduced. As years pass, the usefulness of the terminal version might decrease, and with it, interest in maintaining it, because having emacs behave differently depending on graphical/terminal is quite a burden, and a complexity chip. I would like to see an abstraction of the emacs GUI over something like the [sixel] protocol, such that the graphical and terminal interfaces can achieve a deeper level of code sharing. This would require emacs to invert the "terminal first, graphical second" assumption (which at time of writing i think still holds). [^reverseterminal]
- Async code in elisp is not easy, or possible in some cases. Emacs supports threads that _yield_ that is that can pause and give back control to the main scheduler, which is an implementation of [cooperative multitasking]. Does emacs need modern support for async primitives? The fact that emacs has mostly been constrained to one core means that the code is quite optimized, and emacs itself can run fairly speedy on smaller devices too. I think that emacs, being an interactive interface, has to support only an _asynchronous graphical interface_. In this case the scope and the context for the asynchronous code would be restricted to just the UI. This is the design used in other electron based editors like [VSCode], where the UI runs in its own separate process. I particularly would like for the _typing experience_ to never be interrupted, and I am fine trading off delayed syntax highlighting, completion, or other ancillary tooling for _soft realtime_ input latency.
- Since in emacs your supposed to have access to _everything_, the way emacs speaks X11 is quite greedy as emacs almost re-implements a full X11 server within itself. This has caused historically some troubles [^flashmacs] since most of the times emacs is used as a window inside another X11, and not an [X11 server itself]. The display server, which handles the graphical sessions. 
  What would a different display environment look like? I imagine something that starts from a lower level, and looks more like a game engine, maybe based on [SDL]. On top of the base direct video output, that would be accessible from either (natively compiled) elisp or a stable C (or rust) API. The emacs window system would be implemented on top of the "pixel cruncher" backend and not rely anymore on an external graphical toolkit like lucid or [GTK] and achieve an higher level of platform agnosticism. It would also mean more reliable performance across systems, because when the display is handled by an external graphical toolkit performance can become unpredictable, and for example things like _spawning a new frame_ end up slower on windows than on linux; when these functionalities become frequently used, like display completion candidates the discrepancies become evident. [^webrender]
- Having a more modern display platforms would allow not just better performance, but access to more advanced visual tools, like proper transitions, shadows, blur, and a better system for layers, since emacs currently implements them with [overlays] which scale poorly. In general, it would be nice to have the full power of CSS3 and beyond, ready to use and improve the currently somewhat spartan emacs interfaces. [^noanimationspls]
- Work on some specification for elisp. Current emacs maintainers care about the ability to run emacs across different platforms (cpu architectures). If as much of the core is rewritten in elisp itself [^elispslow], the only thing left in the internals becomes the elisp interpreter. With an agreement on some form of elisp specification, porting the whole of emacs to a different runtime becomes feasible, since the problem is equivalent to "just" implementing an elisp interpreter.
- An emacs funding platform? In this [reddit post] it is mentioned how it is hard to "just fund" people to work on things, and it must be developers interested in working on specific features that have to ask for funding. This however doesn't consider the fact that not many people are well versed in the emacs internals. Effectively, waiting on developers to gain the knowledge to implement specific features can take 20 years (and counting); what would speed things up would be to _first_ pay people to learn (and write documentation!) about emacs internals such that more people can familiarize with it and slowly move emacs development from the [cathedral and bazaar] development model to a more inclusive one.

- Packages wishlist:
  - [Tree-sit] all the things! Emacs syntax highlighting is based around regular expressions, which are not slow (most of the times) but can cause some performance cliffs that it would quite desireable to avoid altogether.
    But treesitter doesn't just help with syntax highlighting, it provides a hierarchical representation of the buffer content which benefit other packages as well:
    - smartparens, paredit, lispyville, etc...: This is the package that provides the most featureful api for applying text manipulations based on text objects, like slurping, but they are slow (smartparens in particular). Rebasing the api on top of treesitter looks appealing.
    - Polymode: is a minor mode for mixing different major modes in the same buffer. It applies region narrowing through regular expressions, using treesitter here will help speed things up.
    - Orgmode: after a grammar for tree sitter has been written, orgmode could receive considerable speed bumps since a lot of org mode logic and execution is based on buffer contents which have to regularly be parsed (properties, code blocks, headings, outputs)
  - Add [hyperbole] to orgmode: this packages implements hyperlink globally, whereas orgmode hyperlinks only work among orgmode buffers. Also orgmode which is based on outline mode, could benefit from the kline mode provided by hyperbole, which implements non colliding nodes.
  - Circhat: a word mashup between [circe.el] and [weechat.el]. Circe implements a very good UI for chat buffers, while weechat.el provides support for interfacing with the [weechat relay protocol], but has a poor and buggy UI. Using weechat for handling chat communications relieves emacs from having to handle all the IRC connections and monitoring all the buffers, which can slow emacs down quite a lot. Moreover weechat has plugin support for matrix, so you get direct matrix support inside emacs too.
  - Tramp: tramp is the emacs package that handles remote connections, but is terribly slow. This is not necessarily all tramps fault, because other packages never check if the current session is local or remote, and apply things like file system heavy operation on remote endpoints. But tramp also lacks async support, which is a very sad state of affairs for something that mostly shills out commands to external processes which handle the requested protocols (ssh, sftp, docker...). VSCode experience with remove hosts is much better, and emacs needs to step-up its game :)

[weechat relay protocol]: https://weechat.org/files/doc/stable/weechat_relay_protocol.en.html
[weechat.el]: https://github.com/the-kenny/weechat.el
[circe.el]: https://github.com/emacs-circe/circe
[hyperbole]: https://www.gnu.org/software/hyperbole/
[Tree-sit]: https://github.com/emacs-tree-sitter/elisp-tree-sitter
[cathedral and bazaar]: https://en.wikipedia.org/wiki/The_Cathedral_and_the_Bazaar
[reddit post]: https://old.reddit.com/r/emacs/comments/gl6lrh/funding_emacs_core_development/fqvs6qk/
[^elispslow]: can't because of speed but speed is only important short term, and without considering jit compilation
[^noanimationspls]: The argument for more advanced animations can get contentious, as many people are of the opinion that things like transitions, blur, textures, shadows, etc don't add value to a GUI...but they do. But defending animations is for another post, here I can just say that careful and thoughtful application of more advanced properties can make a big difference in usability and productivity too (It's not just styling!).
[overlays]: https://www.gnu.org/software/emacs/manual/html_node/elisp/Overlays.html
[emacs-ng]: https://github.com/emacs-ng/emacs-ng
[^webrender]: [emacs-ng] uses webrender, which allows gpu based drawing, since it works similarly to a game engine, it fullfills parts of my wishes, but I don't know how the webrender backend connects to emacs internals; if its efforts are akin to the [pgtk] backend that it would still fall quite a bit short. 
[GTK]: https://www.gtk.org/
[SDL]: https://www.libsdl.org/
[emacs]: https://www.gnu.org/software/emacs
[virtual machine]: https://en.wikipedia.org/wiki/Virtual_machine
[jit compilation]: https://en.wikipedia.org/wiki/Just-in-time_compilation
[MACLISP]: https://en.wikipedia.org/wiki/Maclisp
[common lisp]: https://en.wikipedia.org/wiki/Common_Lisp
[X11]: https://en.wikipedia.org/wiki/X_Window_System
[X11 server itself]: https://github.com/ch11ng/exwm
[sixel]: https://en.wikipedia.org/wiki/Sixel
[cooperative multitasking]: https://en.wikipedia.org/wiki/Cooperative_multitasking

[^kernelmacs]: It is fun however, to think about a future where GNU HURD (the kernel) can be interfaced with emacs to speak with a lisp closer to bare metal
[^ccore]: There is still, however, a bulk of 200k lines of C code that implements core functionalities
[^flashmacs]: Since emacs displays things as a "server" when talking to another server, it sends a full "update" of the window, which has caused flickering in some cases.
[^reverseterminal]: [browsh] is able to display webpages within the terminal, the rich website is "reduced" to support the terminal interface, this is a case of "graphical first, terminal second"
[browsh]: https://www.brow.sh/
[VSCode]: https://code.visualstudio.com/
