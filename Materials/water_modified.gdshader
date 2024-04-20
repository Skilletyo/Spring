shader_type spatial;

uniform vec3 water_color : source_color = vec3(0.0, 0.25, 0.45);
uniform vec3 water_color2 : source_color = vec3(0.0, 0.25, 0.45);
uniform float roughness : hint_range(0.0, 1.0) = 0.4;

uniform float wave_time = 0;
uniform sampler2D wave_texture;
uniform float wave_scale = 64.0;
uniform float height_scale = 0.85;
varying float wave_height;
varying vec3 uv_world_pos;

uniform sampler2D normal1;
uniform vec2 wave_dir1 = vec2(1.0, 0.0);
uniform sampler2D normal2;
uniform vec2 wave_dir2 = vec2(0.0, 1.0);
uniform float wave_speed : hint_range(0.0, 0.2) = 0.015;

void vertex() {
	// Vertext displacement for waves
	uv_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wave_height = texture(wave_texture, uv_world_pos.xz / wave_scale + wave_time * wave_speed).r;
	VERTEX.y += wave_height * height_scale;
}

void fragment()
{
	// Normal maps
	vec2 normal_offset1 = (TIME * wave_dir1) * wave_speed;
	vec2 normal_offset2 = (TIME * wave_dir2) * wave_speed;
	vec3 normal_blend = mix(texture(normal1, uv_world_pos.xz / wave_scale + normal_offset1), texture(normal2, uv_world_pos.xz / wave_scale + normal_offset2), 0.5).rgb;
	
	vec4 color_texture = texture(wave_texture, uv_world_pos.xz / wave_scale + normal_offset1);
	vec3 color_out = mix(water_color, water_color2, color_texture.r);
	ALBEDO = color_out;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal_blend;
}