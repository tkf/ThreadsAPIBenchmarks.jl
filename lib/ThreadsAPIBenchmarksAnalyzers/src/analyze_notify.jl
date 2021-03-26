module NotifyOverheads

using DataFrames
using DataFrames: AbstractDataFrame
using Plots
using ThreadsAPIBenchmarks: load_notify_overheads

load_rawdf(args...; kwargs...) =
    DataFrame(collect(load_notify_overheads(args...; kwargs...)))

function df_notify_overheads(rawdf::AbstractDataFrame)
    df = select(rawdf, Not(:notified))
    df[!, :max] = maximum.(rawdf.notified) .- df.pre
    df[!, :min] = minimum.(rawdf.notified) .- df.pre
    df[!, :notify] = df.post .- df.pre
    return df
end

function plot_hists(rawdf::AbstractDataFrame)
    df = df_notify_overheads(rawdf)

    groups = groupby(df, :nthreads, sort = true)
    colors = getindex.(Ref(cgrad(:vik)), range(0, 1, length = length(groups)))
    plt_max = plot()
    plt_min = plot()
    plt_notify = plot()
    xmin = 1e3
    xmax = 1e6
    xlim = (xmin, xmax)

    for (i, (k, g)) in enumerate(pairs(groups))
        stephist!(
            plt_max,
            g.max,
            # label = "N=$(k.nthreads)",
            label = "",
            color = colors[i],
            linewidth = 4,
        )
        stephist!(
            plt_min,
            g.min,
            # label = "N=$(k.nthreads)",
            label = "",
            color = colors[i],
            linewidth = 4,
        )
        stephist!(
            plt_notify,
            g.notify,
            label = "N=$(k.nthreads)",
            # label = "",
            color = colors[i],
            linewidth = 4,
        )
    end

    return plot(
        plot!(plt_max, ylabel = "max"),
        plot!(plt_min, ylabel = "min"),
        plot!(plt_notify, ylabel = "notify", xlabel = "overhead [ns] (log scale)"),
        yticks = nothing,
        layout = (3, 1),
        # layout = (2, 1),
        xlim = xlim,
        xscale = :log10,
        left_margin = 5 * Plots.mm,
    )
end

function plot_seq(rawdf::AbstractDataFrame)
    groups = groupby(rawdf, :nthreads, sort = true)
    colors = getindex.(Ref(cgrad(:vik)), range(0, 1, length = length(groups)))
    plts = map(enumerate(pairs(groups))) do (i, (k, g))
        xs_notified = [i for (i, xs) in enumerate(g.notified) for _ in xs]
        ys_notified = [x - pre for (pre, xs) in zip(g.pre, g.notified) for x in xs]
        ys_notify = g.post .- g.pre
        p = plot()
        scatter!(
            p,
            xs_notified,
            ys_notified,
            markershape = :xcross,
            markersize = 1,
            label = i == 1 ? "notified" : "",
            ylabel = "overhead [ns] (N=$(k.nthreads))",
            xlabel = "trial",
        )
        scatter!(
            p,
            ys_notify,
            markershape = :cross,
            markersize = 3,
            label = i == 1 ? "notify" : "",
        )
        return p
    end

    exs = map(zip(rawdf.pre, rawdf.post, rawdf.notified)) do (pre, post, notified)
        l, h = extrema(notified .- pre)
        d = post - pre
        return (min(l, d), max(h, d))
    end

    ymax = nextpow(10, maximum(last, exs))
    ymin = prevpow(10, minimum(first, exs))
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

end # module NotifyOverheads
