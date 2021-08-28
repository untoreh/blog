
module LDJ

using ExportAll
using Franklin
using Franklin: locvar, globvar, path;
const fr = Franklin;
using JSON
using Dates: Date, now, year
# include("exporter.jl")

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
        "copyrightYear" => year(now()),
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
        "description" => read(path(:assets) * "/bio.md", String) |> x -> fr.convert_md(x; isinternal=true),
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

@doc "file path must be relative to the project directory, assumes the published website is under '__site/'"
function ldj_trans(file_path, url_path, lang)
    let url = joinpath(fr.globvar(:website_url), lang, url_path)
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

# exportall()
@exportAll()

end
