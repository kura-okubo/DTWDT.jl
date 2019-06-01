<<<<<<< HEAD
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
=======
push!(LOAD_PATH,"../src/")

using Documenter, DTWDT

makedocs(
    modules = [DTWDT],
    format = Documenter.HTML(
        # Use clean URLs, unless built as a "local" build
        prettyurls = !("local" in ARGS),
        canonical = "https://kura-okubo.github.io/DTWDT.jl/stable/",
        assets = ["assets/favicon.ico"],
    ),
    clean = false,
    sitename="DTWDT.jl",
    authors="kurama",
    linkcheck = !("skiplinks" in ARGS),
    pages = [
        "Home" => "index.md",
    ],
    strict = true,
)

deploydocs(
    repo="github.com/kura-okubo/DTWDT.jl.git",
>>>>>>> dev
    target = "build",
    deps   = nothing,
    make   = nothing,
)
