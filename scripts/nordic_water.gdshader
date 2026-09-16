shader_type spatial;
render_mode cull_disabled;
uniform vec4 water_color : source_color = vec4(0.035,0.55,0.78,1.0);
varying vec3 world_point;
void vertex(){world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float wave=sin(world_point.x*2.7+TIME*0.75)+sin(world_point.z*3.1-TIME*0.6);
 float glint=pow(max(0.0,sin(world_point.x*1.7+sin(world_point.z*2.3)+TIME*0.45)*cos(world_point.z*1.9-TIME*0.3)),8.0)*0.025;
 ALBEDO=water_color.rgb*(0.96+wave*0.025)+vec3(glint);
 ROUGHNESS=0.48;
 METALLIC=0.0;
}
