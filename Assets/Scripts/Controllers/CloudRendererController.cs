using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CloudRendererController : MonoBehaviour
{
    public Texture3D lowFrequencyCloudNoise;
    public Texture2D heightDensityGradient;
    public float densityAbsorption = 0.5f;
    public bool resetShader = false;

    public enum NoiseTilingSettings{
        _128 = 128,
        _256 = 256,
        _512 = 512,
        _1024 = 1024,
        _2048 = 2048,
        _4096 = 4096,
        _8192 = 8192,
        _16384 = 16384
    };
    public NoiseTilingSettings noiseTilingSettings = NoiseTilingSettings._4096;

    public bool flipTransmittance = false;

    public enum CloudCoverageMode{
        None = 0,
        Himilayas = 1,
        SwissAlps = 2,
        Threshold = 3,
    }
    public CloudCoverageMode cloudCoverageMode = CloudCoverageMode.Himilayas;
    public enum BaseCloudMode{
        SingleChannel = 0,
        AllChannel = 1,
    }
    public BaseCloudMode baseCloudMode = BaseCloudMode.SingleChannel;

    [Range(0.0f, 1.0f)]
    public float cloudCoverage = 1.0f;
    public float atmosphereLow = 1500.0f;
    public float atmosphereHigh = 5000.0f;

    // Start is called before the first frame update
    void Start()
    {
        ResetShader();
    }

    void ResetShader(){
        Shader.SetGlobalTexture("_LowFrequencyCloudNoise", lowFrequencyCloudNoise);
        Shader.SetGlobalTexture("_HeightDensityGradient", heightDensityGradient);
    }

    // Update is called once per frame
    void Update()
    {
        if(resetShader){
            ResetShader();
            resetShader = false;
        }
        Shader.SetGlobalFloat("_DensityAbsorption", densityAbsorption);
        Shader.SetGlobalFloat("_NoiseTiling", (float)noiseTilingSettings);
        Shader.SetGlobalInt("_FlipTransmittance", flipTransmittance ? 1 : 0);
        Shader.SetGlobalInt("_CloudCoverageMode", (int)cloudCoverageMode);
        Shader.SetGlobalFloat("_CloudCoverage", cloudCoverage);
        Shader.SetGlobalFloat("_AtmosphereLow", atmosphereLow);
        Shader.SetGlobalFloat("_AtmosphereHigh", atmosphereHigh);
        Shader.SetGlobalInt("_BaseCloudMode", (int)baseCloudMode);
    }


}
