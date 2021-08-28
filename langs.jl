if !isdefined(@__MODULE__, :TLangs)
    fr.process_config()
    @doc "languages for translation"
    const TLangs = [(lang, code)
                    for (lang, code) in fr.globvar(:languages)
                        if lang != fr.globvar(:lang)]::Vector{Tuple{String, String}}
    @warn "there are $(length(TLangs)) target languages"
end
if !isdefined(@__MODULE__, :SLang)
    @doc "main source language"
    const SLang =  isnothing(fr.globvar(:lang_code)) ? "en" : fr.globvar(:lang_code)
    @warn "source language set to $SLang"
end
