shader_type canvas_item;

uniform sampler2D NOISE_PATTERN : repeat_enable;
uniform vec2 NOISE_SCALE_1 = vec2(1,1);
uniform vec2 NOISE_SCALE_2 = vec2(1,1);
uniform vec2 SCROLL_1 = vec2(0.2, 0.1);
uniform vec2 SCROLL_2 = vec2(0.1, 0.3);
uniform sampler2D TONE_MAPPING;
uniform float BLUR : hint_range(0,7) = 3.0;
uniform float BASE_INTENSITY : hint_range(0,0.5) = 0.1;
uniform float INTENSITY_FACTOR : hint_range(0, 5.0) = 1.5;

void fragment() {
	vec4 source_texture = texture(TEXTURE, UV);
	float tex_alpha = textureLod(TEXTURE, UV, BLUR).a;
	float pattern_intensity_1 = texture(NOISE_PATTERN, UV * NOISE_SCALE_1 + TIME * SCROLL_1).r;
	float pattern_intensity_2 = texture(NOISE_PATTERN, UV * NOISE_SCALE_2 + TIME * SCROLL_2).r;
	float intensity = tex_alpha * INTENSITY_FACTOR * (pattern_intensity_1 * pattern_intensity_2 + BASE_INTENSITY);
	COLOR = source_texture + texture(TONE_MAPPING, vec2(intensity));
}
