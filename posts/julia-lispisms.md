+++
date = "1/21/2023"
title = "Julia lispisms"
tags = ["programming"]
rss_description = "Things that I find confusing about julia syntax"
+++

Julia parses its syntax pretty much like a lisp.
However the syntax is not quite like s-exprs so has to deal with different contexes...lets see:

A symbol in julia:
```julia
typeof(:abc)
# Symbol
```

Also a symbol:
```julia
typeof(:(abc))
# Symbol
```

Not a symbol:
```julia
typeof(:(abc isa Symbol))
# Expr
```
So after some spaces it becomes an expression, or a *list*.

However the `:()` notation is **not** _quoting_.
An expression is still valid julia code. In fact:
```julia
typeof(esc(:(abc def)))
# ERROR: syntax: missing comma or ) in argument list
```
Since `abc def` is not valid julia code.
So the `:()` notation is more like a lisp `(read '(...))`. Where we instrument the compiler to _read_ the quoted code.

You want to just quote things? Well you can't quote a whole expression, but you can quote symbols:
```julia
typeof(QuoteNode(:abc))
# QuoteNode
```
Where is this used in general? To deal with ambiguities between _bound_ symbols and literal symbols.
Bound symbols are variables, functions, modules:

```julia
m = :Main
eval(:(typeof($m)))
# Module
```
What if we wanted the `:Main`  _symbol_?
```julia
eval(:(typeof($(QuoteNode(m)))))
# Symbol
```

Don't get tricked by the `quote ... end` syntax.
It's not a `QuoteNode`:

```julia
typeof(quote abc end)
# Expr
```
It is a multi line expression like `:()`, like `begin ... end`.

Maybe julia could be more practical as a lisp where you just pass quoted lists around `'(...)` by having something that is better than strings:
```julia
eval(Base.Meta.parse("abc def"))
```

dunno.
