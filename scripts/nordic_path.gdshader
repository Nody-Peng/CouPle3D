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
 vec3 stone=mix(vec3(0.62,0.65,0.61),vec3(0.80,0.77,0.69),n);
 ALBEDO=mix(vec3(0.53,0.55,0.50),stone,gap);
 ROUGHNESS=0.95;
}
