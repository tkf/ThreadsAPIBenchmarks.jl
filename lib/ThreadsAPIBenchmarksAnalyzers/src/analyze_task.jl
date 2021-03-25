module TaskOverheads

using DataFrames
using DataFrames: AbstractDataFrame
using Plots
using Statistics: median
using ThreadsAPIBenchmarks: load_task_overheads

load_rawdf(args...; kwargs...) = DataFrame(collect(load_task_overheads(args...; kwargs...)))

function plot_hists(rawdf::AbstractDataFrame)
    # ad-hoc filtering of extremes
    th_spawn = median(rawdf.spawn_overhead) * 100
    th_sync = median(rawdf.sync_overhead) * 100
    ok = (rawdf.spawn_overhead .< th_spawn) .& (rawdf.sync_overhead .< th_sync)
    rawdf = rawdf[ok, :]

    groups = groupby(rawdf, :nthreads, sort = true)
    colors = getindex.(Ref(cgrad(:vik)), range(0, 1, length = length(groups)))
    plt_spawn = plot()
    plt_sync = plot()

    for (i, (k, g)) in enumerate(pairs(groups))
        stephist!(
            plt_spawn,
            g.spawn_overhead,
            label = "N=$(k.nthreads)",
            color = colors[i],
            linewidth = 4,
        )
        stephist!(
            plt_sync,
            g.sync_overhead,
            label = "N=$(k.nthreads)",
            color = colors[i],
            linewidth = 4,
        )
    end

    return plot(
        plot!(plt_spawn, ylabel = "spawn"),
        plot!(plt_sync, ylabel = "sync", xlabel = "overhead [ns]"),
        yticks = nothing,
        xlim = (0, 15_000),
        layout = (2, 1),
        left_margin = 5 * Plots.mm,
    )
end

function plot_seq(rawdf::AbstractDataFrame)
    groups = groupby(rawdf, :nthreads, sort = true)
    plts = map(pairs(groups)) do (k, g)
        p = plot()
        scatter!(
            p,
            g.spawn_overhead,
            markershape = :xcross,
            markersize = 3,
            label = "spawn",
            ylabel = "overhead [ns] (N=$(k.nthreads))",
            xlabel = "trial",
        )
        scatter!(
            p,
            g.sync_overhead,
            markershape = :cross,
            markersize = 3,
            label = "sync",
        )
        return p
    end

    ymax = nextpow(10, max(maximum(rawdf.spawn_overhead), maximum(rawdf.sync_overhead)))
    ymin = prevpow(10, min(minimum(rawdf.spawn_overhead), minimum(rawdf.sync_overhead)))
    return plot(plts...; ylim = (ymin, ymax), yscale = :log10)
end

function analyze(args...; kwargs...)
    rawdf = load_rawdf(args...; kwargs...)
    return (
        rawdf = rawdf,
        hists = plot_hists(rawdf),
        seq = plot_seq(rawdf),
        #
    )
end

end # module TaskOverheads
