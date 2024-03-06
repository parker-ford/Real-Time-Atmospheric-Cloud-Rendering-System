using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RaycastController : MonoBehaviour
{
    public GameObject sphere;
    public Shader shader;
    public int rayMarchSteps = 5;
    [Range(0.0f, 1.0f)]
    public float blendFactor = 0.0f;
    [Range(0.0f, 1.0f)]
    public float pixelOffsetWeight = 0.0f;
    public float distanceOffsetWeight = 0.0f;
    
    void Start()
    {
        Shader.SetGlobalTexture("_BlueNoiseTexture", UnityEditor.AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Textures/BlueNoise/BlueNoise.png"));
    }

    // Update is called once per frame
    void Update()
    {
        Shader.SetGlobalVector("_SphereCenter", sphere.transform.position);
        Shader.SetGlobalFloat("_SphereRadius", sphere.transform.localScale.y / 2.0f);
        Shader.SetGlobalFloat("_BlendFactor", blendFactor);
        Shader.SetGlobalFloat("_RayMarchSteps", rayMarchSteps);
    }
}
