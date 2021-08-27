module cssFlags

using NodeJS
using PyCall
using Conda
using Franklin; fr = Franklin
import Pkg

ppath = dirname(Pkg.project().path)
flags_path = joinpath("node_modules", "flag-icon-css/")
vars_file = joinpath(flags_path, "less", "variables.less")
css_flags_file = joinpath(flags_path, "less", "flag-icon-list.less")

script = "flag-icon.min.css"
csspath = joinpath(ppath, "_css", script)
npm = npm_cmd()

const country_langs = Dict{String, String}(
    "ar" => "sa",
    "en" => "gb",
    "el" => "gr",
    "hi" => "in",
    "pa" => "in",
    "ja" => "jp",
    "jw" => "id",
    "bn" => "bd",
    "tl" => "ph",
    "zh" => "cn",
    "ko" => "kr",
    "uk" => "ua",
    "zu" => "za",
    "vi" => "vn",
    "ur" => "pk",
    "sv" => "se"
)

function lang_to_country(lang)
    if haskey(country_langs, lang)
        country_langs[lang]
    else
        lang
    end
end

function check_path()
    if pwd() !== ppath
        @info "Switching path to project root $ppath"
        cd(ppath)
    end
end

function install()
    if run(`$npm list flag-icon-css`).exitcode != 0
        run(`$npm install flag-icon-css`)
        cd(flags_path)
        run(`$npm install`)
    end
end

function select_langs()
    fr.process_config()

    flags = IOBuffer()
    for (_, code) in fr.globvar(:languages)
        println(flags, ".flag-icon($(lang_to_country(code)));")
    end

    write(css_flags_file, String(take!(flags)))
    close(flags)
end

function build()
    # change flags path to assets/flags
    flags_vars = read(vars_file, String)
    flags_vars = replace(flags_vars,
                         "@flag-icon-css-path: '../flags';" =>
                             "@flag-icon-css-path: '../assets/flags';")
    write(vars_file, flags_vars)
    cd(flags_path)
    run(`node_modules/grunt/bin/grunt build`)
    cd(ppath)
end

function copy()
    cd(flags_path)
    cp("css/$script", csspath; force=true)
    @info "copied cssflags to $csspath"
    cd(ppath)
    flags_dir = joinpath("$(flags_path)", "flags")
    flags_target =  joinpath(fr.path(:assets), "flags")
    if ispath(flags_target)
        @warn "flags directory $flags_target exists, skipping"
    else
        cp(realpath(flags_dir), flags_target)
        @info "copied $flags_dir to $flags_target"
    end
end

function genflags()
    check_path()
    install()
    select_langs()
    build()
    copy()
end

end
