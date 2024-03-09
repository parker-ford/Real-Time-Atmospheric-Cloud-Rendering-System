using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ApplyRaycastParameters : MonoBehaviour
{
   const int WHITE_NOISE_OFFSET = 0x1;
    const int NROOKS_OFFSET = 0x2;
    const int UNIFORM_OFFSET = 0x4;
    const int MARCH_OFFSET = 0x8;

    public enum PixelOffsetType
    {
        WhiteNoise,
        Nrooks,
        Uniform,
        None
    }


    public Shader shader;

    [Header("Per pixel Offsets")]
    public PixelOffsetType pixelOffsetType = PixelOffsetType.WhiteNoise;
    [Range(0.0f, 200.0f)]
    public float pixelOffsetWeight = 0.0f;
    [Range(0.0f, 200.0f)]
    public float blueNosieOffsetWeight = 0.0f;

    [Header("Distance Offsets")]
    public int rayMarchSteps = 5;
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
        switch (pixelOffsetType)
        {
            case PixelOffsetType.WhiteNoise:
                rayCastBitmask |= WHITE_NOISE_OFFSET;
                break;
            case PixelOffsetType.Nrooks:
                rayCastBitmask |= NROOKS_OFFSET;
                break;
            case PixelOffsetType.Uniform:
                rayCastBitmask |= UNIFORM_OFFSET;
                break;
        }

        Shader.SetGlobalFloat("_RayMarchSteps", rayMarchSteps);
        Shader.SetGlobalInt("_RaycastBitMask", rayCastBitmask);
        Shader.SetGlobalFloat("_PixelOffsetWeight", pixelOffsetWeight);
        Shader.SetGlobalFloat("_RayMarchDistanceOffsetWeight", marchDistanceOffsetWeight);
        Shader.SetGlobalFloat("_BlueNoiseOffsetWeight", blueNosieOffsetWeight);
    
    }
}
