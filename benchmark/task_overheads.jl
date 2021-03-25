using JSON
include("utils.jl")

function task_overheads()
    tid = mod1(Threads.threadid() + 1, Threads.nthreads())
    t1 = Ref(zero(time_ns()))
    t0 = time_ns()
    task = Threads.@task t1[] = time_ns()
    task.sticky = false
    ccall(:jl_set_task_tid, Cvoid, (Any, Cint), task, tid - 1)
    schedule(task)
    wait(task)
    t2 = time_ns()
    return (
        spawn_overhead = t1[] - t0,
        sync_overhead = t2 - t1[],
    )
end

function main(args = ARGS)
    output, = args
    mkpath(dirname(output))
    data = Dict(
        :results => sample(task_overheads, 10_000),
        :metadata => metadata(),
    )
    open(output, write = true) do io
        JSON.print(io, data)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
