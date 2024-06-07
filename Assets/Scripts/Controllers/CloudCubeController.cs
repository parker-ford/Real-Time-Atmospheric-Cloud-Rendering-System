using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CloudCubeController : MonoBehaviour
{
    public enum VolumeMode {
        UnlitVolume,
        SimpleLitVolume,
        LitVolume,
        NonHomogeneousVolume,
        CloudVolume
    }
    public VolumeMode volumeMode = VolumeMode.UnlitVolume;

    [Range(0.1f, 100.0f)]
    public float sphereRadius = 0.5f;
    public float absorptionCoefficient = 0.5f;
    public float scatteringCoefficient = 0.5f;
    public float density = 1.0f;
    [Range(-1.0f, 1.0f)]
    public float phaseAsymmetry = 0.0f;
    [Range(0.01f, 1.0f)]
    public float stepSize = 0.2f;
    [Range(0.0f, 1.0f)]
    public float shadowDensity = 0.5f;
    [Range(1, 10)]
    public int lightSteps = 5;
    public MyLight myLight;
    public float lightIntensity = 1.0f;
    public Texture3D denistyField; 
    public Texture3D lowFrequencyCloudNoise;
    public float noiseTiling = 1.0f;
    public float transmissionCutoff = 0.1f;
    public float cloudFalloff = 1.0f;
    public bool useAces = false;
    public float lightMarchDistance = 256;
    public Color extinctionColor = new Color(0.5f, 0.5f, 0.5f, 1.0f);
    void Start()
    {
        Shader.SetGlobalTexture("_DensityField", denistyField);
        Shader.SetGlobalTexture("_LowFrequencyCloudNoise", lowFrequencyCloudNoise);
    }

    // Update is called once per frame
    void Update()
    {
        Shader.SetGlobalInt("_VolumeMode", (int)volumeMode);
        Shader.SetGlobalFloat("_AbsorptionCoefficient", absorptionCoefficient);
        Shader.SetGlobalFloat("_ScatteringCoefficient", scatteringCoefficient);
        Shader.SetGlobalFloat("_Density", density);
        Shader.SetGlobalFloat("_StepSize", stepSize);
        Shader.SetGlobalVector("_LightDir", myLight.getLightDir());
        Shader.SetGlobalFloat("_SphereRadius", sphereRadius);
        Shader.SetGlobalFloat("_PhaseAsymmetry", phaseAsymmetry);
        Shader.SetGlobalFloat("_LightIntensity", lightIntensity);
        Shader.SetGlobalFloat("_NoiseTiling", noiseTiling);
        Shader.SetGlobalFloat("_TransmissionCutoff", transmissionCutoff);
        Shader.SetGlobalFloat("_CloudFalloff", cloudFalloff);
        // Shader.SetGlobalFloat("_LightStepSize", lightStepSize);
        Shader.SetGlobalInt("_LightSteps", lightSteps);
        Shader.SetGlobalInt("_UseACES", useAces ? 1 : 0);
        Shader.SetGlobalFloat("_LightMarchDistance", lightMarchDistance);
        Shader.SetGlobalFloat("_ShadowDensity", shadowDensity);
        Shader.SetGlobalColor("_ExtinctionColor", extinctionColor);
    }

}
