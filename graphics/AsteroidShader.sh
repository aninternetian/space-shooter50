#define PI 3.1415

#define TWO_PI 6.28318530718

#define HALF_PI = 1.5708

uniform float time;

uniform float speed;

uniform float seed;

uniform vec3 color;


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


float plot(vec2 st, float pct){
  return  smoothstep( pct-0.02, pct, st.y) -
          smoothstep( pct, pct+0.02, st.y);
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



float asteroid (in vec2 st, float seed, out float otl, out float mask) 
{
    vec2 pos = rotate2d(time * speed *.25) * st;
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


vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
	vec2 uv = screen_coords/screen_res;	
	vec2 duv = uv +  vec2(0, time * .05);
	float df = 0.;

	float asMsk, asOtl;
	float astr = asteroid(
		uv * 3. + vec2(2.1, -1.), seed, 
		asOtl, asMsk
		);
	
	 col += vec3(
        astr + asMsk * asOtl, 
        astr + asMsk - asOtl, 
        astr * asOtl + asMsk
    ) * (asMsk - asOtl) + astr * color;
	
    return vec4(col 1.0) 
}
