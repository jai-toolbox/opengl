// Empirical model for ONE synthetic shader recipe and render-target format.
// It is not a conversion from advertised FLOPS to arbitrary shader FPS.
GL_Throughput_Point :: struct { fragments, gpu_ms: float64; }
GL_Throughput_Model :: struct {
    fixed_gpu_ms, ms_per_million_fragments: float64;
    minimum_fragments, maximum_fragments: float64;
    maximum_fit_error: float64;
    validation_error: float64;
    timing_variation: float64;
    gpu_ms_per_draw, cpu_ms_per_draw, triangles_per_ms: float64;
}
GL_Throughput_Estimate :: struct {
    fragments, gpu_ms, cpu_ms, frame_ms, fps: float64;
    low_fps, high_fps, observed_error: float64;
    extrapolated: bool;
}

gl_fit_throughput_model :: (points: [] GL_Throughput_Point) -> GL_Throughput_Model, bool {
    model: GL_Throughput_Model;
    if points.count < 3 return model,false;
    mean_x, mean_y, total_weight: float64;
    model.minimum_fragments = points[0].fragments;
    for point: points {
        if !is_finite(point.fragments) || !is_finite(point.gpu_ms) || point.fragments <= 0 || point.gpu_ms <= 0 return model,false;
        weight := 1/(point.gpu_ms*point.gpu_ms);
        mean_x += weight*point.fragments/1000000;
        mean_y += weight*point.gpu_ms;
        total_weight += weight;
        model.minimum_fragments = min(model.minimum_fragments,point.fragments);
        model.maximum_fragments = max(model.maximum_fragments,point.fragments);
    }
    // Relative-error least squares gives small and large workloads comparable
    // influence, rather than fitting almost exclusively to the largest draw.
    if total_weight <= 0 || !is_finite(total_weight) return model,false;
    mean_x /= total_weight; mean_y /= total_weight;
    covariance, variance: float64;
    for point: points {
        x := point.fragments/1000000-mean_x;
        weight := 1/(point.gpu_ms*point.gpu_ms);
        covariance += weight*x*(point.gpu_ms-mean_y); variance += weight*x*x;
    }
    if variance <= 0 || !is_finite(variance) || !is_finite(covariance) return model,false;
    model.ms_per_million_fragments = covariance/variance;
    if model.ms_per_million_fragments <= 0 || !is_finite(model.ms_per_million_fragments) return model,false;
    model.fixed_gpu_ms = mean_y-model.ms_per_million_fragments*mean_x;
    if model.fixed_gpu_ms < 0 {
        model.fixed_gpu_ms = 0;
        xy, squared_x: float64;
        for point: points {
            x := point.fragments/1000000; weight := 1/(point.gpu_ms*point.gpu_ms);
            xy += weight*x*point.gpu_ms; squared_x += weight*x*x;
        }
        model.ms_per_million_fragments = xy/squared_x;
    }
    for point: points {
        prediction := gl_throughput_fragment_ms(model,point.fragments);
        model.maximum_fit_error = max(model.maximum_fit_error,abs(prediction-point.gpu_ms)/point.gpu_ms);
    }
    return model,true;
}

gl_throughput_fragment_ms :: (model: GL_Throughput_Model, fragments: float64) -> float64 {
    return model.fixed_gpu_ms+model.ms_per_million_fragments*fragments/1000000;
}

gl_estimate_throughput :: (model: GL_Throughput_Model, fragments: float64, triangles: float64,
                           draws: s32 = 1, other_cpu_ms: float64 = 0, other_gpu_ms: float64 = 0) -> GL_Throughput_Estimate, bool {
    estimate: GL_Throughput_Estimate;
    if !is_finite(fragments) || !is_finite(triangles) || !is_finite(other_cpu_ms) || !is_finite(other_gpu_ms)
        || fragments < 0 || triangles < 0 || draws < 1 || other_cpu_ms < 0 || other_gpu_ms < 0
        || model.ms_per_million_fragments <= 0 || model.triangles_per_ms <= 0 return estimate,false;
    estimate.fragments = fragments;
    // Geometry and fragment processing can overlap. The calibrated fragment
    // model already includes one draw; charge only additional draw overhead.
    estimate.gpu_ms = max(gl_throughput_fragment_ms(model,fragments),triangles/model.triangles_per_ms)
        +cast(float64)(draws-1)*model.gpu_ms_per_draw+other_gpu_ms;
    estimate.cpu_ms = cast(float64)draws*model.cpu_ms_per_draw+other_cpu_ms;
    estimate.frame_ms = max(estimate.gpu_ms,estimate.cpu_ms);
    if !is_finite(estimate.gpu_ms) || !is_finite(estimate.cpu_ms) || !is_finite(estimate.frame_ms) || estimate.frame_ms <= 0 return estimate,false;
    estimate.fps = 1000/estimate.frame_ms;
    estimate.extrapolated = fragments < model.minimum_fragments || fragments > model.maximum_fragments;
    estimate.observed_error = max(cast(float64)0.05,max(model.maximum_fit_error,max(model.validation_error,model.timing_variation)));
    estimate.low_fps = 1000/(estimate.frame_ms*(1+estimate.observed_error));
    estimate.high_fps = 1000/(estimate.frame_ms*max(cast(float64)0.05,1-estimate.observed_error));
    return estimate,true;
}
