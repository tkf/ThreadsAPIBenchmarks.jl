function sample(f, nsamples::Integer)
    T = typeof(f())
    samples = Vector{T}(undef, nsamples)  # avoid allocation during measurements
    for i in eachindex(samples)
        samples[i] = f()
    end
    return samples
end

function metadata()
    return Dict(
        :nthreads => Threads.nthreads(),
        :julia_version => string(VERSION),
        # ... what else?
    )
end
