Shader "Unlit/FallBackWater"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _WaterColor("Water Color", Color) = (1,1,1,1)
        _HorizonColor("Horizon Water Color", Color) = (0, 0, 1, 1)

        [Header(Waves)] // If you'd like to have more waves, simply add another wave property and calculate another gertsner wave
        _WaveSpeed("Wave Speed", Float) = 9.8
        _Wave1("Wave 1 (dir, steepness, wavelength)", Vector) = (1,0,0.5,10) // X and Y is used as the direction of our waves, Z is the steepness and W is wavelength
        _Wave2("Wave 2", Vector) = (1,0,0.5,10)
        _Wave3("Wave 3", Vector) = (1,0,0.5,10)
        [KeywordEnum(One, Two, Three)] Waves("Number of Waves to Use", Float) = 0.0

        [Header(Color)]
        _FresnelIntensity("Fresnel Intensity", Range(0,10)) = 1
        _FresnelRamp("Fresnel Ramp", Range(0,10)) = 1
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent-200" }
        Cull Off

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0  // added target 3.0 to enable the necessary shader features
            #pragma shader_feature_vertex WAVES_ONE WAVES_TWO WAVES_THREE

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
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
            float _WaveSpeed;
            float4 _Wave1, _Wave2, _Wave3;
            float4 _WaterColor, _HorizonColor;
            float _FresnelIntensity, _FresnelRamp;

            float4 alphaBlend(float4 top, float4 bottom) // This will be used to blend the colours of the foam without making them brighter
            {
                float3 color = (top.rgb * top.a) + (bottom.rgb * (1 - top.a));
                float alpha = top.a + bottom.a * (1 - top.a);

                return float4(color, alpha);
            }

            float3 GerstnerWave(float4 wave, float3 p, inout float3 tangent, inout float3 binormal)
            {
                float steepness = wave.z; // Use the z value of wave to control wave steepness
                float wavelength = wave.w; // Use the w value of wave to control wavelength
                float k = 2 * UNITY_PI / wavelength;
                float c = sqrt(_WaveSpeed / k); // Waves dont have an arbitrary speed, its instead related to the wave number and gravity of earth
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
                vert += GerstnerWave(_Wave1, vert, tangent, binormal);
                #if defined(WAVES_TWO) 
                    vert += GerstnerWave(_Wave2, vert, tangent, binormal);
                #endif

                #if defined(WAVES_THREE) 
                    vert += GerstnerWave(_Wave2, vert, tangent, binormal);
                    vert += GerstnerWave(_Wave3, vert, tangent, binormal);
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

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = _WaterColor;
                float fresnelAmount = 1 - max(0.0, dot(i.viewNormal, i.viewDir)); // Max(0.0 ensures this is always positive)
                fresnelAmount = pow(fresnelAmount, _FresnelRamp) * _FresnelIntensity; // Use FresnelRamp and Intensity to change how the fresnel works

                // Dot product is used to determine if the vertex is above or below the camera. This is then used as the value to compare in step
                // Step checks if the dot product is >=, or < the first value, which is 0. This allows me to disable the fresnel effect underwater
                col = lerp(col, _HorizonColor, fresnelAmount * step(0.0, dot(i.viewNormal, i.viewDir)));
                return col;
            }
            ENDCG
        }
    }
}
