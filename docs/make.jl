# Run this file to build a new documentation
using Documenter
include("../src/Vicon.jl")

makedocs(   sitename="Vicon.jl",
            format = Documenter.HTML(prettyurls = false),
            pages = [
                    "index.md",
                    "Vicon config" => "ViconConfig.md",
                    "Example" => "Example.md",
                    "Functions" => "Module.md",
                    ],
        )
