using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace UnderwaterEffect
{
    public class NormalsReplacementShader : MonoBehaviour
    {
        // This script allows us to get the normals buffer without having it be combined with the depth buffer
        [SerializeField]
        Shader normalsShader;

        private RenderTexture renderTexture, colourTexture, depthTexture;
        private Camera normalsCamera;

        private void Start()
        {
            Camera thisCamera = GetComponent<Camera>();

            // Create a render texture matching the main camera's current dimensions.
            renderTexture = new RenderTexture(thisCamera.pixelWidth, thisCamera.pixelHeight, 24);
            colourTexture = new RenderTexture(thisCamera.pixelWidth, thisCamera.pixelHeight, 0, RenderTextureFormat.Default);
            depthTexture = new RenderTexture(thisCamera.pixelWidth, thisCamera.pixelHeight, 16, RenderTextureFormat.Depth);
            // Surface the render texture as a global variable, available to all shaders.
            Shader.SetGlobalTexture("_CameraNormalsTexture", renderTexture);

            //thisCamera.targetTexture = colourTexture;
            // Setup a copy of the camera to render the scene using the normals shader.
            GameObject copy = new GameObject("Normals camera");

            // Add a camera component to the new gameObject and set it as the normal's camera
            normalsCamera = copy.AddComponent<Camera>();

            // Copy the parent's camera settings to the child's camera
            normalsCamera.CopyFrom(thisCamera);
            normalsCamera.transform.SetParent(transform);
            normalsCamera.targetTexture = renderTexture;

            //normalsCamera.SetTargetBuffers(colourTexture.colorBuffer, depthTexture.depthBuffer);
            // This causes the camera to render using a specific shader, and then output a texture with the view space normals of the objects
            normalsCamera.SetReplacementShader(normalsShader, "RenderType");
            normalsCamera.depth = thisCamera.depth - 1; // This ensures the main camera will render over this camera
        }

        private void OnApplicationQuit()
        {
            //RenderTexture.ReleaseTemporary(colourTexture);
        }
    }
}

