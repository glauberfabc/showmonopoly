extends Reference
# Bolas 3D desenhadas por código: esfera com luz difusa, brilho especular, luz de borda e disco branco para o número.
const SIZE = 72
const NUMBER_COLORS = [Color("f6c52b"), Color("ff7f24"), Color("ec4a97"), Color("20b8cc"), Color("9a63f2")]
const VAULT_COLORS = [Color("2fc25e"), Color("e5413f"), Color("3478ea")]
const CARD_COLORS = [Color("45b886"), Color("df6860"), Color("57a8db"), Color("b493d9")]

static func number_group(number):
	return int(clamp(int((number - 1) / 18), 0, 4))

static func make(base, with_disc = true):
	var img = Image.new()
	img.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.lock()
	var light = Vector3(-0.42, -0.58, 0.69).normalized()
	var half = (light + Vector3(0, 0, 1)).normalized()
	var cream = Color("fff6dc")
	for y in range(SIZE):
		for x in range(SIZE):
			var nx = (x + 0.5) / SIZE * 2.0 - 1.0
			var ny = (y + 0.5) / SIZE * 2.0 - 1.0
			var r = sqrt(nx * nx + ny * ny)
			if r > 1.03:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var alpha = clamp((1.02 - r) * SIZE * 0.5, 0.0, 1.0)
			var z = sqrt(max(0.0, 1.0 - r * r))
			var n = Vector3(nx, ny, z)
			var diff = max(0.0, n.dot(light))
			var spec = pow(max(0.0, n.dot(half)), 34.0)
			var rim = pow(1.0 - z, 2.4)
			var bounce = pow(max(0.0, ny), 2.0) * 0.18
			var shade = 0.30 + 0.80 * diff
			var col = Color(base.r * shade, base.g * shade, base.b * shade, 1.0)
			col = Color(col.r + base.r * bounce, col.g + base.g * bounce, col.b + base.b * bounce, 1.0)
			col = Color(col.r + rim * 0.22, col.g + rim * 0.22, col.b + rim * 0.26, 1.0)
			if with_disc:
				if r < 0.60:
					var s2 = 0.80 + 0.20 * diff
					col = Color(cream.r * s2, cream.g * s2, cream.b * s2, 1.0)
				elif r < 0.65:
					col = Color(col.r * 0.55, col.g * 0.55, col.b * 0.55, 1.0)
			var glint = spec * (0.55 if with_disc and r < 0.60 else 0.95)
			col = Color(min(1.0, col.r + glint), min(1.0, col.g + glint), min(1.0, col.b + glint), alpha)
			img.set_pixel(x, y, col)
	img.unlock()
	var texture = ImageTexture.new()
	texture.create_from_image(img, Texture.FLAG_FILTER)
	return texture

static func build_set():
	var set = {}
	for i in range(NUMBER_COLORS.size()):
		set["n%d" % i] = make(NUMBER_COLORS[i])
	for i in range(VAULT_COLORS.size()):
		set["v%d" % i] = make(VAULT_COLORS[i])
	for i in range(CARD_COLORS.size()):
		set["c%d" % i] = make(CARD_COLORS[i], false)
	set["gold"] = make(Color("e9bb4c"))
	return set
