#version 330 core
layout( location = 0 ) in vec3 aPos; // the position variable has attribute position 0
layout( location = 1 ) in vec2 aTexCoord; // the position variable has attribute position 0

//out vec4 vertexColor; // specify a color output to the fragment shader

uniform float iTime;
uniform vec2 iResolution;
uniform vec2 iMouse;
uniform sampler2D iChannel1;

void main()
{

	//vec2 fld = texture2D( iChannel1, aTexCoord ).yz;
	//gl_Position = vec4( aPos.x + fld.x, aPos.y + fld.y, aPos.z, 1.0 ); // see how we directly give a vec3 to vec4's constructor
	//vertexColor = vec4(0.5, 0.0, 0.0, 1.0); // set the output variable to a dark-red color

	vec2 mou = iMouse / iResolution;


	gl_PointSize = 10.0;
	gl_Position = vec4( aPos.xy - 1.0, aPos.z, 1.0 );

}