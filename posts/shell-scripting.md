+++
date = "7/15/2021"
title = "shell scripting"
tags = ["programming", "shell"]
rss_description = "Thoughts on shell scripting"
+++

**[Bash]/[zsh]** shell scripting gets the job done. It is also quite ugly. Maybe it is intended. The less you want to look at it the shorter the scripts will be.
I am not a fan of using bash/zsh as an interactive shell, the amount of plugins required to make up for a nice experience is daunting, and every additional plugin is a pitfall for possible shell slow downs. 
Never-the-less the amount of work done by psprint with [zinit & friends] is very impressive (and also kind of the only sensible choice for a plugin manager if you want to use zsh as an interactive shell). However it doesn't solve the fact that all those loaded plugins are _non-shared_ memory among (probably) many shell processes.

[zinit & friends]: https://github.com/zdharma/zinit
[Bash]: https://www.gnu.org/software/bash/
[zsh]: https://zsh.sourceforge.io/

**[Fish shell]** is my preferred shell at the time of writing. The amount of installed plugins is very minimal, because it does most of the things you would want from a shell _out of the box_.
The scripting is somewhat slower than zsh but nobody cares about scripting speed so it is fine. The syntax is nice of ML heritage (like Julia) with end statements, instead of curly braces. Writing scripts is more verbose than bash/zsh however it is also a lot more readable. Things like process substitution, strings interpolation and piping end up a little bit more verbose.
It has _global_ variables, shared across all running processes, and _universal_ variables, shared across sessions, which makes things easier without having to write everything down and source forgetful scripts.

[Fish shell]: https://fishshell.com/

**[Elvish]** is a shell with support for a lot of things, like a daemon or web mode which allows it to send commands remotely...? I think it is too much and I start calling it bloated. IMHO a shell should strive for simplicity, and be self contained. I think shells should be designed to handle scenarios where they are processes spawned a conspicuous amount of times, that behave consistently from start to finish and that are self-contained such that they can handle crashes gracefully. So despite all the other features (like structured data)...daemons are no go for me.

[Elvish]: https://elv.sh/

**[Ion Shell]** is _almost posix_ shell from redox, which also works on unix, with the goal of _also_ working on windows, although it doesn't work ATTOW. Its goal is to simply be a better shell, so it takes the good from posix and adds to it. It seems to be focused on providing a good scripting language, but not a very good interactive experience, fish shell has spoiled me, and I am not going back to a shell without _first class_ interactivity.

[Ion Shell]: https://gitlab.redox-os.org/redox-os/ion

**[Oil shell]** has the goal to replace bash, which is commendable, however it targets only unix systems with no Windows in sight. It has focused on fixing the bash compatibility layer up until now, with future plans to focus on the interactivity part. Considering the fact that the interactive part of the shell has not yet been written, makes me a little doubtful about its future and although I hope it does not, I feat it might loose steam before it achieve its intended goals. Also the lack of windows support is not ideal.

[Oil shell]: https://www.oilshell.org/

**[Rash]** a shell with support for structured data that works with [Racket] objects, when I look up racket more I will try it, although my past experience with the [_emacs shell_] is not really nice, since the _eshell_ only works within emacs, and doesn't work nicely as a _system shell_ ...unless your system is emacs (despite emacs is my main editor and I do write _some_ lisp, it is not my operative system). (Here I should also mention the Julia REPL, the best repl for any programming language).

[Rash]: https://rash-lang.org/

**[Powershell]** Powershell, the main Windows shell works also on linux and macs, thanks to the cross platform [NET]. But it is too verbose, slow, and probably (not verified) littered with _windowsisms_; It is a big no for me.

[Powershell]: https://github.com/PowerShell/PowerShell

**[Nu shell]**...of course we spare the best for last. This is probably my next go to shell; first-class attention for interactivity, careful consideration of each shell builtin and cross platform, and structured text.

[Nu shell]: https://www.nushell.sh/

Shells that are not in this list ATTOW were probably considered not interesting enough.

[Racket]: https://en.wikipedia.org/wiki/Racket_(programming_language)
[_emacs_shell_]: https://www.gnu.org/software/emacs/manual/html_mono/eshell.html
[NET]: https://github.com/dotnet/runtime
