shader_type canvas_item;
render_mode blend_add;
// Brilho do logotipo: varredura diagonal de luz + pulsação suave, restritos às cores quentes
// (dourado e vermelho) da própria arte, sem alterar a geometria das letras.
uniform vec2 tex_size = vec2(1024.0, 1536.0);
uniform vec4 region = vec4(226.0, 56.0, 576.0, 104.0);
uniform float t = 0.0;
uniform float strength = 1.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 l = (UV * tex_size - region.xy) / region.zw;
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	float warm = smoothstep(0.10, 0.42, c.r - c.b);
	float bright = smoothstep(0.35, 0.85, lum);
	float edge = smoothstep(0.0, 0.12, l.y) * (1.0 - smoothstep(0.88, 1.0, l.y)) * smoothstep(0.0, 0.05, l.x) * (1.0 - smoothstep(0.95, 1.0, l.x));
	float mask = warm * (0.30 + 0.70 * bright) * edge;
	float x = l.x + l.y * 0.35;
	float pos = fract(t * 0.30) * 1.9 - 0.45;
	float band = exp(-pow((x - pos) * 7.5, 2.0));
	float second = exp(-pow((x - (pos - 0.22)) * 16.0, 2.0)) * 0.45;
	float pulse = 0.5 + 0.5 * sin(t * 2.3);
	vec3 glow = vec3(1.0, 0.92, 0.62) * (band * 0.95 + second + pulse * 0.16) * mask * strength;
	COLOR = vec4(glow, 1.0);
}
