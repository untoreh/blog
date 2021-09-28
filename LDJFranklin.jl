module LDJFranklin
include("LDJ.jl")
using .LDJ
using ExportAll
using Franklin: globvar, locvar
using FranklinUtils
using Conda
using JSON
using IterTools: chain
using DataStructures: OrderedDict
using Base.Unicode: titlecase

const BOOKS = []

# function lx_book(name, author, url, sameas="", _)
function lx_book(com, _)
    args = lxproc(com)
    name, author, url, tags, comments  = strip.(args) |>
        x -> split(x, r"; ?")
    # name, author, url = split(args, "\" \"")
    push!(BOOKS, (name=name, author=author, url=url, tags=tags, comments=comments, sameas=""))
    "[" * name * "](" * url * ")"
end

using HTTP: get
using URIs: URI
import Base.convert

convert(::Type{Symbol}, s::String) = Symbol(s)
@doc "Fetch books list from a calibre content server"
function calibredb_books_server(server="http://localhost:8099"; query=Dict("library_id" => "",
                                                                           "num" => typemax(Int32)))
    get(server * "/interface-data/books-init";  query) |>
        res -> String(res.body) |>
        JSON.parse |>
        r -> r["metadata"]
end

@doc "generate LDJ data from a list of books"
function hfun_ldj_library()
    empty!(BOOKS)
    if locvar(:fd_rpath) === "reads/index.md"
        # add calibre books to library
        calibre_books = calibredb_books_server(locvar(:calibre_server);
                                               query=Dict("library_id" => locvar(:calibre_library),
                                                          "num" => 10000))
        for (_, book) in calibre_books
            push!(BOOKS, (name=book["title"], author=book["author_sort"],
                          url="", tags=book["tags"], sameas=""))
        end
        bookfeed(BOOKS) |> wrap_ldj
    else
        ""
    end
end

@doc "create html lists by grouping books based on their tags"
function hfun_insert_library(groups=[])
    c = IOBuffer()
    if isempty(groups)
        lists = Dict(["all" => Vector{String}()])
        setgroup! = book -> begin
            "read" ∈ book.tags && push!(lists["all"], book.name)
        end
    else
        lists = OrderedDict([g => [] for g in groups])
        setgroup! = book -> begin
            for g in groups
                if "read" ∈ book.tags && g ∈ book.tags
                    push!(lists[g], book)
                end
            end
        end
    end
    for book in BOOKS
        setgroup!(book)
    end
    write(c, "<div id=\"library\">")
    for (group_name, group_list) in lists
        if length(group_list) > 0
            write(c, "<h2>$(titlecase(group_name))</h2>")
            write(c, "<ul class=\"$(group_name)-books\">")
            for book in group_list
                write(c, "<li class=\"book-entry\">")
                println(c, book.name, "<div class=\"book-author\"> - ", book.author,"<div>")
                write(c, "</li>")
            end
            write(c, "</ul>")
        end
    end
    write(c, "</div>")
    ret = String(take!(c))
    close(c)
    ret
end

# function calibre_books_cli(library="http://localhost:8099", fields="authors,isbn,publisher,tags,title")
#     @assert !isnothing(Sys.which("calibredb"))
#     # since calibre is a python package, and is installed system-wide,
#     # make sure we are not using julia python env
#     let pythonpath = ENV["PYTHONPATH"]
#         delete!(ENV, "PYTHONPATH")
#         l = read(`calibredb --with-library $library list --for-machine -f $fields`, String)
#         ENV["PYTHONPATH"] = pythonpath
#         l |> JSON.parse
#     end
# end

@exportAll

end
