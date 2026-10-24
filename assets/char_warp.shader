shader_type canvas_item;
// Dá profundidade a um personagem pintado na arte de fundo: respiração, guinada (yaw) como uma
// rotação em torno do eixo vertical e aceno da mão. A deformação é multiplicada por uma máscara
// que se anula nas bordas do recorte, então o personagem se mexe "à frente" do cenário sem emendas.
uniform vec2 tex_size = vec2(1024.0, 1536.0);
uniform vec4 box = vec4(0.0, 12.0, 320.0, 410.0);       // x, y, largura, altura do recorte (px da arte)
uniform vec2 center = vec2(120.0, 215.0);               // eixo do personagem
uniform float side = 1.0;                               // 1: borda direita some; -1: borda esquerda some
uniform vec4 protect = vec4(185.0, 200.0, 840.0, 322.0); // retângulo da moldura de acumulados (x0,y0,x1,y1)
uniform vec2 hand = vec2(270.0, 115.0);
uniform vec2 wrist = vec2(235.0, 130.0);
uniform float t = 0.0;
uniform float phase = 0.0;
uniform float sway = 3.0;
uniform float yaw = 4.5;
uniform float breath = 4.0;
uniform float wave = 0.035;

void fragment() {
	vec2 p = UV * tex_size;
	float wy = smoothstep(box.y, box.y + 60.0, p.y) * (1.0 - smoothstep(box.y + box.w - 110.0, box.y + box.w, p.y));
	float wx;
	if (side > 0.0) {
		wx = 1.0 - smoothstep(box.x + box.z - 90.0, box.x + box.z, p.x);
	} else {
		wx = smoothstep(box.x, box.x + 90.0, p.x);
	}
	float inside_x = smoothstep(protect.x - 14.0, protect.x + 8.0, p.x) * (1.0 - smoothstep(protect.z - 8.0, protect.z + 14.0, p.x));
	float inside_y = smoothstep(protect.y - 14.0, protect.y + 8.0, p.y) * (1.0 - smoothstep(protect.w - 8.0, protect.w + 14.0, p.y));
	float w = wy * wx * (1.0 - inside_x * inside_y);
	float h = clamp(1.0 - (p.y - box.y) / box.w, 0.0, 1.0);
	float u = clamp((p.x - center.x) / (box.z * 0.5), -1.0, 1.0);
	float bulge = 1.0 - u * u;
	vec2 d = vec2(0.0);
	d.x += sway * sin(t * 1.15 + phase) * (0.25 + 0.75 * h);
	d.x += yaw * sin(t * 0.9 + phase + 1.3) * bulge * h;
	d.y -= breath * (0.5 + 0.5 * sin(t * 1.7 + phase)) * h * 0.9;
	float hw = 1.0 - smoothstep(26.0, 88.0, length(p - hand));
	float a = wave * sin(t * 3.1 + phase) * hw;
	vec2 r = p - wrist;
	vec2 turned = vec2(r.x * cos(a) - r.y * sin(a), r.x * sin(a) + r.y * cos(a));
	d += (turned - r) * hw;
	vec2 q = p - d * w;
	COLOR = texture(TEXTURE, q / tex_size);
}
