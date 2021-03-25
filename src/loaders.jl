function load_rawdata(pattern; benchmarkstore = default_benchmarkstore())
    rawdata = map(JSON.parsefile, readdir(pattern, benchmarkstore))
    sort!(rawdata, by = data -> data["metadata"]["nthreads"])
    return rawdata
end

load_task_overheads(pattern = glob"*/task_overheads.json"; kw...) =
    Iterators.map(load_rawdata(pattern; kw...)) do data
        nthreads = data["metadata"]["nthreads"]
        Iterators.map(data["results"]) do result
            (
                nthreads = nthreads,
                spawn_overhead = result["spawn_overhead"],
                sync_overhead = result["sync_overhead"],
            )
        end
    end |>
    Iterators.flatten

load_notify_overheads(pattern = glob"*/notify_overheads.json"; kw...) =
    Iterators.map(load_rawdata(pattern; kw...)) do data
        nthreads = data["metadata"]["nthreads"]
        Iterators.map(data["results"]) do result
            (
                nthreads = nthreads,
                notified = collect(Int, result["notified"]),
                pre = result["pre"],
                post = result["post"],
            )
        end
    end |>
    Iterators.flatten
