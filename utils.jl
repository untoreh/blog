using Franklin; const fr = Franklin;
using Franklin: convert_md, convert_html, pagevar, path, globvar;
using Base.Iterators:flatten
using DataStructures:DefaultDict
using Dates:DateFormat, Date

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
#
#m

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

function iter_posts()
    posts_list = readdir(dirname("posts/"))
    filter!(f -> endswith(f, ".md") && f != "index.md" && !startswith(f, "."), posts_list)
    return posts_list
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
                      date = pagevar(fi, :date), description = pagevar(fi, :rss_description),))
    end
    # pull all posts if n <= 0

    n = n >= 0 ? n : length(posts) + 1
    for ele in view(sort(posts, by=x -> Date(x.date, df), rev=true), 1:min(length(posts), n))
        markdown *= "* [($(ele.date)) $(ele.title)](../$(ele.link)) -- _$(ele.description)_ \n"
    end

    return fd2html(markdown, internal=true)
end

function hfun_taglist_desc(tag::Union{Nothing,String}=nothing)::String
    if isnothing(tag)
    tag = locvar(:fd_tag)
    end

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
    sort!(rpaths, by=sorter, rev=false)

    for rpath in rpaths
        title = pagevar(rpath, "title")
        if isnothing(title)
            title = "/$rpath/"
        end
        url = get_url(rpath)
        desc = pagevar(rpath, "rss_description")
        write(c, "<li><a href=\"$url\">$title</a> -- $desc </li>")
    end
    write(c, "</ul>")
    html = String(take!(c))
    close(c)
    return html
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
        write(c, "Articles tagged: <a href=\"/$tag_page/$tag/\">$tag</a>")
    end
    write(c, "</div></div>")
    return String(take!(c))
end

@doc "the base font size for tags in the tags cloud (rem)"
const tag_cloud_font_size = 1;

function hfun_tags_cloud()
    tags = DefaultDict{String,Int}(0)
    # count all the tags
    for p in iter_posts()
        fi = "posts/" * splitext(p)[1]
        for t in pagevar(fi, :tags)
    tags[t] += 1
        end
    end
    ordered_tags = [k for k in keys(tags)]
    sort!(ordered_tags)
    # normalize counts
    counts = [tags[t] for t in ordered_tags]
    min, max = extrema(counts)
    sizes = @. ((counts - min) / (max - min)) + 1
    # make html with inline size based on counts
    c = IOBuffer()
    write(c, "<div id=tag_cloud>")
    for (n, (tag, count)) in enumerate(zip(ordered_tags, counts))
        write(c, "<a href=\"$tag\" style=\"font-size: $(sizes[n] * tag_cloud_font_size)rem\"> $tag </a>")
    end
    write(c, "</div>")
    String(take!(c))
end

@doc "check if page is an article "
function hfun_post_title()
    path = locvar(:fd_rpath)
    if (!isnothing(match(r"posts/.+", path)) &&
        path !== "posts/index.html")

    link = locvar(:link)
    title = locvar(:title)
    desc = locvar(:rss_description)
    "
        <div>
        <h1 id=\"title\"><a href=\"\">$title</a></h1>
        <blockquote id=\"page-description\" style=\"font-style: italic;\">
            $desc
        </blockquote>
        </div>
      "
    else
        ""
    end
    # path = locvar(:fd_rpath)::String
    # ispage("/posts")
end

@doc "insert a colored star"
function hfun_star(args)
    color = args[1]
    "<span style=\"color:var(--$color); margin-left: 0.2rem;\"><i class=\"fa fa-star\" aria-hidden=\"true\"></i></span>"
end

@doc "return the tag of the current page or none"
function hfun_tag_title(prefix="Tag: ", default="Tags")
    # NOTE: franklin as {{if else}} and {{isdef}}
    c = IOBuffer()
    let tag = locvar(:fd_tag)
        if tag != ""
            write(c, prefix)
            write(c, tag)
        else
            # write(c, locvar(:title))
            write(c, default)
        end
    end
    String(take!(c))
end

