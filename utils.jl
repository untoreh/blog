
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

include("misc.jl");
include("Content.jl"); using .Content;
include("LDJ.jl"); using .LDJ

using Translator
tr_task = nothing

@doc "insert additional html into a target html file by html node"
function set_inclusions()
    empty!(Translator.tforms)
    Translator.tforms[HTMLElement{:head}] =
        (el, file_path, url_path,pair) ->
        push!(el,
              Translator.convert(HTMLElement{:script},
                                 LDJ.ldj_trans(file_path, url_path, pair.trg)))
end

function config_translator()
    fr.process_config()
    setlangs!((fr.globvar(:lang), fr.globvar(:lang_code)),
              fr.globvar(:languages))
    sethostname!(fr.globvar(:website_url))
    set_inclusions()
    Translator.load_db()
end

function translate_website()
    global tr_task
    if isnothing(Translator.SLang.code)
        config_translator()
    end
    website_dir = joinpath(@__DIR__, "__site/")
    set_inclusions()
    tr_task = @task Translator.translate_dir(website_dir)
    schedule(tr_task)
end

function test(reset=false, srv_sym=:deep; get_html = false, get_tree = false, TR=nothing)
    try
        dir = "__site"
        file = "/home/fra/dev/blog/__site/posts/chronichles_of_a_cryptonote_dropper/index.html"
        srv_val = Val(srv_sym)

        config_translator()
        rx = Regex("(.*$(dir)/)(.*\$)")
        langpairs = [(src=Translator.SLang.code, trg=lang.code) for lang in Translator.TLangs]

        if reset reset() end
        if isnothing(TR)
            TR = Translator.init_translator(srv_val)
        end
        Translator.translate_file(file, rx, langpairs, TR; t_path="wow.html")
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

