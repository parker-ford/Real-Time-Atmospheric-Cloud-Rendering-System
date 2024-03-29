using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CloudRendererV2Controller : MonoBehaviour
{
    public Texture2D cloudMap;
    public Texture2D cloudHeightGradient;
    public float atmosphereLow = 1500;
    public float atmosphereHigh = 5000;
    public float noiseTiling = 100;
    public float lightIntensity = 1;

    [Range(0.0f, 3.0f)]
    public float absorptionCoefficient = 0.5f;
    [Range(0.0f, 3.0f)]
    public float scatteringCoefficient = 1.0f;
    [Range(0.0f, 10.0f)]
    public float cloudDensity = 1.0f;
    [Range(0.0f, 10.0f)]
    public float shadowDensity = 1.0f;
    public float lightStepSize = 10;
    public float stepSize = 20;

    public Color cloudColor = new Color(1, 1, 1, 1);
    public Color extinctionColor = new Color(1, 1, 1, 1);
    public Color lightColor = new Color(1, 1, 1, 1);
    [Range(0, 10)]
    public int lightStepCount = 5;

    public bool useHeightGradient = true;

    public float alphaThreshold = 0.1f;

    // Start is called before the first frame update
    void Start()
    {
        Shader.SetGlobalTexture("_CloudMap", cloudMap);
        Shader.SetGlobalTexture("_CloudHeightGradient", cloudHeightGradient);
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
        Shader.SetGlobalColor("_CloudColor", cloudColor);
        Shader.SetGlobalColor("_ExtinctionColor", extinctionColor);
        Shader.SetGlobalColor("_LightColor", lightColor);
        Shader.SetGlobalFloat("_StepSize", stepSize);
        Shader.SetGlobalInt("_UseHeightGradient", useHeightGradient ? 1 : 0);
        Shader.SetGlobalFloat("_AlphaThreshold", alphaThreshold);
        Shader.SetGlobalInt("_LightStepCount", lightStepCount);
    }
}
