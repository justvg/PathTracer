void mainImage(out vec4 FragColor, in vec2 FragCoord)
{
    vec3 Color = texture(iChannel0, FragCoord / iResolution.xy).rgb;
    FragColor = vec4(Color, 1.0);
}