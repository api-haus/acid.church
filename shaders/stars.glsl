// Star Nest by Pablo RomÃ¡n Andrioli

// This content is under the MIT License.

#define iterations 12
#define formuparam 0.57

#define volsteps 10
#define stepsize 0.2

#define zoom   1.200
#define tile   1.0
#define speed  0.010

#define brightness 0.0015
#define darkmatter 1.00
#define distfading 0.730
#define saturation 1.0

#define mo (2.0 * iMouse.xy - iResolution.xy) / iResolution.y
#define blackholeCenter vec3(time*2., time, -2.)
#define blackholeRadius 1.05
#define blackholeIntensity 2.5

float iSphere(vec3 ray, vec3 dir, vec3 center, float radius)
{
	vec3 rc = ray-center;
	float c = dot(rc, rc) - (radius*radius);
	float b = dot(dir, rc);
	float d = b*b - c;
	float t = -b - sqrt(abs(d));
	float st = step(0.0, min(t, d));
	return mix(-1.0, t, st);
}

vec3 iPlane(vec3 ro, vec3 rd, vec3 po, vec3 pd){
	float d = dot(po - ro, pd) / dot(rd, pd);
	return d * rd + ro;
}

vec3 r(vec3 v, vec2 r)//incomplete but ultrafast rotation fcn thnx to rodolphito
{
	vec4 t = sin(vec4(r, r + 1.5707963268));
	float g = dot(v.yz, t.yw);
	return vec3(v.x * t.z - g * t.x,
	v.y * t.w - v.z * t.y,
	v.x * t.x + g * t.z);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	//get coords and direction
	vec2 uv=fragCoord.xy/iResolution.xy-.5;
	uv.y*=iResolution.y/iResolution.x;
	vec3 dir=vec3(uv*zoom, 1.);
	float time=iTime*speed+.25;

	//mouse rotation
	vec3 from=vec3(0.0, 0.0, -15.0);
	from = r(from, mo / 10.0);
	dir = r(dir, mo / 10.0);
	from+=blackholeCenter;

	vec3 nml = normalize(blackholeCenter - from);
	vec3 pos = iPlane(from, dir, blackholeCenter, nml);
	pos = blackholeCenter - pos;
	float intensity = dot(pos, pos);
	float bhr = blackholeRadius + sin(iTime);
	float bhi = blackholeIntensity * (sin(iTime) / 2.0 + .5);

	if (intensity > bhr * bhr){
		intensity = 1.0 / intensity;
		dir = mix(dir, pos * sqrt(intensity), bhi * intensity);

		//volumetric rendering
		float s=0.1, fade=1.;
		vec3 v=vec3(0.);
		for (int r=0; r<volsteps; r++) {
			vec3 p=from+s*dir*.5;
			p = abs(vec3(tile)-mod(p, vec3(tile*2.)));// tiling fold
			float pa, a=pa=0.;
			for (int i=0; i<iterations; i++) {
				p=abs(p)/dot(p, p)-formuparam;// the magic formula
				a+=abs(length(p)-pa);// absolute sum of average change
				pa=length(p);
			}
			float dm=max(0., darkmatter-a*a*.001);//dark matter
			a*=a*a;// add contrast
			if (r>6) fade*=1.-dm;// dark matter, don't render near
			//v+=vec3(dm,dm*.5,0.);
			v+=fade;
			v+=vec3(s, s*s, s*s*s*s)*a*brightness*fade;// coloring based on distance
			fade*=distfading;// distance fading
			s+=stepsize;
		}
		v=mix(vec3(length(v)), v, saturation);//color adjust
		fragColor = vec4(v*.01, 1.);
	}
	else fragColor = vec4(0.0);
}
