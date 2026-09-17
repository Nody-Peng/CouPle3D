shader_type spatial;
render_mode specular_disabled;
uniform vec4 lawn_color : source_color = vec4(0.345, 0.737, 0.263, 1.0);
uniform vec4 grass_light : source_color = vec4(0.447, 0.804, 0.337, 1.0);
uniform vec4 grass_dark : source_color = vec4(0.306, 0.682, 0.235, 1.0);
varying vec3 world_point;
void vertex() { world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
 // Sparse, world-anchored tufts keep the lawn quiet at every camera angle.
 vec2 cell = floor(world_point.xz / 0.32);
 float n = fract(sin(dot(floor(cell / 3.0), vec2(12.9898, 78.233))) * 43758.5453);
 vec2 tuft = mod(cell, 3.0);
 float mark = step(0.97, n) * step(1.0, tuft.x) * step(tuft.x, tuft.y);
 ALBEDO = mix(lawn_color.rgb, grass_light.rgb, mark * 0.40);
 ALBEDO = mix(ALBEDO, grass_dark.rgb, step(n, 0.045) * 0.3);
 ROUGHNESS = 1.0;
}
