using PrettyTables
using ColorSchemes
using Colors:hex

header = [ "FS", "seq", "rread", "rrw", "files", "create", "read", "append"]
stats = Any[
"raw"        76    266440  22489  44870  4430  6028  3688  ;
"zfs"        99    358000  23097  49602  7470  1146  4860  ;
"f2fs"       2064  372524  25418  46123  7250  2803  4325  ;
"xtreemefs"  155   7279    7366   422    131   306   134   ;
"glusterfs"  173   4305    4537   1420   1123  1951  798   ;
"beegfs"     78    25751   21495  6216   2518  3242  2682  ;
"orangefs"   323   13683   10402  1380   1310  1979  1571  ;
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
        HTMLDecoration(color="#" * hex(get(cs, cell_norm)))
    end
end


function gen_table(stats, title)
    hl = HTMLHighlighter(f=(dt, i, j) -> j > 1, fd=choose_color_html)
    open(joinpath(@__DIR__,  "output/benchFsIOPS.out"), "w") do f
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
gen_table(stats, "Bandwidth")
