using Franklin

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

function hfun_recent_posts(m::Vector{String})
    @assert length(m) < 3 "only two arguments allowed for recent posts (the number of recent posts to pull and the path)"
    n = parse(Int64, m[1])
    path = length(m) == 1 ? "posts/" : m[2]
  list = readdir(dirname(path))
  filter!(f -> endswith(f, ".md") && f != "index.md", list)
  markdown = ""
  posts = []
  df = DateFormat("mm/dd/yyyy")
  for (k, post) in enumerate(list)
      fi = path * splitext(post)[1]
      title = pagevar(fi, :title)
      date = pagevar(fi, :date)
      push!(posts, (title = title, link = fi, date = date))
  end

  # pull all posts if n <= 0
n = n >= 0 ? n : length(posts) + 1

  for ele in sort(posts, by=x -> x.date, rev=true)[1:min(length(posts), n)]
    markdown *= "* [($(ele.date)) $(ele.title)](../$(ele.link))\n"
  end

  return fd2html(markdown, internal=true)
end
