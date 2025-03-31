const float TAU = 6.2831853071795864769252867665590;

#region Uniforms and samplers
// Surface info
uniform vec2 texelSize;
uniform vec2 texOffset;
uniform bool mapBorder;
uniform vec2 surfaceSize;
uniform vec2 tileSize;

// Wall texture
uniform vec2 texWallOffset;
uniform vec2 texWallSize;
uniform vec2 texWallTileAmount;
uniform vec3 texWallHighlight;
uniform vec3 texWallShadow;
uniform sampler2D texWall;

// Ore texture
uniform sampler2D texOre;
uniform vec2 texOreOffset;
uniform vec2 texOreSize;
uniform vec2 texOreTileAmount;
uniform vec3 texOreHighlight[7];
uniform vec3 texOreShadow[7];
#endregion

varying vec2 v_vTexcoord;

#region Functions
float rand(vec2 x) {
	return fract(sin(dot(x, vec2(12.9898, 78.233))) * 43758.5453);
}

float getTex(float x, float y) {
	return texture2D(gm_BaseTexture, v_vTexcoord + vec2(x, y)).r;
}

bool isHighlight1() {
	return (getTex(-texelSize.x, 0.0) != getTex(0.0, 0.0) || getTex(0.0, -texelSize.y) != getTex(0.0, 0.0)
			|| (mapBorder && (v_vTexcoord.x - texelSize.x < 0.0 || v_vTexcoord.y - texelSize.y < 0.0)));
}

bool isShadow1() {
	return (getTex(texelSize.x, 0.0) != getTex(0.0, 0.0) || getTex(0.0, texelSize.y) != getTex(0.0, 0.0)
			|| (mapBorder && (v_vTexcoord.x + texelSize.x > 1.0 || v_vTexcoord.y + texelSize.y > 1.0)));
}
#endregion

void main() {
	vec4 baseCol = texture2D(gm_BaseTexture, v_vTexcoord);
	
	if (baseCol.a == 0.0) {
		#region Outline
		baseCol.a += texture2D(gm_BaseTexture, v_vTexcoord + texelSize * vec2(-1.0, 0.0)).a;
		baseCol.a += texture2D(gm_BaseTexture, v_vTexcoord + texelSize * vec2(1.0, 0.0)).a;
		baseCol.a += texture2D(gm_BaseTexture, v_vTexcoord + texelSize * vec2(0.0, -1.0)).a;
		baseCol.a += texture2D(gm_BaseTexture, v_vTexcoord + texelSize * vec2(0.0, 1.0)).a;
		baseCol.a += texture2D(gm_BaseTexture, v_vTexcoord + texelSize * vec2(-1.0, -1.0)).a;
		baseCol.a += texture2D(gm_BaseTexture, v_vTexcoord + texelSize * vec2(-1.0, 1.0)).a;
		baseCol.a += texture2D(gm_BaseTexture, v_vTexcoord + texelSize * vec2(1.0, -1.0)).a;
		baseCol.a += texture2D(gm_BaseTexture, v_vTexcoord + texelSize * vec2(1.0, 1.0)).a;
		
		gl_FragColor = vec4(vec3(0.0), baseCol.a);
		#endregion
	} else {
		#region Highlights / shadows
		bool b = false;
		float rad;
		float angle;
		float value;
		
		for (float i = 0.0; i < 32.0; i += 1.0) {
			rad = floor(i / 8.0);
			angle = i / 8.0 * TAU;
			
			if (texture2D(gm_BaseTexture, v_vTexcoord + texelSize * vec2(rad * cos(angle), rad * sin(angle))).a == 0.0) {
				value = floor((mod(angle + TAU * 0.255, TAU) / TAU) * 4.0) / 4.0;
				value = value + step(value, 0.499) * (0.25 - 0.5 * (1.0 - step(value, 0.0)));
				
				if (baseCol.r == 1.0) {
					gl_FragColor = vec4(mix(texWallShadow, texWallHighlight, value), baseCol.a);
				} else {
					gl_FragColor = texture2D(texOre, texOreOffset + (fract(texOffset + surfaceSize * v_vTexcoord / tileSize) + vec2(baseCol.r * 255.0, 0.0)) * texOreSize / texOreTileAmount);
				}
				b = true;
				break;
			}
		}
		#endregion
		#region Texture
		if (!b) {
			if (baseCol.r == 1.0) {
				// Wall
				if (isHighlight1()) {
					// Shadow
					gl_FragColor = vec4(texWallHighlight, 1.0);
				} else if (isShadow1()) {
					// Highlight
					gl_FragColor = vec4(texWallShadow, 1.0);
				} else {
					// Texture
					float density = min(2.0, floor(baseCol.b / 0.2));
					vec2 tileIndex = vec2(floor(rand(floor(surfaceSize * v_vTexcoord / tileSize) + density) * 2.99), density);

					gl_FragColor = vec4(texture2D(texWall, texWallOffset + (fract(texOffset + surfaceSize * v_vTexcoord / tileSize) + tileIndex) * texWallSize / texWallTileAmount).rgb, baseCol.a);
				}
			} else {
				float oreIndex = baseCol.r * 255.0;
				
				// Ore
				if (isHighlight1()) {
					// Shadow
					gl_FragColor = vec4(texOreShadow[int(oreIndex)], 1.0);
				} else if (isShadow1()) {
					// Highlight
					gl_FragColor = vec4(texOreHighlight[int(oreIndex)], 1.0);
				} else {
					// Texture
					gl_FragColor = texture2D(texOre, texOreOffset + (fract(texOffset + surfaceSize * v_vTexcoord / tileSize) + vec2(oreIndex, 0.0)) * texOreSize / texOreTileAmount);
				}
			}
		
		}
		#endregion
	}
}