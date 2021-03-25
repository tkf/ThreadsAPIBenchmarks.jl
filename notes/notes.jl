# # Measuring overheads of some threading API

using DisplayAs
using ThreadsAPIBenchmarksAnalyzers: TaskOverheads, NotifyOverheads

# ## Overhead of `@spawn` and `@sync`
#
# Measuring the overhead of `@spawn` and `@sync` is not entirely trivial.
# `@btime wait(Threads.@spawn nothing)` does not reflect the actual overhead
# since `@spawn` may use the current thread to run the task. That is to say,
# the following check likely to pass even if `nthreads() > 1`:

let n = 0
    for _ in 1:1000
        n += fetch(Threads.@spawn Threads.threadid()) == Threads.threadid()
    end
    @assert n > 0
end

# ThreadsAPIBenchmarks.jl contains a benchmark for measuring the overheads of
# `@sync` and `@spawn`. That is to say, it measures sync overhead `t1 - t0` and
# `t2 - t1` of
#
# ```julia
# t0 = time_ns()
# @sync @spawn t1 = time_ns()
# t2 = time_ns()
# ```
#
# while making sure `@spawn`ed task is executed in a different OS threads.
#
# The distribution of the above measurement is shown below for different number
# `N = nthreads()` of threads:

begin
    task_overheads = TaskOverheads.analyze()
    task_overheads.hists
end |> DisplayAs.PNG
#-

# Here is a more direct plot of the raw data to show that the multimodality of
# the distribution comes from the temporal proximity of the measurements (some
# state transitions in Julia runtime, OS, or hardware?):

begin
    ## task_overheads = TaskOverheads.analyze()
    task_overheads.seq
end |> DisplayAs.PNG

# ## Overhead of `notify` (`schedule`)
#
# Following distribution describes the overheads of `wait` and `notify` on
# `Threads.Condition`. It is essentially the overhead of re-`schedule`.
#
# The first two rows (`max` and `min`) shows the distribution of the time took
# for `notify` to end the `wait` of the peer threads. The first row `max` shows
# the slowest among all threads and second row `min` is for the fastest. The
# last row `notify` is `@time notify(...)`.

begin
    notify_overheads = NotifyOverheads.analyze()
    notify_overheads.hists
end
#-

# Compared to `@sync` and `@spawn`, there are not much temporal irregularities
# especially for `N > 2`:

begin
    ## notify_overheads = NotifyOverheads.analyze()
    notify_overheads.seq
end |> DisplayAs.PNG
