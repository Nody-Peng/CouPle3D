shader_type spatial;
uniform vec4 lawn_color : source_color = vec4(0.43,0.70,0.36,1.0);
varying vec3 world_point;
void vertex(){world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float variation=sin(world_point.x*0.12+sin(world_point.z*0.1))*sin(world_point.z*0.17)*0.045;
 float mowing=sin(world_point.x*0.8+world_point.z*0.25)*0.012;
 ALBEDO=lawn_color.rgb*(1.0+variation+mowing);
 ROUGHNESS=1.0;
}
