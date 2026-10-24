shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec4 art = texture(TEXTURE, UV);
	vec2 p = UV*vec2(1024.0,1536.0);
	float box_y = step(231.0,p.y)*(1.0-step(344.0,p.y));
	float box_x = max(step(95.0,p.x)*(1.0-step(285.0,p.x)), max(step(407.0,p.x)*(1.0-step(617.0,p.x)),step(728.0,p.x)*(1.0-step(920.0,p.x))));
	float white_light = smoothstep(0.58,0.91,min(art.r,min(art.g,art.b)));
	float gold_crest = step(308.0,p.y)*step(art.b+0.18,art.r)*step(art.b+0.13,art.g);
	COLOR = vec4(art.rgb,max(white_light,gold_crest)*box_x*box_y);
}
