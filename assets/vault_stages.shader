shader_type canvas_item;
uniform float variant = 0.0;
void fragment() {
    vec4 pixel = texture(TEXTURE, UV);
    float green = smoothstep(0.02, 0.12, pixel.g - max(pixel.r, pixel.b));
    vec3 red = vec3(pixel.g, pixel.r * 0.8, pixel.b * 0.8);
    vec3 blue = vec3(pixel.r * 0.7, pixel.b * 0.9, pixel.g);
    vec3 tint = variant < 1.5 ? red : blue;
    if (variant > 0.5) pixel.rgb = mix(pixel.rgb, tint, green);
    COLOR = pixel;
}
