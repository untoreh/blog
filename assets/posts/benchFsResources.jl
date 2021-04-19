
using PrettyTables
using ColorSchemes
using Colors:hex

header = [ "FS", "CPU (Server)", "CPU (Client)", "RAM (Server)", "RAM (Client)"]
stats = Any[
"xtreemefs"  100 25 300 201 ;
"glusterfs"   100 50 92 277;
"beegfs"      80 80 42 31 ;
"orangefs"    15 75 60 20 ;
]

function minmax(data, header)
    ncols = size(data, 2)
    # Dict(header[n] => extrema(selectdim(data, 2, n)) for n in 2:ncols )
    [extrema(selectdim(data, 2, n)) for n in 2:ncols]
end

const data_minmax = minmax(stats, header)

cs = ColorSchemes.flag_ml

function choose_color_html(h, data, i, j)
    # NOTE: ensure that this function always returns an HTMLDecoration
    let cell = data[i, j]
        min, max = data_minmax[j-1]
        cell_norm = (cell - min) / (max - min)
        HTMLDecoration(color="#" * hex(get(cs, 1 - cell_norm)))
    end
end


function gen_table(stats)
    hl = HTMLHighlighter(f=(dt, i, j) -> j > 1, fd=choose_color_html)
    open(joinpath(@__DIR__,  "output/", replace(basename(@__FILE__), ".jl" => ".out")), "w") do f
    pretty_table(f, stats, header;
                   # header_crayon=crayon"yellow bold",
                   # formatters=(format_num,),
                   highlighters=(hl,),
                 backend=:html,
                 tf=tf_html_matrix,
                 alignment=:c,
                 standalone=false,
                 )
    end
end
gen_table(stats)
