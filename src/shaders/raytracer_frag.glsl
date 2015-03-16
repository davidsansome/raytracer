#define CAMERA_OFFSET 0.707
#define MAX_BOUNCES 10
#define SUBPIXEL_SAMPLING


#define VERYBIG 1000000.0
#define VERYSMALL 0.000001

#define TYPE_SPHERE 0
#define TYPE_TRIANGLE 1

uniform vec2 pixelSize;
uniform int objectPassThrough;

uniform sampler2D texture;


// Geometry data

#define SPHERE_COUNT 4
#define TRIANGLE_COUNT 2

vec3 spherePositions[SPHERE_COUNT] =
{
	vec3(1.0, 0.0, 5.0),
	vec3(-1.0, 0.0, 5.0),
	vec3(0.0, 2.0, 4.0),
	vec3(-2.0, 0.0, 3.0)
};

float sphereSizes[SPHERE_COUNT] =
{
	1.0,
	1.0,
	1.0,
	1.0
};

float sphereReflectivity[SPHERE_COUNT] =
{
	0.5,
	0.5,
	0.5,
	0.5
};

vec4 sphereColors[SPHERE_COUNT] =
{
	vec4(1.0, 0.0, 0.0, 1.0),
	vec4(0.0, 1.0, 0.0, 1.0),
	vec4(0.0, 0.0, 1.0, 1.0),
	vec4(1.0, 1.0, 1.0, 0.5)
};

vec3 trianglePoints[TRIANGLE_COUNT * 3] =
{
	vec3(4.0, -1.0, 9.0),
	vec3(4.0, -1.0, 1.0),
	vec3(-4.0, -1.0, 1.0),
	
	vec3(4.0, -1.0, 9.0),
	vec3(-4.0, -1.0, 9.0),
	vec3(-4.0, -1.0, 1.0)
};

float triangleReflectivity[TRIANGLE_COUNT] =
{
	0.8,
	0.8
};





bool shadow(vec3 origin, vec3 direction)
{
	for (int i=0 ; i<SPHERE_COUNT ; ++i)
	{
		// Translated sphere center
		vec3 vpc = spherePositions[i] - origin;
		
		if (dot(direction, vpc) < 0.0) // Sphere is behind us
			continue;
		
		// Projection of sphere's center onto our ray
		vec3 pc = dot(direction, vpc) * direction;
		
		// Work out how far the line passes from the sphere
		float l = length(vpc - pc);
		
		if (l > sphereSizes[i]) // Ray doesn't intersect sphere
			continue;
		
		return true;
	}
	
	return false;
}

vec4 sphereLighting(int i, vec3 pos, vec3 direction,
                    out vec3 normal,
                    out vec3 reflection,
                    out bool inShadow,
                    out float reflectivity)
{
	vec3 lightVector = normalize(gl_LightSource[0].position.xyz - pos);
	
	normal = normalize(pos - spherePositions[i]);
	reflection = reflect(direction, normal);
	inShadow = shadow(pos, lightVector);
	reflectivity = sphereReflectivity[i];
	
	float ambient = 0.2;
	float diffuse = inShadow ? 0.0 : 0.7 * clamp(dot(normal, lightVector), 0.0, 1.0);
	float specular = inShadow ? 0.0 : 2.0 * pow(clamp(dot(reflection, lightVector), 0.0, 1.0), 50.0);
	
	vec4 color = sphereColors[i];
	color.rgb *= ambient + diffuse;
	color.rgb += specular;
	color.rgb *= color.a;
	
	return clamp(color, 0.0, 1.0);
}

vec4 triangleLighting(int i, vec3 pos, vec3 direction, vec2 uv,
                      out vec3 normal,
                      out vec3 reflection,
                      out bool inShadow,
                      out float reflectivity)
{
	vec3 lightVector = normalize(gl_LightSource[0].position.xyz - pos);
	
	normal = vec3(0.0, 1.0, 0.0);
	reflection = reflect(direction, normal);
	inShadow = shadow(pos, lightVector);
	reflectivity = triangleReflectivity[i];
	
	float ambient = 0.2;
	float diffuse = inShadow ? 0.0 : 0.7 * clamp(dot(normal, lightVector), 0.0, 1.0);
	//float specular = inShadow ? 0.0 : 2.0 * pow(clamp(dot(reflection, lightVector), 0.0, 1.0), 50.0);
	
	//vec4 color = texture2D(texture, uv);
	vec4 color = vec4(0.5, 0.5, 0.5, 1.0);
	color.rgb *= ambient + diffuse;
	//color.rgb += specular;
	color.rgb *= color.a;
	
	return clamp(color, 0.0, 1.0);
}

void nextSphere(vec3 origin, vec3 direction,
                out int closestIndex,
                out float closestDistance)
{
	closestIndex = -1;
	closestDistance = VERYBIG;
	
	for (int i=0 ; i<SPHERE_COUNT ; ++i)
	{
		// Translated sphere center
		vec3 vpc = spherePositions[i] - origin;
		
		if (dot(direction, vpc) < 0.0) // Sphere is behind us
			continue;
		
		// Projection of sphere's center onto our ray
		vec3 pc = dot(direction, vpc) * direction;
		
		// Work out how far the line passes from the sphere
		float l = length(vpc - pc);
		
		if (l > sphereSizes[i]) // Ray doesn't intersect sphere
			continue;
		
		float dist = sqrt(sphereSizes[i]*sphereSizes[i] - l*l);
		float di = length(pc) - dist;
		
		if (length(vpc) < sphereSizes[i])
			continue;
		
		if (di > closestDistance) // Another sphere is infront of this one
			continue;
		
		closestIndex = i;
		closestDistance = di;
	}
}

void nextTriangle(vec3 origin, vec3 direction,
                  out int closestIndex,
                  out vec2 closestUV,
                  out float closestT)
{
	closestIndex = -1;
	closestT = VERYBIG;
	for (int i=0 ; i<TRIANGLE_COUNT ; ++i)
	{
		// Don't really know what the letters mean, taken from:
		// http://www.lighthouse3d.com/opengl/maths/index.php?raytriint
		vec3 e1 = trianglePoints[i*3 + 1] - trianglePoints[i*3 + 0];
		vec3 e2 = trianglePoints[i*3 + 2] - trianglePoints[i*3 + 0];
		vec3 h = cross(direction, e2);
		float a = dot(e1, h);
		
		if (a > -VERYSMALL && a < VERYSMALL)
			continue;
		
		float f = 1.0 / a;
		vec3 s = origin - trianglePoints[i*3 + 0];
		float u = f * dot(s, h);
		if (u < 0.0 || u > 1.0)
			continue;
		
		vec3 q = cross(s, e1);
		float v = f * dot(direction, q);
		if (v < 0.0 || u + v > 1.0)
			continue;
		
		float t = f * dot(e2, q);
		if (t < 0.001)
			continue;
		
		if (t < closestT)
		{
			closestT = t;
			closestUV = vec2(u, v);
			closestIndex = i;
		}
	}
}

void nextShape(vec3 origin, vec3 direction,
               out int index,
               out int type,
               out vec2 uv,
               out float t)
{
	int triI, sphI;
	vec2 triUV;
	float triT, sphT;
	
	nextTriangle(origin, direction, triI, triUV, triT);
	nextSphere(origin, direction, sphI, sphT);
	
	if (sphT < triT)
	{
		type = TYPE_SPHERE;
		index = sphI;
		uv = vec2(0.0, 0.0);
		t = sphT;
	}
	else
	{
		type = TYPE_TRIANGLE;
		index = triI;
		uv = triUV;
		t = triT;
	}
}

vec4 projectRay(vec3 origin, vec3 direction)
{
	vec4 color = vec4(0.0, 0.0, 0.0, 0.0);
	
	int i;
	int type;
	float d;
	vec2 uv;
	nextShape(origin, direction, i, type, uv, d);
	
	for (int k=0 ; k<objectPassThrough ; ++k)
	{
		if (i == -1)
			return color;
		
		origin += direction * (d + 0.001);
		nextShape(origin, direction, i, type, uv, d);
	}
	
	if (i == -1)
		return color;
	
	float initialAlpha = sphereColors[i].a;
	float alpha = 1.0;
	
	int loopCounter = MAX_BOUNCES;
	while (i != -1 && loopCounter >= 0)
	{
		// We found a sphere
		vec3 intersection = origin + direction * d;
		vec3 normal;
		vec3 reflection;
		bool inShadow;
		vec4 shapeColor;
		float reflectivity;
		
		if (type == TYPE_SPHERE)
			shapeColor = sphereLighting(i, intersection, direction, normal, reflection, inShadow, reflectivity);
		else
			shapeColor = triangleLighting(i, intersection, direction, uv, normal, reflection, inShadow, reflectivity);
		
		// See if it's in shadow
		//if (inShadow)
		//	sphereColor.rgb *= 0.5;
		
		color += alpha * shapeColor;
		alpha *= reflectivity;
		
		// Reflect our ray off it
		origin = intersection;
		direction = reflection;
		
		// Now see if it hits something else
		nextShape(origin, direction, i, type, uv, d);
		
		loopCounter --;
	}
	
	return vec4(color.rgb, initialAlpha);
}

void main()
{
	vec3 cameraPos = (gl_ModelViewMatrix * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec2 subPixelSize = pixelSize / 3.0;
	vec4 color = vec4(0.0, 0.0, 0.0, 0.0);
	
	// Sample at the pixel
	color += projectRay(cameraPos, normalize(gl_NormalMatrix * vec3(gl_TexCoord[0].xy, CAMERA_OFFSET)));
	
#ifdef SUBPIXEL_SAMPLING
	// Sample left and right
	color += projectRay(cameraPos, normalize(gl_NormalMatrix * vec3(gl_TexCoord[0].x + subPixelSize.x, gl_TexCoord[0].y, CAMERA_OFFSET)));
	color += projectRay(cameraPos, normalize(gl_NormalMatrix * vec3(gl_TexCoord[0].x - subPixelSize.x, gl_TexCoord[0].y, CAMERA_OFFSET)));
	
	// Sample above and below
	color += projectRay(cameraPos, normalize(gl_NormalMatrix * vec3(gl_TexCoord[0].x, gl_TexCoord[0].y + subPixelSize.y, CAMERA_OFFSET)));
	color += projectRay(cameraPos, normalize(gl_NormalMatrix * vec3(gl_TexCoord[0].x, gl_TexCoord[0].y - subPixelSize.y, CAMERA_OFFSET)));
	
	gl_FragColor = color / 5.0;
#else
	gl_FragColor = color;
#endif
}
