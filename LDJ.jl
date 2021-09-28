
module LDJ

macro unimp(fname)
    quote
        function $(esc(fname))()
            throw("unimplemented")
        end
    end
end

@doc "Set properties (a (k, v) vector) to data (an dict)."
macro setprops!()
    quote
        pr = $(esc(:props))
        data = $(esc(:data))
        if !isempty(pr)
            for (p, v) in pr
	            data[p] = v
            end
        end
        data
    end
end

include("Content.jl")
using .Content

using Memoization
using ExportAll
    using Franklin
using Franklin: locvar, globvar, path;
const fr = Franklin;
using JSON
using Dates: Date, now, year, DateTime
# include("exporter.jl")

const DATE_FORMAT = "mm/dd/yyyy"
const EMPTY_DATE = Date("0001-01-01")

## LD+JSON functions
@inline function schema()
    "@context" => "https://schema.org"
end

@inline function get_date()
	let d = fr.locvar(:date)
        if d === EMPTY_DATE
            DateTime(2021, 1, 1)
        else
            DateTime(d, DATE_FORMAT)
        end
    end
end

@inline function wrap_ldj(data::IdDict)
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

@memoize function hfun_ldj_place()
    IdDict(
        "homeLocation" => IdDict(
            "@type" => "https://schema.org/Place",
            "addressCountry" => locvar(:country),
            "addressRegion" => locvar(:region),
        ),
    ) |> wrap_ldj
end

@memoize function author()
    IdDict(
        "@type" => "https://schema.org/Person",
        "image" => locvar(:author_image),
        "name" => locvar(:author),
        "description" => isdefined( @__MODULE__, :author_bio) ? author_bio() : "",
        "email" => locvar(:email),
        "sameAs" => [locvar(:github), locvar(:twitter)],
    )
end

@memoize function hfun_ldj_author()
    author() |> wrap_ldj
end

function publisher()
	author()
end

function hfun_ldj_publisher()
    hfun_ldj_author()
end

@memoize function get_languages()
    [IdDict("@type" => "Language", "name" => lang) for (lang, _) in locvar(:languages)]
end

function hfun_ldj_webpage()
    IdDict(
        "@context" => "https://schema.org",
        "@type" => "https://schema.org/WebPage",
        "@id" => locvar(:fd_full_url),
        "identifier" => locvar(:fd_full_url),
        "url" => locvar(:fd_full_url),
        "lastReviewed" => locvar(:fd_mtime_raw),
        "mainEntityOfPage" => IdDict(
            "@type" => "Article",
            "@id" => locvar(:fd_full_url)
        ),
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
        "author" => author(),
        "publisher" => publisher(),
        "creativeWorkStatus" => "Published",
        "dateModified" => locvar(:fd_mtime_raw),
        "dateCreated" => get_date(),
        "datePublished" => get_date(),
        "headline" => locvar(:title),
        "image" => locvar(:images),
        "name" => locvar(:title),
        "abstract" => locvar(:rss_description),
        "description" => locvar(:rss_description),
        "availableLanguage" => get_languages(),
        "keywords" => locvar(:tags),
        "mentions" => locvar(:mentions),
    ) |> wrap_ldj
end

@doc "file path must be relative to the project directory, assumes the published website is under '__site/'"
function ldj_trans(file_path, src_url, trg_url, lang)
    IdDict(
        "@type" => "https://schema.org/WebPage",
        "@id" => trg_url,
        "url" => trg_url,
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
        "translationOfWork" => IdDict("@id" => src_url)
    ) |> wrap_ldj
end

@doc """Take a list of (name, link) tuples and returns a breadcrumb
definition with hierarchy from top to bottom"""
function breadcrumbs(items)
    IdDict(
        "@type" => "BreadcrumbList",
        "itemListElement" => [
            IdDict(
                "@type" => "ListItem",
                "position" => n,
                "name" => name,
                "item" => item
            ) for (n, (name, item)) in enumerate(items)
                ]
    ) |> wrap_ldj
end

function hfun_ldj_crumbs()
    post_crumbs() |> breadcrumbs
end

Book = @NamedTuple begin
	name::String
    author::String
    url::String
    sameas::String
end

function book(name, author, url, tags, sameas)
    book = IdDict(                schema(),
                "@type" => "Book",
                "@id" => url,
                "url" => url,
                "urlTemplate" => url,
                "name" => name,
                "author" => IdDict(
                    "@type" => "Person",
                    "name" => author
                ),
                "sameAs" => sameas )
    !isempty(url) && begin
	    book["url"] = url
        book["@id"] = url
        book["urlTemplate"] = url
    end
    book
end

function bookfeed(books; props=[])
    data = IdDict(
        schema(),
        "@type" => "DataFeed",
        "dataFeedElement" => [book(b...) for b in books],)
    @setprops!
end

function hfun_ldj_book(args...; kwargs...)
	book(args...; kwargs...)
end

function event_status(status)
    let schema = "https://schema.org/Event"
        if status === "cancelled"
            schema * "Cancelled"
        elseif status === "moved"
            schema * "MovedOnline"
        elseif status === "postponed"
            schema * "Postponed"
        elseif status === "rescheduled"
            schema * "Rescheduled"
        else
            schema * "Scheduled"
        end
    end
end

function online_event(;name, start_date, end_date, url, image=[], desc="",
                      status="EventScheduled", prev_date="",
                      perf=IdDict(), org=IdDict(), offers=IdDict())
	IdDict(
        schema(),
        "@type" => "Event",
        "name" => name,
        "startDate" => start_date,
        "endDate" => end_date,
        "previousStartDate" => prev_date,
        "eventStatus" => event_status(status),
        "eventAttendanceMode" => "https://schema.org/OnlineEventAttendanceMode",
        "location" => IdDict(
            "@type" => "VirtualLocation",
            "url" => url
        ),
        "image" => image,
        "description" => desc,
        "offers" => offers,
        "performer" => perf,
        "organizer" => org)
end

function license(name="")
	if name === "mit"
        "https://en.wikipedia.org/wiki/MIT_License"
    elseif name === "apache"
        "https://en.wikipedia.org/wiki/Apache_License"
    elseif name === "gpl" || name === "gplv3"
        "https://www.gnu.org/licenses/gpl-3.0.html"
    elseif name === "gplv2"
        "https://www.gnu.org/licenses/old-licenses/gpl-2.0.html"
    elseif name === "sol"
        "https://wiki.p2pfoundation.net/Copysol_License"
    elseif name === "crypto" || name === "cal"
        "https://raw.githubusercontent.com/holochain/cryptographic-autonomy-license/master/README.md"
    else
        "https://creativecommons.org/publicdomain/zero/1.0/"
    end
end

function orgschema(name, url, contact="", tel="", email="", sameas="")
    IdDict(
        "@type" => "Organization",
        "name" => name,
        "url" => url,
        "sameAs" => sameas,
        "contactPoint" => IdDict(
            "@type" => "ContactPoint",
            "contactType" => contact,
            "telephone" => tel,
            "email" => email,))
end

function coverage(start_date, end_date="")
	start_date * "/" * (isempty(end_date) ? ".." : end_date)
end

function place_schema(coords="")
    IdDict(
        "@type" => "Place",
        "geo" => IdDict(
            "@type" => "GeoShape",
            "box" => coords
        )
    )
end

@doc "dist is a tuple of (format, url) for content format and download link"
function dataset(;name, url, desc="", sameas="", id="",
                 keywords=[], parts=[], license="", access=true,
                 creator=IdDict(), funder=IdDict(), catalog="", dist=[],
                 start_date="", end_date="", coords="")
    IdDict(
        schema(),
        "@type" => "Dataset",
        "name" => name,
        "url" => url,
        "description" => desc,
        "sameAs" => sameas,
        "identifier" => isempty(id) ? url : id,
        "keywords" => keywords,
        "hasPart" => parts,
        "license" => license,
        "isAccessibleForFree" => access,
        "creator" => creator,
        "funder" => funder,
        "includedInDataCatalog" => IdDict(
            "@type" => "DataCatalog",
            "name" => catalog
        ),
        "distribution" => [
            IdDict(
                "@type" => "DataDownload",
                "encodingFormat" => f,
                "contentUrl" => d
            ) for (f, d) in dist
                ],
        "temporalCoverage" => isempty(start_date) ? start_date : coverage(start_date, end_date),
        "spatialCoverage" => place_schema(coords)
    )
end


function faqschema(faqs)
    IdDict(
        schema(),
        "@type" => "FAQPage",
        "mainEntity" => [
            IdDict(
                "@type" => "Question",
                "name" => question,
                "acceptedAnswer" => IdDict(
                    "@type" => "Answer",
                    "text" => answer
                )
            ) for (question, answer) in faqs])
end

@doc "estimatedCost, MonetaryAmount (monetary) or Text"
function cost(type; currency="USD", value="0")
    if type === "monetary"
	    IdDict(
            "@type" => "MonetaryAmount",
            "currency" => currency,
            "value" => value
        )
    else
        type
    end
end

function image(url; width="", height="", license=(license="", acquire=""))
	IdDict(
        schema(),
        "@type" => "ImageObject",
        "url" => url,
        "width" => width,
        "height" => height,
        "license" => license.license,
        "acquireLicensePage" => license.acquire)
end

@doc "create an HowToSupply, HowToTool or HowToStep"
function howtoitem(name, type="supply"; props=[])
    if type === "supply"
        tp = "HowToSupply"
    elseif type === "item"
        tp = "HowToItem"
    elseif type === "direction"
        tp = "HowToDirection"
    elseif type === "tip"
        tp = "HowToTip"
    else
        tp = "HowToStep"
    end
    data = IdDict(
        "@type" => tp,
        "name" => name
    )
    @setprops!
end

function howto(;name, desc="", image=IdDict(),
               cost=(currency="USD", value=0), supply=[],
               tool=[], step=[], totaltime="")
	IdDict(
        schema(),
        "@type" => "HowTo",
        "name" => name,
        "description" => desc,
        "image" => image,
        "estimatedCost" => cost("monetary"; cost...),
        "supply" => supply,
        "tool" => tool,
        "step" => step,
        # https://en.wikipedia.org/wiki/ISO_8601#Durations
        "totalTime" => "")
end

function logo(;type="Organization", url, logo, props=[])
    data = IdDict(
        schema(),
        "@type" => type,
        "url" => url,
        "logo" => logo
    )
    @setprops!
end

function ratingprop(value, best, count)
    "aggregateRating" => IdDict(
        "@type" => "AggregateRating",
        "ratingValue" => value,
        "bestRating" => best,
        "ratingCount" => count)
end

function movie(;url, name, image="", created="", director="", rating="", review_author="", review="", props=[])
    data = IdDict(
        "@type" => "Movie",
        "url" => url,
        "name" => name,
        "image" => image,
        "dateCreated" => created,
        "director" => IdDict(
            "@type" => "Person",
            "name" => director,),
        "review" => IdDict(
            "@type" => "Review",
            "reviewRating" => IdDict(
                "@type" => "Rating",
                "ratingValue" => rating,),
            "author" => IdDict(
                "type" => "Person",
                "name" => review_author
            ),
            "reviewBody" => review,))
    @setprops!
end

function itemslist(items)
    IdDict(
        schema(),
        "@type" => "ItemList",
        "itemListElement" => items
    )
end

function review(;name, rating="", author="", review="", org=[],
                item_props=[], props=[])
    data = IdDict(
        schema(),
        "@type" => "Review",
        "itemReviewed" => IdDict(p => v for (p, v) in item_props) ,
        "reviewRating" => IdDict(
            "@type" => "Rating",
            "ratingvalue" =>  rating,
        ),
        "name" => name,
        "author" => IdDict(
            "@type" => "Person",
            "name" => author
        ),
        "reviewBody" => review,
        "publisher" => orgschema(org...)
    )
    @setprops!
end

function searchaction(;url, template, query, props=[])
    data = IdDict(
        schema(),
        "@type" => "WebSite",
        "url" => url,
        "potentialAction" => IdDict(
            "@type" => "SearchAction",
            "target" => IdDict(
                "@type" => "EntryPoint",
                "urlTemplate" => template,),
            "query-input" => "required " * query))
    @setprops!
end

function speakable(;name, url, css::AbstractVector)
    IdDict(
        schema(),
        "@type" => "WebPage",
        "name" => name,
        "speakable" => IdDict(
            "@type" => "SpeakableSpecification",
            "cssSelector" => css
        ),
        "url" => url
    )
end

function pubevents(events)
    [IdDict(
        "@type" => "BroadcastEvent",
        "isLiveBroadcast" => true,
        "startDate" => start_date,
        "endDate" => end_date) for (start_date, end_date) in events]
end

function video(;name, url, desc="", duration="", embed="",
               expire="", regions="", views, thumbnail="", date="", pubevents=[])
    IdDict(
        schema(),
        "@type" => "VideoObject",
        "contentURL" => url,
        "description" => desc,
        "duration" => duration,
        "embedURL" => embed,
        "expires" => expire,
        "regionsAllowed" => regions,
        "interactionStatistic" => IdDict(
            "@type" => "InteractionCounter",
            "interactionType" => IdDict("@type" => "WatchAction"),
            "userInteractionCount" => views,
        ),
        "name" => name,
        "thumbnailUrl" => thumbnail,
        "uploadDate" => date,
        "publication" => pubevents
    )
end

@unimp jobtraining

@unimp jobposting

@unimp business

@unimp factcheck

@unimp mathsolver

@unimp practiceproblems

@unimp product

@unimp qapage

@unimp recipe

@unimp softwareapp

@unimp subscription

# exportall()
@exportAll()

end
