

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
