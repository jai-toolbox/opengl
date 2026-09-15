vec3 if_early_return(float x, float y) {
    if (((x <= 0.0) || (y <= 0.0))) {
        return vec3(0.0);
    }
    return vec3(x, y, 1.0);
}
