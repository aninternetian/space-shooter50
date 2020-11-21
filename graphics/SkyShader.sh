#define PI 3.1415

#define TWO_PI 6.28318530718

#define HALF_PI = 1.5708

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



float normUp (in float val) {
	return val * .5 + .5;
}


vec2 normUp (in vec2 val) {
	return val * .5 + .5;
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


float nebula (in vec2 p, out vec3 kts) {
    p += vec2(3., 0.);
    p *= vec2(2., 1.);
    float n = noise2d(p * 3.);
    float c = perlin(p * .9);
    n *= smoothstep(c, c + .4, .1);
    kts.x = n;
    n *= 1.- perlin((p + vec2(2)) * 10.);
    n *= 1.- noise2d(p * 8.);
    kts.y = n;
    n *= sign(hash21(p) - .95);
    kts.z = n;
    return clamp(n / step(n, .005), 0., 1.) * .05;
}


float stars (in vec2 p, out float id, float s) {
    p *= 3.;
    vec2 gp = 1.5 - fract(p * s) * 3.;
    vec2 gi = floor(p * s);
    id = noise2d(gi * 333.33) + .01;
    gp = rotate2d(time * 3. * (id * 2. - .5)) * gp;
    float df = 1. - pow(dot(gp, gp) * gp.x * gp.y * 5000. * id, 2.);
	return min(1., df * max(0., hash21(gi) - .9) * 16.);
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
	vec2 uv = 1.- (screen_coords - .5 * love_ScreenSize.xy)/love_ScreenSize.x;	
	vec2 duv = uv +  vec2(0, t * .05);
	float df = 0.;
    vec3 kts; float nbul = nebula(uv + vec2(0, t * .001), kts);
    float sId; float strs = stars(uv + vec2(0, t * .065), sId, 6.);
    float farstrs = starsBg(duv, 6., vec2(-t, t) * .01) * 2.;
    float met1 = meteorsBg(duv, .65, vec2(-t * .5, t * 2.) * .05) *.7;
    float met2 = meteorsBg(duv, .75, vec2(t * .1)) * noise(duv.y * 2.) * .75;
	
	df = max(met1, met2);
    df = max(df, strs - df);
	
    vec3 col = vec3(
        max(nbul, abs(sin(kts.x * kts.y * 4.))), 
        max(nbul * kts.x, nbul + kts.y), 
        pow(max(nbul, kts.y), normUp(cos(kts.x * 8.)))) * .1;
	col += vec3(abs(sin(farstrs * TWO_PI)) * .65, abs(sin(farstrs * PI)), min(1., farstrs * 2.));
    col += max(vec3(0), vec3(strs * abs(sin(sId)), strs * (sin(sId * PI)), strs * sin(sId + TWO_PI)));
    //col += max(vec3(0), vec3(strs * normUp(sin(sId * TWO_PI)), strs * normUp(sin(sId)), strs * normUp(sin(sId))));
	
	col = max(col, vec3(df));
	
    return vec4(col, 1.0); 
}
