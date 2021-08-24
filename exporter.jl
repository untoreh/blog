excluded = Set([names(@__MODULE__; all=true)..., :excluded, Symbol(@__MODULE__), :eval, :include])
function exportall(override=true)
    for n in Base.names(@__MODULE__; all=true)
        if n !== :exportall &&
            Base.isidentifier(n) &&
            n ∉ excluded &&
            (override || !isdefined(Main, n))
            @eval export $n
        end
    end
end
