<!--
Add here global page variables to use throughout your
website.
The website_* must be defined for the RSS to work
-->

@def title = "untoreh's site"
@def website_title = "untoreh's site"
@def website_descr = "you know...stuff"
@def website_url = "https://unto.re"

@def author = "untoreh"

@def mintoclevel = 2

<!--
Add here files or directories that should be ignored by Franklin, otherwise
these files might be copied and, if markdown, processed by Franklin which
you might not want. Indicate directories by ending the name with a `/`.
-->

@def ignore = ["node_modules/", "franklin", "franklin.pub"]

<!--
Add here global latex commands to use throughout your
pages. It can be math commands but does not need to be.
For instance:
* \newcommand{\phrase}{This is a long phrase to copy.}
-->

\newcommand{\color}[2]{~~~<span style="color:#1">#2</span>~~~}
\newcommand{\styletext}[2]{~~~<span style="#1">#2</span>~~~}
\newcommand{\website}{{{website_url}}}
\newcommand{\icon}[1]{~~~<i class="fas #1 icon"></i>~~~}
\newcommand{\iconb}[1]{~~~<i class="fab #1 icon"></i>~~~}
