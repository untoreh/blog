using Kroki

puml = """
@startuml

control start
rectangle step [
step
]


start <=> "step" step
step <=> start
@enduml
"""
# NOTE: remember @__DIR__ is relative to the path of the SCRIPT (uml_example.jl)
let out_file = joinpath(@__DIR__, "output", "example.png")
    dg = Kroki.Diagram(:PlantUML, puml)
    open(out_file, "w+") do f
        show(f, "image/png", dg)
    en
end
