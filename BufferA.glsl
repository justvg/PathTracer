// This is to prevent a ray from intersecting a surface it just bounced off of.
const float MinRayHitTime = 0.01f;
const float MaxRayHitTime = 10000.0f;

const int NumBounces = 8;
const float NormalNudge = 0.01f;

const float FoVDegrees = 90.0f;
const float PI = 3.14159265359f;
const float TwoPI = 2.0f*PI;

uint WangHash(inout uint Seed)
{
    Seed = uint(Seed ^ uint(61)) ^ uint(Seed >> uint(16));
    Seed *= uint(9);
    Seed = Seed ^ (Seed >> 4);
    Seed *= uint(0x27d4eb2d);
    Seed = Seed ^ (Seed >> 15);
    return Seed;
}

float RandomFloat01(inout uint State)
{
    float Result = float(WangHash(State)) / 4294967296.0;
    return(Result);
}

vec3 RandomUnitVector(inout uint State)
{
    float Z = 2.0f*RandomFloat01(State) - 1.0f;
    float Angle = TwoPI*RandomFloat01(State);
    float Radius = sqrt(1.0f - Z*Z);
    float X = Radius * cos(Angle);
    float Y = Radius * sin(Angle);
	
    vec3 Result = vec3(X, Y, Z);
    return(Result);
}

struct ray_hit_info
{
    float t;
    vec3 Normal;
    vec3 Albedo;
    vec3 Emissive;
};
    
float ScalarTriple(vec3 A, vec3 B, vec3 C)
{
    float Result = dot(cross(A, B), C);
    return(Result);
}
    
bool TestQuadRay(in vec3 RayPosition, in vec3 RayDir, inout ray_hit_info HitInfo, in vec3 A, in vec3 B, in vec3 C, in vec3 D)
{
 	vec3 Normal = normalize(cross(C-A, C-B));
    if(dot(RayDir, Normal) > 0.0f)
    {
        Normal *= -1.0f;
        
        vec3 Temp = A;
        A = D;
        D = Temp;
        
        Temp = B;
        B = C;
        C = Temp;
    }
    
    vec3 P = RayPosition;
    vec3 PQ = RayDir;
    vec3 PA = A - P;
    vec3 PB = B - P;
    vec3 PC = C - P;
    vec3 PD = D - P;
    
    vec3 IntersectionP;
    
    float V = ScalarTriple(PQ, PA, PC);
	if(V >= 0.0f)
    {
        // Test intersection against triangle ABC
        float U = ScalarTriple(PQ, PC, PB);
        if(U < 0.0f) return(false);
        float W = ScalarTriple(PQ, PB, PA);
    	if(W < 0.0f) return(false);
        
        float Denom = 1.0f / (U + V + W);
        U *= Denom;
        V *= Denom;
        W = 1.0f - U - V;

        IntersectionP = A*U + B*V + C*W;
    }
    else
    {
        // Test intersection against triangle DAC
        float U = ScalarTriple(PQ, PD, PC);
        if(U < 0.0f) return(false);
        float W = ScalarTriple(PQ, PA, PD);
    	if(W < 0.0f) return(false);
        V = -V;
        
        float Denom = 1.0f / (U + V + W);
        U *= Denom;
        V *= Denom;
        W = 1.0f - U - V;

        IntersectionP = A*U + D*V + C*W;
    }
    
    float t;
    if (abs(RayDir.x) > 0.1f)
    {
        t = (IntersectionP.x - RayPosition.x) / RayDir.x;
    }
    else if (abs(RayDir.y) > 0.1f)
    {
        t = (IntersectionP.y - RayPosition.y) / RayDir.y;
    }
    else
    {
        t = (IntersectionP.z - RayPosition.z) / RayDir.z;
    }
    
    if((t > MinRayHitTime) && (t < HitInfo.t))
    {
        HitInfo.t = t;
        HitInfo.Normal = Normal;
        return(true);
    }
    
    return(false);
}
    
bool TestSphereRay(in vec3 RayPosition, in vec3 RayDir, inout ray_hit_info HitInfo, in vec4 Sphere)
{
    vec3 M = RayPosition - Sphere.xyz;
    float B = dot(M, RayDir);
    float C = dot(M, M) - Sphere.w*Sphere.w;
    
    if((C > 0.0f) && (B > 0.0f))
    {
        return(false);
    }
    
    float Discr = B*B - C;
    if(Discr < 0.0f)
    {
        return(false);
    }
    
    bool FromInside = false;
    float t = -B - sqrt(Discr);
    if(t < 0.0f)
    {
        FromInside = true;
        t = -B + sqrt(Discr);
    }
    
    if((t > MinRayHitTime) && (t < HitInfo.t))
    {
        HitInfo.t = t;
        HitInfo.Normal = normalize((RayPosition + t*RayDir) - Sphere.xyz) * (FromInside ? -1.0f : 1.0f);
        return(true);
    }
    
    return(false);
}

void TestSceneTrace(in vec3 RayPosition, in vec3 RayDir, inout ray_hit_info HitInfo)
{
    vec3 SceneTranslation = vec3(0.0f, 0.0f, 10.0f);
    vec4 SceneTranslation4 = vec4(SceneTranslation, 0.0f);
    
   	// back wall
    {
        vec3 A = vec3(-12.6f, -12.6f, 25.0f) + SceneTranslation;
        vec3 B = vec3( 12.6f, -12.6f, 25.0f) + SceneTranslation;
        vec3 C = vec3( 12.6f,  12.6f, 25.0f) + SceneTranslation;
        vec3 D = vec3(-12.6f,  12.6f, 25.0f) + SceneTranslation;
        if(TestQuadRay(RayPosition, RayDir, HitInfo, A, B, C, D))
        {
            HitInfo.Albedo = vec3(0.7f, 0.7f, 0.7f);
            HitInfo.Emissive = vec3(0.0f, 0.0f, 0.0f);
        }
	}    
    
    // floor
    {
        vec3 A = vec3(-12.6f, -12.45f, 25.0f) + SceneTranslation;
        vec3 B = vec3( 12.6f, -12.45f, 25.0f) + SceneTranslation;
        vec3 C = vec3( 12.6f, -12.45f, 15.0f) + SceneTranslation;
        vec3 D = vec3(-12.6f, -12.45f, 15.0f) + SceneTranslation;
        if(TestQuadRay(RayPosition, RayDir, HitInfo, A, B, C, D))
        {
            HitInfo.Albedo = vec3(0.7f, 0.7f, 0.7f);
            HitInfo.Emissive = vec3(0.0f, 0.0f, 0.0f);
        }        
    }
    
    // cieling
    {
        vec3 A = vec3(-12.6f, 12.5f, 25.0f) + SceneTranslation;
        vec3 B = vec3( 12.6f, 12.5f, 25.0f) + SceneTranslation;
        vec3 C = vec3( 12.6f, 12.5f, 15.0f) + SceneTranslation;
        vec3 D = vec3(-12.6f, 12.5f, 15.0f) + SceneTranslation;
        if(TestQuadRay(RayPosition, RayDir, HitInfo, A, B, C, D))
        {
            HitInfo.Albedo = vec3(0.7f, 0.7f, 0.7f);
            HitInfo.Emissive = vec3(0.0f, 0.0f, 0.0f);
        }        
    }    
    
    // left wall
    {
        vec3 A = vec3(-12.5f, -12.6f, 25.0f) + SceneTranslation;
        vec3 B = vec3(-12.5f, -12.6f, 15.0f) + SceneTranslation;
        vec3 C = vec3(-12.5f,  12.6f, 15.0f) + SceneTranslation;
        vec3 D = vec3(-12.5f,  12.6f, 25.0f) + SceneTranslation;
        if(TestQuadRay(RayPosition, RayDir, HitInfo, A, B, C, D))
        {
            HitInfo.Albedo = vec3(0.7f, 0.1f, 0.1f);
            HitInfo.Emissive = vec3(0.0f, 0.0f, 0.0f);
        }        
    }
    
    // right wall 
    {
        vec3 A = vec3( 12.5f, -12.6f, 25.0f) + SceneTranslation;
        vec3 B = vec3( 12.5f, -12.6f, 15.0f) + SceneTranslation;
        vec3 C = vec3( 12.5f,  12.6f, 15.0f) + SceneTranslation;
        vec3 D = vec3( 12.5f,  12.6f, 25.0f) + SceneTranslation;
        if(TestQuadRay(RayPosition, RayDir, HitInfo, A, B, C, D))
        {
            HitInfo.Albedo = vec3(0.1f, 0.7f, 0.1f);
            HitInfo.Emissive = vec3(0.0f, 0.0f, 0.0f);
        }        
    }    
    
    // light
    {
        vec3 A = vec3(-5.0f, 12.4f,  22.5f) + SceneTranslation;
        vec3 B = vec3( 5.0f, 12.4f,  22.5f) + SceneTranslation;
        vec3 C = vec3( 5.0f, 12.4f,  17.5f) + SceneTranslation;
        vec3 D = vec3(-5.0f, 12.4f,  17.5f) + SceneTranslation;
        if(TestQuadRay(RayPosition, RayDir, HitInfo, A, B, C, D))
        {
            HitInfo.Albedo = vec3(0.0f, 0.0f, 0.0f);
            HitInfo.Emissive = vec3(1.0f, 0.9f, 0.7f) * 20.0f;
        }        
    }
    
	if(TestSphereRay(RayPosition, RayDir, HitInfo, vec4(-9.0f, -9.5f, 20.0f, 3.0f)+SceneTranslation4))
    {
        HitInfo.Albedo = vec3(0.9f, 0.9f, 0.75f);
        HitInfo.Emissive = vec3(0.0f, 0.0f, 0.0f);        
    } 
    
	if(TestSphereRay(RayPosition, RayDir, HitInfo, vec4(0.0f, -9.5f, 20.0f, 3.0f)+SceneTranslation4))
    {
        HitInfo.Albedo = vec3(0.9f, 0.75f, 0.9f);
        HitInfo.Emissive = vec3(0.0f, 0.0f, 0.0f);        
    }    
    
	if(TestSphereRay(RayPosition, RayDir, HitInfo, vec4(9.0f, -9.5f, 20.0f, 3.0f)+SceneTranslation4))
    {
        HitInfo.Albedo = vec3(0.75f, 0.9f, 0.9f);
        HitInfo.Emissive = vec3(0.0f, 0.0f, 0.0f);
    }    
}

vec3 GetColorForRay(in vec3 StartRayPosition, in vec3 StartRayDir, inout uint RNGState)
{
    vec3 ResultColor = vec3(0.0f, 0.0f, 0.0f);
    vec3 ThroughputColor = vec3(1.0f, 1.0f, 1.0f);
    vec3 RayPosition = StartRayPosition;
    vec3 RayDir = StartRayDir;
    
    for(int BounceIndex = 0; BounceIndex < NumBounces; BounceIndex++)
    {
        ray_hit_info HitInfo;
        HitInfo.t = MaxRayHitTime;
		TestSceneTrace(RayPosition, RayDir, HitInfo);
        
        if(HitInfo.t == MaxRayHitTime)
        {
         	ResultColor += texture(iChannel1, RayDir).rgb * ThroughputColor;
            break;
        }
        
        RayPosition = (RayPosition + HitInfo.t*RayDir) + NormalNudge*HitInfo.Normal;
        RayDir = normalize(HitInfo.Normal + RandomUnitVector(RNGState));
        
        ResultColor += HitInfo.Emissive * ThroughputColor;
        ThroughputColor *= HitInfo.Albedo;
    }
    
    return(ResultColor);
}

void mainImage(out vec4 FragColor, in vec2 FragCoord)
{
    vec3 RayPosition = vec3(0.0f, 0.0f, 0.0f);
    float CameraDistance = 1.0f / tan(0.5f*FoVDegrees * PI / 180.0f);
    vec3 RayTarget = vec3(2.0f*(FragCoord/iResolution.xy) - 1.0f, CameraDistance);
    float AspectRatio = iResolution.x / iResolution.y;
    RayTarget.y /= AspectRatio;
	vec3 RayDir = normalize(RayTarget - RayPosition);
    
    uint RNGState = uint(uint(FragCoord.x) * uint(1973) + uint(FragCoord.y) * uint(9277) + uint(iFrame) * uint(26699)) | uint(1);
    
    // Raytrace for this pixel
    vec3 Color = vec3(0.0f, 0.0f, 0.0f);
	for(int Index = 0; Index < 3; Index++)
    {
     	Color += GetColorForRay(RayPosition, RayDir, RNGState);   
    }
	Color /= 2.0;    
    
    
    vec3 LastFrameColor = texture(iChannel0, FragCoord / iResolution.xy).rgb;
    Color = mix(LastFrameColor, Color, 1.0f / float(iFrame + 1));
    
    // Output to screen
    FragColor = vec4(Color, 1.0);
}