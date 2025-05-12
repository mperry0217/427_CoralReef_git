// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
Shader "Custom/BaseWaterShader"
{
    Properties
    {
        [Header(Texture)]
        _MainTex("Texture", 2D) = "white" {}
        _NormalMap("Normal Map", 2D) = "bump" {}

        [Header(Color)]
        _ShoreColor("Shore Color", Color) = (1, 1, 1, 1)
        _MainColor("Main Color", Color) = (1, 1, 1, 1)
        _DeepColor("Deep Water Color", Color) = (0, 0, 1, 1)
        _DepthColor("Depth Color", Color) = (0, 0, 1, 1)
        _DepthMaxDistance("Depth Maximum Distance", Float) = 1
        _ShoreCutoff("Shore Cutoff", Range(0,30)) = 0
        _HorizonColor("Horizon Water Color", Color) = (0, 0, 1, 1)
        _FresnelIntensity("Fresnel Intensity", Range(0,10)) = 1
        _FresnelRamp("Fresnel Ramp", Range(0,10)) = 1
        _CrestModifier("Crest Modifier", Float) = 1
        _CrestColor("Crest Color", Color) = (1,1,1,1)
        _WaterFogColor("Water Fog Color", Color) = (0, 0, 0, 0)
        _WaterFogDensity("Water Fog Density", Range(0, 2)) = 0.1

        [Header(Waves)] // If you'd like to have more waves, simply add another wave property and calculate another gertsner wave
        _WaveSpeed("Wave Speed", Float) = 9.8
        _Wave1("Wave 1 (dir, steepness, wavelength)", Vector) = (1,0,0.5,10) // X and Y is used as the direction of our waves, Z is the steepness and W is wavelength
        _Wave2("Wave 2", Vector) = (1,0,0.5,10)
        _Wave3("Wave 3", Vector) = (1,0,0.5,10)
        [KeywordEnum(One, Two, Three)] Waves("Number of Waves to Use", Float) = 0.0
             
        [Header(Reflection and Refraction)]
        _ReflectionStrength("Reflection Strength", Range(0.0, 1.0)) = 0.5  // Reflection strength property
        _RefractionStrength("Refraction Strength", Range(0.0, 1.0)) = 0.5  // Refraction strength property
        //_RefractionSpeed("Refraction Speed", Float) = 1
        //_RefractionIntensity("Refraction Intensity", Float) = 1

        [Header(Foam)]
        _SurfaceNoise("Surface Noise", 2D) = "white" {}
        _SurfaceNoiseCutoff("Surface Noise Cutoff", Range(0, 1)) = 0.777
        _FoamTex("Foam Texture", 2D) = "white" {}
        _FoamDirection("Foam Direction", Vector) = (0.03, 0.03, 0, 0)
        _FoamMaxDistance("Foam Max Distance", Float) = 0.4
        _FoamMinDistance("Foam Min Distance", Float) = 0.04
        _FoamColor("Foam Colour", Color) = (1, 1, 1, 1)

        [Header(Other)]
        _Transparency("Transparency", Range(0, 1)) = 1.0
        _Specular("Specular", Range(0, 1)) = 0.5

    }

        SubShader
        {
            Tags { "RenderType" = "Transparent" "Queue" = "Transparent-200" }
            Cull Off

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            // We need a GrabPass to get the color of things behind water for fx like Refraction/Reflection
            GrabPass { "_SceneColor" }
            Pass
            {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma target 3.0  // added target 3.0 to enable the necessary shader features
                #pragma shader_feature_vertex WAVES_ONE WAVES_TWO WAVES_THREE

                #define SMOOTHSTEP_AA 0.01 // This allows us to use smooth step for antialiasing purposes - smoothly blending the alpha from 0 to 1
                #include "UnityCG.cginc"
                #include "WaterShaderFunctions.cginc"

                struct appdata // This is the object-space data of the vertex
                {
                    float4 vertex : POSITION; // local vertex position
                    float3 normal : NORMAL;
                    float2 uv : TEXCOORD0;
                };

                struct v2f // This is the data that is passed from Vertex to Fragment
                { 
                    float2 uv : TEXCOORD0;
                    float3 worldPos : TEXCOORD1;
                    float3 normal : NORMAL;
                    float3 viewNormal : TEXCOORD2;
                    float3 viewDir : TEXCOORD3;  // Added viewDir to vertex-to-fragment struct
                    float4 vertex : SV_POSITION; // screen clip space position and depth
                    float4x4 invViewMatrix : TEXCOORD4;  // Added inverse view matrix
                    float4 projPos : TEXCOORD8; 
                    float waveHeight : TEXCOORD9;
                };

                sampler2D _MainTex;
                float4 _MainTex_ST;
                sampler2D _NormalMap;
                float4 _NormalMap_ST;
                samplerCUBE _CubeMap;  // Add a cubemap sampler for reflection and refraction
                float4 _MainColor;
                float4 _DeepColor;
                float4 _ShoreColor;
                float _ShoreCutoff;
                float4 _HorizonColor;
                float _FresnelIntensity, _FresnelRamp;
                float _CrestModifier;
                float4 _CrestColor;
                /*float4 _IntersectionColor;
                float _IntersectionThreshold;
                float _IntersectionPow;*/
                float _DepthFactor;
                float _DepthMaxDistance;
                float _WaveSpeed;
                float4 _Wave1, _Wave2, _Wave3;
                float _Transparency;
                float _Specular;
                float _ReflectionStrength;
                float _RefractionStrength;
                float _RefractionSpeed;
                float _RefractionIntensity;
                sampler2D _CameraDepthTexture;
                sampler2D _SceneColor;
                sampler2D _CameraNormalsTexture;
                sampler2D _SurfaceNoise;
                // if a float4 has same name as a texture with _ST appended at the end, unity populates it so it can be used for tiling and offset. This can also be edited
                // in inspector
                float4 _SurfaceNoise_ST; 
                float _SurfaceNoiseCutoff;
                sampler2D _FoamTex;
                float4 _FoamDirection;
                float _FoamMaxDistance;
                float _FoamMinDistance;
                float4 _FoamColor;
                float _NormalStrength;
                float3 _WaterFogColor;
                float _WaterFogDensity;

                
                v2f vert(appdata v) // Set the variables of vert based on variables received from appdata AKA the vertex data
                {
                    v2f o; // Declare a new v2f struct, which will later be used in the fragment program
                    o.uv = v.uv;
                    //o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz; 

                    // We want our fresnel colour to effect our plane like its still flat and not distorted by waves
                    o.viewNormal = UnityObjectToWorldNormal(v.normal);
                    //o.uv = v.uv * _Tiling;  // Adjusted UV coordinates by Tiling factor
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex); // Transform_TEX modifies the UV input with the provided texture's tiling and offset
                    o.viewDir = normalize(WorldSpaceViewDir(v.vertex));  // Calculate view direction

                    // Waves can be visualised as just changing the y-value of a vertex's world space coords
                    float3 vert = v.vertex; // Copy the position values of the vertex

                    // Use the tangents and binormals of a flat plane
                    float3 tangent = float3(1, 0, 0);
                    float3 binormal = float3(0, 0, 1);


                    // Add the offsets calculated by the Gertsner Wave function to the vert. For each wave, repeat this step
                    vert += GerstnerWave(_Wave1, vert, tangent, binormal,_WaveSpeed);
                    #if defined(WAVES_TWO) 
                        vert += GerstnerWave(_Wave2, vert, tangent, binormal, _WaveSpeed);
                    #endif

                    #if defined(WAVES_THREE) 
                        vert += GerstnerWave(_Wave2, vert, tangent, binormal, _WaveSpeed);
                        vert += GerstnerWave(_Wave3, vert, tangent, binormal, _WaveSpeed);
                    #endif

                    float3 normal = normalize(cross(binormal, tangent));
                    v.vertex.xyz = vert; // Tell the vertex program to use the displaced coordinates for the position coordinates of the vertex
                    v.normal = normal;
                    
                    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                    // This will be used for the actual normal for lighting
                    o.normal = UnityObjectToWorldNormal(v.normal);

                    // This will be used to colour wave peaks with a different colour
                    o.waveHeight = vert.y;
                    
                    o.vertex = UnityObjectToClipPos(vert);
                    // Calculate inverse view matrix
                    o.invViewMatrix = UNITY_MATRIX_V;

                    // Get the screenPos from the clip space position of the vertex
                    o.projPos = ComputeScreenPos(o.vertex);
                    //o.viewNormal = COMPUTE_VIEW_NORMAL; // Compute the vertex's view normal using this unity macro so we can use it in fragment
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target // fixed4 is a type which returns low precisiong rgba color
                {
                    fixed4 tex = tex2D(_MainTex, i.uv * _MainTex_ST);
                    //fixed4 normalMap = tex2D(_NormalMap, i.normal);
                    //Move and distort the UVs for our refractions
                    //float timeOffset = _Time.x * _RefractionSpeed;
                    //float2 normalUV1 = float2(i.uv.x + timeOffset, i.uv.y - timeOffset);
                    //float2 normalUV2 = float2(i.uv.x - timeOffset, i.uv.y + timeOffset);

                    //// Sample the normal map twice with our moving UVs
                    //float3 normal1 = tex2D(_NormalMap, normalUV1 * _NormalMap_ST);
                    //float3 normal2 = tex2D(_NormalMap, normalUV2 * _NormalMap_ST);

                    //// Blend the sampled maps together
                    //float3 newNormal = normalize(float3(normal1.rg + normal2.rg, normal1.b * normal2.b));
                    //i.normal = UnpackNormal(tex2D(_NormalMap, newNormal) * _NormalStrength);

                    //newNormal *= _RefractionStrength;
                    //newNormal += i.projPos.xyz;
                    //i.normal = newNormal;

                    // Depth fade of water
                    // Get the depth of the object beneath water by using a sample of the camera's depth texture and the screen space position of the vertex                 
                    float existingDepth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)).r;

                    // Since existingDepth01 is not scaled linearly, we have to decode it to become linear
                    float existingDepthLinear = LinearEyeDepth(existingDepth01);

                    // Find the depth of the vertex relative to the water surface by subtracting vertex's depth from object beneath water's depth
                    float depthDiff = existingDepthLinear - i.projPos.w; // Conveniently, i.projPos.w is the depth of the water surface

                    // Find how the deep the water is as a perentage clamped between 0 and 1
                    float waterDepthDifference = 1.0 - saturate(depthDiff / _DepthMaxDistance);
                    float shoreDifference = 1.0 - saturate(depthDiff / _ShoreCutoff);


                    // Saturate clamps value to always be between 0 and 1 
                    float4 color = lerp(_DeepColor, _MainColor, waterDepthDifference); // Color water based on depth
                    color = lerp(color, _ShoreColor, shoreDifference); 
                    
                    
                    // Color the peaks of waves with CrestColor. Multiply height with CrestModifier in situations where height is very small
                    //float height = clamp(i.waveHeight, -_CrestModifier, _CrestModifier);
                    //color = lerp(color, _CrestColor, saturate(height * _CrestModifier));


                    // Fresnel Horizon water colour
                    // Fresnel effect is derived from this formula
                    float fresnelAmount = 1 - max(0.0, dot(i.viewNormal, i.viewDir)); // Max(0.0 ensures this is always positive)
                    fresnelAmount = pow(fresnelAmount, _FresnelRamp) * _FresnelIntensity; // Use FresnelRamp and Intensity to change how the fresnel works

                    // Dot product is used to determine if the vertex is above or below the camera. This is then used as the value to compare in step
                    // Step checks if the dot product is >=, or < the first value, which is 0. This allows me to disable the fresnel effect underwater
                    color = lerp(color, _HorizonColor, fresnelAmount * step(0.0, dot(i.viewNormal, i.viewDir)));
                    
                    // Underwater fog
                    float2 screenCoord = i.projPos.xy / i.projPos.w;
                    float3 backgroundColor = tex2D(_SceneColor, screenCoord).rgb;
                    float fogFactor = exp2(-_WaterFogDensity * depthDiff);
                    float3 fogColor = lerp(_WaterFogColor, backgroundColor, fogFactor);
                    //color.rgb = lerp(_WaterFogColor, backgroundColor, fogFactor);


                    // Code for reflection, refraction and specularity
                    float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                    float3 halfDir = normalize(lightDir + viewDir);

                    float spec = pow(max(0.0, dot(i.normal, halfDir)), 20.0) * _Specular;
                    float fresnel = pow(1.0 - max(0.0, dot(viewDir, i.normal)), 2.0) * _Specular;

                    // Refraction
                    float4 screenPos;
                    screenPos.xy = (i.vertex.xy / i.vertex.w) * 0.5 + 0.5;
                    screenPos.z = i.vertex.z / i.vertex.w;
                    float4 sceneColor = tex2D(_MainTex, screenPos.xy);

                    // Reflection and refraction
                    float3 reflectionDir = reflect(-i.viewDir, i.normal);
                    float3 refractionDir = refract(-i.viewDir, i.normal, 0.75);  // Refraction index for water is typically around 0.75
                    float4 reflectionColor = texCUBE(_CubeMap, reflectionDir) * _ReflectionStrength;
                    float4 refractionColor = texCUBE(_CubeMap, refractionDir) * _RefractionStrength;

                    tex *= color;
                    tex.rgb += spec;  // Adding specular component
                    tex.a *= _Transparency;


                    // Foam code
                    float factor = 1 - step(0.1, abs(existingDepthLinear - i.projPos.w));

                    // Get the uv coordinates of the vertex and displace them over time to produce foam that appears to slide in one direction
                    float2 noiseUV = float2(i.uv.x + _Time.y * _FoamDirection.x, i.uv.y + _Time.y * _FoamDirection.y);
                    // Get a sample of the foam texture.
                    float surfaceFoamSample = tex2D(_SurfaceNoise, noiseUV * _SurfaceNoise_ST);
                    
                    // Find the view space normal of the vertex
                    float3 existingNormal = tex2D(_CameraNormalsTexture, UNITY_PROJ_COORD(i.projPos));
                    float3 normalDot = saturate(dot(existingNormal, i.viewNormal));

                    float foamDistance = lerp(_FoamMaxDistance, _FoamMinDistance, normalDot);
                    // Calculate the different between depthDiff and foamDistance and clamping it to 0 and 1
                    float foamDepthDifference01 = saturate(depthDiff / foamDistance);
                    float surfaceNoiseCutoff = foamDepthDifference01 * _SurfaceNoiseCutoff;

                    // Step is used to check if the value should be ignored. if its not ignored, it will be rendered white to show foam
                    // However, smoothstep is used so we can blend the foam into the water. As values move from 0 to 0.5, it accelerates. From 0.5 to 1, it decelerates
                    // if the result is out of the bounds 0 and 1, it will return 0 or 1 just like step
                    float surfaceNoise = smoothstep(surfaceNoiseCutoff - SMOOTHSTEP_AA, surfaceNoiseCutoff + SMOOTHSTEP_AA, surfaceFoamSample);

                    float4 surfaceNoiseColor = _FoamColor;
                    surfaceNoiseColor.a *= surfaceNoise;

                    // Other foam code 
                    /*float surfaceIntersect = saturate(abs(depthDiff) / _IntersectionThreshold);
                    tex += _IntersectionColor * pow(1 - surfaceIntersect, 4) * _IntersectionPow;
                    return tex;*/
                    return alphaBlend(surfaceNoiseColor, tex);
                    
                }


                ENDCG
            }
        }

        //Fallback "FallBackWater"
}
