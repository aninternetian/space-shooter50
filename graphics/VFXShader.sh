#define PI 3.1415

#define TWO_PI 6.28318530718

#define HALF_PI 1.5708

uniform float time;

uniform float progress;

uniform vec2 position; 


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


float explosion (in vec2 st, in float t, out vec2 mt) {
    vec2 seed = vec2(mod(floor(time / 32.), 32.), mod(floor(time), 32.));
    float t1 = abs(sin(t));
    float t3 = smoothstep(t, t1, 1.3);
    vec2 rst = rotate2d(t + seed.x * seed.y) * st;
    vec2 rst2 = rotate2d(1.- t) * st;
    float n = noise2d((rst2 + seed) * 12.);
    float n1 = perlin(rst * 9. * n * t1);
    float n2 = noise2d(rst2 * 16. * t);
    float n3 = noise2d((st + seed) * 25.);
    float d = dot(rst, rst);
    float f = dot(rst2, rst2);
    float r = dot(st, st);
    mt.x = f * d * n1;
    r = step(r, .12 + t * .3);
    d = smoothstep(d * f * n, mix(d * n, f * (1.- n3 * .15), t) + .001 * t * t * t3 * 18., .01 * t);
    mt.y = d;
    d += d * n1 * n2;
    return d * r;
}


vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{    
    float t = progress;
    vec2 uv = (1.- screen_coords) / love_ScreenSize.x;	
    vec2 mt; float expl = explosion(uv, t * 3, mt);	   
    vec3 col = smoothstep(expl * mt.x - .1, expl * mt.y, .9), 
        min(1., smoothstep(expl * mt.y, expl * mt.x, .7) * 4.), 
        min(1., smoothstep(expl - .1, expl * mt.y, .2) * 2. * mt.y)

    return vec4(col, sign(dot(col, col)));
}