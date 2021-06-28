@doc "wrapper for the py-googletrans library"
module Translate
using PyCall
using Conda
using Pkg
using JSON

const OptPy = Union{PyObject,Nothing}
const StrOrVec = Union{String,Vector{String}}

mutable struct GoogleTrans
    mod::OptPy
    tr::OptPy
end

mutable struct Trans
    mod::OptPy
    # target lang translator instances
    tr::Dict{Tuple{Symbol,String,String},OptPy}
end

mutable struct Translators
    mod::OptPy
    apis::Tuple
end

mutable struct Deep
    mod::OptPy
    tr::Dict{Symbol, OptPy}
    apis::Tuple
end

if ! isdefined(Main, :googletrans) || isnothing(googletrans.mod)
    googletrans = GoogleTrans(nothing, nothing)
end
if ! isdefined(Main, :trans) || isnothing(trans.mod)
    trans = Trans(nothing, Dict())
end
if ! isdefined(Main, :translators) || isnothing(translators.mod)
    translators = Translators(
        nothing,
        (:google, :bing, :yandex, :alibaba, :baidu, :deepl, :sogou, :tencent, :youdao),
    )
end
if ! isdefined(Main, :deep) || isnothing(deep.mod)
    deep = Deep(nothing, Dict(),
                (:GoogleTranslator,
                 :MicrosoftTranslator,
                 :PonsTranslator,
                 :LingueeTranslator,
                 :MyMemoryTranslator,
                 :YandexTranslator,
                 :DeepL,
                 :QCRI,
                 :single_detection,
                 :batch_detection))
end

function _add_python_user_path()
    pysys = pyimport("sys")
    py_v = pysys.version_info
    py_path = "python$(py_v[1]).$(py_v[2])"
    py_sys_path = PyVector(pysys."path")
    @show py_path
    let home = ENV["HOME"]
        pushfirst!(py_sys_path, "$home/.local" * "/lib/$py_path/site-packages")
        pushfirst!(py_sys_path, "")
    end
end

function _init_env()
    Conda.pip_interop(true)
    # we need to add paths to python runtime because pycall doesn't include them
    _add_python_user_path()
end

if ! isdefined(Main, :installed)
    installed = Dict(m => false for m in (:deep, :trans, :gtrans, :translators))
end

@doc """setup chosen service from pip and instantiate it.
srv [ :trans, :gtrans, :deep, :translators ]
"""
function init(srv = :deep)
    if installed[srv]
        return
    end
    _init_env()
    # NOTE: Conda will install in ~/.local/lib on unix, because conda site-packages is not writeable
    if srv == :deep
        Conda.pip("install --user", "deep_translator")
        deep.mod = pyimport("deep_translator")
        for cls in deep.apis
            deep.tr[cls] = deep.mod[cls]
        end
    elseif srv == :trans
        Conda.pip("install --user", "git+git://github.com/terryyin/translate-python")
        trans.mod = pyimport("translate")
    elseif srv == :gtrans
        Conda.pip("install --user --pre", "googletrans")
        googletrans.mod = pyimport("googletrans")
        googletrans.tr = googletrans.mod.Translator(
            service_urls = [
                "translate.google.com",
                "translate.google.de",
                "translate.google.es",
                "translate.google.fr",
                "translate.google.it",
            ],
        )
    elseif srv == :translators
        Conda.pip("install --user", "translators")
        translators.mod = pyimport("translators")
    else
        ErrorException("service $srv not supported") |> throw
    end
    installed[srv] = true
end

@doc "translate a string with googletrans"
function gtrans_translate(data::StrOrVec; src = "auto", dest = "en")
    googletrans.tr.translate(data, src = src, dest = dest).text
end

@doc """translate a string with translate-python
dest::String
provider::Symbol [:mymemory, :deepl]
"""
function trans_translate(
    data::StrOrVec;
    src = "english",
    dest = "english",
    provider = :mymemory,
)
    let tr_key = (provider, src, dest)
        if !haskey(trans.tr, tr_key)
            trans.tr[tr_key] =
                trans.mod.Translator(from_lang = src, to_lang = dest, provider = provider)
        end
        trans.tr[tr_key].translate(data)
    end
end

function translators_translate(
    data::StrOrVec;
    src = "english",
    dest = "english",
    provider = :google,
)
    # translators.mod[provider](data, from_language=src, to_language=dest)
    translators.mod[provider](data, to_language=dest)
end

function deep_translate(data::StrOrVec; src="auto", dest)
    deep.mod[:GoogleTranslator]()
end

cache_path = joinpath(@__DIR__, "translations.json")
cache_path_bak = cache_path * ".bak"
cache_dict_type = IdDict{UInt64, String}
translated_text = cache_dict_type()

import JSON
# json keys are strings, but we use hashes which are UInt
JSON.convert(T::Type{UInt64}, v::String) = parse(UInt64, v)

if length(translated_text) === 0
    if isfile(cache_path)
        merge!(translated_text, JSON.parsefile(cache_path; dicttype=cache_dict_type))
        display("loaded translations from $cache_path")
        cp(cache_path, cache_path_bak; force=true)
    elseif isfile(cache_path_bak)
        merge!(translated_text, JSON.parsefile(cache_path_bak; dicttype=cache_dict_type))
        display("loaded translations from $cache_path_bak")
    else
        translated_text = IdDict{UInt64, String}()
        display("no previous translations found at $cache_path")
    end
end

@doc "syncs translations file with in-memory translated text"
function update_translations()
    open(cache_path, "w") do f
        JSON.print(f, translated_text)
    end
end

@doc "returns the cached translation if present, otherwise the return value of the translation function f"
function translate(str::String, tr::Union{Function, PyObject})
    let k = hash(str)
    if haskey(translated_text, k)
        return translated_text[k]
    else
        let trans = tr(str)
        translated_text[k] = isnothing(trans) ? "" : trans
        end
    end
    end
end

end
