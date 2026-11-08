// GPU benchmark queries are drained after the batch, never between timed draws.
// The callback supplies its own target, program and draw state.
GL_Benchmark_Draw :: #type (user_data: *void);
GL_Benchmark_Result :: struct {
    median_gpu_ms, p10_gpu_ms, p90_gpu_ms: float64;
    median_submit_ms: float64;
    samples_passed: u64;
}

gl_benchmark_percentile :: (values: [] float64, fraction: float64) -> float64 {
    assert(values.count > 0);
    for i: 1..values.count-1 {
        value := values[i]; j := i;
        while j > 0 && values[j-1] > value { values[j] = values[j-1]; j -= 1; }
        values[j] = value;
    }
    index := cast(float64)(values.count-1)*fraction;
    low := cast(int)index; high := min(low+1,values.count-1);
    return values[low]+(values[high]-values[low])*(index-cast(float64)low);
}

gl_benchmark_draw :: (draw: GL_Benchmark_Draw, user_data: *void, samples: s32 = 24, warmup: s32 = 8) -> GL_Benchmark_Result {
    assert(samples >= 4 && samples <= 240 && warmup >= 1 && warmup <= 64);
    queries: [..] GLuint;
    array_resize(*queries,samples+2);
    gl_create_queries(queries);
    defer { gl_delete_queries(queries); array_free(queries); }
    // This also waits for shader compilation and warmup work before sampling.
    gl_begin_query(GL_TIME_ELAPSED,queries[samples]);
    for i: 0..warmup-1 draw(user_data);
    gl_end_query(GL_TIME_ELAPSED);
    elapsed: GLuint64;
    gl_get_query_u64_parameter(queries[samples],GL_QUERY_RESULT,*elapsed);
    // Coverage is an untimed diagnostic, not an extra query in the timing loop.
    gl_begin_query(GL_SAMPLES_PASSED,queries[samples+1]);
    draw(user_data);
    gl_end_query(GL_SAMPLES_PASSED);
    gpu, cpu: [..] float64;
    array_resize(*gpu,samples); array_resize(*cpu,samples);
    defer array_free(gpu); defer array_free(cpu);
    for i: 0..samples-1 {
        gl_begin_query(GL_TIME_ELAPSED,queries[i]);
        start := current_time_monotonic();
        draw(user_data);
        cpu[i] = to_float64_seconds(current_time_monotonic()-start)*1000;
        gl_end_query(GL_TIME_ELAPSED);
    }
    for i: 0..samples-1 {
        gl_get_query_u64_parameter(queries[i],GL_QUERY_RESULT,*elapsed);
        gpu[i] = cast(float64)elapsed/1000000;
        assert(gpu[i] > 0,"GPU timer returned zero; this context cannot provide usable timings");
    }
    result: GL_Benchmark_Result;
    gl_get_query_u64_parameter(queries[samples+1],GL_QUERY_RESULT,*result.samples_passed);
    result.median_gpu_ms = gl_benchmark_percentile(gpu,0.5);
    result.p10_gpu_ms = gl_benchmark_percentile(gpu,0.1);
    result.p90_gpu_ms = gl_benchmark_percentile(gpu,0.9);
    result.median_submit_ms = gl_benchmark_percentile(cpu,0.5);
    return result;
}
