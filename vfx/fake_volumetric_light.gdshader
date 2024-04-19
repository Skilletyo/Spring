shader_type spatial;
render_mode blend_mix, unshaded;
uniform vec3 tint_color: source_color = vec3(1.0);
//uniform float transparency = 0.5;
uniform float fresnel_value = 0.5;
uniform float transparency_multiplier = 0.5;
uniform float proximity_fade_distance;
uniform float distance_fade_min = 0.0;
uniform float distance_fade_max = 10.0;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;uniform vec3 uv1_scale;

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	
	float basic_fresnel = fresnel(fresnel_value, NORMAL, VIEW);
	ALBEDO = tint_color.rgb;
	
	// Calculate proximity
	float depth_tex = textureLod(depth_texture,SCREEN_UV,0.0).r;
	vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV*2.0-1.0,depth_tex,1.0);
	world_pos.xyz/=world_pos.w;
	ALPHA = clamp(1.0-smoothstep(world_pos.z+proximity_fade_distance,world_pos.z,VERTEX.z),0.0,1.0);
	ALPHA *= clamp(smoothstep(distance_fade_min, distance_fade_max, length(VERTEX)), 0.0, 1.0);
	
	ALPHA *= (1.0 - basic_fresnel) * transparency_multiplier;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
