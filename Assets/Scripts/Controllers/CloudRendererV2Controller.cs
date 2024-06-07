using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CloudRendererV2Controller : MonoBehaviour
{
    [Header("Textures")]
    public Texture2D cloudMap;
    public float cloudMapTiling = 100;
    public Texture3D lowFrequencyCloudNoise;
    public float noiseTiling = 100;
    public Texture2D cloudHeightGradient;
    [Header("Atmosphere")]
    public float atmosphereLow = 1500;
    public float atmosphereHigh = 5000;

    [Header("Cloud Properties")]
    [Range(0.0f, 1.0f)]
    public float absorptionCoefficient = 0.5f;
    [Range(0.0f, 1.0f)]
    public float scatteringCoefficient = 1.0f;
    [Range(0.0f, 1.0f)]
    public float cloudDensity = 1.0f;
    [Range(0.0f, 10.0f)]
    public float shadowDensity = 1.0f;
    [Range(0.0f, 1.0f)]
    public float cloudType = 0f;
    public float cloudFalloff = 1.0f;
    public float stepSize = 20;
    [Range(1.00001f, 2.0f)]
    public float stepGrowthRate = 1.5f;


    [Header("Lighting")]
    public Light sun;
    public float lightIntensity = 1;
    public float lightStepSize = 10;
    public Color lightColor = new Color(1, 1, 1, 1);
    public Color ambientColor = new Color(1, 1, 1, 1);
    public float ambientStrength = 1.0f;
    public float multipleScatteringStrength = 1.0f;
    [Range(0, 10)]
    public int lightStepCount = 5;
    public float phaseAsymmetry = 0.0f;
    [Range(0.0f, 1.0f)]
    public float dualHGWeight = 0.0f;




    // [Range(0.0f, 1.0f)]
    // public float alphaThreshold = 0.1f;

    // Start is called before the first frame update
    void Start()
    {
        Debug.Log(sun.transform.forward);
        Shader.SetGlobalTexture("_CloudMap", cloudMap);
        Shader.SetGlobalTexture("_CloudHeightGradient", cloudHeightGradient);
        Shader.SetGlobalTexture("_LowFrequencyCloudNoise", lowFrequencyCloudNoise);
    }

    // Update is called once per frame
    void Update()
    {
        Shader.SetGlobalFloat("_AtmosphereLow", atmosphereLow);
        Shader.SetGlobalFloat("_AtmosphereHigh", atmosphereHigh);
        Shader.SetGlobalFloat("_NoiseTiling", noiseTiling);
        Shader.SetGlobalFloat("_LightIntensity", lightIntensity);
        Shader.SetGlobalFloat("_AbsorptionCoefficient", absorptionCoefficient);
        Shader.SetGlobalFloat("_ScatteringCoefficient", scatteringCoefficient);
        Shader.SetGlobalFloat("_CloudDensity", cloudDensity);
        Shader.SetGlobalFloat("_ShadowDensity", shadowDensity);
        Shader.SetGlobalFloat("_LightStepSize", lightStepSize);
        Shader.SetGlobalColor("_LightColor", lightColor);
        Shader.SetGlobalColor("_AmbientColor", ambientColor);
        Shader.SetGlobalFloat("_StepSize", stepSize);
        // Shader.SetGlobalFloat("_AlphaThreshold", alphaThreshold);
        Shader.SetGlobalInt("_LightStepCount", lightStepCount);
        Shader.SetGlobalVector("_LightDir", -sun.transform.forward);
        Shader.SetGlobalFloat("_CloudMapTiling", cloudMapTiling);
        Shader.SetGlobalFloat("_PhaseAsymmetry", phaseAsymmetry);
        Shader.SetGlobalFloat("_CloudFalloff", cloudFalloff);
        Shader.SetGlobalFloat("_DualHGWeight", dualHGWeight);
        Shader.SetGlobalFloat("_AmbientStrength", ambientStrength);
        Shader.SetGlobalFloat("_MultipleScatteringStrength", multipleScatteringStrength);
        Shader.SetGlobalFloat("_CloudType", cloudType);
        Shader.SetGlobalFloat("_StepGrowthRate", stepGrowthRate);
    }
}
