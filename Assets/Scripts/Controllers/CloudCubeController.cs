using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CloudCubeController : MonoBehaviour
{
    public float absorptionCoefficient = 0.5f;
    public float stepSize = 0.2f;
    public Vector3 lightDir = new Vector3(0, 1, 0);
    void Start()
    {
    }

    // Update is called once per frame
    void Update()
    {
        Shader.SetGlobalFloat("_AbsorptionCoefficient", absorptionCoefficient);
        Shader.SetGlobalFloat("_StepSize", stepSize);
        Shader.SetGlobalVector("_LightDir", lightDir);
    }

}
