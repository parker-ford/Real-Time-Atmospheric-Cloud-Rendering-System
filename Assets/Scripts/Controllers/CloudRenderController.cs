using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CloudRenderController : MonoBehaviour
{
    public Shader shader;
    public Texture3D lowFrequencyCloudNosie;
    public bool resetShader = false;
    public float densityAbsorption = 0.5f;
    // Start is called before the first frame update
    void Start()
    {
        SetTextures();
    }

    // Update is called once per frame
    void Update()
    {
        if(resetShader){
            SetTextures();
            resetShader = false;
        }
        Shader.SetGlobalFloat("_DensityAbsorption", densityAbsorption);
    }
    void SetTextures(){
        Shader.SetGlobalTexture("_LowFrequencyCloudNoise", lowFrequencyCloudNosie);
    }
}
