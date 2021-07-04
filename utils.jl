using Conda

# These must be set before initializing Franklin
py_v = chomp(String(read(`$(joinpath(Conda.BINDIR, "python")) -c "import sys; print(str(sys.version_info.major) + '.' + str(sys.version_info.minor))"`)))
ENV["PYTHON3"] = joinpath(Conda.BINDIR, "python")
ENV["PIP3"] = joinpath(Conda.BINDIR, "pip")
ENV["PYTHONPATH"] = "$(Conda.LIBDIR)/python$(py_v)"

using Franklin;
const fr = Franklin;
using Franklin: convert_md, convert_html, pagevar, path, globvar;
using Base.Iterators: flatten
using DataStructures: DefaultDict
using Dates: DateFormat, Date
using ResumableFunctions
using JSON


function hfun_bar(vname)
    val = Meta.parse(vname[1])
    return round(sqrt(val), digits = 2)
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
    perm = sortperm(dates, rev = true)
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
    m = convert_md(raw; isinternal = true)
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
        view(sort(posts, by = x -> Date(x.date, df), rev = true), 1:min(length(posts), n))
        markdown *= "* [($(ele.date)) $(ele.title)](../$(ele.link)) -- _$(ele.description)_ \n"
    end

    return fd2html(markdown, internal = true)
end

function hfun_taglist_desc(tag::Union{Nothing,String} = nothing)::String
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
    sort!(rpaths, by = sorter, rev = false)

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
    else
        write(c, "Articles tagged: <a href=\"/$tag_page/$tag/\">$tag</a>")
    end
    write(c, "</div></div>")
    return String(take!(c))
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
        chop(String(take!(c)); tail=10) * "</span></div>"
    else
        ""
    end
end

function tag_link(tag, font_size::Union{Float64, Nothing}=nothing)
    style=""
    if !isnothing(font_size)
        style="font-size: $(font_size)rem"
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
            icon="<i class=\"fa $icon_name icon\"></i>"
        else
            icon = ""
        end
        write(
            c,
            "<a href=\"$(joinpath("/", tag_path, tag))\" style=\"font-size: $(sizes[n] * tag_cloud_font_size)rem\"> $icon $tag </a>",
        )
    end
    write(c, "</div>")
    String(take!(c))
end


@doc "check if page is an article "
function hfun_post_title()
    path = locvar(:fd_rpath)
    if (!isnothing(match(r"posts/.+", path)) && path !== "posts/index.html")

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
function hfun_tag_title(prefix = "Tag: ", default = "Tags")
    # NOTE: franklin as {{if else}} and {{isdef}}
    c = IOBuffer()
    write(c, "<div id=\"tag-name\">")
    let tag = locvar(:fd_tag)
        if tag != ""
            write(c, prefix)
            write(c, tag)
        else
            # write(c, locvar(:title))
            write(c, default)
        end
    end
    write(c, "</div>")
    String(take!(c))
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

### LD+JSON functions

function wrap_ldj(data::IdDict)
    "<script type=\"application/ld+json\">$(JSON.json(data))</script>"
end

function hfun_ldj_website()
    IdDict(
        "@context" => "https://schema.org/",
        "@type" => "WebSite",
        "@id" => "https://unto.re",
        "url" => locvar(:website_url),
        "copyrightHolder" => locvar(:author),
        "copyrightYear" => Dates.year(now()),
    ) |> wrap_ldj
end

function hfun_ldj_search()
    IdDict(
        "potentialAction" => IdDict(
            "@type" => "SearchAction",
            "target" => locvar(:website_url) * "/search?&q={query}",
            "query" => "required",
            "query-input" => "required maxlength=100 name=query",
            "actionStatus" => "https://schema.org/PotentialActionStatus",
        ),
    ) |> wrap_ldj
end

function hfun_ldj_place()
    IdDict(
        "homeLocation" => IdDict(
            "@type" => "https://schema.org/Place",
            "addressCountry" => locvar(:country),
            "addressRegion" => locvar(:region),
        ),
    ) |> wrap_ldj
end

function hfun_ldj_author()
    IdDict(
        "@type" => "https://schema.org/Person",
        "image" => locvar(:author_image),
        "name" => locvar(:author),
        "description" => locvar(:bio),
        "email" => locvar(:email),
        "sameAs" => [locvar(:github), locvar(:twitter)],
    ) |> wrap_ldj
end

function hfun_ldj_webpage()
    IdDict(
        "@type" => "https://schema.org/WebPage",
        "@id" => locvar(:fd_full_url),
        "identifier" => locvar(:fd_full_url),
        "url" => locvar(:fd_full_url),
        "lastReviewed" => locvar(:fd_mtime),
        "mainContentOfPage" =>
            IdDict("@type" => "WebPageElement", "cssSelector" => ".franklin-content"),
        "accessMode" => locvar(:accessMode),
        "accessModeSufficient" => IdDict(
            "@type" => "itemList",
            "itemListElement" => locvar(:accessModeSufficient),
            "description" => "text and images",
        ),
        "inLanguage" => locvar(:lang),
        "accessibilitySummary" => "Visual elements are tentatively described.",
        "audience" => "cool people",
        "author" => locvar(:author),
        "creativeWorkStatus" => "Published",
        "dateModified" => locvar(:fd_mtime),
        "dateCreated" => locvar(:fd_ctime),
        "datePublished" => locvar(:fd_ctime),
        "headline" => locvar(:title),
        "name" => locvar(:title),
        "abstract" => locvar(:rss_description),
        "description" => locvar(:rss_description),
        "availableLanguage" =>
            [IdDict("@type" => "Language", "name" => lang) for (lang, code) in locvar(:languages)],
        "keywords" => locvar(:tags),
        "mentions" => locvar(:mentions),
    ) |> wrap_ldj
end

function ldj_trans(file_path, lang)
    let url = replace(file_path, "__site" => joinpath(fr.locvar(:website_url), lang))
    IdDict(
        "@type" => "https://schema.org/WebPage",
        "@id" => url,
        "url" => url,
        "name" => fr.pagevar(file_path, :title),
        "abstract" => fr.pagevar(file_path, :rss_description),
        "description" => fr.pagevar(file_path, :rss_description),
        "headline" => fr.pagevar(file_path, :title),
        "keywords" => fr.pagevar(file_path, :tags),
        "mentions" => fr.pagevar(file_path, :mentions),
        "inLanguage" => lang,
        "translator" => IdDict("@type" => "https://schema.org/Organization",
                               "name" => "Google",
                               "url" => "https://translate.google.com/"),
        "translationOfWork" => IdDict("@id" => replace(file_path, "__site" => fr.locvar(:website_url)),
                                      )) |> wrap_ldj
    end
end


included_translate_dirs = Set(("posts", "tag", "reads", "_rss"))
using EzXML
using Gumbo
using AbstractTrees
include("translate.jl")
if isnothing(Translate.deep.mod)
    Translate.init(:deep)
end

extension(url::String) = try
    match(r"\.[A-Za-z0-9]+$", url).match
catch
    ""
end

@resumable function walkfiles(root; exts=Set((".md", ".html")),
                        dirs::Union{Set{String}, Nothing}=included_translate_dirs)
    """
iterate over files in a directory, recursively and selectively by extension name and dir name
"""
    for p in readdir(root)
        # directory, not excluded
        if isdir(p) && in(splitpath(f)[end], dirs)
            walkdir(p; exts, dirs)
            # file, only included
        elseif in(extension(splitpath(p)[end]), exts)
                @yield p
        end
    end
end

function translate_website(opt=true)
    if opt
        optimize()
    end
    rx = r"\.(html|md)$"
    for file in walkdir(".")
        let file_path = joinpath(dir, file)
            @show file_path
            continue
            if ! isnothing(match(rx, file_path))
                # for (lang, code) in fr.locvar(:languages)
                #     html = traverse_html(Gumbo.parsehtml(read(file_path, String)), file_path)
                #     mkdir(dirname(joinpath(file_path, code)))
                # end
                return traverse_html(Gumbo.parsehtml(read(file_path, String)), file_path, "it")
                # return html
                # end
            end
        end
    end
end

@doc """convert a "<script..." string to an `HTMLElement` """
function convert(T::Type{HTMLElement{:script}}, v::String)
    parsehtml(v).root[1][1]
end

function translate(str::String; src="en", target="it")
    let tr = Translate.deep.mod[:GoogleTranslator](source=src, target=target)
        Translate.translate(str, tr.translate)
    end
end

@doc """traverses a Gumbo HTMLDoc structure translating text nodes and "alt" attributes """
function traverse_html(data, path, lang)
    prev_type = Nothing
    script_type = HTMLElement{:script}
    head_type = HTMLElement{:head}
    insert_json = true
    ldj = convert(script_type, ldj_trans(path, lang))
    # use PreOrder to ensure we know if some text belong to a <script> tag
    for (n, el) in enumerate(PreOrderDFS(data.root))
        let tp = typeof(el)
            if insert_json && tp === head_type
                push!(el, ldj)
                insert_json = false
            end
            if tp === HTMLText
                # skip scripts
                if prev_type !== script_type
                    let trans = translate(el.text; target=lang)
                        # only replace if translation is successful
                        if ! isnothing(trans)
                            el.text = trans
                        end
                    end
                end
            elseif hasfield(tp, :attributes)
                # also translate "alt" attributes which should hold descriptions
                if haskey(el.attributes, "alt")
                    let trans = translate(el.attributes["alt"]; target=lang)
                        if ! isnothing(trans)
                            el.attributes["alt"] = trans
                        end
                    end
                end
            end
            prev_type  = tp
        end
    end
    Translate.update_translations()
    data
end

function hfun_insert_path(args)
    (pwd(), dirname(locvar(:fd_rpath)), args[1]) |> (x) -> joinpath(x...) |> readlines |> join
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
