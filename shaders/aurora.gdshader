shader_type canvas_item;
// Cheap brand aurora for the game background. Three offset sine fields, one
// vignette. Deliberately no noise texture: this has to stay warm on a Pixel 3.

uniform vec4 deep : source_color = vec4(0.070588, 0.039216, 0.164706, 1.0);
uniform vec4 violet : source_color = vec4(0.169, 0.102, 0.361, 1.0);
uniform vec4 teal : source_color = vec4(0.047, 0.231, 0.267, 1.0);
uniform float speed = 0.035;
uniform float intensity = 1.0;

void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;

	float w1 = sin(uv.x * 2.6 + t * 2.0) * 0.5 + 0.5;
	float w2 = sin(uv.y * 2.2 - t * 1.6 + w1 * 1.6) * 0.5 + 0.5;
	float w3 = sin((uv.x + uv.y) * 3.0 + t * 2.7) * 0.5 + 0.5;

	vec3 col = mix(deep.rgb, violet.rgb, w1 * 0.55);
	col = mix(col, teal.rgb, w2 * 0.30);
	col += vec3(0.025, 0.040, 0.060) * w3;

	// soft top glow, like light bleeding from above the board
	float top = smoothstep(0.45, 0.0, uv.y);
	col += vec3(0.09, 0.05, 0.16) * top * 0.35;

	// vignette
	float d = distance(uv, vec2(0.5, 0.45));
	col *= 1.0 - d * 0.55;

	COLOR = vec4(col * intensity, 1.0);
}
