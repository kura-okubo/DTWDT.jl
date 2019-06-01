using Documenter, DTWDT

makedocs(;
    modules=[DTWDT],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
        "Installation" => "Installation.md",
    ],
    repo="https://github.com/kura-okubo/DTWDT.jl/blob/{commit}{path}#L{line}",
    sitename="DTWDT.jl",
    authors="kurama",
    assets=String[],
)

deploydocs(;
    repo="github.com/kura-okubo/DTWDT.jl",
    target = "build",
    deps   = nothing,
    make   = nothing,
)
