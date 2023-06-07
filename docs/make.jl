# Run this file to build a new documentation
import Pkg; 
Pkg.add("Documenter")
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


deploydocs(
    repo = "github.com/Finn-Sueberkrueb/Vicon.jl.git",
)