const float Exposure = 0.5f;

void mainImage(out vec4 FragColor, in vec2 FragCoord)
{
    vec3 Color = texture(iChannel0, FragCoord / iResolution.xy).rgb;
    
    Color *= Exposure;
    Color = ACESFilm(Color);
    Color = LinearToSRGB(Color);
    
    FragColor = vec4(Color, 1.0);
}