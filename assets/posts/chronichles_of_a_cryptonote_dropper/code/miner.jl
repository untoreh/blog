# This file was generated, do not modify it. # hide
#hideall
using Kroki
miner = """
@startuml

control miner
rectangle endpoint [
endpoint
]
rectangle proxy [
proxy
]
storage pool [
pool
]

miner <=> "forwards to proxy" endpoint
endpoint <=> "handle jobs" proxy
proxy <=> "submit shares" pool
@enduml
"""
dg = Kroki.Diagram(:PlantUML, miner)
open(joinpath(@OUTPUT, "miner.png"), "w+") do f
    show(f, "image/png", dg)
end