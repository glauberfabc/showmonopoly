extends Node2D
# Letras brancas recebem o degradê; o contorno da fonte mantém o vermelho.
var caption = ""
var face = null

func _init():
	var shader = Shader.new()
	shader.code = """shader_type canvas_item;
varying float local_y;
uniform float type_size = 40.0;
void vertex() { local_y = VERTEX.y; }
void fragment() {
    vec4 tint = COLOR;
    if (tint.r > 0.9 && tint.g > 0.9 && tint.b > 0.9) {
        float t = clamp(local_y / type_size, 0.0, 1.0);
        vec3 gold = mix(vec3(1.0, 1.0, 0.78), vec3(1.0, 0.80, 0.08), smoothstep(0.15, 0.58, t));
        gold = mix(gold, vec3(1.0, 0.39, 0.015), smoothstep(0.58, 1.0, t));
        tint.rgb = gold;
    }
    COLOR = tint * texture(TEXTURE, UV);
}
"""
	material = ShaderMaterial.new()
	material.shader = shader

func set_amount(value, typeface, at):
	position = at
	visible = true
	if caption != value or face != typeface:
		caption = value
		face = typeface
		material.set_shader_param("type_size", float(face.size))
		update()

func _draw():
	if face == null: return
	var baseline = Vector2(0, face.size)
	draw_string(face, baseline + Vector2(2, 4), caption, Color("501008"))
	draw_string(face, baseline, caption, Color.white)
