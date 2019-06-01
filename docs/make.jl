push!(LOAD_PATH,"../src/")

using Documenter, DTWDT

makedocs(
    modules=[DTWDT],
    sitename="DTWDT.jl",
    authors="kurama",
    pages=Any[
        "Home" => "index.md",
    ],
)

deploydocs(
    repo="github.com/kura-okubo/DTWDT.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing,
)
