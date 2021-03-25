module ThreadsAPIBenchmarks

using Glob
using JSON

export run_benchmarks, create_default_symlink

include("core.jl")
include("runners.jl")
include("loaders.jl")

end
