using Kroki

diag_name = "os-hops"
puml = """
@startuml

control start
rectangle step [
step
]

start <=> "step" step
@enduml
"""
dg = Kroki.Diagram(:PlantUML, puml)
open(joinpath(@OUTPUT,diag_name), "w+") do f
    show(f, "image/png", dg)
end
