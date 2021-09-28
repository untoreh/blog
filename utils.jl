
using Conda
using Revise

# These must be set before initializing Franklin
py_v = chomp(String(read(`$(joinpath(Conda.BINDIR, "python")) -c "import sys; print(str(sys.version_info.major) + '.' + str(sys.version_info.minor))"`)))
ENV["PYTHON3"] = joinpath(Conda.BINDIR, "python")
ENV["PIP3"] = joinpath(Conda.BINDIR, "pip")
ENV["PYTHONPATH"] = "$(Conda.LIBDIR)/python$(py_v)"

using Franklin; const fr = Franklin;
# NOTE: when using and convert_md, pass `isinternal=true`
# to avoid clobbering global vars
using Franklin: convert_md, convert_html, pagevar, globvar, locvar, path;

# include("misc.jl");
# include("LDJ.jl"); using .LDJ; using .LDJ.Content;
using Gumbo: HTMLElement, hasattr, setattr!, getattr
include("LDJFranklin.jl"); using .LDJFranklin; using .LDJFranklin.LDJ; using .LDJFranklin.LDJ.Content

using Translator

function add_ld_data(el, file_path, url_path, pair)
    src_url = Content.canonical_url()
    trg_url = Content.post_link(url_path, pair.trg)

    LDJ.ldj_trans(file_path, src_url, trg_url, pair.trg) |>
        x -> Translator.convert(HTMLElement{:script}, x) |>
        x -> push!(el, x)

    # find canonical link and apply translation
    for el in el.children
        if el isa HTMLElement{:link} &&
            hasattr(el, "rel") &&
            getattr(el, "rel") === "canonical"
            setattr!(el, "href", Content.canonical_url(pair.trg))
            break
        end
    end
    # push!(el, canonical_url() |> canonical_link_el)
    # push!(el, breadcrumbs([("Home", locvar(:website_url)),
    #                        ("Posts List", joinpath(locvar(:website_url), globvar(:posts_path))),
    #                        (locvar(:title), locvar(trg_url))]))
end

@doc "insert additional html into a target html file by html node"
function set_transforms()
    let tf = Translator.tforms
        empty!(tf)
        tf[HTMLElement{:head}] = add_ld_data
    end
end

function config_translator()
    fr.process_config()
    setlangs!((fr.globvar(:lang), fr.globvar(:lang_code)),
              fr.globvar(:languages))
    sethostname!(fr.globvar(:website_url))
    push!(Translator.skip_class, "menu-lang-btn")
    set_transforms()
    push!(Translator.excluded_translate_dirs, :langs)
    Translator.load_db()
end

function translate_website(;dir=joinpath(@__DIR__, "__site/"), method=Translator.trav_langs)
    if isnothing(Translator.SLang.code)
        config_translator()
    end
    try
        Translator.translate_dir(dir;method)
    catch e
        if e isa InterruptException
            display("Interrupted")
        else
            rethrow(e)
        end
    end
end

function test(reset=false, srv_sym=:deep; get_html=false, get_tree=false, TR=nothing, one_lang=("German", "de"))
    try
        dir = "__site"
        file = "/home/fra/dev/blog/__site/index.html"
        srv_val = Val(srv_sym)

        config_translator()
        if length(one_lang) > 0
            setlangs!(Translator.Lang("English", "en"),
                      [Translator.Lang(one_lang...)])
        end
        rx = Regex("(.*$(dir)/)(.*\$)")
        langpairs = [(src = Translator.SLang.code, trg = lang.code) for lang in Translator.TLangs]

        if reset reset() end
        if isnothing(TR)
            TR = Translator.init_translator(srv_val)
        end
        Translator.translate_file(file, rx, langpairs, TR)
        Translator.save_to_db(;force=true)
        return TR
    catch e
        if isa(e, InterruptException)
            display("interrupted")
        else
            rethrow(e)
        end
    end
end


reset() = begin
	empty!(Translator.tr_cache_tmp)
    close(Translator.db.db)
    Translator.db.db = nothing
    Translator.load_db()
    global db
    db = Translator.db.db
end

clear_db() = begin
empty!(Translator.db.db)
    empty!(Translator.tr_cache_tmp)
end

