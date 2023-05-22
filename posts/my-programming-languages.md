+++
date = "5/22/2023"
title = "My programming languages"
tags = ["programming"]
rss_description = "My programming languages of choice"
+++

To keep the list short I try to stick to _one language per ecosystem_

## Julia

Ok this is not an ecosystem but since it is my top language of choice it has to come first. The reason it is my favourite is that it is the only dynamic language that is _truly ergonomic_, I like how easy it easy to benchmark things, I like Makie, the way types compose and how the dispatch system seamlessly integrates with parametric types. 

[Julia](https://julialang.org/) trades off some memory and compilation time for speed and ease of use, and it is rare to see processes smaller than ~500M of ram. So if you hate electron or java you might have a problem with julia too, although there are solutions that give you small julia binaries they are all experimental, and anyway, julia is a dynamic first language, so I think the primary target use case will always be to run stuff from the repl and compiled binaries will always be second citizens, but time will tell. 

Recently a language called mojo came out, and some people started questioning if it was a "threat" to julia. If you have used julia for quite some time, and then glossed over the mojo docs (like I did) you might have realized that mojo is a static language _bolted_ on top of the dynamic python so it is hard to call it a language "unified" with python, therefore you are comparing apples and oranges...

If you want to compare julia with something else there are a couple of others "JAOT"s based languages:
- numba: same as julia llvm jit based a mixmash of python,numpy and numba specific idioms, you can't really build large projects based on it, only useful for speeding up small functions
- gccemacs: emacs in native compilation mode does the same as julia, but in a much weaker form, because it can't really infer very concrete types from lisp, definitely not _emacs lisp_, and is based on gcc jit.

## Nim
 We can call it the "C" ecosystem, and my second fav language is [nim](https://nim-lang.org/), but I rarely use it because its tooling is crap. So please someone dump a few millions in nim tooling development, thanks! It is my favourite because as I mentioned before julia is very hard to ship and you definitely don't want to ship gigabyte sized binaries. Nim instead can compile very small binaries and make tham static too. 

The only pain point (from a language perspective ofc) is the interaction between threads and async. Passing stuff between async couritines and threads can be full of gotchas, so it lacks some kind of system that makes it easier to juggle between threads and the async runtime. Also using an async runtime can make binaries grow quite large because of the async closures rewrites or something like that, bottom line is that binaries have a boatload of codegen-ed functions, and debugging them is also hard because of the function naming scheme.

Apart from being overall easy to ship, it has great ffi support, dot call syntax, a macro/template system that is even better than lisps (if you ignore lack of sexprs), macros in julia are ok but nim can "dispatch" macros and templates over types, allow you to choose between "dirt and hygiene" and the language server was able to provide lots of intelligence betweeen functions, macros and templates that even rust couldn't achieve (if only it wouldn't crash every 2 second and be slow as hell...sigh). 

Nim also has nimscript, my wish is that a full fledged interactive repl could be built around that, if hot code reloading ever gets picked up again, that is...

## Rust
Rust is what I use since nim tooling is crap, if nim tooling wasn't crap I would use nim. I don't personally find rust memory safety such an advantage over nim. Nim doesn't not have "fearless concurrency", that is compared to rust it is easy in nim to segfaul when dealing with threads. However rust uses lifetimes to achieve thread safety, while nim doesn't have any such thing at the language level. Lifetimes are likeley the most confusing and hard to read rust language feature so there might be a reason in there...

In general you can say that after a certain point business bugs become more common than memory bugs, and you don't want to overcomplicate the language to achieve diminishing returns in memory safety while clobbering the readability and increase complexity of the language itself. Because quantifying how much a language makes business bugs more common is pretty much impossible to quantify, this point is always going to be moot.

## The rest
These are only language on top of my list of "alternative" languages that I _might_ pick once per ecosystem

- Beam: Hard choice between gleam and elixir, might end up choosing gleam or try them both and pick one, ofc they are fundamentally different languages, but I did mention that would choose only one per ecosystem.
What follows is what I would use any these ecosystems, but haven't really tried them:
- JVM/Graal: Clojure. A close second might have been scala in the past, but clojure is effectively the only "industrial" lisp out there, so gotta pick that one.
- Node/Deno/Bun: I would choose typescript simply because it is the most common compile-to-js language. In the future I might consider ReScript, if its ecosystem will ever grow large enough.
- CLR: None? I would say F# but I would prefer to say no CLR. The clr seems to have implementations also for clojure and swift so there's that, but my impression has always been that using any of these "ports" would be met with a bunch of incompatibilities, anyway I don't see myself ever approaching the clr by personal choice.
- Lisp: is lisp an ecosystem? Eh...not really, although someone might say that it's all sexprs and porting things from one scheme to another is as close as a search-and-replace query as you are going to get. If emacs lisp had a speedy dialect that would leverage gccemacs to spit out fast code I would strongly consider it over common lisp. If I had to pick a scheme instead, that would be racket without questions. Do I see myself writing actual software either in commonlisp or racket? Not likely, because If I needed a lisp I would pick clojure.

Apart from these "ecosystem" language picks there are a couple other worth an honorable mention.

- Raku: I have done some moderate PHPing in the past, and zero perl, yet raku seems really interesting, if not for the unparalled code-golfability of the language. 
- Red: the full stack promise is appealing, and the rebol heritage is unique enough that it is worth writing a decently sized app in it to try it out
- Dart: If I stumble on some UI dev I might try it, but I would prefer to stick with one of my top languages even for UI dev, the question then becomses, _by how much_ does dart (or haxe!) increase productivity thanks to the multi platform support?
- Verse: the language from epic games, unique because of effectively being the only modern approach to a prolog-ish language. It seems clear the epic built this because everybody hates UE blueprints. But if the language remains tightly couple to UE I don't see myself ever trying it.

There are many other popular languages, like some more functional ones like ocaml, haskell or other simpler ones like zig or vlang which I have not mentioned because I think they are _too dead set_ over their paradigm (immutability/simplicity), and in general I guess I prefer more "rounded" languages.

This list ended up not being that short, sorry I guess.
