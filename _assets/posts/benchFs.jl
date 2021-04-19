
using PrettyTables
using ColorSchemes
using Colors:hex

header = [ "FS", "seq", "rread", "rrw", "files", "create", "read", "append", "rename", "delete"]
stats = Any[
"raw"        78793   1040.9e3  89958   179483  17.3e3   23.55e3  14.408e3  4677  5373;
"zfs"        102121  1398.5e3  92391   198410  29.18e3  4.47e3   18.98e3   4695  8468;
"f2fs"       2064e3  1455e3    101674  184495  28.32e3  10.95e3  16.89e3   4233  3912;
"xtreemefs"  159310  29117     29468   1690    0.51e3   1.19e3   0.52e3    274   330;
"glusterfs"  178026  17222     18152   5681    4.38e3   7.62e3   3.11e3    413   1076;
"beegfs"     79934   103006    85983   24867   9.83e3   12.66e3  10.47e3   2889  3588;
"orangefs"   330781  54735     41611   5523    5.12e3   7.02e3   6.13e3    638   1989;
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
    open(joinpath(@__DIR__,  "output/benchFs.out"), "w") do f
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
