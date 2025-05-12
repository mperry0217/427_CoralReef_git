## Overview

This package contains shader and C# code for Terresquall's Free Underwater Effect.

## Assets

### 1. **UnderwaterEffect Shader**

### 2. **WaterSurface Shader**

#### Features

1. `_MainTex ("Texture")`: This is the main texture used by the shader. The wave effect is based on this texture. You can use a flat color texture if you want a simple, uniform color for the water.

2. `_NormalMap`: This is a texture that modifies the normals of the object, making it look like there are small details on the surface without needing extra geometry. In this case, the normal map can make the water surface appear to have small waves or ripples.

3. `_MainColor ("Main Color")`: This is the main color of the water in shallow areas. It is applied to the texture. Changing this value will tint the water.

4. `_ShoreColor ("Shore Color")`: This is the color of the water when it is very shallow, such as long along the shoreline of a water body. The water will transition from this color to the main color based on depth.

5. `_DeepWaterColor ("Deep Water Color")`: This is the color of the water when it is deep. The water will transition from this color to the main color based on depth.

6. `_DepthColor ("Depth Color")`: If the 'Use Water Specific Depth' property is checked on the Camera's Underwater Effect component, this will override the colour that the water is tinted while the player is under the certain surface.

7. `_DepthMaximumDistance ("Depth Maximum Distance")`: This controls how deep the water must be before it will be coloured as Deep Water Color. Increasing this value will require water to have a greater depth before it is coloured as Deep Water.

8. `_ShoreCutoff ("Shore Cutoff")`: This controls the depth at which the Shore Color transitions into the Main Color.

9. `_HorizonWaterColor ("Horizon Water Color")`: This is the color the water surface will be when the player views it horizontally from the surface.

10. `_FresnelIntensity ("Fresnel Intensity")` and `_FresnelRamp ("Fresnel Ramp)`: These values control how the color of the water surface changes depending on the angle the player is looking at it.

11. `_CrestModifier ("Crest Modifier")` and `_CrestColor ("Crest Color")`: These values control how the wave crests (top of the wave) of the water surface will look like.

12. `_WaterFogColor ("Water Fog Color")` and `_WaterFogDensity ("Water Fog Density")`: These values control the color of the water fog (Fog that appears a distance away from the player underwater), and how far the player can see through it.

13. `_WaveSpeed ("Wave Speed")`: This controls the speed of all waves. A higher value will cause Waves to move faster across the water surface.

14. `_Wave1 ("Wave 1")`, `_Wave2("Wave 2")`, `_Wave3("Wave 3")`: This is a Vector with four components whose values represent the Waves. The X and Y values of the Waves determine the direction the waves travel. The Z value determines the Waves' amplitude. The W value represents the wavelength of the Wave.

15. `_NumberOfWavesToUse ("Number of Waves to Use")`: This is a keyword that controls how many waves will be affecting the Water Surface's mesh. A value of One will only use Wave 1, while a value of Two and Three will add the Waves 2 and 3, respectively. You can use this to control how complex you would like the waves to be.

16. `_SurfaceNoise ("Surface Noise")`: This represents the noise texture used in calculating the foam. You can also use the Tiling values of Surface Noise to change the tiling of the Foam.

17. `_FoamTex ("Foam Texture")`: This represents the foam texture.

18. `_FoamDirection ("Foam Direction")`: This vector field  represents the direction that the foam travels in. Only the X and Y values are used to determine the direction of the foam; The Z and W values do not affect the Foam Direction.

19. `_FoamIntensity ("Foam Intensity")`: This defines the intensity of the foam. It has a range of 0.0 to 1.0, with a default value of 0.5. Modifying this value will affect how pronounced the foam appears in the rendered scene. ***[Incomplete]***

20. `_FoamMaxDistance("Foam Max Distance")`and `_FoamMinDistance("Foam Min Distance")`: These values are used to control the size of the foam based on the view space normal of vertexes where foam is to be displayed. Changing these values will affect the size of foam around an object.

21. `_FoamColour ("Foam Colour")`: This controls the color of the foam around objects.

22. `_Transparency ("Transparency")`: This controls the transparency of the water.

23. `_Specular ("Specular")`: This controls the shininess of the water, affecting how the light reflects off the surface.

24. `_ReflectionStrength ("Reflection Strength")`: This controls the intensity of the reflected environment on the water surface.

25. `_RefractionStrength ("Refraction Strength")`: This controls the amount of light distortion that occurs when light passes through the water.

### 3. **CameraUnderWaterEffect Script**

#### Features

1. `useWaterSpecificDepth`: This is a bool that determines whether all underwater surfaces use the camera's Depth Color, or override it with the water surface's Depth Color (e.g. Lava having a red depth color instead).

2. `waterLayers`: This is a LayerMask that determines what is considered water by the script. It is used when the script checks whether the camera is underwater.

3. `shader`: This is the shader that's used to create the camera's underwater effect.

4. `depthColor`: This Color value is used to tint the camera's view when it's underwater.

5. `depthStart` and `depthEnd`: These values are used to determine the range of depth in which the underwater effect is applied.

6. `depthLayers`: This is a LayerMask that's used to determine what objects should have the underwater depth effect applied to them.

7. `pixelOffset`: This value determines the pixel offset for the noise effect applied when underwater.

8. `noiseScale`: This value determines the scale of the noise effect applied when underwater.

9. `noiseFrequency`: This value determines the frequency of the noise effect applied when underwater.

10. `noiseSpeed`: This value determines the speed of the noise effect applied when underwater.

### 4. **WaveDisplacement Script**

#### Features

1. `dimension`: This is the size of the square mesh that will be generated. The number of vertices along each side of the mesh is dimension + 1.
  
2. `uvScale`: This value is used to scale the UV coordinates of the mesh.

3. `waveStrength`: This is a multiplier that is applied to the displacement of the vertices, controlling the overall strength of the wave effect.

4. `Octave`: Used to control various aspects of the wave effect.
   - `speed`: This determines the speed of the waves.
   - `scale`: This determines the scale of the waves.
   - `height`: This determines the height of the waves.
   - `alternate`: This determines whether to alternate the wave pattern.

5. `octaves`: This is an array of Octave structures, which are used to determine the speed, scale, height, and alternation of the waves.

## Prerequisites

To use these shaders, you need:

- Unity 2019.4 or later

Installing the URP package is recommended but not required.

## Attributions

1. [Texture pack for the WaterSurface.](https://www.texturecan.com/details/282/#google_vignette)