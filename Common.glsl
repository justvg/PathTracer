vec3 LessThan(vec3 V, float Value)
{
    vec3 Result = vec3((V.x < Value) ? 1.0f : 0.0f,
                       (V.y < Value) ? 1.0f : 0.0f,
                       (V.z < Value) ? 1.0f : 0.0f);
   	return(Result);
}

vec3 LinearToSRGB(vec3 RGB)
{
    RGB = clamp(RGB, 0.0f, 1.0f);
    
    vec3 Result = mix(pow(RGB, vec3(1.0f / 2.4f)) * 1.055f - 0.055f,
                      RGB * 12.92f,
                      LessThan(RGB, 0.0031308f));
    return(Result);
}

vec3 SRGBToLinear(vec3 RGB)
{
    RGB = clamp(RGB, 0.0f, 1.0f);
    
    vec3 Result = mix(pow((RGB + 0.055f) / 1.055f, vec3(2.4f)),
                      RGB / 12.92f,
                      LessThan(RGB, 0.04045f));
    return(Result);
}

// ACES tone mapping curve fit to go from HDR to LDR
//https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilm(vec3 X)
{
    float A = 2.51f;
    float B = 0.03f;
    float C = 2.43f;
    float D = 0.59f;
    float E = 0.14f;
    
    vec3 Result = clamp((X*(A*X + B)) / (X*(C*X + D) + E), 0.0f, 1.0f);
    return(Result);
}