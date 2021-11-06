+++
date = "11/5/2021"
title = "is Julia a lisp?"
tags = ["programming"]
rss_description = "What defines a lisp? Can Julia be called a LISP?"
+++

# What is a LISP?
A [lisp], from wikipedia:
> Lisp (historically LISP) is a family of programming languages with a long history and a distinctive, fully parenthesized prefix notation.
Also, from wikipedia:
> Once Lisp was implemented, programmers rapidly chose to use S-expressions, and M-expressions were abandoned.
And again:
> Lisp was the first language where the structure of program code is represented faithfully and directly in a standard data structure, a quality much later dubbed "homoiconicity".
Also:
> LISP is an acronym for LISt Processing. 

# What about Julia?
Julia code can be represented using `:()` or `Expr(...)` notation. It can be traversed and manipulated as it is a data structure made of symbols and other literals, Julia is homoiconic (and the code is parsed with a lisp). However Julia syntax doesn't make use of _just_ prefix notation, it has M-Expressions.

# S and M Expressions
Some people consider _S-Expression only syntax_ a requirement for a lisp language to be called such. The advantage of S-Exprs is that code is easier to parse and manipulate by other people, it is an indirect benefit, it is a simpler common ground that in turn gives the ability to write more _powerful code editing_ code. Julia has macros, but in some sense, they are less powerful than lisp macros because it is harder to manipulate M-Exprs.

# Is Julia a LISP?
\del{I don't care.}

\del{Who cares?} 

Meh. :)

[lisp]: https://en.wikipedia.org/wiki/Lisp_(programming_language)
