push!(LOAD_PATH,"../src/")

using Documenter, DTWDT
using DTWDT.DTWDTfunctions

makedocs(
    modules = [DTWDT],
    format = Documenter.HTML(),
    sitename="DTWDT.jl",
    authors="kurama",
    pages = [
        "Home" => "index.md",
        "Functions" => "Functions.md",
        "Sample results" => "Sampleresults.md"
        
    ],
)

deploydocs(
    repo="github.com/kura-okubo/DTWDT.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing,
)
