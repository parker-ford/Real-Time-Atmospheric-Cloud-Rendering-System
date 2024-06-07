using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CloudMapController : MonoBehaviour
{
    public ComputeShader shader;
    public float perlinFreqency = 4f;
    public float worleyFrequency = 4f;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Shader.SetGlobalFloat("_PerlinFrequency", perlinFreqency);
        Shader.SetGlobalFloat("_WorleyFrequency", worleyFrequency);
        // shader.SetFloat("_PerlinFrequency", perlinFreqency);
        // shader.SetFloat("_WorleyFrequency", worleyFrequency);
    }
}
