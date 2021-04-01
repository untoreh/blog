using PrettyTables

header = [ "ci" "configuration" "performance" "ban-hammer" ]
ci = Any[
"Bitrise"          3  2  2;
"Travis"           1  2  1;
"Codeship"         2  3  2;
"Gitlab"           2  1  1;
"Circleci"         3  1  2;
"Semaphore"        1  1  2;
"Docker"           2  2  1;
"Quay"             1  2  2;
"Codefresh"        3  1  2;
"Wercker"          2  2  3;
"Azure-pipelines"  2  2  3;
"Continuousphp"    3  2  2;
"Buddy"            3  3  3;
"Drone"            3  1  3;
"Appveyor"         3  2  3;
"Nevercode"        3  1  2;
"Zeist/vercel"     3  1  3;
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
function choose_color_html(h, data, i, j)
    let cell = data[i, j]
        if cell == 1
            HTMLDecoration(color="green")
        elseif cell == 2
            HTMLDecoration(color="yellow")
        elseif cell == 3
            HTMLDecoration(color="red")
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
# hl = Highlighter(f=(data, i, j) -> j > 1 ,
#                    fd=choose_color,
#                    crayon=crayon"blue bold")

hl = HTMLHighlighter(f=(data, i, j) -> j > 1,
                     fd=choose_color_html)

open(joinpath(@__DIR__,  "output/ciServicesTable.out"), "w") do f
    pretty_table(f, ci, header,
                   # header_crayon=crayon"yellow bold",
                   formatters=(format_num,),
                   highlighters=(hl,),
                 backend=:html,
                 tf=tf_html_matrix,
                 alignment=:c,
                 standalone=false,
                 )
end
