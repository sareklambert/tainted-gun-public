uniform float time;
uniform bool U1;
uniform bool U2;
uniform bool U3;
uniform bool U4;
uniform float S1;
uniform float S2;
uniform float S3;
uniform float S4;
uniform vec2 offset;

// Simple hash function
float Hash(vec2 P) {
	return fract(cos(dot(P,vec2(91.52, -74.27))) * 939.24);
}

// 2D signed hash function
vec2 Hash2(vec2 P) {
	return 1. - 2. * fract(cos(P.x * vec2(91.52, -74.27) + P.y * vec2(-39.07, 09.78)) * 939.24);
}

// 2D value noise
float Value(vec2 P) {
	vec2 F = floor(P);
	vec2 S = P-F;
	
	// Bi-cubic interpolation for mixing the cells
	vec4 M = (S * S * (3. - S - S)).xyxy;
	M = M * vec4(-1, -1, 1, 1) + vec4(1, 1, 0, 0);
	
	// Mix between cells
	return (Hash(F + vec2(0, 0)) * M.x + Hash(F + vec2(1, 0)) * M.z) * M.y +
			(Hash(F + vec2(0, 1)) * M.x + Hash(F + vec2(1, 1)) * M.z) * M.w;
}

// 2D Perlin gradient noise
float Perlin(vec2 P) {
	vec2 F = floor(P);
	vec2 S = P - F;
	
	// Bi-quintic interpolation for mixing the cells
	vec4 M = (S * S * S * (6. * S * S - 15. * S + 10.)).xyxy;
	M = M * vec4(-1, -1, 1, 1) + vec4(1, 1, 0, 0);
	
	// Add up the gradients
	return (dot(Hash2(F + vec2(0, 0)), S - vec2(0, 0)) * M.x + dot(Hash2(F + vec2(1, 0)),S - vec2(1, 0)) * M.z) * M.y + 
			(dot(Hash2(F + vec2(0, 1)),S - vec2(0, 1)) * M.x + dot(Hash2(F + vec2(1, 1)), S - vec2(1, 1)) * M.z) * M.w +
			.5;
}

// 2D Worley noise
float Worley(vec2 P) {
	float D = 1.;
	vec2 F = floor(P + .5);
	
	// Find the the nearest point the neigboring cells
	D = min(length(.5 * Hash2(F + vec2( 1, 1)) + F - P + vec2( 1, 1)), D);
	D = min(length(.5 * Hash2(F + vec2( 0, 1)) + F - P + vec2( 0, 1)), D);
	D = min(length(.5 * Hash2(F + vec2(-1, 1)) + F - P + vec2(-1, 1)), D);
	D = min(length(.5 * Hash2(F + vec2( 1, 0)) + F - P + vec2( 1, 0)), D);
	D = min(length(.5 * Hash2(F + vec2( 0, 0)) + F - P + vec2( 0, 0)), D);
	D = min(length(.5 * Hash2(F + vec2(-1, 0)) + F - P + vec2(-1, 0)), D);
	D = min(length(.5 * Hash2(F + vec2( 1, -1))+ F - P + vec2( 1, -1)), D);
	D = min(length(.5 * Hash2(F + vec2( 0, -1))+ F - P + vec2( 0, -1)), D);
	D = min(length(.5 * Hash2(F + vec2(-1, -1))+ F - P + vec2(-1, -1)), D);
	return D;
}

// 2D Simplex gradient noise
float Simplex(vec2 P) {
	// Skewing and unskewing constants
	#define S (sqrt(.75) - .5)
	#define G (.5 - inversesqrt(12.))
	
	// Calculate simplex cells
	vec2 N = P + S * (P.x + P.y);
	vec2 F = floor(N);
	vec2 T = vec2(1, 0) + vec2(-1, 1) * step(N.x - F.x, N.y - F.y);
	
	// Distance to the nearest cells
	vec2 A = F - G * (F.x + F.y) - P;
	vec2 B = F + T - G * (F.x + F.y) - G - P;
	vec2 C = F + 1.- G * (F.x + F.y) - G - G - P;
	
	// Calculate weights and apply quintic smoothing
	vec3 I = max(.5 - vec3(dot(A, A), dot(B, B), dot(C, C)), 0.);
	I = I * I * I * (6. * I * I, -15. * I + 10.);
	I /= dot(I, vec3(1));
	
	// Add up the gradients
	return .5 + (dot(Hash2(F), A) * I.x + dot(Hash2(F + T), B) * I.y + dot(Hash2(F + 1.), C) * I.z);
}

// Output noise
void main() {
	// Coordinates for the noise
	vec2 P = gl_FragCoord.xy + offset + 20. * time;
	
	// Create noise floats
	float N1 = 1.0;
	float N2 = 1.0;
	float N3 = 1.0;
	float N4 = 1.0;
	
	// Fractal Perlin noise
	if (U1) {
		if (S1 > 0.0) {
			N1 = step(0.4 * Perlin(P / 64.0) + 0.3 * Perlin(P / 32.0) + 0.2 * Perlin(P / 16.0) + 0.1 * Perlin(P / 8.0), S1);
		} else {
			N1 = 0.4 * Perlin(P / 64.0) + 0.3 * Perlin(P / 32.0) + 0.2 * Perlin(P / 16.0) + 0.1 * Perlin(P / 8.0);
		}
	}
	
	// Fractal Worley noise
	if (U2) {
		if (S2 > 0.0) {
			N2 = step(0.4 * Worley(P / 64.0) + 0.3 * Worley(P / 32.0) + 0.2 * Worley(P / 16.0) + 0.1 * Worley(P / 8.0), S2);
		} else {
			N2 = 0.4 * Worley(P / 64.0) + 0.3 * Worley(P / 32.0) + 0.2 * Worley(P / 16.0) + 0.1 * Worley(P / 8.0);
		}
	}
	
	// Fractal value noise
	if (U3) {
		if (S3 > 0.0) {
			N3 = step(0.4 * Value(P / 64.0) + 0.3 * Value(P / 32.0) + 0.2 * Value(P / 16.0) + 0.1 * Value(P / 8.0), S3);
		} else {
			N3 = 0.4 * Value(P / 64.0) + 0.3 * Value(P / 32.0) + 0.2 * Value(P / 16.0) + 0.1 * Value(P / 8.0);
		}
	}
	
	// Fractal Simplex noise
	if (U4) {
		if (S4 > 0.0) {
			N4 = step(0.4 * Simplex(P / 64.0) + 0.3 * Simplex(P / 32.0) + 0.2 * Simplex(P / 16.0) + 0.1 * Simplex(P / 8.0), S4);
		} else {
			N4 = 0.4 * Simplex(P / 64.0) + 0.3 * Simplex(P / 32.0) + 0.2 * Simplex(P / 16.0) + 0.1 * Simplex(P / 8.0);
		}
	}
	
	gl_FragColor = vec4(N1 * N2 * N3 * N4);
}