#version 330 core
out vec4 fragColor;

uniform float iTime;
uniform float iTimeDelta;
uniform vec2 iResolution;
uniform vec2 iMouse;
uniform sampler2D iChannel0;

/*
void main()
{

	vec2 uv = gl_FragCoord.xy / iResolution;
	vec2 p = gl_FragCoord.xy / iResolution.y;
	vec2 mou = iMouse / iResolution.y;

	float c = smoothstep( 0.1, 0.1 - 0.005, length( p - mou ) );

	float t = texture( iChannel0, uv ).r;

    c += t;
    
	fragColor = vec4( vec3( c ), 1 );

}
*/


// This is taken from my own shader https://www.shadertoy.com/view/llfBzl
float tri( float dis, float dec, float fre, float amp, float spe )
{

	return exp( -dec * dis );
    
}

// This function returns the center of the uv coordinates and relates it to the mouse position 
float dis( vec2 uv, vec2 mou )
{
    
	return length( uv - mou );

}

void main()
{
    
    vec2 uv = gl_FragCoord.xy / iResolution;
	vec2 p = gl_FragCoord.xy / iResolution.y;
	vec2 mou = iMouse / iResolution.y;
    
    float dist = dis( p, mou );
    float amp = 1.4;
    float dec = 45.0;
    float fre = 400.0;
    float spe = 5.0;
    
    float col = tri( dist, dec, fre, amp, spe );
    
    float xpi = 1.0 / iResolution.x;
    float ypi = 1.0 / iResolution.y;
    
    vec4 center = texture( iChannel0, uv );
    float top = texture( iChannel0, vec2( uv.x, uv.y + ypi ) ).r;
	float rig = texture( iChannel0, vec2( uv.x + xpi, uv.y ) ).r;
    float lef = texture( iChannel0, vec2( uv.x - xpi, uv.y ) ).r;
    float dow = texture( iChannel0, vec2( uv.x, uv.y - ypi ) ).r;
    
    float red = -(center.a - 0.5) * 2.0 + (top + lef + rig + dow - 2.0);
    red += col; // mouse
    red *= 0.98; // damping
    red *= step(0.1, iTime); // hacky way of clearing the buffer
    red = 0.5 + red * 0.5;
    red = clamp(red, 0., 1.);
    
    //fragColor = vec4( vec3( mix( vec4( 0, 0, 0, center.r ), vec4( red, 0.1, 0.0, center.r ), col ) ), 1 );
    
    fragColor = vec4( mix( vec3( red, 0.1, 0.4 ), vec3( 0.2, col, red ), col ), center.r );
    
}


