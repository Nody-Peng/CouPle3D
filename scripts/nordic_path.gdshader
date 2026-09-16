shader_type spatial;
render_mode cull_disabled;
varying vec3 stone_world;
void vertex(){stone_world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 q=stone_world.xz/vec2(0.78,0.48);
 q.x+=mod(floor(q.y),2.0)*0.5;
 vec2 cell=floor(q),f=fract(q);
 float n=fract(sin(dot(cell,vec2(12.9898,78.233)))*43758.5453);
 float edge=min(min(f.x,1.0-f.x),min(f.y,1.0-f.y));
 float gap=smoothstep(0.025,0.07,edge);
 vec3 stone=mix(vec3(0.72,0.48,0.29),vec3(0.85,0.64,0.40),n);
 ALBEDO=mix(vec3(0.64,0.42,0.27),stone,gap);
 ROUGHNESS=0.95;
}
