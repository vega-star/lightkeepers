#[compute]
#version 450

layout(location = 0) in vec2 position;
layout(location = 1) in vec2 texCoords;

out vec2 TexCoords;

void main()
{
    TexCoords = texCoords;
    gl_Position = vec4(position, 0.0, 1.0);
}

// Fragment Shader
#version 330 core
out vec4 FragColor;

in vec2 TexCoords;

uniform sampler2D texture0;

vec3 palette[32] = vec3[32](
    vec3(1.0, 0.0, 0.0), // Red
    vec3(0.0, 1.0, 0.0), // Green
    vec3(0.0, 0.0, 1.0), // Blue
    vec3(1.0, 1.0, 0.0), // Yellow
    vec3(1.0, 0.0, 1.0), // Magenta
    vec3(0.0, 1.0, 1.0), // Cyan
    vec3(1.0, 0.5, 0.0), // Orange
    vec3(0.5, 0.0, 1.0), // Purple
    vec3(0.5, 0.5, 0.5), // Gray
    vec3(0.0, 0.5, 0.5), // Teal
    vec3(0.5, 0.5, 0.0), // Olive
    vec3(1.0, 0.5, 0.5), // Light Red
    vec3(0.5, 1.0, 0.5), // Light Green
    vec3(0.5, 0.5, 1.0), // Light Blue
    vec3(1.0, 1.0, 0.5), // Light Yellow
    vec3(1.0, 0.5, 1.0), // Light Magenta
    vec3(0.5, 1.0, 1.0), // Light Cyan
    vec3(0.5, 0.25, 0.0), // Brown
    vec3(0.25, 0.0, 0.5), // Dark Purple
    vec3(0.25, 0.25, 0.25), // Dark Gray
    vec3(0.0, 0.25, 0.25), // Dark Teal
    vec3(0.25, 0.25, 0.0), // Dark Olive
    vec3(0.75, 0.25, 0.25), // Dark Red
    vec3(0.25, 0.75, 0.25), // Dark Green
    vec3(0.25, 0.25, 0.75), // Dark Blue
    vec3(0.75, 0.75, 0.25), // Dark Yellow
    vec3(0.75, 0.25, 0.75), // Dark Magenta
    vec3(0.25, 0.75, 0.75), // Dark Cyan
    vec3(0.75, 0.5, 0.25), // Tan
    vec3(0.5, 0.25, 0.75), // Plum
    vec3(0.25, 0.5, 0.75), // Slate
    vec3(0.75, 0.75, 0.75)  // Light Gray
);

vec3 closestPaletteColor(vec3 color)
{
    float minDistance = 1000.0;
    vec3 closestColor = color;
    for(int i = 0; i < 32; i++)
    {
        float distance = length(color - palette[i]);
        if(distance < minDistance)
        {
            minDistance = distance;
            closestColor = palette[i];
        }
    }
    return closestColor;
}

void main()
{
    vec3 color = texture(texture0, TexCoords).rgb;
    vec3 finalColor = closestPaletteColor(color);
    FragColor = vec4(finalColor, 1.0);
}
