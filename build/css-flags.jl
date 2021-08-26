using NodeJS
using Franklin; fr = Franklin
import Pkg

ppath = dirname(Pkg.project().path)
if pwd() !== ppath
    @info "Switching path to project root $ppath"
    cd(ppath)
end

npm = npm_cmd()
run(`$npm install grunt flag-icon-css cofeescript`)

langs = fr.process_config()

flags = IOBuffer()
for (lang, code) in fr.globvar(:languages)
    println(flags, ".flag-icon($code);")
end

flags_path = "node_modules/flag-icon-css/"
css_flags_file = "$(flags_path)less/flag-icon-list.less"
write(css_flags_file, String(take!(flags)))
close(flags)

cd(flags_path)
run(`$npm install`)
run(`node_modules/grunt/bin/grunt build`)

script = "flag-icon.min.css"
csspath = joinpath(ppath, "_css", script)
cp("css/$script", csspath)
@info "copied cssflags to $csspath"
