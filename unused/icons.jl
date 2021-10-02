using Cascadia
# conflict with ezxml
import Gumbo
using HTTP
using StringDistances
"""
This is a failed attempt at programmatic fetching of icon by tag name, without context, results are poor.
"""

@doc """ Reads the font-awesome src url from foot.html """
function _fa_url()
    s = Selector("#fa")
    html = Gumbo.parsehtml(read("_layout/foot.html", String))
    url = eachmatch(s, html.root) |>
        first |>
        (x) -> getattr(x, "src")
end

@doc """ Parses the font-awesome version from the url string"""
function _fa_version(url)
    v_rgx = r"\/v([0-9\.]+)\/"
    match(v_rgx, url)[1]
end

cache_dir = "__cache"
fa_file = joinpath(cache_dir, "fa.css")
fa_version_file = joinpath(cache_dir, "fa-version.txt")
fa_names_file = joinpath(cache_dir, "fa-names.txt")

@doc """ Updates the font-awesome css local file if different from the stored one """
function _cache_fa_css()
    url = _fa_url()
    v = _fa_version(url)
    if isfile(fa_file) &&
        read(fa_version_file, String) == v
        return nothing
    else
        try mkdir(dirname(fa_file)) catch end
        println("fetching font-awesome css...")
        body = HTTP.get(url)
        write(fa_file, body)
        write(fa_version_file, v)
        println("font-awesome css cached successfully")
        return true
    end
end


@doc """
Parses icons names from font-awesome css file and saves them
"""
function _save_icons_names()
    names_rgx = r"\],([a-z]+)\:\["
    css = read(fa_file, String)
    open(fa_names_file, "w") do f
        for m in eachmatch(names_rgx, css)
            write(f, m[1] * "\n")
        end
    end
end

@doc """
Get font-awesome list of icons names fetching the font-awesome css file if not found
"""
function get_icons_names()
    new = _cache_fa_css()
    !isnothing(new) && _save_icons_names()
    readlines(fa_names_file)
end

function icon_element(name, type="b")
    """<i class="fa fa-$name icon"></i>"""
end

@doc """
Search for an icon from the given string
Jaro() < 0.2
"""
function get_icon(str, names=nothing::Union{Nothing, Array{String}}) ::Union{String, Nothing}
    if isnothing(names)
        names = get_icons_names()
    end
    j = Jaro()
    for n in names
        if j(str, n) < 0.2
            return icon_element(n)
        end
    end
    ""
end
