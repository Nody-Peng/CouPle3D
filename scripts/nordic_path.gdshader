shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform vec4 path_color : source_color = vec4(0.878, 0.624, 0.400, 1.0);
uniform vec4 path_dark : source_color = vec4(0.761, 0.490, 0.310, 1.0);
uniform vec4 path_light : source_color = vec4(0.937, 0.710, 0.471, 1.0);
varying vec3 stone_world;
void vertex(){stone_world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 q=stone_world.xz/vec2(0.78,0.48);
 q.x+=mod(floor(q.y),2.0)*0.5;
 vec2 cell=floor(q),f=fract(q);
 float n=fract(sin(dot(cell,vec2(12.9898,78.233)))*43758.5453);
 float edge=min(min(f.x,1.0-f.x),min(f.y,1.0-f.y));
 float gap=step(0.035,edge);
 vec3 stone=mix(path_color.rgb,path_light.rgb,step(0.72,n)*0.55);
 ALBEDO=mix(path_dark.rgb,stone,gap);
 ROUGHNESS=1.0;
}
