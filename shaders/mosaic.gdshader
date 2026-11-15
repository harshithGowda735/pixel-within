shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float block : hint_range(1.0, 64.0) = 1.0;
uniform float flat_mix : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flat_color : source_color = vec4(0.06, 0.04, 0.12, 1.0);

void fragment() {
	vec2 res = vec2(320.0, 180.0);
	vec2 cell = (floor(SCREEN_UV * res / block) + 0.5) * block / res;
	vec4 c = texture(screen_tex, cell);
	COLOR = mix(c, flat_color, flat_mix);
}
