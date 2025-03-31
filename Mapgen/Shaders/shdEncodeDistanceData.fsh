varying vec2 v_vTexcoord;

uniform sampler2D SDF;

void main() {
	vec4 col = texture2D(gm_BaseTexture, v_vTexcoord);
	float dist = 1. - texture2D(SDF, v_vTexcoord).a;
	
	col.g = dist;
	col.b = dist;
	
	gl_FragColor = col;
}
