# Untoreh's website

The website can be divided in four parts

- Posts
- round up of previous projects

# Notes
- Translation doesn't edit LDJ data, it just addes the ldj markup mentioning that the page is translated.
- RSS feeds don't have translations.
- AMP pages are generated for main website and for the translations.
- TurboPages feeds need to be checked in case new ones have to be added to the WM dashboard

## Writing a blog post
Offline scripts used to generate content should be placed in the toplevel `/scripts` folder.

# Publishing to gh-pages
- Clone the branch `gh-pages` into `./__site.bak` dir in the git repo root dir if not present already.
- Make sure `/tmp/__site` links back to `./__site` (to speed up generation).
- Generate the site which will update contents of `/tmp/__site`
```julia
pubup(all=true, publish=true) # render all pages with translation, minification, etc...
```
By passing `publish=true` the new built website is commited and pushed to the `gh-pages` branch (present in `./__site.bak`), or if you want to publish separately set it to `false` and call `dopublish()` afterwards.
Publishing (r)syncs the contents of `__site` to `__site.bak` then commits and pushes.
Ensure new images are added to the gh-pages branch (even though it should have already been added), i.e.:
```bash
cd ./__site.bak
git status *.{png,jpg,gif,webp}
```
