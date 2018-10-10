#version 330 core
out vec4 fragColor;

uniform float iTime;
uniform vec2 iResolution;

// Thanks iq and Shane and dila

#define EPS        0.001
#define STEPS        256
#define FAR         100.
#define PI  acos( -1.0 )
#define TPI     PI * 2.0
#define HASHSCALE  .1031
#define tim           5.

// https://www.shadertoy.com/view/4djSRW

float hash(float p)
{
	vec3 p3 = fract(vec3(p) * HASHSCALE);
	p3 += dot(p3, p3.yzx + 19.19);
	return fract((p3.x + p3.y) * p3.z);
}

// iq's

float noise(in vec3 x)
{

	vec3 p = floor(x);
	vec3 k = fract(x);

	k *= k * k * (3.0 - 2.0 * k);

	float n = p.x + p.y * 57.0 + p.z * 113.0;

	float a = hash(n);
	float b = hash(n + 1.0);
	float c = hash(n + 57.0);
	float d = hash(n + 58.0);

	float e = hash(n + 113.0);
	float f = hash(n + 114.0);
	float g = hash(n + 170.0);
	float h = hash(n + 171.0);

	float res = mix(mix(mix(a, b, k.x), mix(c, d, k.x), k.y),
		mix(mix(e, f, k.x), mix(g, h, k.x), k.y),
		k.z
	);

	return res;

}

float fbm(in vec3 p)
{

	float f = 0.0;
	f += 0.5000 * noise(p); p *= 2.02;
	f += 0.2500 * noise(p); p *= 2.03;
	f += 0.1250 * noise(p); p *= 2.01;
	f += 0.0625 * noise(p);
	f += 0.0125 * noise(p);
	return f / 0.9375;

}

// https://www.shadertoy.com/view/MlXSWX

vec2 path(in float z)
{
	float a = 54.0;
	float b = a * 0.5;
	float s = sin(z / a)*cos(z / b); return vec2(s*b, 0.);
}

float smin(float a, float b, float k)
{
	float h = clamp(0.5 + 0.5*(b - a) / k, 0.0, 1.0);
	return mix(b, a, h) - k * h*(1.0 - h);
}

mat2 rot(float a)
{

	return mat2(cos(a), -sin(a),
		sin(a), cos(a)
	);

}

vec2 map(vec3 p)
{

	/*vec2 tun = abs(p.xy-fbm(p))*vec2(0.5, 0.1071);
	float n = 1. - max(tun.x, tun.y) + (0.5);
	return min(n, p.y + fbm(p));*/

	vec3 pO = vec3(0.0, 0.0, -iTime * tim - 0.9);
	pO.xy += path(pO.z);

	vec2 sph = vec2(length(p - pO) - 0.3 - fbm(p - pO + iTime) * 0.1, 0.0);

	float tun = length(p.xy - path(p.z)) - 12.0;
	float dif = length(p.xy - path(p.z)) - 6.5;
	float fina = max(tun, -dif);
	vec2 fin = vec2(fina - fbm(p + iTime) * 2.0, 1.0);

	if (sph.x < fin.x) fin = sph;

	return fin;

}

vec3 norm(vec3 p)
{

	vec2 e = vec2(EPS, 0.0);
	return normalize(vec3(map(p + e.xyy).x - map(p - e.xyy).x,
		map(p + e.yxy).x - map(p - e.yxy).x,
		map(p + e.yyx).x - map(p - e.yyx).x
	));

}

float softShadows(in vec3 ro, in vec3 rd)
{

	float res = 1.0;
	for (float t = 0.1; t < 8.0; ++t)
	{

		float h = map(ro + rd * t).x;
		if (h < EPS) return 0.0;
		res = min(res, 2.0 * h / t);

		t += h;

	}

	return res;

}

vec3 shad(vec3 ro, vec3 rd, float t)
{

	vec3 p = ro + rd * t;
	vec3 n = norm(p);
	vec3 lig = normalize(vec3(0.0, 0.0, -iTime * tim));
	lig.xy += path(lig.z);
	vec3 ref = reflect(rd, n);
	vec3 col = vec3(0.0);
	//vec3 ref = texture( iChannel0, reflect( rd, n ) ).xyz;

	float amb = 0.5 + 0.5 * n.y;
	float dif = max(0.0, dot(n, lig));
	float sha = softShadows(p, lig);
	float spe = pow(clamp(dot(ref, lig), 0.0, 1.0), 16.0);
	float rim = pow(1.0 + dot(n, rd), 2.0);

	col += 0.4 * amb;
	col += 0.2 * dif * sha;
	col += 0.15 * spe;
	col += 0.1 * rim;

	if (map(p).y == 1.0)
	{

		col += mix(vec3(0.3, 0.1, 0.0), vec3(0.0, 0.1, 0.2), fbm(p + iTime));

	}

	if (map(p).y == 0.0)
	{

		col *= vec3(0);

	}

	col *= vec3(16.0 / (16.0 + t * t * 0.05));
	col /= vec3(0.05 * (9.0 + t * t * 0.05));

	col *= sqrt(col);

	return col;

}

float ray(vec3 ro, vec3 rd, out float d)
{

	float t = 0.0; d = EPS;
	for (int i = 0; i < STEPS; ++i)
	{

		d = 0.5 * map(ro + rd * t).x;
		if (d < EPS || t > FAR) break;

		t += d;

	}

	return t;

}

void main()
{
	// Normalized pixel coordinates (from 0 to 1)
	vec2 uv = (-iResolution.xy + 2.0 * gl_FragCoord.xy) / iResolution.y;
	//vec2 mou = iMouse.xy / iResolution.xy;

	vec3 ro = vec3(0.0, 0.0, -iTime * tim);
	vec3 rd = normalize(vec3(uv, -1.0));

	ro.xy += path(ro.z);
	rd.zx *= rot(path(ro.z).x / -1000.0);

	float d = 0.0;
	float t = ray(ro, rd, d);

	vec3 p = ro + rd * t;
	vec3 n = norm(p);

	vec3 col = d < EPS ? shad(ro, rd, t) : vec3(1.0);

	if (map(p).y == 0.0)
	{

		rd = normalize(reflect(rd, n));
		ro = rd * EPS;

		if (d < EPS)
		{

			col += shad(ro, rd, t) * 0.3;

		}

	}

	// Output to screen
	fragColor = vec4(col, 1.0);
}
/*
void main()
{

	vec2 uv = ( -iResolution.xy + 2.0 * gl_FragCoord.xy ) / iResolution.y;

	vec3 col = vec3( length( uv ) + sin( iTime ) );

	fragColor = vec4( col, 1.0 );
}
*/