using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CloudRaymarchController : MonoBehaviour
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

    public enum Res {
        FullResolution = 0,
        HalfResolution,
        QuarterResolution
    };

    public enum TextureDebug {
        Composite,
        Albedo,
        Mask,
        Depth
    }
    public enum ToneMapper {
        RGBClamp,
        dubugHDR,
        schlick,
        ward,
        reinhard,
        reinhardExtended,
        filmic,
        uchimura,
        narkowiczACES,
        hillACES
    }

    public enum LightingDebug {
        LightingOff,
        LightingOn,
    }

    public enum DensityDebug {
        DimensionalProfile,
        NoiseEroded,
        cloudMap,
        cloudTypeMap,
    }

    public enum TypeDebug {
        GlobalCloudType,
        CloudTypeMap,
    }


    [Header("Shaders")]
    public ComputeShader renderCloudsCompute;
    public ComputeShader cloudAccumulatorCompute;
    public Shader cloudCompositerShader;

    [Header("Resolution")]
    public Res resolutionScale;

    [Header("Debug")]
    public TextureDebug debugTexture;
    public DensityDebug debugDensity;
    public LightingDebug debugLighting;
    public TypeDebug debugType;

    [Header("Raymarch Parameters")]
    [Range(0, 2000)]
    public int rayMarchSteps = 5;
    public float stepSize = 5f;
    [NonSerialized]
    public PixelOffsetType pixelOffsetType = PixelOffsetType.Nrooks;
    [NonSerialized]
    public float pixelOffsetWeight = 1.0f;
    [NonSerialized]
    public float blueNosieOffsetWeight = 1.0f;
    private int rayCastBitmask = 0;

    [Header("Temporal Anti-Aliasing")]
    [Range(1, 8)]
    public int numSuperSamples;
    private int lastSamples;
    private int maxNumSamples = 8;
    private RenderTexture[] cloudAlbedoFullBuffers;
    private RenderTexture[] cloudAlbedoHalfBuffers;
    private RenderTexture[] cloudAlbedoQuarterBuffers;
    private RenderTexture[] cloudMaskFullBuffers;
    private RenderTexture[] cloudMaskHalfBuffers;
    private RenderTexture[] cloudMaskQuarterBuffers;
    private RenderTexture[] cloudDepthFullBuffers;
    private RenderTexture[] cloudDepthHalfBuffers;
    private RenderTexture[] cloudDepthQuarterBuffers;

    private int frame = 0; 

    [Header("Atmosphere Parameters")]
    public float lowerRadius = 100f;
    public float upperRadius = 500f;

    [Header("Cloud Map Parameters")]
    public Texture2D cloudMap;
    public float cloudMapTiling = 100f;
    public Vector2 cloudMapOffset = new Vector2(0, 0);
    [Range(-1.5f, 0.99f)]
    public float cloudCoverage = 0.5f;

    [Header("Cloud Type Parameters")]
    public Texture2D cloudHeightGradient;
    public Texture2D cloudTypeMap;
    [Range(0.0f, 1.0f)]
    public float globalCloudType = 0.0f;
    public float cloudTypeMapTiling = 100f;
    [Range(0.0f, 1.0f)]
    public float cloudTypeModifier = 0.0f;

    [Header("Cloud Noise Parameters")]
    public Texture3D billowyNoise;
    public Texture3D wispyNoise;
    public float billowyNoiseTiling = 100f;
    public float wispyNosieTiling = 100f;

    [Header("Cloud Paramters")]
    [Range(0.0f, 1.0f)]
    public float cloudDensity = 0.5f;
    [Range(0.0f, 1.0f)]
    public float scatteringCoefficient = 0.5f;
    [Range(0.0f, 1.0f)]
    public float absorptoinCoefficient = 0.5f;
    [Range(0.0f, 1.0f)]
    public float shadowDensity = 1.0f;

    [Header("Wind")]
    public Vector3 windDirection;
    public float windSpeed = 1;
    public float windStretchFactor = 0;



    [Header("Direct Lighting")]
    public float lightIntensity = 1;
    public Color lightColor;
    public float lightStepSize = 10;
    public int lightMarchSteps = 10;
    [Range(0.0f, 1.0f)]
    public float powderWeight = 0.0f;
    Light sun;

    [Header("Ambient Lighting")]
    [Range(0.0f, 1.0f)]
    public float ambientStrength = 1.0f;
    public Color ambientColor;

    [Header("Multiple Scattering")]
    [Range(0.0f, 1.0f)]
    public float multipleScatteringStrength = 1.0f;
    public int multipleScatteringOctaves = 4;
    public float multipleScatteringAttenuation = 0.5f;
    public float multipleScatteringContribution = 0.5f;
    public float multipleScatteringEccentricity = 0.5f;


    [Header("Light Phase")]
    [Range(0.0f, 1.0f)]
    public float phaseWeight = 0.7f;
    public float hgAsymmetry = 0.2f;
    public float draineAsymmetry = 0.5f;
    public float draineAlpha = 0.5f;

    [Header("Depth Fog")]
    public float depthFogDensity = 0.0f;
    public float depthFogOffset = 0.0f;


    private RenderTexture cloudAlbedoFullTex;
    private RenderTexture cloudAlbedoHalfTex;
    private RenderTexture cloudAlbedoQuarterTex;
    private RenderTexture cloudMaskFullTex;
    private RenderTexture cloudMaskHalfTex;
    private RenderTexture cloudMaskQuarterTex;
    private RenderTexture cloudDepthFullTex;
    private RenderTexture cloudDepthHalfTex;
    private RenderTexture cloudDepthQuarterTex;

    private Material cloudCompositer;

    // Start is called before the first frame update
    void Start()
    {
        cloudAlbedoFullBuffers = new RenderTexture[maxNumSamples];
        cloudAlbedoHalfBuffers = new RenderTexture[maxNumSamples];
        cloudAlbedoQuarterBuffers = new RenderTexture[maxNumSamples];

        cloudMaskFullBuffers = new RenderTexture[maxNumSamples];
        cloudMaskHalfBuffers = new RenderTexture[maxNumSamples];
        cloudMaskQuarterBuffers = new RenderTexture[maxNumSamples];

        cloudDepthFullBuffers = new RenderTexture[maxNumSamples];
        cloudDepthHalfBuffers = new RenderTexture[maxNumSamples];
        cloudDepthQuarterBuffers = new RenderTexture[maxNumSamples];

        for(int i = 0; i < maxNumSamples; i++){
            cloudAlbedoFullBuffers[i] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB64, RenderTextureReadWrite.Linear);
            cloudAlbedoFullBuffers[i].enableRandomWrite = true;
            cloudAlbedoFullBuffers[i].Create();

            cloudAlbedoHalfBuffers[i] = new RenderTexture(Mathf.CeilToInt(Screen.width / 2), Mathf.CeilToInt(Screen.height / 2), 0, RenderTextureFormat.ARGB64, RenderTextureReadWrite.Linear);
            cloudAlbedoHalfBuffers[i].enableRandomWrite = true;
            cloudAlbedoHalfBuffers[i].Create();

            cloudAlbedoQuarterBuffers[i] = new RenderTexture(Mathf.CeilToInt(Screen.width / 4), Mathf.CeilToInt(Screen.height / 4), 0, RenderTextureFormat.ARGB64, RenderTextureReadWrite.Linear);
            cloudAlbedoQuarterBuffers[i].enableRandomWrite = true;
            cloudAlbedoQuarterBuffers[i].Create();

            cloudMaskFullBuffers[i] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
            cloudMaskFullBuffers[i].enableRandomWrite = true;
            cloudMaskFullBuffers[i].Create();

            cloudMaskHalfBuffers[i] = new RenderTexture(Mathf.CeilToInt(Screen.width / 2), Mathf.CeilToInt(Screen.height / 2), 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
            cloudMaskHalfBuffers[i].enableRandomWrite = true;
            cloudMaskHalfBuffers[i].Create();

            cloudMaskQuarterBuffers[i] = new RenderTexture(Mathf.CeilToInt(Screen.width / 4), Mathf.CeilToInt(Screen.height / 4), 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
            cloudMaskQuarterBuffers[i].enableRandomWrite = true;
            cloudMaskQuarterBuffers[i].Create();

            cloudDepthFullBuffers[i] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
            cloudDepthFullBuffers[i].enableRandomWrite = true;
            cloudDepthFullBuffers[i].Create();

            cloudDepthHalfBuffers[i] = new RenderTexture(Mathf.CeilToInt(Screen.width / 2), Mathf.CeilToInt(Screen.height / 2), 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
            cloudDepthHalfBuffers[i].enableRandomWrite = true;
            cloudDepthHalfBuffers[i].Create();

            cloudDepthQuarterBuffers[i] = new RenderTexture(Mathf.CeilToInt(Screen.width / 4), Mathf.CeilToInt(Screen.height / 4), 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
            cloudDepthQuarterBuffers[i].enableRandomWrite = true;
            cloudDepthQuarterBuffers[i].Create();
        }

        lastSamples = numSuperSamples;


        cloudAlbedoFullTex = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB64, RenderTextureReadWrite.Linear);
        cloudAlbedoFullTex.enableRandomWrite = true;
        cloudAlbedoFullTex.Create();

        cloudAlbedoHalfTex = new RenderTexture(Mathf.CeilToInt(Screen.width / 2), Mathf.CeilToInt(Screen.height / 2), 0, RenderTextureFormat.ARGB64, RenderTextureReadWrite.Linear);
        cloudAlbedoHalfTex.enableRandomWrite = true;
        cloudAlbedoHalfTex.Create();

        cloudAlbedoQuarterTex = new RenderTexture(Mathf.CeilToInt(Screen.width / 4), Mathf.CeilToInt(Screen.height / 4), 0, RenderTextureFormat.ARGB64, RenderTextureReadWrite.Linear);
        cloudAlbedoQuarterTex.enableRandomWrite = true;
        cloudAlbedoQuarterTex.Create();

        cloudMaskFullTex = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        cloudMaskFullTex.enableRandomWrite = true;
        cloudMaskFullTex.Create();

        cloudMaskHalfTex = new RenderTexture(Mathf.CeilToInt(Screen.width / 2), Mathf.CeilToInt(Screen.height / 2), 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        cloudMaskHalfTex.enableRandomWrite = true;
        cloudMaskHalfTex.Create();

        cloudMaskQuarterTex = new RenderTexture(Mathf.CeilToInt(Screen.width / 4), Mathf.CeilToInt(Screen.height / 4), 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        cloudMaskQuarterTex.enableRandomWrite = true;
        cloudMaskQuarterTex.Create();

        cloudDepthFullTex = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        cloudDepthFullTex.enableRandomWrite = true;
        cloudDepthFullTex.Create();

        cloudDepthHalfTex = new RenderTexture(Mathf.CeilToInt(Screen.width / 2), Mathf.CeilToInt(Screen.height / 2), 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        cloudDepthHalfTex.enableRandomWrite = true;
        cloudDepthHalfTex.Create();

        cloudDepthQuarterTex = new RenderTexture(Mathf.CeilToInt(Screen.width / 4), Mathf.CeilToInt(Screen.height / 4), 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        cloudDepthQuarterTex.enableRandomWrite = true;
        cloudDepthQuarterTex.Create();

        cloudCompositer = new Material(cloudCompositerShader);

        renderCloudsCompute.SetInt("_BufferWidth", Screen.width);
        renderCloudsCompute.SetInt("_BufferHeight", Screen.height);
        renderCloudsCompute.SetTexture(0, "pixels", cloudAlbedoFullTex);

        renderCloudsCompute.SetTexture(0, "_BlueNoiseTextureCompute", UnityEditor.AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Textures/BlueNoise/BlueNoise.png"));
        renderCloudsCompute.SetTexture(0, "_BlueNoiseTextureCompute0", UnityEditor.AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Textures/BlueNoise/BlueNoise0.png"));
        renderCloudsCompute.SetTexture(0, "_BlueNoiseTextureCompute1", UnityEditor.AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Textures/BlueNoise/BlueNoise1.png"));
        renderCloudsCompute.SetTexture(0, "_BlueNoiseTextureCompute2", UnityEditor.AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Textures/BlueNoise/BlueNoise2.png"));

        renderCloudsCompute.SetTexture(0, "_CloudMap", cloudMap);
        renderCloudsCompute.SetTexture(0, "_CloudHeightGradient", cloudHeightGradient);
        renderCloudsCompute.SetTexture(0, "_CloudTypeMap", cloudTypeMap);

        renderCloudsCompute.SetTexture(0, "_BillowyNoise", billowyNoise);
        renderCloudsCompute.SetTexture(0, "_WispyNoise", wispyNoise);

        Shader.SetGlobalInt("_NumSuperSamples", 1);
        Shader.SetGlobalFloat("_CameraFOV", Camera.main.fieldOfView);
        Shader.SetGlobalFloat("_CameraAspect", Camera.main.aspect);

        sun = GameObject.FindObjectOfType<Light>();


    }

    // Update is called once per frame
    void Update()
    {

    }


    void UpdateCloudParameters(){
        rayCastBitmask = 0;
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

        renderCloudsCompute.SetFloat("_RayMarchSteps", rayMarchSteps);
        renderCloudsCompute.SetInt("_RaycastBitMask", rayCastBitmask);
        renderCloudsCompute.SetFloat("_PixelOffsetWeight", pixelOffsetWeight);
        renderCloudsCompute.SetFloat("_BlueNoiseOffsetWeight", blueNosieOffsetWeight);

        renderCloudsCompute.SetFloat("_CloudMapTiling", cloudMapTiling);
        renderCloudsCompute.SetVector("_CloudMapOffset", cloudMapOffset);
        renderCloudsCompute.SetFloat("_BillowyNoiseTiling", billowyNoiseTiling);
        renderCloudsCompute.SetFloat("_WispyNoiseTiling", wispyNosieTiling);

        renderCloudsCompute.SetFloat("_AtmosphereLow", lowerRadius);
        renderCloudsCompute.SetFloat("_AtmosphereHigh", upperRadius);

        renderCloudsCompute.SetFloat("_CloudCoverage", cloudCoverage);

        renderCloudsCompute.SetFloat("_GlobalCloudType", globalCloudType);
        renderCloudsCompute.SetInt("_DebugType", (int)debugType);
        renderCloudsCompute.SetFloat("_CloudTypeMapTiling", cloudTypeMapTiling);
        renderCloudsCompute.SetFloat("_CloudTypeModifier", cloudTypeModifier);

        renderCloudsCompute.SetFloat("_CloudDensity", cloudDensity);
        renderCloudsCompute.SetFloat("_ScatteringCoefficient", scatteringCoefficient);
        renderCloudsCompute.SetFloat("_AbsorptionCoefficient", absorptoinCoefficient);
        renderCloudsCompute.SetFloat("_ShadowDensity", shadowDensity);
        renderCloudsCompute.SetInt("_DebugDensity", (int)debugDensity);

        renderCloudsCompute.SetVector("_LightDir", -sun.transform.forward);
        renderCloudsCompute.SetFloat("_LightIntensity", lightIntensity);
        renderCloudsCompute.SetFloat("_LightStepSize", lightStepSize);
        renderCloudsCompute.SetFloat("_PhaseWeight", phaseWeight);
        renderCloudsCompute.SetFloat("_DraineAsymmetry", draineAsymmetry);
        renderCloudsCompute.SetFloat("_HGAsymmetry", hgAsymmetry);
        renderCloudsCompute.SetFloat("_DraineAlpha", draineAlpha);
        renderCloudsCompute.SetFloat("_AmbientStrength", ambientStrength);
        renderCloudsCompute.SetVector("_AmbientColor", ambientColor);
        renderCloudsCompute.SetVector("_LightColor", lightColor);
        renderCloudsCompute.SetFloat("_MultipleScatteringStrength", multipleScatteringStrength);
        renderCloudsCompute.SetFloat("_DebugLighting", (int)debugLighting);

        renderCloudsCompute.SetFloat("_FogDensity", depthFogDensity);
        renderCloudsCompute.SetFloat("_FogOffset", depthFogOffset);

        renderCloudsCompute.SetFloat("_WindSpeed", windSpeed);
        renderCloudsCompute.SetVector("_WindDirection", windDirection);


        renderCloudsCompute.SetFloat("_MultipleScatteringAttenuation", multipleScatteringAttenuation);
        renderCloudsCompute.SetFloat("_MultipleScatteringContribution", multipleScatteringContribution);
        renderCloudsCompute.SetFloat("_MultipleScatteringEccentricity", multipleScatteringEccentricity);
        renderCloudsCompute.SetInt("_MultipleScatteringOctaves", multipleScatteringOctaves);

        renderCloudsCompute.SetFloat("_StepSize", stepSize);
        renderCloudsCompute.SetFloat("_WindStretchFactor", windStretchFactor);
        renderCloudsCompute.SetFloat("_PowderWeight", powderWeight);
        renderCloudsCompute.SetInt("_LightMarchSteps", lightMarchSteps);
    }

        private RenderTexture getCloudMaskBuffer(){
        switch(resolutionScale){
            case Res.FullResolution:
                return cloudMaskFullBuffers[frame % numSuperSamples];
            case Res.HalfResolution:
                return cloudMaskHalfBuffers[frame % numSuperSamples];
            case Res.QuarterResolution:
                return cloudMaskQuarterBuffers[frame % numSuperSamples];
        }
        return cloudMaskFullBuffers[frame % numSuperSamples];
    }

    private RenderTexture getCloudAlbedoBuffer(){
        switch(resolutionScale){
            case Res.FullResolution:
                return cloudAlbedoFullBuffers[frame % numSuperSamples];
            case Res.HalfResolution:
                return cloudAlbedoHalfBuffers[frame % numSuperSamples];
            case Res.QuarterResolution:
                return cloudAlbedoQuarterBuffers[frame % numSuperSamples];
        }
        return cloudAlbedoFullBuffers[frame % numSuperSamples];
    }

    private RenderTexture getCloudDepthBuffer(){
        switch(resolutionScale){
            case Res.FullResolution:
                return cloudDepthFullBuffers[frame % numSuperSamples];
            case Res.HalfResolution:
                return cloudDepthHalfBuffers[frame % numSuperSamples];
            case Res.QuarterResolution:
                return cloudDepthQuarterBuffers[frame % numSuperSamples];
        }
        return cloudDepthFullBuffers[frame % numSuperSamples];
    }

    private RenderTexture getCloudAlbedoTexture(){
        switch(resolutionScale){
            case Res.FullResolution:
                return cloudAlbedoFullTex;
            case Res.HalfResolution:
                return cloudAlbedoHalfTex;
            case Res.QuarterResolution:
                return cloudAlbedoQuarterTex;
        }
        return cloudAlbedoFullTex;
    }

    private RenderTexture getCloudMaskTexture(){
        switch(resolutionScale){
            case Res.FullResolution:
                return cloudMaskFullTex;
            case Res.HalfResolution:
                return cloudMaskHalfTex;
            case Res.QuarterResolution:
                return cloudMaskQuarterTex;
        }
        return cloudMaskFullTex;
    }

    private RenderTexture getCloudDepthTexture(){
        switch(resolutionScale){
            case Res.FullResolution:
                return cloudDepthFullTex;
            case Res.HalfResolution:
                return cloudDepthHalfTex;
            case Res.QuarterResolution:
                return cloudDepthQuarterTex;
        }
        return cloudDepthFullTex;
    }

    private void resetTextures(){

        for(int i = 0; i < maxNumSamples; i++){
            cloudAlbedoFullBuffers[i].Release();
            cloudAlbedoFullBuffers[i] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB64, RenderTextureReadWrite.Linear);
            cloudAlbedoFullBuffers[i].enableRandomWrite = true;
            cloudAlbedoFullBuffers[i].Create();

            cloudAlbedoHalfBuffers[i].Release();
            cloudAlbedoHalfBuffers[i] = new RenderTexture(Mathf.CeilToInt(Screen.width / 2), Mathf.CeilToInt(Screen.height / 2), 0, RenderTextureFormat.ARGB64, RenderTextureReadWrite.Linear);
            cloudAlbedoHalfBuffers[i].enableRandomWrite = true;
            cloudAlbedoHalfBuffers[i].Create();

            cloudAlbedoQuarterBuffers[i].Release();
            cloudAlbedoQuarterBuffers[i] = new RenderTexture(Mathf.CeilToInt(Screen.width / 4), Mathf.CeilToInt(Screen.height / 4), 0, RenderTextureFormat.ARGB64, RenderTextureReadWrite.Linear);
            cloudAlbedoQuarterBuffers[i].enableRandomWrite = true;
            cloudAlbedoQuarterBuffers[i].Create();

            cloudMaskFullBuffers[i].Release();
            cloudMaskFullBuffers[i] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
            cloudMaskFullBuffers[i].enableRandomWrite = true;
            cloudMaskFullBuffers[i].Create();

            cloudMaskHalfBuffers[i].Release();
            cloudMaskHalfBuffers[i] = new RenderTexture(Mathf.CeilToInt(Screen.width / 2), Mathf.CeilToInt(Screen.height / 2), 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
            cloudMaskHalfBuffers[i].enableRandomWrite = true;
            cloudMaskHalfBuffers[i].Create();

            cloudMaskQuarterBuffers[i].Release();
            cloudMaskQuarterBuffers[i] = new RenderTexture(Mathf.CeilToInt(Screen.width / 4), Mathf.CeilToInt(Screen.height / 4), 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
            cloudMaskQuarterBuffers[i].enableRandomWrite = true;
            cloudMaskQuarterBuffers[i].Create();

            cloudDepthFullBuffers[i].Release();
            cloudDepthFullBuffers[i] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
            cloudDepthFullBuffers[i].enableRandomWrite = true;
            cloudDepthFullBuffers[i].Create();

            cloudDepthHalfBuffers[i].Release();
            cloudDepthHalfBuffers[i] = new RenderTexture(Mathf.CeilToInt(Screen.width / 2), Mathf.CeilToInt(Screen.height / 2), 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
            cloudDepthHalfBuffers[i].enableRandomWrite = true;
            cloudDepthHalfBuffers[i].Create();

            cloudDepthQuarterBuffers[i].Release();
            cloudDepthQuarterBuffers[i] = new RenderTexture(Mathf.CeilToInt(Screen.width / 4), Mathf.CeilToInt(Screen.height / 4), 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
            cloudDepthQuarterBuffers[i].enableRandomWrite = true;
            cloudDepthQuarterBuffers[i].Create();
        }

        cloudAlbedoFullTex.Release();
        cloudAlbedoFullTex = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB64, RenderTextureReadWrite.Linear);
        cloudAlbedoFullTex.enableRandomWrite = true;
        cloudAlbedoFullTex.Create();

        cloudAlbedoHalfTex.Release();
        cloudAlbedoHalfTex = new RenderTexture(Mathf.CeilToInt(Screen.width / 2), Mathf.CeilToInt(Screen.height / 2), 0, RenderTextureFormat.ARGB64, RenderTextureReadWrite.Linear);
        cloudAlbedoHalfTex.enableRandomWrite = true;
        cloudAlbedoHalfTex.Create();

        cloudAlbedoQuarterTex.Release();
        cloudAlbedoQuarterTex = new RenderTexture(Mathf.CeilToInt(Screen.width / 4), Mathf.CeilToInt(Screen.height / 4), 0, RenderTextureFormat.ARGB64, RenderTextureReadWrite.Linear);
        cloudAlbedoQuarterTex.enableRandomWrite = true;
        cloudAlbedoQuarterTex.Create();

        cloudMaskFullTex.Release();
        cloudMaskFullTex = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        cloudMaskFullTex.enableRandomWrite = true;
        cloudMaskFullTex.Create();

        cloudMaskHalfTex.Release();
        cloudMaskHalfTex = new RenderTexture(Mathf.CeilToInt(Screen.width / 2), Mathf.CeilToInt(Screen.height / 2), 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        cloudMaskHalfTex.enableRandomWrite = true;
        cloudMaskHalfTex.Create();

        cloudMaskQuarterTex.Release();
        cloudMaskQuarterTex = new RenderTexture(Mathf.CeilToInt(Screen.width / 4), Mathf.CeilToInt(Screen.height / 4), 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        cloudMaskQuarterTex.enableRandomWrite = true;
        cloudMaskQuarterTex.Create();

        cloudDepthFullTex.Release();
        cloudDepthFullTex = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        cloudDepthFullTex.enableRandomWrite = true;
        cloudDepthFullTex.Create();

        cloudDepthHalfTex.Release();
        cloudDepthHalfTex = new RenderTexture(Mathf.CeilToInt(Screen.width / 2), Mathf.CeilToInt(Screen.height / 2), 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        cloudDepthHalfTex.enableRandomWrite = true;
        cloudDepthHalfTex.Create();

        cloudDepthQuarterTex.Release();
        cloudDepthQuarterTex = new RenderTexture(Mathf.CeilToInt(Screen.width / 4), Mathf.CeilToInt(Screen.height / 4), 0, RenderTextureFormat.RFloat, RenderTextureReadWrite.Linear);
        cloudDepthQuarterTex.enableRandomWrite = true;
        cloudDepthQuarterTex.Create();
    }


    void OnRenderImage(RenderTexture source, RenderTexture destination) {

        UpdateCloudParameters();

        Shader.SetGlobalInt("_Frame", frame);
        Shader.SetGlobalInt("_NumSuperSamples", numSuperSamples);

        RenderTexture cloudMaskBuffer = getCloudMaskBuffer();
        RenderTexture cloudBuffer = getCloudAlbedoBuffer();
        RenderTexture cloudDepthBuffer = getCloudDepthBuffer();

        renderCloudsCompute.SetInt("_BufferWidth", cloudBuffer.width);
        renderCloudsCompute.SetInt("_BufferHeight", cloudBuffer.height);
        renderCloudsCompute.SetTexture(0, "_CloudTex", cloudBuffer);
        renderCloudsCompute.SetTexture(0, "_CloudMask", cloudMaskBuffer);
        renderCloudsCompute.SetTexture(0, "_CloudDepth", cloudDepthBuffer);

        if(lastSamples != numSuperSamples){
    
            resetTextures();

            frame = 0;

            lastSamples = numSuperSamples;
        
        }

        RenderTexture cloudMaskTex = getCloudMaskTexture();
        RenderTexture cloudAlbedoTex = getCloudAlbedoTexture();
        RenderTexture cloudDepthTex = getCloudDepthTexture();


        if(frame < numSuperSamples){
            renderCloudsCompute.Dispatch(0, Mathf.CeilToInt(cloudBuffer.width / 8.0f), Mathf.CeilToInt(cloudBuffer.height / 8.0f), 1);

            cloudAccumulatorCompute.SetTexture(0, "_AccumulatedScatter", cloudAlbedoTex);
            cloudAccumulatorCompute.SetTexture(0, "_AccumulatedTransmittance", cloudMaskTex);
            cloudAccumulatorCompute.SetTexture(0, "_AccumulatedDepth", cloudDepthTex);
            cloudAccumulatorCompute.SetTexture(0, "_Transmittance", cloudMaskBuffer);
            cloudAccumulatorCompute.SetTexture(0, "_Scatter", cloudBuffer);
            cloudAccumulatorCompute.SetTexture(0, "_Depth", cloudDepthBuffer);
            cloudAccumulatorCompute.SetInt("_AccumulateMode", 1);
            cloudAccumulatorCompute.Dispatch(0, Mathf.CeilToInt(cloudBuffer.width / 8.0f), Mathf.CeilToInt(cloudBuffer.height / 8.0f), 1);
        }
        else{
            cloudAccumulatorCompute.SetTexture(0, "_AccumulatedScatter", cloudAlbedoTex);
            cloudAccumulatorCompute.SetTexture(0, "_AccumulatedTransmittance", cloudMaskTex);
            cloudAccumulatorCompute.SetTexture(0, "_AccumulatedDepth", cloudDepthTex);
            cloudAccumulatorCompute.SetTexture(0, "_Transmittance", cloudMaskBuffer);
            cloudAccumulatorCompute.SetTexture(0, "_Scatter", cloudBuffer);
            cloudAccumulatorCompute.SetTexture(0, "_Depth", cloudDepthBuffer);
            cloudAccumulatorCompute.SetInt("_AccumulateMode", 0);
            cloudAccumulatorCompute.Dispatch(0, Mathf.CeilToInt(cloudBuffer.width / 8.0f), Mathf.CeilToInt(cloudBuffer.height / 8.0f), 1);

            renderCloudsCompute.Dispatch(0, Mathf.CeilToInt(cloudBuffer.width / 8.0f), Mathf.CeilToInt(cloudBuffer.height / 8.0f), 1);

            cloudAccumulatorCompute.SetTexture(0, "_AccumulatedScatter", cloudAlbedoTex);
            cloudAccumulatorCompute.SetTexture(0, "_AccumulatedTransmittance", cloudMaskTex);
            cloudAccumulatorCompute.SetTexture(0, "_AccumulatedDepth", cloudDepthTex);
            cloudAccumulatorCompute.SetTexture(0, "_Transmittance", cloudMaskBuffer);
            cloudAccumulatorCompute.SetTexture(0, "_Scatter", cloudBuffer);
            cloudAccumulatorCompute.SetTexture(0, "_Depth", cloudDepthBuffer);

            cloudAccumulatorCompute.SetInt("_AccumulateMode", 1);
            cloudAccumulatorCompute.Dispatch(0, Mathf.CeilToInt(cloudBuffer.width / 8.0f), Mathf.CeilToInt(cloudBuffer.height / 8.0f), 1);
        }

        cloudCompositer.SetTexture("_CloudTex", cloudAlbedoTex);
        cloudCompositer.SetTexture("_CloudMask", cloudMaskTex);
        cloudCompositer.SetTexture("_CloudDepth", cloudDepthTex);
        cloudCompositer.SetInt("_DebugTexture", (int)debugTexture);


        Graphics.Blit(source, destination, cloudCompositer);

        frame++;
    }
}
