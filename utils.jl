using Conda
using Revise

# NOTE: when using and convert_md, pass `isinternal=true`
# to avoid clobbering global vars

# These must be set before initializing Franklin
py_v = chomp(String(read(`$(joinpath(Conda.BINDIR, "python")) -c "import sys; print(str(sys.version_info.major) + '.' + str(sys.version_info.minor))"`)))
ENV["PYTHON3"] = joinpath(Conda.BINDIR, "python")
ENV["PIP3"] = joinpath(Conda.BINDIR, "pip")
ENV["PYTHONPATH"] = "$(Conda.LIBDIR)/python$(py_v)"

using Franklin; const fr = Franklin;
using LDJ: ldjfranklin; ldjfranklin(); using LDJ.LDJFranklin
using Translator; Translator.franklinlangs(); using .FranklinLangs;
using FranklinContent; FranklinContent.franklincontent_hfuncs();
FranklinContent.load_amp(); using .AMP
FranklinContent.load_yandex(); using .Yandex
FranklinContent.load_minify(); using .FranklinMinify
FranklinContent.load_opg(); using .OPG
FranklinContent.load_simkl(); using .Simkl

function pubup(what=nothing; all=false, clear=false, publish=false, fail=false)
    # set the global path
    site = fr.path(:site)

    trg, src = FranklinLangs.get_languages()
    target_dirs = [code for (_, code) in trg if code !== src]
    append!(target_dirs, ["posts", "tag", "reads", "_rss"])

    # clear at the beginning
    (all || clear) && begin
        @assert site !== pwd() && islink(site)
        display("Cleaning site directory $site  ...")
        try run(`bash -c "rm -r $(joinpath(site, "*"))"`) catch end
    end

    (all || what === :opt) && begin
        fr.optimize(prerender=true, minify=false)
        fr.def_GLOBAL_VARS!()
        fr.process_config()
    end
    (all || what === :trans) && begin
        display("Translating...")
        @time (FranklinLangs.translate_website();
               FranklinLangs.sitemap_add_translations(;amp=true))
    end
    # the search index also includes translations
    (all || what === :search) && begin
        lunr()
        # copy the index to the site folder
        cp(joinpath(fr.path(:libs), "lunr", "lunr_index.js"),
           joinpath(site, "libs", "lunr", "lunr_index.js"); force=true)
    end

    # seo pages
    (all || what === :amp) && begin
        display("AMP pages...")
        @time AMP.ampdir(fr.path(:site); dirs=target_dirs)
    end
    (all || what === :yandex) && begin
        display("Turbo pages...")
        @time Yandex.turbodir(fr.path(:site); dirs=target_dirs)
    end

    # minification at the end to minify every html page and asset
    (all || what === :minify) && begin
        display("Minification...")
        @time FranklinMinify.minify_website()
    end
    if publish
        trg_dir = "/tmp/__site"
        bak_dir = joinpath(fr.path(:folder), "__site.bak")
        @assert !isnothing(Sys.which("git")) &&
            !isnothing(Sys.which("fd")) &&
            !isnothing(Sys.which("rsync"))
        display("Publishing website...")
        cd(fr.path(:folder))
        cma = read(`git rev-parse --short HEAD`, String) |> chomp

        cd(bak_dir)
        run(`rsync -a $trg_dir/ $bak_dir/`)
	    run(pipeline(`fd "\.((?:css)|(?:html)|(?:js)|(?:xml))\$" ./`,
                     `xargs git add -A`))
        # occursin("branch is up to date", read(`git status`, String)) ||
        try
            run(`git commit -m "$cma"`)
            run(`git push github-pages gh-pages`)
        catch
            throw("Branch clean?")
        end
    else
        srv_dir()
    end
    nothing
end

# load_vars(fr.path(:assets) * "/amp.html")
function srv_dir()
    Franklin.LiveServer.serve(
        port=8000,
        # coreloopfun=coreloopfun,
        dir="/tmp/__site/",
        host="127.0.0.1",
        launch_browser=false
    )
end
