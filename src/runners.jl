benchmarksdir() = joinpath(@__DIR__, "..", "benchmark")

function run_benchmarks(
    outdir = default_benchmarkstore();
    nthreadsrange = 2 .^ (1:floor(Int, log2(cld(Sys.CPU_THREADS, 2)))),
)
    julia = `$(Base.julia_cmd()) --startup-file=no`
    for name in ["task_overheads", "notify_overheads"]
        for nthreads in nthreadsrange
            @info "Executing benchmark `$name` with $nthreads threads"
            outfile = joinpath(outdir, string(nthreads), name * ".json")
            script = joinpath(benchmarksdir(), name * ".jl")
            @time run(`$julia --threads=$nthreads $script $outfile`)
        end
    end
end
