#version 330 core
out vec4 fragColor;

uniform float iTime;
uniform float iTimeDelta;
uniform vec2 iResolution;
uniform vec2 iMouse;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;

const float dx = 0.5;
const float dt = dx * dx * 0.5;
const int ITER = 5;
const float siz = 0.1;
const float di = 0.25;
const float alp = ( dx * dx ) / dt;
const float rbe = 1.0 / ( 4.0 + alp );
const float vo = 12.0;
const int FIELD = 1;
const float vf = 0.01;
const float mul = 100.0;

/*
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
*/

//2D Vector field visualizer by nmz (twitter: @stormoid)

/*
	There is already a shader here on shadertoy for 2d vector field viz, 
	but I found it to be hard to use so I decided to write my own.

	Heavily modified by me to make it work as an interactive vector field 
	for my fluid sim.

*/

//#define keyTex iChannel3
//#define KEY_I texture(keyTex,vec2((105.5-32.0)/256.0,(0.5+0.0)/3.0)).x

const float arrow_density = 0.2;
const float arrow_length = 0.95;

const vec3 luma = vec3(0.2126, 0.7152, 0.0722);

float segm(in vec2 p, in vec2 a, in vec2 b) //from iq
{
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa,ba)/dot(ba,ba), 0., 1.);
	return length(pa - ba*h)*20.*arrow_density;
}

float cur( vec2 uv )
{
    
    float xpi = 1.0 / iResolution.x;
    float ypi = 1.0 / iResolution.y;
    
    float x = uv.x;
    float y = uv.y;
    
    float top = texture( iChannel0, vec2( x, y + ypi ) ).r;
    float lef = texture( iChannel0, vec2( x - xpi, y ) ).r;
    float rig = texture( iChannel0, vec2( x + xpi, y ) ).r;
    float dow = texture( iChannel0, vec2( x, y - ypi ) ).r;
    
    float dY = ( top - dow ) * 0.5;
    float dX = ( rig - lef ) * 0.5;
    
    return dX * dY;
}

vec2 vor( vec2 uv )
{
    
    vec2 pre = uv;
    
    float xpi = 1.0 / iResolution.x;
    float ypi = 1.0 / iResolution.y;
    
    float x = uv.x;
    float y = uv.y;

    vec2 dir = vec2( 0 );
    dir.y = ( cur( vec2( x, y + ypi ) ) ) - ( cur( vec2( x, y - ypi ) ) );
    dir.x = ( cur( vec2( x + xpi, y ) ) ) - ( cur( vec2( x - xpi, y ) ) );
    
    dir = normalize( dir );
    
    if( length( dir ) > 0.0 )
    
    uv -= dt * vo * cur( uv ) * dir;
    
    return uv;
    
}

void main()
{
	vec2 p = gl_FragCoord.xy / iResolution.y;
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec2 mou = iMouse.xy / iResolution.y;
    p *= mul;
    mou *= mul;
    
    float fO = 0.0;
    fO = texture( iChannel1, vor( uv ) ).r + texture( iChannel1, vor( uv ) ).g + texture( iChannel1, vor( uv ) ).b;
   	fO *= 0.333;
    //if( iMouse.z > 0.5 )
    fO += 0.05 * length( p - mou );
    
    vec2 ep = vec2( 1e-4, 0 );
    vec2 rz= vec2(0);
	for( int i=0; i<FIELD; i++ )
	{
		float t0 = texture( iChannel0, uv ).a * dt * vf;
		float t1 = texture( iChannel0, uv + ep.xy ).a * dt * vf;
		float t2 = texture( iChannel0, uv + ep.yx ).a * dt * vf;
        vec2 g = vec2((t1-t0), (t2-t0))/ep.xx;
		vec2 t = vec2(-g.y,g.x);
        
        p += .9*t + g*0.3;
        rz += t;
	}
    
    vec2 fld = rz;
    
    vec3 col = sin(vec3(-.3,0.1,0.5)+fld.x-fld.y)*0.65+0.35;
    col = mix(col,vec3(fld.x,-fld.x,fld.y),smoothstep(0.75,1.,sin(0.4)))*0.85;
    float fviz = 0.0;
    
    vec2 ip = floor(p*arrow_density)/arrow_density + .5/arrow_density;   
    vec2 t = rz;
    float m = pow(length(t),0.5)*(arrow_length/arrow_density);
    vec2 b = normalize(t)*m;
    float r = segm(p, ip, ip+b);
    vec2 prp = (vec2(-b.y,b.x));
    r = min(r,segm(p, ip+b, ip+b*0.65+prp*0.3));
    r = clamp(min(r,segm(p, ip+b, ip+b*0.65-prp*0.3)),0.,1.);
    fviz = r;
    
    col = max(vec3(0.0), 1.-fviz*vec3(1.));    
    
    float o = 0.0;
    
    //if( iFrame <= 4 || KEY_I < 0.5 )
    
    o = texture( iChannel0, uv ).a * 0.98;
    
    if( uv.y < 0.00 || uv.x < 0.00 || uv.x > 1.0 || uv.y > 1.0 ) o *= 0.0;
    
    fragColor = vec4( col.r, fld, fO + o );
    
}
