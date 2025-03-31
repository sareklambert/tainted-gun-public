varying vec2 v_vTexcoord;
uniform sampler2D SDFTexture;
uniform sampler2D normalTexture;
uniform vec2 texelSize;
uniform vec2 textureSize;
uniform float time;
uniform float falloffRange;

// Define constants
#define CENTER .5
#define RANGE 1024.0
#define TAU 6.28318

// Performance / Resolution
const float NUM_SAMPLES = 40.0;
const int MAX_STEPS = 15;

// Raycast algorithm
vec3 Raycast(vec2 startPosition, vec2 direction) {
	vec2 scaledDirection = direction * 256.0 / textureSize;
	
	vec2 currentPosition = startPosition + 0.01 * scaledDirection;
	float currentDistance;
	
	// Trace along the distance field until reaching a wall or the max steps
	for (int i = 0; i < MAX_STEPS; i++) {
		currentDistance = 1. - texture2D(SDFTexture, currentPosition).a;

		// Avoid sampling inside walls
		if (currentDistance < 0.005) {
			currentPosition -= 0.004 * scaledDirection;
			return vec3(currentPosition.x, currentPosition.y, 0.0);	
		}
		
		// Out of bounds check
		if (abs(currentPosition.x - 0.5) > 0.5 || abs(currentPosition.y - 0.5) > 0.5) {
			return vec3(currentPosition.x, currentPosition.y, 1.0);	
		}

		// Move position
		currentPosition += currentDistance * scaledDirection;
	}
	
	// Return result
	return vec3(currentPosition.x, currentPosition.y, currentDistance);
}

void main() {
	// Sample normal map
	vec4 normalSample = texture2D(normalTexture, v_vTexcoord);
	vec3 normal = normalize(normalSample.rgb - 0.5);
	
	// Get the texture and pixel positions
	vec2 pos = v_vTexcoord;
	vec2 pixelPos = pos * textureSize;
	
	// Don't calculate light for the walls; just empty space
	if (texture2D(SDFTexture, v_vTexcoord).a == 1.) discard;
	
	// Set the sample scale and base color
	float sampleScale = 1.0 / NUM_SAMPLES;
	vec4 col = vec4(0.0, 0.0, 0.0, 1.0);
	
	// Dithered sampling to hide artifacts
	float dirOffset;
	dirOffset = fract(pixelPos.x * 0.65) + 0.375 * fract(pixelPos.y * 0.65);
	dirOffset += time;
	
	// Iterate through samples by shooting rays in a circle
	for (float i = 0.0; i < NUM_SAMPLES; i++) {
		// Get current direction
		float dir = (i + dirOffset) / NUM_SAMPLES * TAU;
		
		// Perform raycast starting at pos, moving towards the point of the direction dir
		vec3 result = Raycast(pos, vec2(cos(dir), sin(dir)));
		
		// Get luminance
		vec4 luminance = texture2D(gm_BaseTexture, result.xy); // This is the previous result of this shader
		
		// Get material
		vec4 SDFSample = texture2D(SDFTexture, result.xy);
		vec2 tex_off = (SDFSample.rg - CENTER) * vec2(SDFSample.a < 1.0);
		vec4 surface = texture2D(SDFTexture, result.xy + tex_off * RANGE * texelSize); // This is the voronoi representation
		
		// Normal mapping
		vec2 direction = normalize(result.xy - v_vTexcoord);
		vec3 lightDir = vec3(direction.x, -direction.y, 1.);
		float ref = pow(max(reflect(-lightDir, normal).z, 0.0), 4.0) * normalSample.a * 0.1;
		
		// Get max radius falloff
		float falloff = smoothstep(falloffRange, 0.0, distance(pixelPos, result.xy * textureSize));
		
		// Calculate color with normal mapping
        float diffuseIntensity = max(dot(normal, lightDir), 0.0);
		
		// Mix components
		vec4 diffuse = min(vec4(1.0), 2.0 * surface) * .8;
		vec4 emission = max(vec4(0.0), 2.0 * surface - 1.0) * .6;
		col += sampleScale * smoothstep(0.05, 0.0, result.z) * (luminance * diffuse + emission) * falloff * diffuseIntensity;
		col += sampleScale * smoothstep(0.05, 0.0, result.z) * (luminance * diffuse + emission) * falloff * diffuseIntensity * ref;
	}
	
	// Return result
    gl_FragColor = col;
}
