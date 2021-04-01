using PrettyTables

header = [ "ci" "configuration" "performance" "banhammer" ]
ci = Any[
"bitrise"  1 2  3  ;
"travis"   1 2  3  ;
]
function choose_color(h, data, i, j)
    let cell = data[i, j]
        if cell == 1
            crayon"green"
        elseif cell == 2
            crayon"yellow"
        elseif cell == 3
            crayon"red"
        end
    end
end
function format_num(v, i, j)
    if j > 1
        if v == 1
            "good"
        elseif v == 2
        "medium"
    else
        "bad"
        end
    else
        v
    end
end
hl = Highlighter(f=(data, i, j) -> j > 1 ,
                   fd=choose_color,
                   crayon=crayon"blue bold")

open("./_assets/scripts/output/ci_services_table.out", "w") do io
    pretty_table(io, ci, header,
                   header_crayon=crayon"yellow bold",
                   formatters=(format_num,),
                   highlighters=(hl), tf=tf_unicode_rounded, alignment=:c)

end
