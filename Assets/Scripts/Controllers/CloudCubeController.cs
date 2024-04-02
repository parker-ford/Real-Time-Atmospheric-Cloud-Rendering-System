using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CloudCubeController : MonoBehaviour
{
    public enum VolumeMode {
        UnlitVolume,
        SimpleLitVolume,
        LitVolume,
    }
    public VolumeMode volumeMode = VolumeMode.UnlitVolume;

    [Range(0.1f, 10.0f)]
    public float sphereRadius = 0.5f;
    public float absorptionCoefficient = 0.5f;
    public float scatteringCoefficient = 0.5f;
    public float density = 1.0f;
    [Range(0.01f, 1.0f)]
    public float stepSize = 0.2f;
    public Vector3 lightDir = new Vector3(0, 1, 0);
    void Start()
    {
    }

    // Update is called once per frame
    void Update()
    {
        Shader.SetGlobalInt("_VolumeMode", (int)volumeMode);
        Shader.SetGlobalFloat("_AbsorptionCoefficient", absorptionCoefficient);
        Shader.SetGlobalFloat("_ScatteringCoefficient", scatteringCoefficient);
        Shader.SetGlobalFloat("_Density", density);
        Shader.SetGlobalFloat("_StepSize", stepSize);
        Shader.SetGlobalVector("_LightDir", lightDir);
        Shader.SetGlobalFloat("_SphereRadius", sphereRadius);
    }

}
