using UnityEngine;
using UnityEditor;

namespace UnderwaterEffect
{
    public class LayerManager
    {
        [MenuItem("Tools/Create New Layer")]
        public static void CreateNewLayer()
        {
            // Name of the new layer
            string newLayerName = "NewLayer"; // Change this to your desired layer name

            // Check if the layer already exists
            bool layerExists = false;
            for (int i = 0; i < 32; i++)
            {
                if (i < 8) // Built-in layers
                {
                    if (i == LayerMask.NameToLayer(newLayerName))
                    {
                        layerExists = true;
                        break;
                    }
                }
                else // Custom layers
                {
                    string layer = LayerMask.LayerToName(i);
                    if (layer == newLayerName)
                    {
                        layerExists = true;
                        break;
                    }
                }
            }

            // If the layer doesn't exist, create it
            if (!layerExists)
            {
                // Find the existing layers
                SerializedObject tagsAndLayers = new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/TagManager.asset")[0]);
                SerializedProperty layersProperty = tagsAndLayers.FindProperty("layers");

                // Find an empty slot in layers
                for (int i = 8; i < 32; i++) // Start from 8, as the first 8 layers are reserved
                {
                    if (string.IsNullOrEmpty(layersProperty.GetArrayElementAtIndex(i).stringValue))
                    {
                        layersProperty.GetArrayElementAtIndex(i).stringValue = newLayerName;
                        tagsAndLayers.ApplyModifiedProperties();
                        Debug.Log($"Layer '{newLayerName}' created.");
                        return;
                    }
                }

                Debug.LogWarning("No empty slots available for new layer.");
            }
            else
            {
                Debug.LogWarning($"Layer '{newLayerName}' already exists.");
            }
        }
    }
}