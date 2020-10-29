uniform vec2 screen_res;

uniform float time;

vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
    vec2 uv = screen_coords/screen_res;	
	//uv = fract(uv * 4.);	
    return vec4(uv, 0., 1.); 
}