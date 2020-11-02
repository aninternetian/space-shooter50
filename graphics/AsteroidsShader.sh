#define PI 3.1415

#define TWO_PI 6.28318530718

#define HALF_PI 1.5708

#define AMOUNT 3

uniform float time;

uniform vec2[AMOUNT] coords; 

uniform float[AMOUNT] rotations;

uniform float[AMOUNT] seeds;

uniform vec3[AMOUNT] colors;


float normUp (in float val) {
	return val * .5 + .5;
}


vec2 normUp (in vec2 val) {
	return val * .5 + .5;
}


float hash21 (in vec2 st) {
    float offset = 43758.5453123;
    vec2 shift = vec2(12.9898,78.233);
    return fract(sin(dot(st.xy, shift))*offset);
}


vec2 hash22(vec2 st){
    st = vec2( dot(st,vec2(127.1,311.7)),
            dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}


float noise (float x) {
    float i = floor(x);
    float f = fract(x);
    float u = f * f * (3. - 2. * f);
    float a = hash21(vec2(i));
    float b = hash21(vec2(i + 1.));
    return mix(a, b, u);
}


float noise2d (vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    vec2 u = f*f*(3.0-2.0*f);
    
    float a = hash21(i);
    float b = hash21(i + vec2(1, 0));
    float c = hash21(i + vec2(0, 1));
    float d = hash21(i + vec2(1, 1));
    
    return mix(a, b, u.x) + 
        (c - a) * u.y * (1. - u.x) +
        (d - b) * u.x * u.y;
}


float perlin(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    vec2 u = f*f*(3.0-2.0*f);
    return mix( 
        mix(dot(hash22(i + vec2(0,0)), f - vec2(0,0)),
            dot(hash22(i + vec2(1,0)), f - vec2(1,0)), u.x),
        mix(dot(hash22(i + vec2(0,1)), f - vec2(0,1)),
            dot(hash22(i + vec2(1,1)), f - vec2(1,1)), u.x), 
        u.y);
}



mat2 rotate2d(float angle){
    return mat2(cos(angle),-sin(angle),
                sin(angle),cos(angle));
}



float asteroid (in vec2 st, float seed, float angle, out float otl, out float mask) 
{
    vec2 pos = rotate2d(angle) * st;
	float grad = dot(pos, pos);
    float circ = dot(st, st);
    float n = noise2d(pos * 8. + vec2(seed));
    float cbg = smoothstep(circ - .1, circ + .1, .1);
    float res = mod(cbg, .6 * (n + grad));
    otl = mod(cbg, .64 * (n + grad));
    mask = cbg - res;
    otl = cbg - otl;
    res = max(mask - otl * 2., res * otl);
    return min(1., res * 2.5);
}


vec4 effect( vec4 rgb, Image texture, vec2 texture_coords, vec2 screen_coords )
{
    float t = time;
	vec2 uv = (1.- screen_coords) / love_ScreenSize.x;		
	vec3 col = vec3(0);
	
	float df = 0;
	
	for (int i = 0; i < AMOUNT; i++) {
		float asMsk, asOtl;
		float astr = asteroid(
			(uv + coords[i]) * 3., seeds[i], 
			t * rotations[i] *.25,
			asOtl, asMsk
			);
		df += astr;

        col += seeds[0] * rotations[0] * .000000001;

        col += vec3(
            normUp(sin(astr + asMsk + asOtl * 5.)), 
            normUp(cos(astr - asMsk * asOtl * abs(sin(t * .5) * TWO_PI))), 
            normUp(sin((astr - asOtl * astr - asMsk) * 24.))
        ) * sin(asMsk - asOtl) + astr * colors[i];
	}	
    
    return vec4(col, sign(df));
    //return vec4(vec3(dot(uv, uv)), 1. + sin(t) * .0000001);//sign(df)); 
}
