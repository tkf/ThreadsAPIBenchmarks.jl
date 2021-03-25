using JSON
include("utils.jl")

function notify_overheads()
    results = [Ref{Any}() for _ in 1:Threads.nthreads()]
    counter1 = Ref(0)
    cond = Threads.Condition()
    tasks = Task[]
    for (tid, ref) in pairs(results)
        task = @task begin
            @assert tid == Threads.threadid()
            # print('.')
            lock(cond) do
                if (counter1[] += 1) == Threads.nthreads()
                    # println("notifying")
                    t0 = time_ns()
                    notify(cond)
                    t1 = time_ns()
                    ref[] = (t0, t1)
                else
                    while counter1[] < Threads.nthreads()
                        wait(cond)
                    end
                    ref[] = time_ns()
                end
            end
        end
        ccall(:jl_set_task_tid, Cvoid, (Any, Cint), task, tid - 1)
        schedule(task)
        push!(tasks, task)
    end
    foreach(wait, tasks)
    T = typeof(time_ns())
    notified = T[r[] for r in results if r[] isa Number]
    pre, post = only(r[] for r in results if !(r[] isa Number))
    return (; notified, pre, post)
end

function main(args = ARGS)
    output, = args
    mkpath(dirname(output))
    data = Dict(
        :results => sample(notify_overheads, 1000),
        :metadata => metadata(),
    )
    open(output, write = true) do io
        JSON.print(io, data)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
