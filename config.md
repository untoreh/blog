<!--
Add here global page variables to use throughout your
website.
The website_* must be defined for the RSS to work
-->

@def title = "untoreh's site"
@def website_title = "untoreh's site"
@def website_descr = "Articles, logs, infos, status and live updates are published here."
@def website_url = "https://www.unto.re"
@def country = "IT"
@def country_name = "italy"
@def author_image = "/assets/appa.webp"
@def logo = "/assets/appa-60px.png"
@def avatar = "/assets/appa.png"
@def email = "contact@unto.re"
@def github = "https://github.com/untoreh"
@def twitter = "https://twitter.com/untoreh"
@def twitter_user = "@untoreh"
@def lang = "English"
@def lang_code = "en"
@def menu = ["/posts", "/media", "/reads", "/tag"]
@def locale = "en_US"

<!-- tag_page_path = "tags" -->

@def region = "Apulia"
@def geo_link = "https://goo.gl/maps/E3Si7WzG4LX7wpNJ6"

@def author = "untoreh"

@def mintoclevel = 2
@def div_content = "franklin-content"
@def posts_path = "/posts/"
@def calibre_server = "http://localhost:8099"
@def calibre_library = "books"

<!-- https://schema.org/accessMode -->

@def accessMode = ["textual", "visual"]
@def accessModeSufficient = ["textual", "visual"]
<!-- @def languages = [("English", "en"), ("Italian", "it")] -->
@def languages = [("English", "en"), ("German", "de"), ("Italian", "it"), ("Mandarin Chinese", "zh"), ("Spanish", "es"), ("Hindi", "hi"), ("Arabic", "ar"), ("Portuguese", "pt"), ("Bengali", "bn"), ("Russian", "ru"), ("Japanese", "ja"), ("Punjabi", "pa"), ("Javanese", "jw"), ("Vietnamese", "vi"), ("French", "fr"), ("Urdu", "ur"), ("Turkish", "tr"), ("Polish", "pl"), ("Ukranian", "uk"), ("Dutch", "nl"), ("Greek", "el"), ("Swedish", "sv"), ("Zulu", "zu"), ("Romanian", "ro"), ("Malay", "ms"), ("Korean", "ko"), ("Thai", "th"), ("Filipino", "tl")]
@def mentions = []
@def translator_name = "Google Translate"
@def translator_url = "http://google.translate.com"


<!--
Add here files or directories that should be ignored by Franklin, otherwise
these files might be copied and, if markdown, processed by Franklin which
you might not want. Indicate directories by ending the name with a `/`.
-->


@def ignore = ["translations.db/", "build/", "unused/", "node_modules/",  "__site.bak/", "franklin/", "franklin.pub/", "README.md",  "translations.json", "translations.json.bak", "TODO.md", "pyrightconfig.json", ".vscode", "*.jl"]

<!--
Add here global latex commands to use throughout your
pages. It can be math commands but does not need to be.
For instance:
* \newcommand{\phrase}{This is a long phrase to copy.}
-->

\newcommand{\color}[2]{~~~<span style="color:#1">#2</span>~~~}
\newcommand{\red}[1]{~~~<span style="color:var(--red)"; font-weight: bold;>#1</span>~~~}
\newcommand{\ylw}[1]{~~~<span style="color:var(--yellow); font-weight: bold;">#1</span>~~~}
\newcommand{\grn}[1]{~~~<span style="color:var(--green); font-weight: bold;">#1</span>~~~}
\newcommand{\styletext}[2]{~~~<span style="#1">#2</span>~~~}
\newcommand{\website}{{{website_url}}}
\newcommand{\icon}[1]{~~~<i class="fas #1 icon"></i>~~~}
\newcommand{\iconb}[1]{~~~<i class="fab #1 icon"></i>~~~}
\newcommand{\panorama}[2]{~~~<a href="#2" target="_blank">#1 (Panorama)</a>~~~}
\newcommand{\album}[1]{~~~<a href="#1" target="_blank">Go To Album</a>~~~}
\newcommand{\insert}[1]{~~~{{insert_path #1}}~~~}
\newcommand{\imgl}[1]{~~~{{insert_img #1 left}}~~~}
\newcommand{\imgr}[1]{~~~{{insert_img #1 right}}~~~}
\newcommand{\imgc}[1]{~~~{{insert_img #1 none}}~~~}
\newcommand{\del}[1]{~~~<del>#1</del>~~~}
