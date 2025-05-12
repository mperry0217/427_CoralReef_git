// CommonFunctions.cginc
#ifndef COMMON_FUNCTIONS
#define COMMON_FUNCTIONS

float4 alphaBlend(float4 top, float4 bottom) // This will be used to blend the colours of the foam without making them brighter
{
    float3 color = (top.rgb * top.a) + (bottom.rgb * (1 - top.a));
    float alpha = top.a + bottom.a * (1 - top.a);

    return float4(color, alpha);
}

float3 GerstnerWave(float4 wave, float3 p, inout float3 tangent, inout float3 binormal,float wavespeed)
{
    float steepness = wave.z; // Use the z value of wave to control wave steepness
    float wavelength = wave.w; // Use the w value of wave to control wavelength
    float k = 2 * UNITY_PI / wavelength;
    float c = sqrt(wavespeed / k); // Waves dont have an arbitrary speed, its instead related to the wave number and gravity of earth
    float2 d = normalize(wave.xy);
    float f = k * (dot(d, p.xz) - c * _Time.y);
    float a = steepness / k;

    tangent += float3(
        -d.x * d.x * (steepness * sin(f)),
        d.x * (steepness * cos(f)),
        -d.x * d.y * (steepness * sin(f))
        );

    binormal += float3(
        -d.x * d.y * (steepness * sin(f)),
        d.y * (steepness * cos(f)),
        -d.y * d.y * (steepness * sin(f))
        );

    // Return the new coordinates to use for the displaced vertex
    return float3(
        d.x * (a * cos(f)),
        a * sin(f),
        d.y * (a * cos(f))
        );
}

#endif // COMMON_FUNCTIONS