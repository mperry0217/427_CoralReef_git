using UnityEngine;

namespace UnderwaterEffect
{
    [RequireComponent(typeof(MeshFilter))]
    public class WaveDisplacement : MonoBehaviour
    {
        public int dimension = 10;
        public Octave[] octaves;
        public float uvScale = 1f;
        public float waveStrength = 1.0f;   //The higher the wave strength the stronger the waves

        private MeshFilter meshFilter;
        private Mesh mesh;


        private void Start()
        {
            // Generate a new Mesh
            mesh = new Mesh();
            mesh.name = gameObject.name;

            // Set up gameObjects with MeshFilter
            meshFilter = gameObject.GetComponent<MeshFilter>();
            meshFilter.mesh = mesh;

            CreateMesh();
        }

        private void CreateMesh()
        {
            Vector3[] vertices = new Vector3[(dimension + 1) * (dimension + 1)];
            Vector3[] normals = new Vector3[vertices.Length];
            Vector2[] uvs = new Vector2[vertices.Length];
            int[] triangles = new int[dimension * dimension * 6];

            float halfDim = dimension / 2f;

            for (int x = 0; x <= dimension; x++)
            {
                for (int z = 0; z <= dimension; z++)
                {
                    vertices[x * (dimension + 1) + z] = new Vector3(x - halfDim, 0f, z - halfDim);
                    normals[x * (dimension + 1) + z] = Vector3.up;
                    uvs[x * (dimension + 1) + z] = new Vector2((float)x / dimension * uvScale, (float)z / dimension * uvScale);
                }
            }

            for (int ti = 0, vi = 0, y = 0; y < dimension; y++, vi++)
            {
                for (int x = 0; x < dimension; x++, ti += 6, vi++)
                {
                    triangles[ti] = vi;
                    triangles[ti + 3] = triangles[ti + 1] = vi + dimension + 1;
                    triangles[ti + 4] = triangles[ti + 2] = vi + 1;
                    triangles[ti + 5] = vi + dimension + 2;
                }
            }

            mesh.vertices = vertices;
            mesh.normals = normals;
            mesh.uv = uvs;
            mesh.triangles = triangles;
            mesh.RecalculateBounds();
        }


        private void Update()
        {
            Vector3[] vertices = mesh.vertices;
            for (int i = 0; i < vertices.Length; i++)
            {
                float y = 0f;
                for (int j = 0; j < octaves.Length; j++)
                {
                    if (octaves[j].alternate)
                    {
                        float perl = Mathf.PerlinNoise((vertices[i].x * octaves[j].scale.x) / dimension, (vertices[i].z * octaves[j].scale.y) / dimension) * Mathf.PI * 2f;
                        y += Mathf.Cos(perl + octaves[j].speed.magnitude * Time.time) * octaves[j].height;
                    }
                    else
                    {
                        float perl = Mathf.PerlinNoise((vertices[i].x * octaves[j].scale.x + Time.time * octaves[j].speed.x) / dimension, (vertices[i].z * octaves[j].scale.y + Time.time * octaves[j].speed.y) / dimension) - 0.5f;
                        y += perl * octaves[j].height;
                    }
                }

                vertices[i].y = y * waveStrength; // Multiply y with waveStrength here
            }

            mesh.vertices = vertices;
            mesh.RecalculateNormals();
        }

        [System.Serializable]
        public struct Octave
        {
            public Vector2 speed;
            public Vector2 scale;
            public float height;
            public bool alternate;
        }
    }
}

