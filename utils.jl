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
using Translator: franklinlangs; franklinlangs(); using Translator.FranklinLangs
using FranklinContent; FranklinContent.franklincontent_hfuncs(); FranklinContent.load_amp(); using .AMP

# using Gumbo: HTMLElement, hasattr, setattr!, getattr
# using Gumbo: parsehtml, setattr!, HTMLElement
# using AbstractTrees: PreOrderDFS
# using URIs

function pubup(;opt=true, search=true, trans=true, amp=true)
    # workaround for pagevars
    fr.def_GLOBAL_VARS!()
    fr.process_config()
	opt && begin
        fr.optimize(prerender=true, minify=true)
        fr.def_GLOBAL_VARS!()
        fr.process_config()
    end
    search && lunr()
    trans && begin
        translate_website()
        sitemap_add_translations()
    end
    if amp
        trg, src = get_languages()
        dirs = [code for (_, code) in trg if code !== src]
        append!(dirs, ["posts", "tag", "reads", "_rss"])
        AMP.ampdir(fr.path(:site); dirs)
    end
end


# load_vars(fr.path(:assets) * "/amp.html")
