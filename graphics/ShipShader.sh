#define PI 3.1415

#define TWO_PI 6.28318530718

#define HALF_PI 1.5708

uniform float time;

uniform vec2 position; 

uniform float shoot;

uniform float thrust;


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


float hull (in vec2 st, float s) 
{  
    st *= 2.;
    int n = 5;
    float a = atan(st.x,st.y)+PI * 2.;
    float r = TWO_PI/float(n);
    float d = cos(floor(.5 + a/r)*r-a)*length(st);
    d = pow(d, abs(cos(a * 4.5)) * .1 + .5);
    d *= abs(cos(a * sin(PI) * 3.5)) * 0.12 + 0.43;
    d = 1.0 - smoothstep(.4, .41, d - s);
	return d;
}


float cockpit (in vec2 p, out float h) 
{
    vec2 a = vec2(0, 0);
    vec2 b = vec2(0,-.21);
    float r = .2;
	
    h = min(1., max(0., dot(p - a, b - a) / dot(b - a, b - a))); 
    
    float h1 = h * abs(sin(h * 8.));
    float d = length(p - a - (b - a) * h1) * r;
    float f = step(d, .015);
    float h2 = sin(h * 1.2);
    d = length(p - a - (b - a) * h2) * r;
    f *= step(d, max(h1 * 1.8, h2 * .75) * .015);
    return f;
}


float paint(in vec2 p) 
{
	p *= 6.;
    int n = 3;
    float a = atan(p.x, p.y) + PI * 3.;
    float r = TWO_PI / float(n);
    float d = cos(floor(.5 + a / r) * r - a) * length(p);
    d = pow(d, abs(cos(a * 8.)) * .12 + .5);
    d *= abs(cos(a * sin(PI))) * 0.1 + 0.43;
    d = smoothstep(.5, .2, d - .015);
	return d;
}


float jet (in vec2 p, float s, float th, out float h) 
{
    vec2 a = vec2(0, 0);
    vec2 b = vec2(.05 * s, -.1);
    float r = .2;
	
    h = min(1., max(0., dot(p - a, b - a) / dot(b - a, b - a))); 
    
    h *= abs(sin(h * 2.) * .5 + .2 * abs(sin(time * 32.)) * .5);
    h = mix(h, abs(sin(h * 3.)) * h * .75, th);

    float d = length(p - a - (b - a) * h) * r;
    
	return smoothstep(d - .001, d + .001, .007);
}


float fire (in vec2 p, in float t, out float h) 
{
	p = p * 24. + vec2(0., -5.2);
    vec2 rp = rotate2d(.7854) * p;
    vec2 a = (sin(rp * 5.) * .7 - .2) * t * .25 + 0.;
    vec2 b = vec2(8.);
    h = min(1., max(0., dot(rp - a, b - a) / dot(b - a, b - a))); 
    h -= pow(h, (sin(h * 6.) * .5 + .5) * .3) * .21 * (t * t * 2.);
    float shape = length(rp - a - (b - a) * h) * .1;
    shape = smoothstep(shape - .005, shape +.005, .15 * pow(t,1.-t));
    return shape;
}


float projectile (in vec2 p, in float t, out float h) 
{
    vec2 a = vec2(0, 0);
    vec2 b = vec2(0, -1);
    float r = .2;

    h = min(1., max(0., dot(p - a, b - a) / dot(b - a, b - a))); 
    
    h = mix(h, h * .75, .35);
    
    float d = length(p - a - (b - a) * h) * r;
	float f = smoothstep(d - .001, d + .01, .007);
    
    return f;
}


vec3 ship (in vec2 p, float shoot, float th) 
{
    float cph;
    float pn = paint(p + vec2(0, -.05)) * 1.75;
    float lp = length(p + vec2(0, .045));
	float cpt = cockpit(p + vec2(0., -0.2), cph) * sin(cph * 1.57);
    float cpt2 = cockpit(p * .9 + vec2(0., -0.189), cph) * sin(cph * 1.57);
    float hll = hull(p * 2., 0.);
    float hll2 = hull(p, 0.);    
    float hll3 = 1.- max(hll * sin(cph * 1.57), 1.- hll * hll2);
	float pt = min(0., pn / cpt * hll);
    
    float jh1;
    float j1 = jet(p + vec2(-.155, .115), 1., th, jh1);
    float jh2;
    float j2 = jet(p + vec2(.155, .115), -1., 1.-th, jh2);
    float js = max(j1, j2);
    float jhs = max(jh1, jh2);
    float fh;
    float fr = fire(p, shoot, fh);
    
    cpt2 = cpt2 - cpt;
    cpt2 *= hll3;
    cpt *= hll;
    cpt *= abs(sin(time)) * .25 + .85;
    hll *= step(cpt, .01);
    hll = max(hll, hll * cpt2); 
    hll3 *= abs(cos(1.-smoothstep(.1, 1., shoot))) * .5 + .5;
    vec3 col = vec3(
        hll3 + hll + min(hll, cpt * cpt2), 
        cpt2 + hll * hll3 * 1.75, 
        cpt * cpt2 - hll * hll2 * .1
    );
    
    col += col * max(cpt, cpt2) + cpt * .75;
    col += vec3(col.b * .5, col.r * .3, col.g * .15);
    col *= vec3(1.- abs(sin(lp * 8. * (-pn) * .5) * .3 + .3));
    
    float thrs = abs(th * 2. - 1.) * 2.;
    vec3 jets = vec3(js * jhs) + vec3(
        js * sin(jhs * thrs * 2.), 
        js * jhs * thrs, 
        js * thrs * .7 - jhs
    );
    jets = jets - jets * (jhs + .01) * 1.;
    
    col = max(col, jets);
    col += vec3(
        fr * (fh + 32.), 
        fr * (1.- fh * 4. + 2.), 
        fr * abs(cos(fh * 6. + .5))
    );
    return col;
} 


vec3 shape (in vec2 st) {
    vec2 rst = rotate2d(-time) * st;
	float r = length(rst)*2.0;
    float a = atan(rst.y,rst.x);
    float f = smoothstep(-.5,1., cos(a*10.))*0.2+0.5;
    float s = f * .49 + .1;
    vec2 pos = rotate2d(time * .25) * st + s * .6;
    float d = dot(pos, pos);
    d = smoothstep(d, d -.0005, .0001);//.001);
    f = smoothstep(f -.1, f +.05, r - sin(st.x * 3.) * .1);
    f -= smoothstep(f, f -.2, (.9 - st.x * .8) - r);
    return vec3(1. - (f + d), .55 - d, f * 2.);
}


vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{    
    float t = time;
    vec2 uv = (1.- screen_coords) / love_ScreenSize.x;		   
    vec3 col = ship(
        (uv + position) * 2.5, shoot, thrust
    );

    return vec4(col, sign(dot(col, col)));
}