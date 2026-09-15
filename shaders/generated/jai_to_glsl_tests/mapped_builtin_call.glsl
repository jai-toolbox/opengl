float mapped_builtin_call(vec3 n, vec3 l) {
    return max(dot(n, l), 0.0);
}
