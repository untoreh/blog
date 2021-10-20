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
using Translator: franklinlangs; franklinlangs(); using Translator.FranklinLangs;
using FranklinContent; FranklinContent.franklincontent_hfuncs();
FranklinContent.load_amp(); using .AMP
FranklinContent.load_yandex(); using .Yandex
FranklinContent.load_minify(); using .FranklinMinify


function pubup(what=nothing; all=false, clear=false)
    # set the global path
    fr.FOLDER_PATH[] = pwd()
    fr.def_GLOBAL_VARS!()
    fr.set_paths!()
    fr.process_config()
    trg, src = FranklinLangs.get_languages()
    target_dirs = [code for (_, code) in trg if code !== src]
    append!(target_dirs, ["posts", "tag", "reads", "_rss"])

    clear && begin
        site = fr.path(:site)
        @assert site !== pwd() && islink(site)
        run(`bash -c "rm -r $(joinpath(site, "*"))"`)
    end

    (all || what === :opt) && begin
        fr.optimize(prerender=true, minify=false)
        fr.def_GLOBAL_VARS!()
        fr.process_config()
    end
    (all || what === :search) && lunr()
    (all || what === :trans) && begin
        FranklinLangs.translate_website()
        FranklinLangs.sitemap_add_translations(;amp=all)
    end
    (all || what === :amp) && AMP.ampdir(fr.path(:site); dirs=target_dirs)
    (all || what === :yandex) && Yandex.turbodir(fr.path(:site); dirs=target_dirs)
    (all || what === :minify) && FranklinMinify.minify_website()
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
