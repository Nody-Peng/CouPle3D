shader_type spatial;
// A color gradient gives crowns depth even on the web preset without real-time shadows.
uniform vec4 canopy_color : source_color = vec4(0.263,0.533,0.286,1.0);
varying float crown_up;
void vertex(){crown_up=NORMAL.y;}
void fragment(){
 float light_band=smoothstep(-0.65,0.85,crown_up);
 vec3 shade=canopy_color.rgb*vec3(0.52,0.66,0.69);
 vec3 sunlit=canopy_color.rgb*vec3(1.20,1.13,0.91);
 ALBEDO=mix(shade,sunlit,light_band);
 ROUGHNESS=1.0;
}
