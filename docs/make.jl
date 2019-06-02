push!(LOAD_PATH,"../src/")

using Documenter, DTWDT

makedocs(
    modules = [DTWDT],
    format = Documenter.HTML(),
    sitename="DTWDT.jl",
    authors="kurama",
    pages = [
        "Home" => "index.md",
        "Installation" => "Installation.md",
    ],
)

deploydocs(
    repo="github.com/kura-okubo/DTWDT.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing,
)
