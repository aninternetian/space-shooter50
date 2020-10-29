#define PI 3.1415

#define TWO_PI 6.28318530718

#define HALF_PI = 1.5708

uniform vec2 screen_res;

uniform float time;


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



float nebula (vec2 st, float scale, vec2 t) {
    st += t;
    float f = perlin(st * scale);
	return f;
}


float stars (vec2 st, float scale, float t) {
    st += t;
    st *= scale;
    vec2 gst = fract(st * scale);
    float f = gst.x * gst.y;//step(1. - noise(st.x * 100.) * noise(st.y * 100.), .1);
    return f;
}


float starsBg (vec2 st, float scale, vec2 t) {
    t += 999.;
    st += t;
    st *= scale;
    st = rotate2d(t.y * .001) * st;
	float f = perlin(st * 24.);
    f = 1. - smoothstep(f - noise2d(st * t * -.025), f + .1, .5);
    return f;
}


float meteorsBg (vec2 st, float scale, vec2 t) {
    st += t;
    st *= scale;
	float f = perlin(st * 24.);
    float th = noise2d(st * 350.);
    float n = noise(f *.4);
    float s = 1. - smoothstep(f * n + th, f * n - th, .5);
    f = 1. - smoothstep(f - .02, f + .025, .5);
    return s * f * s;
}


vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
	float t = time;
	vec2 uv = screen_coords/screen_res;	
	vec2 duv = uv +  vec2(0, t * .05);
	float df = 0.;
    float strs = starsBg(duv, 5., vec2(-t, t) * .01) * 2.;
    float met1 = meteorsBg(duv, .65, vec2(-t * .5, t * 2.) * .05) *.7;
    float met2 = meteorsBg(duv, .75, vec2(t * .1)) * noise(duv.y * 2.) * .75;
    float nbl = nebula(duv, 8., vec2(0.)) * .035;
	
	df = max(met1, met2);
    df = max(df, strs - df);
	
	vec3 col = vec3(nbl * .25, nbl * .2, nbl);
	col = max(col, vec3(df));
	
    return vec4(col, 1.0);
}
