shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec2 uv = UV;
	vec2 p = uv * vec2(1024.0,1536.0);
	// Animate only smoke above the side vessels; UI typography stays stationary.
	float side = max(1.0-smoothstep(60.0,115.0,abs(p.x-190.0)),1.0-smoothstep(60.0,115.0,abs(p.x-825.0)));
	float smoke = side * smoothstep(38.0,90.0,p.y) * (1.0-smoothstep(145.0,174.0,p.y));
	uv.x += sin(p.y*0.035-TIME*1.4)*smoke*0.0015;
	uv.y += cos(p.x*0.027+TIME*0.8)*smoke*0.001;
	vec4 art = texture(TEXTURE, uv);
	float edge = smoothstep(890.0,1010.0,p.x)+1.0-smoothstep(14.0,85.0,p.x);
	float warm = max(0.0,art.r-art.b)*edge;
	art.rgb += art.rgb*warm*sin(TIME*3.2+p.y*0.022)*0.035;
	// A slow diagonal sheen changes illumination, never the letters' geometry.
	float logo = smoothstep(320.0,340.0,p.x)*(1.0-smoothstep(680.0,700.0,p.x));
	logo *= smoothstep(10.0,25.0,p.y)*(1.0-smoothstep(180.0,200.0,p.y));
	float luminance = dot(art.rgb,vec3(0.299,0.587,0.114));
	float ink = smoothstep(0.33,0.72,luminance);
	float sweep_position = mod(TIME*91.0,620.0)-120.0;
	float diagonal = p.x-320.0+p.y*0.32;
	float sheen = 1.0-smoothstep(5.0,48.0,abs(diagonal-sweep_position));
	float breathe = 0.035+0.025*sin(TIME*1.15);
	art.rgb += vec3(1.0,0.84,0.44)*logo*ink*(breathe+sheen*0.24);
	COLOR = art;
}
