shader_type canvas_item;

void fragment() {
    vec2 uv = UV;
    
    // Sky gradient
    vec3 color = mix(vec3(0.02, 0.0, 0.1), vec3(1.0, 0.5, 0.0), smoothstep(0.0, 1.0, uv.y));
    
    // Sun
    vec2 sun_pos = vec2(0.5, 0.6);
    float sun_dist = distance(uv, sun_pos);
    if (sun_dist < 0.25) {
        // glowing sun with stripes
        float stripes = sin(uv.y * 150.0 - TIME * 2.0);
        if (stripes < 0.0 || sun_dist < 0.15) {
            color = mix(vec3(1.0, 0.9, 0.0), vec3(1.0, 0.4, 0.0), uv.y);
        }
    }
    
    // City Silhouette
    float h1 = (sin(uv.x * 20.0) * cos(uv.x * 12.0) + sin(uv.x * 35.0) * 0.5) * 0.15 + 0.8;
    float h2 = (cos(uv.x * 15.0 - 5.0) * sin(uv.x * 25.0) + cos(uv.x * 40.0) * 0.5) * 0.15 + 0.85;
    
    // Buildings step functions
    h1 = floor(h1 * 20.0) / 20.0;
    h2 = floor(h2 * 25.0) / 25.0;
    
    if (uv.y > h1) {
        color = vec3(0.05, 0.02, 0.08); // front buildings
    } else if (uv.y > h2) {
        // back buildings
        color = vec3(0.1, 0.05, 0.15); 
    }
    
    COLOR = vec4(color, 1.0);
}
