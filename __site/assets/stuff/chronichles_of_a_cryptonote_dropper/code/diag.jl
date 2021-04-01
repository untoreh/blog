# This file was generated, do not modify it. # hide
#hideall

using Kroki
diag = """
@startuml

control runner
rectangle dnsRecord [
fetch startup script from dns record
]
rectangle payload [ 
fetch payload 
]
storage process [ 
unpack, setup, execute 
]

runner => dnsRecord
dnsRecord => payload
payload => process
@enduml
"""
dg = Kroki.Diagram(:PlantUML, diag)
open(joinpath(@OUTPUT, "diag.png"), "w+") do f
    show(f, "image/png", dg)
end