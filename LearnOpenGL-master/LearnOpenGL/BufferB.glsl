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


float hash( vec2 a )
{

    return fract( sin( a.x * 3433.8 + a.y * 3843.98 ) * 45933.8 );

}

float noise( vec2 uv )
{
    
    vec2 lv = fract( uv );
    lv = lv * lv * ( 3.0 - 2.0 * lv );
    vec2 id = floor( uv );
    
    float bl = hash( id );
    float br = hash( id + vec2( 1, 0 ) );
    float b = mix( bl, br, lv.x );
    
    float tl = hash( id + vec2( 0, 1 ) );
    float tr = hash( id + vec2( 1 ) );
    float t = mix( tl, tr, lv.x );
    
    float c = mix( b, t, lv.y );
    
    return c;

}

float fbm( vec2 uv )
{

	float f = noise( uv * 4.0 );
    f += noise( uv * 8.0 ) * 0.5;  
    f += noise( uv * 16. ) * 0.25; 
    f += noise( uv * 32. ) * 0.125; 
    f += noise( uv * 64. ) * 0.0625;
    f /= 2.0;
    
    return f;

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


vec2 adv( vec2 uv )
{
 
    
    vec2 pre = texture( iChannel1, uv ).yz;

    uv = uv - dt * iTimeDelta * pre;
    
    return uv;
    
}

float dis( vec2 uv, vec2 mou )
{

    return length( uv - mou );

}

float cir( vec2 uv, vec2 mou, float r )
{

    float o = smoothstep( r, r - 0.05, dis( uv, mou ) );
    
    return o;

}

vec4 dif( vec2 uv, vec2 p, vec2 mou, sampler2D tex, out float cen )
{

    float xpi = 1.0 / iResolution.x;
    float ypi = 1.0 / iResolution.y;
    
    float x = uv.x;
    float y = uv.y;
    
    vec4 cent = texture( tex, uv );
    vec4 top = texture( tex, vec2( x, y + ypi ) );
    vec4 lef = texture( tex, vec2( x - xpi, y ) );
    vec4 rig = texture( tex, vec2( x + xpi, y ) );
    vec4 dow = texture( tex, vec2( x, y - ypi ) );
    
    vec4 col = ( di * rbe ) * ( top + lef + rig + dow + alp * cen ) * rbe;
    
    #ifdef WATERPAINTING
    
    col += 0.2 * texture( iChannel3, uv );
    
    if( iMouse.z > 0.5 )
	col += cir( p, mou, siz );
    
    #else
    
    //col += 0.4 * vec4( fbm( uv + 2.0 ), fbm( uv ), fbm( uv + 3.0 ), 1 );
    //col += cir( p, vec2( 0.9, 0.5 ), siz );
    
    if( iMouse.z > 0.5 )
	col += cir( p, mou, siz );
    
    #endif
    
    return col;

}

vec2 div( vec2 uv )
{

    float xpi = 1.0 / iResolution.x;
    float ypi = 1.0 / iResolution.y;
    
    float x = uv.x;
    float y = uv.y;
    
    float cen = texture( iChannel0, uv ).a;
    float top = texture( iChannel0, vec2( x, y + ypi ) ).r;
    float lef = texture( iChannel0, vec2( x - xpi, y ) ).r;
    float rig = texture( iChannel0, vec2( x + xpi, y ) ).r;
    float dow = texture( iChannel0, vec2( x, y - ypi ) ).r;
    
    float dX = dt * ( rig - lef ) * 0.5;
    float dY = dt * ( top - dow ) * 0.5;
    
    return vec2( dX, dY );

}

vec2 pre( vec2 uv )
{

    vec2 pre = uv;
    
    float xpi = 1.0 / iResolution.x;
    float ypi = 1.0 / iResolution.y;
    
    uv -= ( di * dx * dx ) * div( ( uv ) );
    
    return uv;

}

vec2 vel( vec2 uv )
{
    
    vec2 pr = pre( uv );
    vec2 die = div( uv );
    
    uv += dt * die - pr;
   
    return uv;
    
}

vec4 jac( vec2 uv, vec2 p, vec2 mou, out float cen )
{

    vec4 col = vec4( 0.0 ); float dam = 1.0; vec4 colO = vec4( 0 ); vec2 pre = uv;
    
    for( int i = 0; i < ITER; ++i )
    {
        
        uv = adv( uv );
        uv -= dt * ( vel( ( uv ) ) );
        col += dam * dif( uv, p, mou, iChannel0, cen );
        colO = texture( iChannel0, uv ) + col * dt * 0.2;
    	dam *= 0.99;
        colO *= dam;
    
    }
    
    if( pre.y < 0.00 || pre.x < 0.00 || pre.x > 1.0 || pre.y > 1.0 ) colO *= 0.0;
    
    return colO;

}

void main()
{
    
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec2 p = gl_FragCoord.xy / iResolution.y;

    vec2 mou = iMouse.xy / iResolution.y;
    
    float ini = 0.0;
    
    float cen = 0.0;
    
    vec4 colO = vec4( 1.0, 0.99, 0.99, 1 ) * jac( uv, p, mou, cen );
    
    fragColor = colO;
    
}