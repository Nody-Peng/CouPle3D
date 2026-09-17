shader_type spatial;
render_mode specular_disabled;
// Three canopy shades retain volume even when Web disables real-time shadows.
uniform vec4 canopy_color : source_color = vec4(0.263,0.533,0.286,1.0);
varying float crown_up;
void vertex(){crown_up=NORMAL.y;}
void fragment(){
 vec3 shade=canopy_color.rgb*vec3(0.42,0.60,0.64);
 vec3 sunlit=mix(canopy_color.rgb,vec3(0.86,0.91,0.55),0.18);
 vec3 leaf=mix(shade,canopy_color.rgb,step(-0.15,crown_up));
 ALBEDO=mix(leaf,sunlit,step(0.60,crown_up));
 ROUGHNESS=1.0;
}
