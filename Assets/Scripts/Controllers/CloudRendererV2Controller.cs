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
    public float lightAbsorption = 0.5f;
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
        Shader.SetGlobalFloat("_LightAbsorption", lightAbsorption);
    }
}
