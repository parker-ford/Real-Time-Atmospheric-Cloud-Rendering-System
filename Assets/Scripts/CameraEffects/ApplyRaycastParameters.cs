using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ApplyRaycastParameters : MonoBehaviour
{
   const int WHITE_NOISE_OFFSET = 0x1;
    const int NROOKS_OFFSET = 0x2;
    const int UNIFORM_OFFSET = 0x4;
    const int MARCH_OFFSET = 0x8;

    public Shader shader;
    public int rayMarchSteps = 5;
    [Range(0.0f, 1.0f)]
    public float blendFactor = 0.0f;
    [Range(0.0f, 1.0f)]
    public float pixelOffsetWeight = 0.0f;
    [Range(0.0f, 5.0f)]
    public float marchDistanceOffsetWeight = 0.0f;
    public bool useRayMarchOffset = false;
    private int rayCastBitmask = 0;
    
    void Start()
    {
        Shader.SetGlobalTexture("_BlueNoiseTexture", UnityEditor.AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Textures/BlueNoise/BlueNoise.png"));
    }

    // Update is called once per frame
    void Update()
    {
        rayCastBitmask = 0;
        if (useRayMarchOffset)
        {
            rayCastBitmask |= MARCH_OFFSET;
        }

        Shader.SetGlobalFloat("_BlendFactor", blendFactor);
        Shader.SetGlobalFloat("_RayMarchSteps", rayMarchSteps);
        Shader.SetGlobalInt("_RaycastBitMask", rayCastBitmask);
        Shader.SetGlobalFloat("_PixelOffsetWeight", pixelOffsetWeight);
        Shader.SetGlobalFloat("_RayMarchDistanceOffsetWeight", marchDistanceOffsetWeight);
    }
}
