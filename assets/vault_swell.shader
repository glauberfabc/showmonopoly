shader_type canvas_item;
// Cofre que enche: barriga que incha, porta que entorta, luz vazando pelas frestas,
// e na abertura a porta gira sobre a dobradiça revelando o interior cheio.
uniform sampler2D opened_art;
uniform vec4 source_rect;
uniform vec2 art_size = vec2(1024.0, 1536.0);
uniform float opening = 0.0;
uniform float impact = 0.0;
uniform float fill = 0.0;
uniform float time = 0.0;
uniform float seed = 0.0;
uniform float flash = 0.0;

const vec2 DOOR_MIN = vec2(0.23, 0.23);
const vec2 DOOR_MAX = vec2(0.81, 0.84);

void fragment() {
	vec2 local = (UV * art_size - source_rect.xy) / source_rect.zw;
	float feather = smoothstep(0.0, 0.06, local.x) * smoothstep(0.0, 0.06, 1.0-local.x) * smoothstep(0.0, 0.10, local.y) * smoothstep(0.0, 0.05, 1.0-local.y);
	float strain = fill * (1.0 - smoothstep(0.0, 0.6, opening));
	// 1) barriga: o centro cresce mais que as bordas (efeito barril)
	vec2 c = vec2(0.5, 0.60);
	vec2 d = local - c;
	vec2 dn = d * vec2(1.0, 1.1);
	float r2 = clamp(dot(dn, dn) * 2.4, 0.0, 1.0);
	float belly = strain * 0.45 * (1.0 - r2);
	vec2 warped = c + d / (1.0 + belly);
	// 2) porta entortando: ondas, torção em sela e arqueamento
	vec2 dmin = warped - DOOR_MIN;
	vec2 dmax = DOOR_MAX - warped;
	float edge = min(min(dmin.x, dmax.x), min(dmin.y, dmax.y));
	float inside = smoothstep(-0.01, 0.02, edge);
	float tension = strain * strain;
	vec2 shift = vec2(0.0);
	shift.x += sin(warped.y * 26.0 + time * 11.0 + seed) * 0.0065 * tension * inside;
	shift.y += cos(warped.x * 21.0 + time * 9.0 + seed) * 0.0055 * tension * inside;
	shift.x += (warped.x - 0.5) * (warped.y - 0.55) * 0.30 * tension * inside;
	shift.y += (warped.x - 0.5) * (warped.y - 0.55) * -0.12 * tension * inside;
	vec2 sample_local = warped + shift;
	vec2 sample_uv = (source_rect.xy + sample_local * source_rect.zw) / art_size;
	vec4 closed = texture(TEXTURE, sample_uv);
	vec4 opened = texture(opened_art, UV);
	// luz vazando pelas frestas da porta
	float seam = exp(-pow(edge * 60.0, 2.0)) * step(-0.03, edge);
	float pulse = 0.55 + 0.45 * sin(time * (8.0 + 10.0 * fill) + seed);
	vec3 leak = vec3(1.0, 0.78, 0.26) * seam * tension * (0.6 + 1.1 * pulse) * 1.1;
	closed.rgb += leak;
	closed.rgb += vec3(0.22, 0.06, 0.0) * tension * (0.5 + 0.5 * pulse) * (1.0 - r2);
	float reveal = smoothstep(0.0, 0.8, opening);
	vec4 color = mix(closed, opened, reveal);
	// a porta (já torta) gira sobre a dobradiça esquerda
	if (opening > 0.01 && opening < 0.98) {
		float width = 0.63 * cos(opening * 1.45);
		float door_x = (local.x - 0.19) / width;
		if (door_x >= 0.0 && door_x <= 1.0 && local.y > 0.43 && local.y < 0.90) {
			vec2 door_uv = (source_rect.xy + vec2(0.19 + door_x * 0.63, local.y) * source_rect.zw) / art_size;
			vec4 door = texture(TEXTURE, door_uv);
			door.rgb *= 1.0 - opening * 0.22;
			color = mix(color, door, smoothstep(0.01, 0.15, opening) * (1.0 - smoothstep(0.85, 0.98, opening)));
		}
	}
	color.rgb += vec3(1.0, 0.75, 0.22) * impact * 0.15;
	color.rgb += vec3(1.0, 0.95, 0.75) * flash;
	COLOR = vec4(color.rgb, color.a * feather);
}
