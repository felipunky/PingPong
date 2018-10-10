#version 330 core
out vec4 fragColor;

uniform float iTime;
uniform float iTimeDelta;
uniform vec2 iResolution;
uniform vec2 iMouse;
uniform sampler2D iChannel0;

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