shader_type canvas_item;
render_mode unshaded;
// Forest-green textile beneath the walnut table, mirroring the CARROM palette.
void fragment() {
    vec2 uv = UV;
    vec3 base = vec3(0.064, 0.137, 0.124);
    float t = TIME * 0.07;
    float weave = sin(uv.x * 650.0) * sin(uv.y * 680.0) * 0.003;
    float grain = fract(sin(dot(floor(uv * vec2(720.0, 480.0)), vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
    float soft = sin(uv.x * 8.0 + t) * 0.004 + sin(uv.y * 10.0 - t) * 0.003;
    float falloff = smoothstep(0.32, 0.83, length((uv - 0.5) * vec2(1.14, 1.0)));
    vec3 col = base + vec3(weave + grain * 0.006 + soft) - vec3(0.018) * falloff;
    COLOR = vec4(col, 1.0);
}
