
module Content
using ExportAll

using FranklinUtils
using Franklin; const fr = Franklin;
using DataStructures:DefaultDict
using Franklin: convert_md, convert_html, pagevar, globvar, locvar, path;
using Dates: DateFormat, Date
using Memoization: @memoize
# include("exporter.jl")


function hfun_bar(vname)
    val = Meta.parse(vname[1])
    return round(sqrt(val), digits=2)
end

function hfun_m1fill(vname)
    var = vname[1]
    return pagevar("index", var)
end

function hfun_color(args)
    color = args[1]
    txt = args[1]
    return "<span color=\"$color\">$txt</span>"
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
    str = String(take!(io))
    close(io)
    str
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
    for (_, post) in enumerate(list)
        fi = posts_path * splitext(post)[1]
        push!(
            posts,
            (
                title = pagevar(fi, :title),
                link = fi,
                date = pagevar(fi, :date),
                description = pagevar(fi, :rss_description),
            ),
        )
    end
    # pull all posts if n <= 0

    n = n >= 0 ? n : length(posts) + 1
    for ele in
        view(sort(posts, by=x -> Date(x.date, df), rev=true), 1:min(length(posts), n))
        markdown *= "* [($(ele.date)) $(ele.title)](../$(ele.link)) -- _$(ele.description)_ \n"
    end

    return fd2html(markdown, internal=true)
end

function tags_sorter(p)
    pvd = pagevar(p, "date")
    if isnothing(pvd)
        return Date(Dates.unix2datetime(stat(p * ".md").ctime))
    end
    return pvd
end


function hfun_taglist_desc(tags::AbstractVector)
    hfun_taglist_desc(tags[1])
end

function hfun_taglist_desc(tag::Union{Nothing,AbstractString}=nothing)
    if isnothing(tag)
        tag = locvar(:fd_tag)
        if isnothing(tag)
            throw("need a tag")
        end
    end

    c = IOBuffer()
    write(c, "<ul>")

    all_tags = globvar(:fd_tag_pages)
    # taags have yet to be processed
    if isnothing(all_tags)
        all_tags = fr.invert_dict(globvar(:fd_page_tags))
    end
    rpaths = all_tags[tag]
    sort!(rpaths, by=tags_sorter, rev=false)

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
        write(
            c,
            "<a href=\"/$tag_page/posts/\"><h1>Posts</h1></a>
<i>that\"s the stuff</i>",
        )
    elseif tag === "bulbs"
        write(
            c,
            "<a href=\"/$tag_page/bulbs/\"><h1>Ideas</h1></a>
<i>commonly known as shower thoughts</i>",
        )
    elseif tag === "about"
        write(c, "<a href=\"/$tag_page/about/\"><h1>About</h1></a>
<i>software that I have written</i>")
    else
        write(c, "Articles tagged: <a href=\"/$tag_page/$tag/\">$tag</a>")
    end
    write(c, "</div></div>")
    str = String(take!(c))
    close(c)
    str
end

@doc "the base font size for tags in the tags cloud (rem)"
const tag_cloud_font_size = 1;

@doc "tag list to display in post footer"
function hfun_addtags()
    if is_post()
        c = IOBuffer()
        write(c, "<div id=\"post-tags-list\">\nPost Tags:\n")
        for tag in locvar(:tags)
            println(c, "<span class=\"post-tag\">", tag_link(tag), ", </span>")
        end
        # remove comma at the end
        str = chop(String(take!(c)); tail=10) * "</span></div>"
        close(c)
        str
    else
        ""
    end
end

function tag_link(tag, font_size::Union{Float64,Nothing}=nothing)
    style = ""
    if !isnothing(font_size)
        style = "font-size: $(font_size)rem"
    end
    link = join(["/posts", globvar(:tag_page_path), tag], "/")
    "<a href=\"$link\" style=\"$style\"> $tag </a>"
end

# include("icons.jl")
@doc "Tag cloud, tags with font size dependent on the number of posts that use it"
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
    icon = ""
    tag_path = globvar(:tag_page_path)
    for (n, (tag, count)) in enumerate(zip(ordered_tags, counts))
        icon_name = icons_tags[tag]
        if icon_name !== ""
            icon = "<i class=\"fa $icon_name icon\"></i>"
        else
            icon = ""
        end
        write(
            c,
            "<a href=\"$(joinpath("/", tag_path, tag))\" style=\"font-size: $(sizes[n] * tag_cloud_font_size)rem\"> $icon $tag </a>",
        )
    end
    write(c, "</div>")
    str = String(take!(c))
    close(c)
    str
end

@memoize function post_link(file_path, code="")
    joinpath(globvar(:website_url), code, splitext(file_path)[1])
end

@doc " write the post title "
function hfun_post_title()
    path = locvar(:fd_rpath)
    if (!isnothing(match(r"posts/.+", path)) && path !== "posts/index.html")

        link = post_link(path)
        title = locvar(:title)
        desc = locvar(:rss_description)
        "
            <div>
            <h1 id=\"title\"><a href=\"$link\">$title</a></h1>
            <blockquote id=\"page-description\" style=\"font-style: italic;\">
                $desc
            </blockquote>
            </div>
          "
    else
        ""
    end
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
    write(c, "<div id=\"tag-name\">")
    let tag = locvar(:fd_tag),
        prefix = tag === "about" || tag === "lightbulbs" ? "" : prefix
        if tag != ""
            write(c, prefix)
            write(c, tag)
        else
            # write(c, locvar(:title))
            write(c, default)
        end
        write(c, "</div>")
    end
    str = String(take!(c))
    close(c)
    str
end

function hfun_insert_bio()
    let bio = read(joinpath(path(:assets), "bio.md"), String) |>
        x -> convert_md(x; isinternal=true)
        replace(bio, "{{bio_link}}" => """<a rel="nofollow noopener noreferrer" href="$(locvar(:geo_link))"
target="_blank"><i class="fas fa-fw fa-map-marker-alt" aria-hidden="true"></i></a>
""")
    end
end

function hfun_recent_posts()
end

function hfun_about_place()
    joinpath(path(:layout), "place.html") |>
        x -> read(x, String) |>
        fr.convert_html
end

@doc "check if page is an index page"
function is_index(path)
    !isnothing(match(r".*/index\.(html|md)", path))
end

@doc "check if page is a post"
function is_post()
    path = locvar(:fd_rpath)
    (!isnothing(match(r"posts/.+", path)) && !is_index(path))
end

@doc "check if page is a tags page"
function is_tag(tag)
    path = locvar(:fd_rpath)
    !isnothing(match(r"$tag/index.(html|md)", path))
end

@doc "insert the utteranc.es comments widget if the page is a post"
function hfun_addcomments()
    if is_post()
        html_str = """
        <script src="https://utteranc.es/client.js"
            repo="untoreh/untoreh.github.io"
            issue-term="pathname"
            label="Comment"
            crossorigin="anonymous"
            async>
        </script>
    """
        return html_str
    else
        ""
    end
end

# @doc "add edited date at appropriate pages"
function hfun_editedpage()
    if is_post() || is_tag("lightbulbs")
        locvar(:fd_mtime)
    else
        ""
    end
end

function hfun_insert_path(args)
    (pwd(), dirname(locvar(:fd_rpath)), args[1]) |> (x) -> joinpath(x...) |> readlines |> join
end

function hfun_insert_img(args)
    if args[2] === "none"
        "<img alt=\"$(splitext(args[1])[1])\" " *
            " src=\"/assets/posts/img/$(args[1])\"" *
            " style=\"float: none; padding: 0.5rem; " *
            " margin-left:auto; margin-right: auto; display: block; \">"
    else
        "<img alt=\"$(splitext(args[1])[1])\" " *
            " src=\"/assets/posts/img/$(args[1])\" " *
            " style=\"float: $(args[2]); padding: 0.5rem;\">"
    end
end

icons_tags =
    DefaultDict("",
                Dict(
                    "programming" => "fas fa-code",
                    "about" => "fas fa-wrench",
                    "lightbulbs" => "fas fa-lightbulb",
                    "apps" => "fab fa-android",
                    "crypto" => "fab fa-bitcoin",
                    "guides" => "fas fa-directions",
                    "hosting" => "fas fa-server",
                    "linux" => "fab fa-linux",
                    "mobile" => "fas fa-mobile-alt",
                    "net" => "fas fa-network-wired",
                    "nice-to-haves" => "fas fa-candy-cane",
                    "opinions" => "fas fa-blog",
                    "philosophy" => "fas fa-pen-alt",
                    "poetry" => "fas fa-feather",
                    "shell" => "fas fa-user-ninja",
                    "cooking" => "fas fa-utensils",
                    "games" => "fas fa-gamepad",
                    "software" => "fas fa-code-branch",
                    "stats" => "fas fa-chart-bar",
                    "tech" => "fas fa-pager",
                    "agri" => "fas fa-tree",
                    "things-that-should-not-be published" => "fas fa-comment-dots",
                    "tools" => "fas fa-tools",
                    "trading" => "fas fa-chart-line"
                ))

function hfun_icon_tag(tag)
    icons_tags[tag]
end

@memoize function get_languages()
    sort(globvar(:languages))
end

function hfun_langs_list()
    c = IOBuffer()
    write(c, "<ul id=\"lang-list\">")
    src = globvar(:lang)
    for (lang, code) in get_languages()
        if lang === src continue end
        write(c, "<a class=\"lang-link\" id=\"lang-", code, "\" href=\"",
                post_link(locvar(:fd_rpath), code), "\">", lang, "</a>")
    end
    write(c, "</ul>")
    str = String(take!(c))
    close(c)
    str
end

# function lx_taglist(com, _)
# 	"~~~" * hfun_taglist_desc("about") * "~~~"
# end

function lx_hfun(com::Franklin.LxCom, _)
    args = lxproc(com) |> split
    let f = getfield(@__MODULE__, Symbol("hfun_" * args[1]))
        length(args) > 1 ? f(args[2:end]...) : f()
    end
end

# exportall()
@exportAll()

end
