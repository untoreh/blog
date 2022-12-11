+++
date = "11/18/2022"
title = "Building a content aggregator for fun and profits?"
tags = ["apps", "programming", "software"]
rss_description = "A full app that scrapes, processes and presents content from the web...on the web."
+++

# Why?
[Information overload](https://en.wikipedia.org/wiki/Information_overload)? It is kinda bad these days, a lot of low signal to noise sources of information, narrowing down your "feeds" such that you don't get overwhelmed is kinda hard. A tool that filters information and presents it in a format that is both easy and quick to digest would be very much useful.
This is why I consider *content aggregation* an evergreen field for disruption. It is and will always be (as long as the internet is free and there is free speech) a good business opportunity. It is one of those instances where its all about the execution (and none at all about the idea).

# Managing expectations
Having said that, my app in the end doesn't do any actual filtering. In fact it simply *aggregates* content from the web. This is because I didn't build users into it, and there is little incentive on doing filtering if it can't be tailored per user.

# The architecture
The diagram of the architecture:
\imgc{content-aggregator-diagram.png}
There are indeed many circles in it!...you know...micro...services?
The apps that I built are the "scraper" and the "server", while the "publisher" is just a routine embedded in the server. The "search" and "proxies" are external tools that do their job. "Frontend" is nothing special, a mix of js and css bundled with webpack.

Since there are different moving parts I will go according to the flow of the content, starting from when the content is seen for the first time.

# The Scraper
Scraping is done in...you guessed it, python. However no ad hoc "scraping" modules are used.
## What do you scrape?
Deciding what to scrape depends on the category of the content. We call categories "topics". 
- Every topic has a list of keywords. 
- The list of keywords if pulled from google adwords using their [python api](https://github.com/googleads/google-ads-python)
- The keywords are queried on multiple search engines, in a round robin order periodically. If the instance has multiple topics, the topics with less available content are searched first. For performing the searches we rely on [searx](https://github.com/searxng/searxng) with proxies. Searx is not exactly library friendly, since its primary use is for its frontend so it required digging through the correct process to initialize the module to perform queries. To speed things up with use the threadpool to perform multiple queries concurrently, we will use the threadpool frequently throughout the project.
- Every keyword search generates a list of potential content sources (The search engines results) which are saved on storage for later processing.
- When we want to find new content for a specific topic we first check if there are available sources, otherwise we generate new sources from the keyword list.
  \imgc{content-pipeline.png}
- Sources are processed through two libraries [trafilatura](https://github.com/adbar/trafilatura) is the main one, if it fails we backup to [goose](https://github.com/goose3/goose3). We also try to find feeds for additional links (which would be considered new sources). For feeds we use [feedfinder](https://github.com/dfm/feedfinder2) but a simple parsing of the html for rss `link` tags would also suffice.
- Our main content type is an `Article`, which from python side it's just a dict, from nim side with parse it as an object. Keys:
  - `title`: the header of the article
  - `content`: the article itself. To determine what's a good article we go through different filtering steps:
    - First we check if either trafilatura or goose have text and if it is long enough. Our minimum size is 300 words. If the size isn't matched, we discard the source (return nothing).
    - Then we fetch the title, and sanitize it by removing urls and whitespaces
    - If the lang is foreign, we translate it back to english (we normalize over english) both content and title.
    - At this point we check for profanity using [profanity_check](https://github.com/dimitrismistriotis/alt-profanity-check). Not that profanity checking is english based to the previous translation is necessary. Otherwise we would need a profanity model for all languages.
    - After we have replaced bad words using profanity filter, we continue by sanitizing the content. We check if the article is relevant. There rules that we use are:
      - The content must start with alphanumeric characters, otherwise there is a high change that it is garbage.
      - Both title and content can't be "noise". Noise is defined by a regex that captures keywords like "login", "signup", "access denied"...etc.
      - At least one word in the title must be present in the body. Otherwise it is possible that parsing chose the wrong parts of the source page for content.
    - If relevance tests have passed, as final step we clean the content against occurrences of too many brackets, white-space, repeated characters and special characters.
    - If cleaning hasn't deleted everything we continue processing the article.
  - `source`: the link pointing to the original source that we parsed
  - `lang`: the language of the article, we use [lingua](https://github.com/pemistahl/lingua-py) to detect the language
  - `desc`: the summary, otherwise an excerpt from the content
  - `author`: the author, otherwise the title of the homepage of the sourcelink
  - `pubDate`: the publishing date of the article, or now
  - `topic`: the topic to which this article belongs to
  - `tags`: relevant keywords for an article, we use the fastest kw extraction lib, which is [rake](https://github.com/csurfer/rake-nltk), alternatives considered are [pyate](https://github.com/kevinlu1248/pyate)(combobasic), [textrank](https://github.com/DerwenAI/pytextrank) and [phrasemachine](https://github.com/slanglab/phrasemachine)
  - `imageTitle`: the alternate text for the image
  - `imageOrigin`: if source parsing (for images we use [lassie](https://github.com/michaelhelmick/lassie)) hasn't found an image, we query search engines for a relevant image, so imageOrigin points to the original page which hosted the image, otherwise it is equal to the source url. 
  - `imageUrl`:  the actual link to the image. We use a bloom filter check for duplicate images, because we don't like duplicates.
  - `icon`: the favicon of the source link
- After we have processed a keyword, we save its found articles and feeds on storage. They will be used by the publsher.
Scraping happens continuously, it's a demon. The main loop pseudo code looks like this, and it is configured _per site_:
- sync proxies forever
- for each topic sorted by unpublished (articles) count (low to high) do the following
  - if minimum interval from last job passed, run a parse job for the topic. The interval increases the more unpublished articles we have for a topic, and is always 0 if we don't have any unpublished articles.
  - Do the same but for feeds (that we collected from sources, if we have any)
  - If the site is meant to create new topics, create one. (This only makes sense if you don't decide the topics list at site creation.)
  - Choose an article from the published ones and send a tweet (we send 3 tweets per day, using [python-twitter](https://github.com/bear/python-twitter))
  - Choose an article from the published ones and update a facebook page (we do 1 update per day, using [facepy](https://github.com/jgorset/facepy))
  (We also connected reddit, but reddit does not allow cross posting, so it was a wasted effort.)
  
# Publishing
Once we have content to publish, we have to decide what to publish and how often. I didn't come up with any tricks here, because as I mentioned previously choosing what to display is user dependent. So we just publish from _newest to oldest_, with the reasoning that something that we scraped more recently is more relevant, it is a [LIFO](https://en.wikipedia.org/wiki/Stack_(abstract_data_type)) queue.
Publishing although quite reliant on python tools, happens in nim, because it runs adjactently to the server, which is also in nim.
## The publishing logic
Publishing happens continuously, and like scraping has idle intervals, publishing does to, in an inversely to scraping. When we scrape, we slow down when we have a _long enough_ cache of unpublished articles, with publishing we slow down when our cache starts to shrink too much. In this way, coupled with scraping, there should always be _some content_ to be published _some time_ in the future.
The actual publishing logic:
- Fetch a batch of unpublished articles from the cache. (We choose to publish 3 new articles per run.)
- Check if they are duplicates. Dup checking is done through locality sensitive hashing, leveraging a nim lib, [minhash](https://github.com/Nim-NLP/minhash/). LSH is quite CPU intensive (you know...hashing), and requires its own thread, (there are a couple other task that we handle that require their own threads).
- Page rendering: this is not required, since the server handles queries on-the-fly, but rendering here is a form of pre-caching.
- Page handling. Since we are dealing with a site we have to choose how many articles to display per page, and increment pages as we publish more articles. We choose to group articles in pages of ~10. The latest page are always less than 10 articles.
- Save the state of the published articles, this means moving the articles from "unpublished" to "published" status, and the LSH database.
- After publishing new articles we have to clear stale caches. We have to clear the homepage, the topic page and the sitemap and rss feed.

# Serving
We setup jobs to both scrape a publish content, all that's left is serving it.
## The web server
After having [tried](https://github.com/dom96/jester) [different](https://github.com/dom96/httpbeast) [web](https://github.com/olliNiinivaara/GuildenStern/) [servers](https://github.com/status-im/nim-chronos/blob/master/chronos/apps/http/httpserver.nim), because of different bugs I settled with [scorper](https://github.com/bung87/scorper).
## Handling a request
### The router
We use nim [pattern matching implementation](https://nim-lang.github.io/fusion/src/fusion/matching.html) to match a tuple of regex captures.
This is the regex which is not RESTful at all:

```nim

const
  rxend = "(?=/+|(?=[?].*)|$)"
  rxAmp = fmt"(/+amp{rxend})"
  rxLang = "(/[a-z]{2}(?:-[A-Z]{2})?" & fmt"{rxend})" # split to avoid formatting regex `{}` usage
  rxTopic = fmt"(/+.*?{rxend})"
  rxPage = fmt"(/+(?:[0-9]+|s|g|feed\.xml|sitemap\.xml){rxend})"
  rxArt = fmt"(/+.*?{rxend})"
  rxPath = fmt"{rxAmp}?{rxLang}?{rxTopic}?{rxPage}?{rxArt}?"
```
`rxPath` shows all the possible nodes that a path can have.
Then our routing looks like:

```nim
let capts = uriTuple(reqCtx.url.path)
case capts:
  of (topic: ""): # homepage...
  of (topic: "assets"): # assets
  of (topic: "i"): # images
  of (topic: "robots.txt"): # robots.txt
  of (page: "sitemap.xml"): # sitemap for topics
  of (art: "index.xml"): # sitemap index for topic pages
  etc...
```

Its not pretty, but not relying on any particular router allowed me to swap underling web server without much fuss when testing. Is it performant? Unclear! Haven't done any benchmarks comparing it to something else. However what smells is ofc the regex that can have bugs, and the fact that the ordering of the cases matters.
> Wait a minute...
There is a bunch of stuff that we do on each request before actual page routing:

initially we setup cleanup code (with `defer:`) which _should_ ensure no leaks happen.

```nim
defer:
  # FIXME: is this cleanup required?
  var futs: seq[Future[void]]
  let resp =
    if ctx.response.issome: ctx.response.get
    else: nil
  if not resp.isnil and not resp.connection.isnil:
    futs.add resp.connection.closeWait()
  if not ctx.isnil:
    if not ctx.connection.isnil:
      futs.add ctx.connection.closeWait()
    futs.add ctx.closeWait()
  await allFutures(futs)
```
We check if the thread is initialized:

```nim
initThread()
```
This should really only run once (it sets a global bool after initialization to check), and could be done outside the request handler.
But what is actually initialized? Well...quite a lot of stuff! Basically we (ab)use global constants
which require initialization, also some of this are not really thread related, since they initialize memory on the heap and is shared across thread

```nim
if threadInitialized:
  debug "thread: already initialized"
  return
debug "thread: base"
initThreadBase()
debug "thread: sonic"
initSonic() # Must be on top
debug "thread: http"
initHttp()
debug "thread: html"
initHtml()
debug "thread: ldj"
initLDJ()
debug "thread: feed"
initFeed()
debug "thread: img"
startImgFlow()
debug "thread: lsh"
startLsh()
debug "thread: mimes"
initMimes()
# ... and other stuff
```

Then we parse the parameters

```nim
var
  relpath = ctx.rawPath
  page: string
  rqlocked: bool
relpath.removeSuffix('/')
debug "handling: {relpath:.120}"

handleParams()
```

What do we use parameters for? The `ParamKey` enum type describes it:

```nim
type
  ParamKey = enum
    none,
    q, p, # sonic
    c, # cache
    d, # delete
    t,  # translations
    u # imgUrls
```

We do _microcaching_ for requests so every request is cached according to the tuple `(path, query, accetEncoding)`, encoding is required because we can serve both (non)compressed bodies.
A request context looks like this:

```nim
let reqCtx = reqCtxCache.lcheckOrPut(reqCacheKey):
  let reqCtx {.gensym.} = new(ReqContext)
  block:
    let l = newAsyncLock()
    checkNil(l):
      reqCtx.lock = l
  reqCtx.url = move url
  reqCtx.params = params
  reqCtx.file = reqCtx.url.path.fp
  reqCtx.key = hash(reqCtx.file)
  reqCtx.rq = initTable[ReqId, HttpRequestRef]()
  new(reqCtx.respBody)
  reqCtx
```
- The `key` field is used to fetch the correct cached page (body) from `pageCache`. The lock is required to ensure that multiple requests happening at the same time don't duplicate rendering jobs (if another request is already generating the page, wait for it to finish). Every base `HttpRequestRef` from the chronos httpserver is stored in the `rq` field. The `params` are already parsed from the previous `handleParams`.
- We support content deletion through the `d` param, which allows us to nuke articles (in case the filtering failed, but it should never be used in practice, just for debugging) with a simple http get request. Who needs other http methods? Not me.
- We support cache clear too. We can either delete the page, `c=0` or all the pages `c=1`. The annoying bits is that we have to check if the path is either an article, a page, an image or an assets, and purge the appropriate cache structure. There is some obvious logic duplication here with the router, but since this is done pre-routing, it has to be ad-hoc, handling only cases relevant for cache purging. It is done pre-routing because also the cache is served without routing, since if the request has already been generated, we can just reply with the body stored in the `respBody` field (and `respHeaders`, `respCode`).
- After handling cache operations, we parse the path.
- After this there is another hijacking going on:
```nim
if handleTranslation():
  return
```
Why is this also done before routing? By default we serve partially translated pages. We are poor :( and translations are based on free services, but we can't afford abysmal load times, so we run the translation deferred while we serve the page translated with only snippets that have been cached in our translations database.

At this point there is the routing, wrapped in an exception such that if serving the correct page fails, we issue a `503`. Issuing a `503` implies that we tried to route a valid url but we couldn't generate a page. For invalid urls we issue a `301` redirect which implies that the url is not valid.
We serve 11 different kind of urls:
- homepage: pulls articles from the most recent topics, pseudo randomly, we don't do any sorting based on popularity.
- generic assets (under `/assets/` path): are directly mapped to a dedicated directory
- generic images (under `/i/` pah): we proxy external images to generate sizes that fit our responsive website, when images are unavailable either a transparent pixel or image icon is served as default.
- robots.txt file
- sitemaps (for homepage and topics and pages): The homepage hosts the sitemapindex pointing to all the topics sitemaps, the topics sitemaps points to all the pages of the topic, the pages sitemap points to all the articles of the page.
- pwa manifest: the pwa manifest should allow the website to be installed as pwa (but frankly haven't tested this)
- searches: The search leverages [sonic](https://github.com/valeriansaliou/sonic) with the [pysonic](https://github.com/alongwy/pysonic) bindings. 
- suggestions: Suggestions are also handled through sonic libraries. But they require 
- feeds: Like sitemaps we have different feeds for the homepage, and for the different topics, although no feeds for singular pages for obvious reasons.
- topic pages: The page dedicated to each topics (e.g. with path `domain.com/my-topic/`) Pulls the latest articles published for the topic, which belong to an _unfinished_ page.
- articles pages: The article page shows the article title, description, source link, tags, published time (in the footer) and at the bottom we pull 3 related articles. The related articles are fetched using a search query on the article title or tags.

## About the rendering
Page rendering is processed from nim side using [karax](https://github.com/karaxnim/karax)
### General page layout
The website is composed of a top fixed bar which shows:
- the homepage url, through the logo svg image.
- the light/dark theme button
- current url using the current path *crumbs* as link text
- the most recent ~10 topics urls
- The search bar (with search button), where when typed suggestions pop up
- the languages button, where when clicked, the list of languages floats up
Since it is a responsive design, when the viewport is smaller, the top bar only holds the search box while the rest appears in a togglable sidebar.
- The footer, holding links for the sitemap, rss, socials, legal
- Ads at different locations are supported

## RSS
This is an example function, shows what we do when a new post is published to update the feed:

```nim
proc update*(tfeed: Feed, topic: string, newArts: seq[Article], dowrite = false) =
    ## Load existing feed for given topic and update the feed (in-memory)
    ## with the new articles provided, it does not write to storage.
    checkNil tfeed
    let
        chann = tfeed.findel("channel")
        itms = chann.drainChannel
        arl = itms.len
        narl = newArts.len

    debug "rss: newArts: {narl}, previous: {arl}"
    let
        fill = RSS_N_ITEMS - arl
        rem = max(0, narl - fill)
        shrinked = if (rem > 0 and arl > 0):
                       itms[0..<(max(0, arl-rem))]
                   else: itms
    debug "rss: articles tail len {len(shrinked)}, newarts: {len(newArts)}"
    assert shrinked.len + narl <= RSS_N_ITEMS, fmt"shrinked: {shrinked.len}, newarticles: {narl}"
    for a in newArts:
        chann.add articleItem(a)
    for itm in shrinked:
        chann.add itm
    if dowrite:
   
        pageCache[][topic.feedKey] = tfeed.toXmlString
```

## Sitemaps
This is the core of adding urls to sitemaps:

```nim
template addUrlToFeed(getLoc, getLocLang) =
  if unlikely(nEntries > maxEntries):
      warn "Number of URLs for sitemap of topic: {topic} exceeds limit! {nEntries}/{maxEntries}"
      break
  let
      url = newElement("url")
      loc = newElement("loc")
  loc.add getLoc().escape.newText
  url.add loc
  addLangs(url, getLocLang)
  result.add url

proc buildTopicPagesSitemap*(topic: string): Future[XmlNode] {.async.} =
    initSitemapIndex()
    await syncTopics()
    var nEntries = 0
    let done = await topicDonePages(topic)
    template langUrl(lang): untyped {.dirty.} = $(WEBSITE_URL / lang / topic / pages[n])
    withPyLock:
        # add the most recent articles first (pages with higher idx)
        let pages = pybi[].list(done.keys()).to(seq[string])
        for n in countDown(pages.len - 1, 0):
          if not (await isEmptyPage(topic, pages[n].parseInt, false)):
            discard sitemapUrl(topic, pages[n]).sitemapEl

template addArticleToFeed() =
  template baseUrl(): untyped =
    getArticleUrl(a, topic)

  template langUrl(lang): untyped =
    getArticleUrl(a, topic, lang)

  if not a.isValidArticlePy:
      continue

  addUrlToFeed(baseUrl, langUrl)

proc buildTopicSitemap(topic: string): Future[XmlNode] {.async.} =
    initUrlSet()
    await syncTopics()
    let done = await topicDonePages(topic)
    var nEntries = 0
    withPyLock:
        # add the most recent articles first (pages with higher idx)
        for pagenum in countDown(len(done) - 1, 0):
            if unlikely(nEntries > maxEntries):
                warn "Number of URLs for sitemap of topic: {topic} exceeds limit! {nEntries}/{maxEntries}"
                break
            checkTrue pagenum in done, "Mismatching number of pages"
            for a in done[pagenum]:
                addArticleToFeed()
```

## Templates
We don't use a template engine since most of the rendering is done with karax, but for pages like ToS we use file templates, where we just replace a bunch of variables, like an `envsubst` command.

```nim
proc pageFromTemplate*(tpl, lang, amp: string): Future[string] {.async.} =
  var txt = await readfileAsync(ASSETS_PATH / "templates" / tpl & ".html")
  let (vars, title, desc) =
    case tpl:
      of "dmca": (tplRep, "DMCA", fmt"dmca compliance for {WEBSITE_DOMAIN}")
      of "tos": (ppRep, "Terms of Service",
          fmt"Terms of Service for {WEBSITE_DOMAIN}")
      of "privacy-policy": (ppRep, "Privacy Policy",
          fmt"Privacy Policy for {WEBSITE_DOMAIN}")
      else: (tplRep, tpl, "")
  txt = multiReplace(txt, vars)
  let
    slug = slugify(title)
    page = await buildPage(title = title, content = txt, wrap = true)
  checkNil(page):
    let processed = await processPage(lang, amp, page, relpath = tpl)
    checkNil(processed, fmt"failed to process template {tpl}, {lang}, {amp}"):
      return processed.asHtml(minify_css = (amp == ""))
```

## Articles pages
When we render pages like home/topics and numbered pages we have to show a list of articles, this function is called in a loop for how many articles we want to show:

```nim
import htmlparser
proc articleEntry(ar: Article, topic = ""): Future[VNode] {.async.} =
  if ar.topic == "" and topic != "":
    ar.topic = topic
  let relpath = getArticlePath(ar)
  try:
    return buildHtml(article(class = "entry")):
      h2(class = "entry-title", id = ar.slug):
        a(href = relpath):
          text ar.title
      tdiv(class = "entry-info"):
        span(class = "entry-author"):
          text ar.getAuthor & ", "
        time(class = "entry-date", datetime = ($ar.pubDate)):
          italic:
            text format(ar.pubDate, "dd/MMM")
      tdiv(class = "entry-tags"):
        if ar.tags.len == 0:
          span(class = "entry-tag-name"):
            a(href = (await nextAdsLink()), target = "_blank"):
              icon("i-mdi-tag")
              text "none"
        else:
          for t in ar.tags:
            if likely(t.isSomething):
              span(class = "entry-tag-name"):
                a(href = (await nextAdsLink()), target = "_blank"):
                  icon("i-mdi-tag")
                  text t
      buildImgUrl(ar)
      tdiv(class = "entry-content"):
        verbatim(articleExcerpt(ar))
        a(class = "entry-more", href = relpath):
          text "[continue]"
      hr()
  except Exception as e:
    logexc()
    warn "articles: entry creation failed."
    raise e

proc buildShortPosts*(arts: seq[Article], topic = ""): Future[
    string] {.async.} =
  for a in arts:
    result.add $(await articleEntry(a, topic))
```
Note how in some lines "ads" creep in X)

## Topics list
In the top bar we show the topics list, this is what prints it:

```nim
proc topicsList*(ucls: string; icls: string; small: static[
    bool] = true): Future[VNode] {.async.} =
  result = newVNode(VNodeKind.ul)
  result.setAttr("class", ucls)
  let topics = await loadTopics(-MENU_TOPICS) # NOTE: the sign is negative, we load the most recent N topics
  result.add buildHtml(tdiv(class = "topics-shadow"))
  var topic_slug, topic_name: string
  var isEmpty: bool
  for i in 0..<topics.len:
    withPyLock:
      (topic_slug, topic_name) = ($topics[i][0], $topics[i][1])
      isEmpty = isEmptyTopic(topic_slug)
    if isEmpty:
      continue
    let liNode = buildHtml(li(class = fmt"{icls}")):
      # tdiv(class = "mdc-icon-button__ripple") # not used without material icons
      a(href = ($(WEBSITE_URL / topic_slug)), title = topic_name,
          class = "mdc-ripple-button"):
        tdiv(class = "mdc-ripple-surface  mdc-ripple-upgraded")
        when small:
          # only use the first letter
          text $topic_name.runeAt(0).toUpper # loadTopics iterator returns pyobjects
        else:
          text topic_name
      when small:
        br()
      else:
        span(class = "separator")
    result.add liNode

```
There are some smelly hard coded material design classes in here. Frankly google material design components suck.

## Post footer
The post footer appears at bottom right of an article page (in ltr) and it really only prints the published date.

```nim
proc postFooter(pubdate: Time): VNode =
  let dt = inZone(pubdate, utc())
  buildHtml(tdiv(class = "post-footer")):
    time(datetime = ($dt)):
      text "Published date: "
      italic:
        text format(dt, "dd MMM yyyy")
```

## Excerpts
When building article entries we might need excerpts if no summary is available.
```nim
proc articleExcerpt(a: Article): string =
  let alen = len(a.content) - 1
  let maxlen = min(alen, ARTICLE_EXCERPT_SIZE)
  if maxlen == alen:
    return a.content
  else:
    let runesize = runeLenAt(a.content, maxlen)
    # If article contains html tags, the excerpt might have broken html
    return parseHtml(a.content[0..maxlen+runesize]).innerText & "..."
```
Wtf is `parseHtml` doing here? It is the case that we allow html inside article contents (but only some tags), this is an option from the python module trafilatura, that we keep enabled because it can affects article format. We also have to be careful about chunking utf-8 strings...

## Minification
The last task after having built the karax `VNode` tree is to dump the bytes. The tree if prefixed with the html header, and optionally minified. 

```nim
proc asHtml*(data: string ; minify: static[bool] = true; minify_css: bool = true): string =
  let html = "<!DOCTYPE html>" & "\n" & data
  sdebug "html: raw size {len(html)}"
  result = when minify:
             html.minifyHtml(minify_css = false,
                             minify_js = false,
                             keep_closing_tags = true,
                             do_not_minify_doctype = true,
                             keep_spaces_between_attributes = true,
                             ensure_spec_compliant_unquoted_attribute_values = true)
           else:
             html
  sdebug "html: minified size {len(result)}"
```

The minification is handled by [minify-html](https://github.com/wilsonzlin/minify-html) which we have bound using [c2nim](https://github.com/nim-lang/c2nim), the binding file contains:

```nim
proc minify*(code: cstring,
             do_not_minify_doctype = false,
             ensure_spec_compliant_unquoted_attribute_values = false,
             keep_closing_tags = true,
             keep_comments = false,
             keep_html_and_head_opening_tags = true,
             keep_spaces_between_attributes = false,
             minify_css = true,
             minify_js = true,
             remove_bangs = false,
             remove_processing_instructions = true): cstring {.importc: "minify".}

proc minifyHtml*(tree: VNode): string = $minify(($tree).cstring)
proc minifyHtml*(data: string): string = $minify(data.cstring)
template minifyHtml*(data: string, args: varargs[untyped]): string =
    $minify(data.cstring, args)
```
But for building we have to provide the static libraries, adding this line in our `nim.cfg`

```toml
--passL:"$PROJECT_DIR/src/rust/target/release/libminify_html_c.a"
```

I mean...that's my path were I built the minify library which _btw_ doesn't actually have an extern c function which nim can consume, so we had to write it ourselves.

```rust
use minify_html::{Cfg, minify as minify_html_native};
use std::ffi::CStr;
use std::ffi::CString;
use std::os::raw::c_char;

#[no_mangle]
pub extern "C" fn minify(
    code: *const c_char,
    do_not_minify_doctype: bool,
    ensure_spec_compliant_unquoted_attribute_values: bool,
    keep_closing_tags: bool,
    keep_comments: bool,
    keep_html_and_head_opening_tags: bool,
    keep_spaces_between_attributes: bool,
    minify_css: bool,
    minify_js: bool,
    remove_bangs: bool,
    remove_processing_instructions: bool,
) -> *const c_char {

    let code = unsafe { CStr::from_ptr(code) };
    let code_vec = code.to_bytes();

    let cfg = Cfg {
        do_not_minify_doctype,
        ensure_spec_compliant_unquoted_attribute_values,
        keep_closing_tags,
        keep_comments,
        keep_html_and_head_opening_tags,
        keep_spaces_between_attributes,
        minify_css,
        minify_js,
        remove_bangs,
        remove_processing_instructions,
    };

    let minified = minify_html_native(code_vec, &cfg);

    let s = unsafe { CString::from_vec_unchecked(minified).into_raw() };
    return s;
}
```

# Nimpy and the quest for crash free garbage deletion
[Python bindings for nim](https://github.com/yglukhov/nimpy/) have to ofc free discard python objects. The problem is that we have to control when nim does GC. The nimpy library assumes the GIL is always locked (it locks it at the beginning), to it is free to call to python whenever. But we unlock the gil in order to allow a python threadpool to run code while nim runs other stuff. If the python GIL was always locked by nim the threadpool would be idle most of time.

```nim
when defined(pyAsync):
  type
    PyGilObj = object
      lock: ThreadLock
      currentLockHolder: int
      state: PyGILState_STATE
    PyGil = ptr PyGilObj

  var pyGil*: PyGil
  var pyGilLock*: ThreadLock
  var pyMainThread: PyThreadState
  proc initPyGil*() =
    assert PyGILState_Check()
    pyGil = create(PyGilObj)
    pyGil.currentLockHolder = getThreadID()
    pyGil.lock = newThreadLock()
    pyGilLock = pyGil.lock
    pyMainThread = PyEval_SaveThread()

  proc acquire*(gil: PyGil): Future[void] {.async.} =
    await gil.lock.acquire
    let id = getThreadId()
    gil.currentLockHolder = id
    gil.state = Py_GILState_Ensure()

  proc tryAcquire*(gil: PyGil): bool =
    if gil.lock.tryAcquire():
      let id = getThreadId()
      gil.currentLockHolder = id
      gil.state = Py_GILState_Ensure()
      return true

  proc release*(gil: PyGil) {.inline.} =
    doassert gil.currentLockHolder == getThreadId(), "Can't release gil lock from a different thread."
    doassert gilLocked()
    Py_GILState_Release(gil.state)
    gil.lock.release
```

This allows how to execute python code holding the GIL, but only on the current thread. The implementation for acquiring/releasing the GIL on different nim threads requires calling different python C abi functions, because the GIL is a mutex.
We then call python using this template:

```nim
template withPyLock*(code): untyped =
  {.locks: [pyGil].}:
    try:
      # echo getThreadId(), " -- ", getCurrentProcessId(), " -- ", procName()
      await pygil.acquire()
      code
    except:
      raise getCurrentException()
    finally:
      # echo getThreadId(), " -- ", getCurrentProcessId(),  " -- unlocked"
      pygil.release()
```

We make use of the nim locks and guards feature, to ensure python types are only accessed when the GIL is held. However this requires defining pyobjects with the guard:

```nim
macro pyObjPtr*(defs: varargs[untyped]): untyped =
  result = newNimNode(nnkStmtList)
  for d in defs:
    let
      name = d[0]
      def = d[1]
    result.add quote do:
      let `name` {.guard: pyGil.} = create(PyObject)
      `name`[] = `def`
```

So I can do:

```nim
pyObjPtr(myVar, pyimport("datetime").datetime))
```
And whenever I call `myVar` which holds the datetime object, I have to wrap it like this:

```nim
withPyLock():
  myVar.fromunixtimestamp(1)
```

Now we can lock the gil when we have to run the GC, overriding the nimpy `PyObject` destructor with this:

```nim
var garbage: seq[PPyObject]

proc `=destroy`*(p: var PyObject) =
  if pygil.tryAcquire:
    if not p.rawPyObj.isnil:
      decRef p.rawPyObj
      p.rawPyObj = nil
    while garbage.len > 1:
      var pp = garbage.pop() # TODO: Does this leak a pointer?
      if not pp.isnil:
        decRef pp
      pp = nil
    pygil.release
  else:
    if not p.rawPyObj.isnil:
      garbage.add p.rawPyObj
```
The lock we use inside the destructor is not an `AsyncLock` as that would be too expensive, and we _don't_ always lock, as that would cause stalls! If we can't lock the gil, we delay the collection, and keep the raw python pointer around for when we will be able to clear it. Honestly I don't know if this causes other forms of issues, but it seems to work *well enough*.

We have a nim module called `pyutils.nim` that does a bunch of nim<>python stuff, for example:

```nim
from utils import withLocks
proc pyhasAttr*(o: PyObject; a: string): bool {.withLocks: [pyGil].} = pybi[].hasattr(
    o, a).to(bool)

proc pyclass(py: PyObject): PyObject {.inline, withLocks: [pyGil].} =
  pybi[].type(py)

proc pytype*(py: PyObject): string =
  py.pyclass.getattr("__name__").to(string)

proc pyisbool*(py: PyObject): bool {.withLocks: [pyGil].} =
  return pybi[].isinstance(py, PyBoolClass[]).to(bool)

proc pyisnone*(py: PyObject): bool {.gcsafe, withLocks: [pyGil].} =
  return py.isnil or pybi[].isinstance(py, PyNoneClass[]).to(bool)
```

This one is used quite a lot:

```nim
proc pyget*[T](py: PyObject; k: string; def: T = ""): T =
  try:
    let v = py.callMethod("get", k)
    if pyisnone(v):
      return def
    else:
      return v.to(T)
  except:
    pyErrClear()
    if pyisnone(py):
      return def
    else:
      return py.to(T)
```

This one is used when we have scheduled a python job, and we want to wait for it to finish asynchronously:

```nim
proc pywait*(j: PyObject): Future[PyObject] {.async, gcsafe.} =
  var rdy: bool
  var res: PyObject
  while true:
    withPyLock:
      checkNil(j)
      rdy = j.callMethod("ready").to(bool)
    if rdy:
      withPyLock:
        checkNil(j)
        res = j.callMethod("get")
      break
    await sleepAsync(250.milliseconds)
  withPyLock:
    if (not res.isnil) and (not pyisnone(res)) and (not pyErrOccurred()):
      return res
    else:
      raise newException(ValueError, "Python job failed.")
```
Proper python async binding would require completing a nim async future from python at the end of the python scheduled job, which we don't do cuz we haven't looked deep enough into handling nim objects from python.

## Ampification
We support google amp, so we generate somewhat amp compliant amp pages. We don't aim for 1:1 support. In fact we nuke all the javascript we have and only serve html/css. Even then we have to be careful not adding custom attributes to html tags, or just custom html tags, amp is bad like that...
For automatic amp page conversion we handle the `head` and the `body` tag differently.

```nim
proc processHead(inHead: VNode, outHead: VNode, level = 0) {.async.} =
  var canonicalUnset = level == 0
  debug "iterating over {inHead.kind}"
  for el in inHead.preorder(withStyles = true):
    case el.kind:
      of VNodeKind.text, skipNodes:
        continue
      of VNodeKind.style:
        if el.len > 0:
          el[0].text.maybeStyle
      of VNodeKind.link:
        if canonicalUnset and el.isLink(canonical):
          outHead.add el
          canonicalUnset = false
        elif el.isLink(stylesheet) and (not ("flags-sprite" in el.getattr("href"))):
          await el.fetchStyle()
        elif el.isLink(preload) and el.getattr("as") == "style":
          await el.fetchStyle()
        else:
          outHead.add el
      of VNodeKind.script:
        if el.getAttr("type") == $ldjson:
          outHead.add el
      of VNodeKind.meta:
        if (el.getAttr("name") == "viewport") or (el.getAttr("charset") != ""):
          continue
        else:
          outHead.add el
      of VNodeKind.verbatim:
        let data = el.toXmlNode
        if data.kind == xnElement:
          if data.tag == "noscript":
            processNoScript()
          elif data.tag == "script":
            continue
          elif data.tag == "style":
            if data.len > 0:
              data[0].text.maybeStyle
          else:
            outHead.add el
      of VNodekind.noscript:
        processNoScript()
      else:
        debug "amphead: adding element {el.kind} to outHead."
        outHead.add el
```
All styles are merged into a single inline script, what's kept is `link` tags which are not style/jscript, like lang. Script tags for `ldljson`, `meta` tags. Verbatim handles nodes which are _literal_, we have to convert them in to `XmlNode` (which means parsing) and handle it correctly.
Process body is similar, we keep some tags, remove others, rename others:

```nim
template process(el: VNode, after: untyped): bool =
  var isprocessed = true
  case el.kind:
    of skipNodes: discard
    of VNodeKind.link:
      if el.isLink(stylesheet):
        await el.fetchStyle()
      else:
        outBody.add el
    of VNodeKind.style:
      el.text.maybeStyle
      el.text = ""
    of VNodeKind.script:
      if el.getAttr("type") == $ldjson:
        outHead.add el
      el.text = ""
    of VNodeKind.form:
      el.setAttr("amp-form", "")
    else:
      isprocessed = false
  if isprocessed:
    after
  isprocessed
```
The `form` tag is replaced with `amp-form`, amp has many of these tags...

We have to ensure that the inline styles are within the correct length:

```nim
styleStr = styleStr
  # .join("\n")
  # NOTE: the replacement should be ordered from most frequent to rarest
  # # remove troublesome animations
  .replace(pre"""\s*?@(\-[a-zA-Z]+-)?keyframes\s+?.+?{\s*?.+?({.+?})+?\s*?}""", "")
  # # remove !important hints
  .replace(pre"""!important""", "")
  # remove charset since not allowed
  .replace(pre"""@charset\s+\"utf-8\"\s*;?/i""", "")

if unlikely(styleStr.len > CSS_MAX_SIZE):
  raise newException(ValueError, fmt"Style size above limit for amp pages. {styleStr.len}")
```

Our amp generation doesn't cover the full amp spec, but it works for our content (through trial and error :S).

## Search
Whenever an article is published, it is ingested into the sonic database, the sonic database handles "collections", "buckets" and "objects"; We define a collection as a website, so every website that wants to deploy the content aggregator has its own collection. We don't use `buckets`, although we could consider each topic a bucket that would narrow the search too much, so every site has just one bucket "default", and each object of the bucket is an article (which can be of different topics).

```nim
proc push*(capts: UriCaptures, content: string) {.async.} =
  ## Push the contents of an article page to the search database
  ## NOTE: NOT thread safe
  var ofs = 0
  while ofs <= content.len:
    let view = content[ofs..^1]
    let key = join([capts.topic, capts.page, capts.art], "/")
    let cnt = runeSubStr(view, 0, min(view.len, bufsize - key.len))
    ofs += cnt.len
    if cnt.len == 0:
      break
    try:
      let lang = await capts.lang.toISO3
      var pushed: bool
      var j: PyObject
      withPyLock:
        j = pySched[].apply(
          pySonic[].push,
          WEBSITE_DOMAIN,
          "default", # TODO: Should we restrict search to `capts.topic`?
          key,
          cnt,
          lang = if capts.lang != "en": lang else: ""
          )
      j = await j.pywait()
      withPyLock:
        pushed = not pyisnone(j) and j.to(bool)
      when not defined(release):
        if not pushed:
          capts.addToBackLog()
          break
    except Exception:
      logexc()
      debug "sonic: couldn't push content, \n {capts} \n {key} \n {cnt}"
      when not defined(release):
        capts.addToBackLog()
        block:
          var f: File
          try:
            await pushLock[].acquire
            f = open("/tmp/sonic_debug.log", fmWrite)
            write(f, cnt)
          finally:
            pushLock[].release
            if not f.isnil:
              f.close()
      break
```
When pushing content into sonic we have to split the data in chunks, which max length is known upon connection. Ingesting data seems to be buggy sometimes, as it appears to not be able to handle some specific characters.
In case the sonic server breaks somehow, we also have a function to reingest all the content:

```nim
proc pushAllSonic*() {.async.} =
  await syncTopics()
  var total, c, pagenum: int
  let pushLog = await readPushLog()
  if pushLog.len == 0:
    withPyLock:
      discard pySonic[].flush(WEBSITE_DOMAIN)
  defer:
    withPyLock:
      discard pySonic[].consolidate()
  for (topic, state) in topicsCache:
    if topic notin pushLog:
      pushLog[topic] = %0
    await pygil.acquire
    defer: pygil.release
    let done = state.group[]["done"]
    for page in done:
      pagenum = ($page).parseint
      c = len(done[page])
      if pushLog[topic].to(int) >= pagenum:
        continue
      var futs: seq[Future[void]]
      for n in 0..<c:
        let ar = done[page][n]
        if ar.isValidArticlePy:
          var relpath = getArticlePath(ar, topic)
          relpath.removeSuffix("/")
          let
            capts = uriTuple(relpath)
            content = ar.pyget("content").sanitize
          echo "pushing ", relpath
          futs.add push(capts, content)
          total.inc
      pygil.release
      await allFutures(futs)
      pushLog[topic] = %pagenum
      await writePushLog(pushLog)
      await pygil.acquire
  info "Indexed search for {WEBSITE_DOMAIN} with {total} objects."
```

## Translation
Translation is quite a messy story. I am at my 4th (!) implementation of a translation wrapper, after having written in php, go and [julia](https://github.com/untoreh/Translator.jl), this is also written in nim. The php/go variants are a little bit rotten nowadays, while the julia variant is actively used for this blog. However to achieve low delay for the web server, the way translation is implemented in julia is not well fit for real time servicing (it translates static files), and anyway adding julia as a dependency once we already have python would be to big of a requirement.

So I had to implement a new translation module in nim. In truth, the initial nim translation module looked a lot like the julia implementation, where we were translating static files [^1]. Afterwards, when the web server started shaping up, I switching it to translate the karax nodes on demand. This allows to translate each web page just in time for the request.

```nim
template translateVbtm(node: VNode, q: QueueDom) =
  assert node.kind == VNodeKind.verbatim
  let tree = ($node).parseHtml() # FIXME: this should be a conversion, but the conversion doesn't preserve whitespace??
  if tree.kind == xnElement and tree.tag == "document":
    tree.tag = "div"
  takeOverFields(tree.toVNode, node)
  translateIter(node, vbtm = false)

template translateIter(otree; vbtm: static[bool] = true) =
  for el in otree.preorder():
    case el.kind:
      of vdom.VNodeKind.text:
        if el.text.isEmptyOrWhitespace:
          continue
        if isTranslatable(el):
          translate(q.addr, el, srv)
      else:
        let t = el.kind
        if t in tformsTags:
          getTForms(dom)[t](el, file_path, url_path, pair)
        if t == VNodeKind.a:
          if el.hasAttr("href"):
            rewriteUrl(el, rewrite_path, hostname)
        if t == VNodeKind.verbatim:
          when vbtm:
            debug "dom: translating verbatim", false
            translateVbtm(el, q)
        else:
          if(el.hasAttr("alt") and el.isTranslatable("alt")) or
            (el.hasAttr("title") and el.isTranslatable("title")):
            translate(q.addr, el, srv)
```
Above is the main iteration loop `translateIter`:
- `getTforms` maps functions to html tags, allowing to perform mutations on case by case basis.
- `rewriteUrl` inserts the lang path (.e.g `/en/`) in the url path.
- `translateVbtm` handle verbatim nodes which require parsing.
Translation is applied to all text nodes and to the `alt` and `title` attributes.

```nim
proc translate*[T](q: ptr[QueueXml | QueueDom], el: T, srv: service) =
  if q.isnil:
    warn "translate: queue can't be nil"
    return
  let (success, length) = setFromDB(q[].pair, el)
  if not success:
    if length > q[].bufsize:
      debug "Translating element singularly since it is big"
      elUpdate(q[], el, srv)
    else:
      if reachedBufSize(length, q[]):
        q[].push()
      q[].bucket.add(el)
      q[].sz += length

proc translate*[T](q: ptr[QueueXml | QueueDom], el: T, srv: service,
    finish: bool): Future[bool] {.async.} =
  if finish:
    if q.isnil:
      return true
    let (success, _) = setFromDB(q[].pair, el)
    if not success:
      addJob(@[el], q[], el.getText)
      debug "translate: waiting for pair: {q[].pair}"
      await doTrans()
  return true

proc translate*(q: ptr[QueueXml | QueueDom], srv: service,
    finish: bool): Future[bool] {.async.} =
  if finish and q[].sz > 0:
    q[].push()
    await doTrans()
    saveToDB(force = true)
  return true
```
Because we have to translate each text node separately (otherwise we can't render back the html) every node translation is a separated job. Since jobs can query translation services of the net, they have to be done asynchronously. We do splitting and merging of translation queries to spare api calls, but the internals of the translation engine are not important to know. The only thing to note is that initially I was using a [python wrapper](https://github.com/nidhaloff/deep-translator) (which I still use for translating scraped content) because self managing wrappers for external apis is a pain, but then switched to self wrapped google and yandex translation service in nim, because python become a considerable bottleneck when handling many concurrent translations.

[^1]: In fact originally the content aggregator was supposed to just generate static files for `caddy` to serve, but because the amount of pages to generate (which is a matrix of n_lang(20) x amp(2) x page), lazy rendering was the better option.

## Stats
Topic and article pages are tracked for hit counts.

```nim
proc updateHits*(capts: UriCaptures) =
  let ak = join([capts.topic, capts.art])
  let tk = capts.topic
  var
    artCount: int32 = statsDB[ak]
    topicCount: int32 = statsDB[tk]
  artCount += 1
  topicCount += 1
  statsDB[ak] = artCount
  statsDB[tk] = topicCount
```
We use hit counts to cleanup pages with a low count periodically.

```nim
proc deleteLowTrafficArts*(topic: string): Future[void] {.gcsafe, async.} =
  let now = getTime()
  var
    pagenum: int
    pagesToReset: seq[int]
    pubTime: Time
    pubTimeTs: int
  var capts = mUriCaptures()
  capts.topic = topic
  for (art, _) in (await publishedArticles[string](topic, "")):
    withPyLock:
      if pyisnone(art):
        continue
      capts.art = pyget[string](art, "slug")
      pagenum = pyget(art, "page", 0)
    capts.page = pagenum.intToStr
    try:
      withPyLock:
        pubTimeTs = pyget(art, "pubTime", 0)
      pubTime = fromUnix(pubTimeTs)
    except:
      pubTime = default(Time)
    if pubTime == default(Time):
      if not (pagenum in pagesToReset):
        debug "tasks: resetting pubTime for page {pagenum}"
        pagesToReset.add pagenum
    # article is old enough
    elif inSeconds(now - pubTime) > cfg.CLEANUP_AGE:
      let hits = topic.getHits(capts.art)
      # article has low hit count
      if hits < cfg.CLEANUP_HITS:
        await deleteArt(capts)
  for n in pagesToReset:
    withPyLock:
      discard site[].update_pubtime(topic, n)
```

## Databases
We use `libmdbx` through [this lib](https://github.com/snej/nimdbx). Probably is overkill, and using leveldb would have sufficed.
We have a type `LRUTrans` where the initial idea was to setup the database as an LRU cache, but it was considerably slower. The implementation can be found [here](https://github.com/untoreh/lrudbx/blob/main/lrudbx.nim)

```nim
type
    CollectionNotNil = ptr Collection not nil
    LRUTransObj = object
        db: nimdbx.Database.Database not nil
        coll: CollectionNotNil
        zstd_c: ptr ZSTD_CCtx
        zstd_d: ptr ZSTD_DCtx
    LRUTrans* = ptr LRUTransObj

proc getImpl(t: LRUTrans, k: int64, throw: static bool): string =
    withLock(tLock):
        var o: seq[byte]
        t.coll.inSnapshot do (cs: CollectionSnapshot):
            # debug "nimdbx: looking for key {k}, {v}"
            o.add cs[k.asData].asByteSeq
        if len(o) > 0:
            result = cast[string](decompress(t.zstd_d, o))
            # debug "nimdbx: got key {k}, with {o.len} bytes"
        elif throw:
            raise newException(KeyError, "nimdbx: key not found")

proc getImpl[T: not int64](t: LRUTrans, k: T, throw: static bool): string =
    getImpl(t, hash(k).int64, throw)


proc `[]`*[T](t: LRUTrans, k: T): auto = t.getImpl(k, false)
proc `get`*[K](t: LRUTrans, k: K): auto = t.getImpl(k, true)

proc `[]=`*(t: LRUTrans, k: int64, v: string) {.gcsafe.} =
    var o: seq[byte]
    if likely(v.len != 0):
      o = compress(t.zstd_c, v, cfg.ZSTD_COMPRESSION_LEVEL)
    withLock(tLock):
        logall "nimdbx: saving key {k}"
        t.coll.inTransaction do (ct: CollectionTransaction):
            {.cast(gcsafe).}:
                ct[k] = o
            ct.commit()
        logall "nimdbx: commited key {k}"

proc `[]=`*[K: not int64](t: LRUTrans, k: K, v: string) = t[hash(k).int64] = v
```

This type is used for four separate databases:
- translations
- page cache
- images cache
- stats
The database type is implemented with getters and setters then do automatic de/compression on read/write. For this reason it shouldn't be used for images...but alas...
There are also a bunch of small micro caches:
- vbtm: for parsed (verbatim) content
- search: for search queries
- feeds: for topic feeds VNodes
- rxcache: for regex, because compile time static regexes are not yet standardized (also because there are multiple regex libraries in nim)
These are implemented as [lru caches](https://github.com/jackhftang/lrucache.nim)[^2], more precisely as "locked" lru caches, where every get and set operation is wrapped around a (thread)lock. This locks can't cause stalls with the async runtime because the lock is acquired and released without any yield statement, so they are atomic in that sense, however they are still useful since we make use of threads for different tasks.

[^2]: However [nim stew](https://github.com/status-im/nim-stew/blob/master/stew/keyed_queue.nim) has a simpler implementation for lru cache which I would have used if found sooner.

# Background Jobs
A couple tasks that we use are CPU hungry, so we use a different thread for them:
- lsh: locality sensitive hashing does a lot of computation 
- images: Image resizing requires decoding/encoding images so it is costly

Two more threads are used to update the assets files list and the ads, although not cpu hungry, a thread is required to avoid stalls caused by the file watcher.

We also have async long running tasks for:
- translations
- http requests

Lsh, images, translation and http requests jobs are handled using a producer/consumer setup. Except that we don't use channels, because channels block and we don't have an async implementation of them that is also threadsafe. We used an async implementation of [this](https://github.com/mashingan/nim-etc/blob/master/sharedseq.nim)[^1].
And an async table, which is like an event bus

```nim
type
  AsyncTableObj[K, V] = object
    lock: ThreadLock
    waiters: Table[K, seq[ptr Future[V]]]
    table: Table[K, V]
  AsyncTable*[K, V] = ptr AsyncTableObj[K, V]

proc pop*[K, V](t: AsyncTable[K, V], k: K): Future[V] {.async.} =
  var popped = false
  withLock(t.lock):
    if k in t.table:
      popped = t.table.pop(k, result)
  if not popped:
    if k notin t.waiters:
      t.waiters[k] = newSeq[ptr Future[V]]()
    var fut = newFuture[V]("AsyncTable.pop")
    t.waiters[k].add fut.addr
    result = await fut

proc put*[K, V](t: AsyncTable[K, V], k: K, v: V) {.async.} =
  withLock(t.lock):
    if k in t.waiters:
      var ws: seq[ptr Future[V]]
      doassert t.waiters.pop(k, ws)
      while ws.len > 0:
        let w = ws.pop()
        if not w.isnil and not w[].isnil and not w[].finished:
          w[].complete(v)
    else:
      t.table[k] = v
```
The nim server also handles three async tasks:

```nim
type
  TaskKind = enum pub, cleanup, mem

proc scheduleTasks(): TaskTable =
  template addTask(t) =
    let fut = (selectTask t)()
    result[t] = fut
  # Publishes new articles for one topic every x seconds
  addTask pub
  # cleanup task for deleting low traffic articles
  addTask cleanup
  # quit when max memory usage reached
  addTask mem
```
The task that monitors mem usage is nice to have, to avoid OOM issues between the containerized process and docker, because docker (or the kernel) doesn't kill the process immediately, and in this period of time the server can become unresponsive, so it is better to restart manually immediately.

[^1]: although wrapping a plain channel in async routines is probably better...alas

# Images
We leverage [imageflow](https://github.com/imazen/imageflow/releases) to resize and cache images locally. The bindings are simple, but the process is a little bit involved.
With `getImg` we fetch the image data from remote url:

```nim
proc getImg*(src: string, kind: Source): Future[string] {.async.} =
  return case kind:
    of urlsrc:
      (await get(src.parseUri, decode = false, proxied = false)).body
    elif fileExists(src):
      await readFileAsync(src)
    else:
      ""
```

Then we have to add it to an imageflow context:

```nim
proc addImg*(img: string): bool =
  ## a lock should be held here throughout the `processImg` call.
  if img == "": return false
  reset(ctx)
  doassert ctx.check
  let a = imageflow_context_add_input_buffer(
    ctx.p,
    inputIoId,
    # NOTE: The image is held in cache, but it might be collected
    cast[ptr uint8](img[0].unsafeAddr),
    img.len.csize_t,
    imageflow_lifetime_lifetime_outlives_context)
  if not a:
    doassert ctx.check
    cmdStr["decode"] = %inputIoId
  return true
```
If the image can't be added, it means imageflow failed to recognized the data as a valid image.
After we have sent the data, we have to send a query to the context, then read the response, and get the output:

```nim
proc doProcessImg(input: string, mtd = execMethod): (string, string) =
  setCmd(input)
  let c = $cmd
  # debug "{hash(c)} - {c}"
  let json_res = imageflow_context_send_json(
      ctx.p,
      mtd,
      cast[ptr uint8](c[0].unsafeAddr),
      c.len.csize_t
    )
  discard imageflow_json_response_read(ctx.p, json_res,
                                       status.addr,
                                       resPtr,
                                       resLen)
  defer: doassert imageflow_json_response_destroy(ctx.p, json_res)

  var mime: string
  if status != 200:
    let msg = resPtr[].toString(resLen[].int)
    debug "imageflow: conversion failed {msg}"
    doassert ctx.check
  else:
    mime = getMime()
  discard imageflow_context_get_output_buffer_by_id(
      ctx.p,
      outputIoId,
      outputBuffer,
      outputBufferLen)
  doassert ctx.check
  result = (outputBuffer[].toString(outputBufferLen[].int), mime)
```
We get the mime type from the response, that will be forwarded in the response of the web server.
From the server side the translation from url path to image flow is handled like this:

```nim
proc processImgData(q: ptr ImgQuery) {.async.} =
  # push img to imageflow context
  initImageFlow() # NOTE: this initializes thread vars
  var acquired, submitted: bool
  let data = (await q.url.rawImg)
  defer:
    if acquired: imgLock[].release
    if not submitted:
      imgOut[q] = true
  if data.len > 0:
    try:
      await imgLock[].acquire
      acquired = true
      if addImg(data):
        let query = fmt"width={q.width}&height={q.height}&mode=max&format=webp"
        logall "ifl server: serving image hash: {hash(await q.url.rawImg)}, size: {q.width}x{q.height}"
        # process and send back
        (q.processed.data, q.processed.mime) = processImg(query)
        imgOut[q] = true
        submitted = true
    except Exception:
      discard
```
The image url is sent as a parameters, in zstd compressed form. The compression shortens the urls (most of the times). This is also how I found a bug in google chrome, where it couldn't handle urls where the query had url-encoded compressed data. Firefox was fine instead.

## LD-JSON
We add to each webpage ldjson scripts .

```nim
proc jwebpage(id, title, url, mtime, selector, description: auto, keywords: seq[string], name = "", headline = "",
            image = "", entity = "Article", status = "Published", lang = "english", mentions: seq[
            string] = (@[]), access_mode = (@["textual", "visual"]), access_sufficient: seq[
            string] = @[], access_summary = "", created = "", published = "",
            props = default(JsonNode)): JsonNode =
    let
        d_mtime = coerce(mtime, "")
        s_created = created.toIsoDate
        description = coerce(description, to = title)
        prd = (v: seq[string]) => v.len == 0

    let data = %*{
        "@context": "https://schema.org",
        "@type": "https://schema.org/WebPage",
        "@id": id,
        "url": url,
        "lastReviewed": coerce(mtime, ""),
        "mainEntityOfPage": {
            "@type": entity,
            "@id": url
        },
        "mainContentOfPage":
        {
            "@type": "WebPageElement", "cssSelector": selector},
        "accessMode": access_mode,
        "accessModeSufficient": {
            "@type": "itemList",
            "itemListElement": coercf(access_sufficient, prd, to = access_mode),
        },
        "creativeWorkStatus": status,
        # NOTE: datePublished should always be provided
        "datePublished": ensure_time(d_mtime.toIsoDate, s_created),
        "dateModified": d_mtime,
        "dateCreated": coerce(s_created, to = d_mtime),
        "name": coerce(name, to = title),
        "description": coerce(description, ""),
        "keywords": coerce(keywords, to = (@[]))
    }
    setArgs data, %*{"inLanguage": lang, "accessibilitySummary": access_summary,
                    "headline": coerce(headline, to = description), "image": image,
                    "mentions": mentions}
    setProps
    data
```

And for translated pages:

```nim
proc translation*(src_url, trg_url, lang, title, mtime, selector, description: auto, keywords: seq[string],
                     image = "", headline = "", props = default(JsonNode),
                     translator_name = "Google", translator_url = "https://translate.google.com/"): auto =
    ## file path must be relative to the project directory, assumes the published website is under '__site/'
    # id, title, url, mtime, selector, description: auto, keywords: seq[string], name = "", headline = "",
    let data = jwebpage(id = trg_url, title, url = trg_url, mtime, selector, description,
                            keywords = keywords, image = image, headline = headline, lang = lang, props = props)
    data["translator"] = %*{"@type": "https://schema.org/Organization",
                             "name": translator_name,
                             "url": translator_url}
    data["translationOfWork"] = %*{"@id": src_url}
    data
```

## Opengraph
Same as ldjson, we also provide opengraph meta tags:

```nim

proc opgBasic(title, tp, url, image: string, prefix = ""): seq[XmlNode] =
  if prefix != "":
    result.add metaTag(fmt"{prefix}:title", title)
    result.add metaTag(fmt"{prefix}:type", tp)
    result.add metaTag(fmt"{prefix}:url", url)
    result.add metaTag(fmt"{prefix}:image", image)
  else:
    result.add metaTag("title", image)
    result.add metaTag("type", image)
    result.add metaTag("url", image)
    result.add metaTag("image", image)

proc opgTags(title, tp, url,
             image: string,
             description = "",
             siteName = "",
             locale = "",
             audio = "",
             video = "",
             determiner = "",
             prefix = ""): seq[XmlNode] {.gcsafe.} =
  ## Generates an HTML String containing opengraph meta result for one item.
  var result = opgBasic(title, tp, url, image, prefix)
  result.add opgOptional(description, siteName, locale, audio, video, determiner)
  return result

proc opgPage*(a: Article): seq[XmlNode] =
  let locale = static(DEFAULT_LOCALE)
  let
    tp = static("article")
    url = getArticleUrl(a)
    siteName = static(WEBSITE_TITLE)
  result = opgTags(a.title, tp, url, a.imageUrl, a.desc, siteName, locale, prefix = "article")
  for t in a.tags:
    result.add metaTag("article:tag", t)
  result.add metaTag("article:author", a.author)
  result.add metaTag("article:published_time", $a.pubTime)
  result.add metaTag("article:section", a.desc)
  # result.add metaTag("article:modified_time", a.pubTime)
  # result.add metaTag("article:expiration_time", a.pubTime)
  result.add twitterMeta("card", "summary")
  result.add twitterMeta("creator", twitterUrl[])
```
Nim macros and templates come in handy when dealing with all this boilerplate heavy code.

## Server side http requests
There is another task, that handles all the http requests (to fetch images, scripts, etc) from the web server side. We use the chronos httpclient:

```nim
const proxiedFlags = {NoVerifyHost, NoVerifyServerName, NewConnectionAlways}
const sessionFlags = {NoVerifyHost, NoVerifyServerName, NoInet6Resolution}
proc requestTask(q: sink ptr Request) {.async.} =
  var trial = 0
  var
    sess: HttpSessionRef
    req: HttpClientRequestRef
    resp: HttpClientResponseRef
    cleanup: seq[Future[void]]
  while trial < q[].retries:
    try:
      trial.inc
      sess = new(HttpSessionRef,
                proxyTimeout = 10.seconds.div(3),
                headersTimeout = 10.seconds.div(2),
                connectTimeout = 10.seconds,
                proxy = if q[].proxied: selectProxy(trial) else: "",
                flags = if q[].proxied: proxiedFlags else: sessionFlags
      )
      req = new(HttpClientRequestRef,
                sess,
                sess.getAddress(q[].url).get,
                q[].meth,
                headers = q[].headers.toHeaderTuple,
                body = q[].body.tobytes,
        )
      resp = await req.fetch(followRedirects = q[].redir, raw = true)
      checkNil(resp):
        defer:
          cleanup.add resp.closeWait()
          resp = nil
        q.response.code = httpcore.HttpCode(resp.status)
        checkNil(resp.connection):
          q.response.body = bytesToString (await resp.getBodyBytes)
          q.response.headers = newHttpHeaders(cast[seq[(string, string)]](
              resp.headers.toList))
        break
    except:
      cdebug():
        logexc()
        debug "cronhttp: request failed"
    finally:
      if not req.isnil:
        cleanup.add req.closeWait()
      if not resp.isnil:
        cleanup.add resp.closeWait()
      if not sess.isnil:
        cleanup.add sess.closeWait()
  httpOut[q] = true
  await allFutures(cleanup)

```
I had to add [support for https and socks5 proxies](https://github.com/untoreh/nim-chronos/tree/update) to the httpclient to be able to use translations effectively.

# Config
You might have noticed capitalized variables throughout the code. All of these are config variables, that are defined in a file, which can be customized per website.

```nim
const
  BASE_URL* = Uri()
  SITE_PATH* = PROJECT_PATH / "site"
  SITE_ASSETS_PATH* = BASE_URL / "assets" / WEBSITE_NAME
  SITE_ASSETS_DIR* = SITE_PATH / "assets" / WEBSITE_NAME
  DATA_PATH* = PROJECT_PATH / "data"
  DATA_ASSETS_PATH* = DATA_PATH / "assets" / WEBSITE_NAME
  DATA_ADS_PATH* = DATA_PATH / "ads" / WEBSITE_NAME
  ASSETS_PATH* = PROJECT_PATH / "src" / "assets"
  DEFAULT_IMAGE* = ASSETS_PATH / "empty.png"
  DEFAULT_IMAGE_MIME* = "image/png"
  CSS_BUN_URL* = $(SITE_ASSETS_PATH / "bundle.css")
  CSS_CRIT_PATH* = SITE_ASSETS_DIR / "bundle-crit.css"
  JS_REL_URL* = $(SITE_ASSETS_PATH / "bundle.js")
  LOGO_PATH* = BASE_URL / "assets" / "logo" / WEBSITE_NAME
  LOGO_URL* = $(LOGO_PATH / "logo.svg")
  LOGO_SMALL_URL* = $(LOGO_PATH / "logo-small.svg")
  LOGO_ICON_URL* = $(LOGO_PATH / "logo-icon.svg")
  LOGO_DARK_URL* = $(LOGO_PATH / "logo-dark.svg")
  LOGO_DARK_SMALL_URL* = $(LOGO_PATH / "logo-small-dark.svg")
  LOGO_DARK_ICON_URL* = $(LOGO_PATH / "logo-icon-dark.svg")
  FAVICON_PNG_URL* = $(LOGO_PATH / "logo-icon.png")
  FAVICON_SVG_URL* = $(LOGO_PATH / "logo-icon.svg")
  APPLE_PNG180_URL* = $(LOGO_PATH / "apple-touch-icon.png")
  MAX_DIR_FILES* = 10
# ...
```

# Conclusion
There are a bunch of things that I have not mentioned, since the devil is in the details...however this is rough tour of the whole code base which amounts to:
- ~12k lines of nim
- ~400 lines of js
- ~1000 lines of scss
- ~3500 lines of python
- 74 lines of rust (for bindings :P)

What would I do differently? 
- Probably rewrite the whole thing in rust, nim currently doesn't handle memory safety nicely, and the amount of time I had to rely on gdb to fix crashes was too much, and I haven't even managed to fix all of them. It is a big problem when half the ecosystem relies on GC and the other half on ORC (or not even orc and just ARC). Mixing async and threads is also painful and async stacktraces are a nightmare, (although I don't know if rust is any better in this regard.)
- Target a [PWA](https://en.wikipedia.org/wiki/Progressive_web_app) from the getgo. The project had quite a troublesome start. In the beginning it was supposed to be static pages served by a webserver, then it became a webserver itself. Interactivity came as an afterthought, so it become just a mix of rendered html plus js/css. This made me too lax on the API, which came out without any structure whatsoever (completely [unRESTFUL](https://en.wikipedia.org/wiki/Representational_state_transfer)). In the rewrite I would use a ui framework, either [preact](https://preactjs.com/) which has full AMP support, or [solidjs](https://www.solidjs.com/).
- Add more ad-hoc parsers for popular platforms. Plain article parsing doesn't work to well (or at all) when the most popular platforms nowadays offer very little content, and lots of videos and images, scraping therefore must be more targeted to rich media instead of just text, if this is not accounted for when planning the scraper architecture, the content and information that the APP will serve will be unbalanced.
