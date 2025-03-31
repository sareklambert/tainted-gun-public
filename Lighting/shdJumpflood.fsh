varying vec2 v_vTexcoord;
uniform vec2 texelSize;
uniform float jumpDist;
uniform float firstPass;

// Define constants
#define CENTER .5
#define RANGE  1024.0

// Jumpflood
// RG: pos offset, A: inverted distance
vec4 JFA(sampler2D t, vec2 uv) {
	bool isFirstPass = firstPass > 0.5;
	vec4 result = vec4(0.0);
	
	// Initialize the closest distance (1.0 is outside the range)
	float dist = 1.0;
    
	// Loop through neighbor cells
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			// Pixel offset with jump distance
			vec2 currentOffset = vec2(x, y) * jumpDist;
			
			// Compute new texture coordinates
			vec2 coord = uv + currentOffset * texelSize;
			
			// Skip texels outside of the texture
			if (coord != clamp(coord, 0.0, 1.0)) continue;
			
			// Sample the texture at the coordinates
			vec4 currentSample = texture2D(t, coord);
			
			// Preserve original color of texture; only fill empty space
			if (x == 0 && y == 0 && currentSample.a >= 1.0) {
			    return currentSample;
			}
			
			// Encode the offset (-0.5 to +0.5)
			vec2 textureOffset = (currentSample.rg - CENTER) * vec2(currentSample.a < 1.0) + currentOffset / RANGE;
			
			// Compute offset distance (inverted)
			float textureDistance = length(textureOffset); 
    		
			// Check for the closest
			if (dist > textureDistance && (!isFirstPass || currentSample.a >= 1.0)) {
				// Store texel offset
				result.rg = textureOffset + CENTER;
				
				// Store the closest distance
				dist = textureDistance;
				result.a = 1.0 - textureDistance * 3.0;
			}
		}
	}
	return result;
}

void main() {
	gl_FragColor = JFA(gm_BaseTexture, v_vTexcoord);
}
