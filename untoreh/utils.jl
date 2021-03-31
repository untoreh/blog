using Franklin; const fr = Franklin;
using Franklin: convert_md, convert_html, pagevar, path, globvar;

function hfun_bar(vname)
    val = Meta.parse(vname[1])
    return round(sqrt(val), digits=2)
end

function hfun_m1fill(vname)
    var = vname[1]
    return pagevar("index", var)
end

# function hfun_color(args)
#     color = args[1]
#     txt = args[1]
#     return "<span color=\"$color\">$txt</span>"
# end

function lx_baz(com, _)
  # keep this first line
    brace_content = Franklin.content(com.braces[1]) # input string
  # do whatever you want here
    return uppercase(brace_content)
end

function hfun_recentblogposts()
    list = readdir("blog")
    filter!(f -> endswith(f, ".md"), list)
    dates = [stat(joinpath("blog", f)).mtime for f in list]
    perm = sortperm(dates, rev=true)
    idxs = perm[1:min(3, length(perm))]
    io = IOBuffer()
    write(io, "<ul>")
    for (k, i) in enumerate(idxs)
        fi = "/blog/" * splitext(list[i])[1] * "/"
        write(io, """<li><a href="$fi">Post $k</a></li>\n""")
    end
    write(io, "</ul>")
    return String(take!(io))
end

function page_content(loc::String)
    raw = read((path(:folder) * "/" * loc * ".md"), String)
    m = convert_md(raw; isinternal=true)
    # remove all `{{}}` functions
    m = replace(m, r"{{.*?}}" => "")
    convert_html(m)
end

function hfun_recent_posts(m::Vector{String})
    @assert length(m) < 3 "only two arguments allowed for recent posts (the number of recent posts to pull and the path)"
    n = parse(Int64, m[1])
    posts_path = length(m) == 1 ? "posts/" : m[2]
  list = readdir(dirname(posts_path))
  filter!(f -> endswith(f, ".md") && f != "index.md" && !startswith(f, "."), list)
  markdown = ""
  posts = []
  df = DateFormat("mm/dd/yyyy")
  for (k, post) in enumerate(list)
      fi = posts_path * splitext(post)[1]
      push!(posts, (title = pagevar(fi, :title), link = fi,
                    date = pagevar(fi, :date), description = pagevar(fi, :desc),))
  end
  # pull all posts if n <= 0

n = n >= 0 ? n : length(posts) + 1
  for ele in sort(posts, by=x -> x.date, rev=true)[1:min(length(posts), n)]
    markdown *= "* [($(ele.date)) $(ele.title)](../$(ele.link)) -- _$(ele.description)_ \n"
    # markdown *= "* [($(ele.date)) $(ele.title)](../$(ele.link))\n"
  end

  return fd2html(markdown, internal=true)

end

function hfun_taglist_desc()::String
    tag = locvar(:fd_tag)::String

    c = IOBuffer()
    write(c, "<ul>")

    rpaths = globvar("fd_tag_pages")[tag]
    sorter(p) = begin
        pvd = pagevar(p, "date")
        if isnothing(pvd)
            return Date(Dates.unix2datetime(stat(p * ".md").ctime))
    end
        return pvd
    end
    sort!(rpaths, by=sorter, rev=true)

    for rpath in rpaths
        title = pagevar(rpath, "title")
        if isnothing(title)
            title = "/$rpath/"
        end
        url = get_url(rpath)
        desc = pagevar(rpath, "desc")
        write(c, "<li><a href=\"$url\">$title</a> -- $desc </li>")
    end
    write(c, "</ul>")
    return String(take!(c))
end

function hfun_tag_title()::String
    tag = locvar(:fd_tag)::String
    tag_page = globvar("tag_page_path")
    c = IOBuffer()
    write(c, "<div id=\"tag_title\"><div class=\"wrap\">")
    if tag === "posts"
        write(c, "<a href=\"/$tag_page/posts/\"><h1>Posts</h1></a>
 <i>that\"s the stuff</i>")
    elseif tag === "bulbs"
        write(c, "<a href=\"/$tag_page/bulbs/\"><h1>Ideas</h1></a>
 <i>commonly known as shower thoughts</i>")
    else
        write(c, "ok")
    end
    write(c, "</div></div>")
    return String(take!(c))
end

function hfun_tags_cloud()
    @show globvar("fd_tag_pages")
end
