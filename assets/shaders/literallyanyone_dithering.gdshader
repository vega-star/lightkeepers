shader_type spatial;
render_mode unshaded;

const float lin = .454545;
const float srgb = 2.2;
//render_mode blend_mul;

//INSTRUCTIONS: Simply uncomment or comment lines 92 and/or 101 to
//        activate/deactivate color behaviors

// If you feel so inclined, make yourself some uniforms to toggle/interpolate between the behaviors

//uniform float fiddler: hint_range(0.0, 1.0);
uniform float rows = 4.0;
uniform float cols = 4.0;

uniform sampler2D pal: source_color, filter_nearest, repeat_enable;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture;
uniform float dither_size;
uniform float dither_amount: hint_range(0.0, 1.0);

float lerp(float val1, float val2, float mul) {
	return val1 + (val2 - val1) * clamp(mul, 0.0, 1.0);
}

vec3 get_srgb(vec3 xyz) {

	vec3 output = vec3(pow(xyz.x, srgb), pow(xyz.y, srgb), pow(xyz.z,srgb));

	return output;
}

vec3 get_linear(vec3 xyz) {

	vec3 output = vec3(pow(xyz.x, lin), pow(xyz.y, lin), pow(xyz.z, lin));

	return output;
}

float PickColor(float x, float y) {
	float output = 0.0;

	float offset = +0.75/(rows*cols);

	x = mod(x, 1.0);
	y =  mod(y, 1.0);

	x = clamp(floor(x*(rows))/((cols*rows)), 0.0, 250.0/256.0);
	y = clamp(floor(y*(cols))/((cols)), 0.0, 250.0/256.0);

	output = y+x;

	return output;
}

vec3 dither(vec3 color_in, vec2 uv, vec2 screen_size) {
	float dith = max(1.0, dither_size);
	vec3 unaltered = color_in;
	float m = rows; float d = rows*cols;
	float f = 0.25/rows;

	color_in = get_linear(color_in);

	float output = 0.0;
	float a = floor(mod(uv.x * screen_size.x/dith, 2.0));
	float b = floor(mod(uv.y * screen_size.y/dith, 2.0));
	float c = mod(a + b , 2.0)+f;

	color_in.r += lerp( -f, f, c);

	color_in = get_srgb(color_in);

	color_in = clamp(vec3(round(color_in.r*(d))/(d),round(color_in.g*(d))/(d),round(color_in.b*(d))/(d)),0.0, 1023.5/1024.0);
	return color_in;
}

void vertex() {
	POSITION = vec4(vec3(VERTEX.x, VERTEX.y, 0.0), 1.0);
	// Called for every vertex the material is visible on.
}

void fragment() {
	float index = 0.0;

	vec3 tex_uv = vec3(UV, 0.0);
	vec4 _tex = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);

	float newval = 0.0;

	vec3 color = _tex.rgb;

	color.r = lerp(color.r, dither(color, SCREEN_UV, VIEWPORT_SIZE).r, dither_amount); // comment this line if you do not want to dither the palette

	vec3 corr = get_linear(color.rgb);

	index = PickColor(corr.r, corr.g);

	vec3 pal_read = get_srgb(textureLod(pal, vec2(index, 0.0), 0.0).rgb);

	ALBEDO.rgb = pal_read;
	//ALBEDO.rgb = dither(color, SCREEN_UV, VIEWPORT_SIZE);
	/* Uncomment the line above to disable the palette, and dither the regular screen colors*/
}
