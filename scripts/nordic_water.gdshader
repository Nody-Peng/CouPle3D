shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform vec4 water_color : source_color = vec4(0.0,0.608,0.816,1.0);
uniform vec4 water_deep : source_color = vec4(0.082,0.416,0.765,1.0);
uniform vec4 water_foam : source_color = vec4(0.584,0.894,0.918,1.0);
varying vec3 world_point;
void vertex(){world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 // Stepped ripple patches stay attached to the 3D surface as the camera rotates.
 vec2 cell=floor(world_point.xz/vec2(0.36,0.24));
 float wave=sin(cell.x*0.43+cell.y*0.31+floor(TIME*3.0)*0.18);
 float patch=sin(cell.y*0.73-cell.x*0.18);
 ALBEDO=mix(water_color.rgb,water_deep.rgb,step(0.68,wave*patch));
 float glint=step(0.96,wave)*step(0.72,patch);
 ALBEDO=mix(ALBEDO,water_foam.rgb,glint*0.65);
 ROUGHNESS=1.0;
}
