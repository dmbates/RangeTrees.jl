using RangeTrees
using Documenter

DocMeta.setdocmeta!(RangeTrees, :DocTestSetup, :(using RangeTrees); recursive=true)

makedocs(;
    modules=[RangeTrees],
    authors="Douglas Bates <dmbates@gmail.com> and contributors",
    repo="https://github.com/dmbates/RangeTrees.jl/blob/{commit}{path}#{line}",
    sitename="RangeTrees.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://dmbates.github.io/RangeTrees.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/dmbates/RangeTrees.jl",
    devbranch="main",
)
