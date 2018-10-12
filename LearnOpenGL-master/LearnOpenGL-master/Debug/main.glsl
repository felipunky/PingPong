#version 330 core
out vec4 fragColor;

uniform float iTime;
uniform vec2 iResolution;
uniform vec2 iMouse;
uniform sampler2D iChannel0;

void main()
{

	vec2 uv = gl_FragCoord.xy / iResolution;

	fragColor = texture( iChannel0, uv );// * vec4( vec3( sin( iTime ) ), 1 );

}