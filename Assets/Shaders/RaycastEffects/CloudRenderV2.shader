Shader "Parker/CloudRenderV2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "../Includes/raycast.cginc"
            #include "../Includes/noise.cginc"

            #define SCALE_TO_EARTH_RADIUS 1
            #define LOW_ATMOSPHERE_RADIUS_HEIGHT 1500.0
            #define HIGH_ATMOSPHERE_RADIUS_HEIGHT 5000.0
            #define LOW_FREQUENCY_CLOUD_NOISE_SIZE 4096.0
            #define CLOUD_COVERAGE 0.3
            #define CLOUD_DENSITY 0.03
            #define CLOUDS_MIN_TRANSMITTANCE 0.1
            #define CLOUDS_COVERAGE .52
            #define CLOUDS_BASE_EDGE_SOFTNESS .0

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            sampler3D _LowFrequencyCloudNoise;
            sampler3D _HighFrequencyCloudNoise;
            sampler2D _CloudMap;
            sampler2D _CloudHeightGradient;

            float _NoiseTiling;
            float _CloudMapTiling;
            float _AtmosphereHigh;
            float _AtmosphereLow;
            float _LightAbsorption;
            float _LightIntensity;
            float _AbsorptionCoefficient;
            float _ScatteringCoefficient;
            float _CloudDensity;
            float _ShadowDensity;
            float _LightStepSize;
            float _StepSize;
            float _AlphaThreshold;
            float _PhaseAsymmetry;
            float _CloudFalloff;
            float _DualHGWeight;
            float _AmbientStrength;
            float _MultipleScatteringStrength;
            float _CloudType;
            float _StepGrowthRate;

            int _LightStepCount;
            int _StepCount;

            float3 _LightDir;
            float3 _LightColor;
            float3 _AmbientColor;

            int _UseHeightGradient;

            float3 ACESFilm(float3 x) {
                float a = 2.51f;
                float b = 0.03f;
                float c = 2.43f;
                float d = 0.59f;
                float e = 0.14f;
                return clamp((x*(a*x+b))/(x*(c*x+d)+e), 0.0, 1.0);
            }

            float henyeyGreenstein(float g, float cosTheta) {
                float gg = g * g;
                return (1.0 / (4.0 * PI))  * ((1.0 - gg) / pow(1.0 + gg - 2.0 * g * cosTheta, 1.5));
            }
            float doubleHenyeyGreenstein(float g, float cosTheta) {
                return lerp(henyeyGreenstein(-g, cosTheta), henyeyGreenstein(g, cosTheta), _DualHGWeight);
            }
   
            float phase(float g, float cosTheta){
                // return henyeyGreenstein(g, cosTheta);
                return doubleHenyeyGreenstein(g, cosTheta);
            }

            float getHeightFract(float3 p){
                p.y -= EARTH_RADIUS;
                float res = (p.y - _AtmosphereLow) / (_AtmosphereHigh - _AtmosphereLow);
                return min(res, 1.0);
            }

             float getBaseCloud(float3 pos){
                float3 samplePos;
                samplePos = remap_f3(pos.xyz, 0, _NoiseTiling, 0.0, 1.0);
                float4 lowFreqNoise = tex3D(_LowFrequencyCloudNoise, samplePos);
                float lowFreqFBM = (lowFreqNoise.g * 0.625) + (lowFreqNoise.b * 0.25) + (lowFreqNoise.a * 0.125);
                float baseCloud = remap_f(lowFreqNoise.r, (1.0 - lowFreqFBM), 1.0, 0.0, 1.0);
                return baseCloud;
                // return lowFreqNoise.r;
            }

            float sampleCloudMap(float3 pos){
                float2 cloudMapSamplePos = remap_f2(pos.xz, 0, _CloudMapTiling, 0, 1);
                return tex2D(_CloudMap, cloudMapSamplePos).r;
            }

            float sampleHeightGradient(float3 pos){
                float cloudHeight = getHeightFract(pos);
                return tex2D(_CloudHeightGradient, float2(_CloudType + (1.0 / (512.0 * 0.5f)), cloudHeight)).r;
            }

            float sampleDensity(float3 pos){
                float density = _CloudDensity;
                density *= sampleCloudMap(pos);
                density *= sampleHeightGradient(pos);
                density *= getBaseCloud(pos);
                return density;
            }

            float calculateDimensionalProfile(float3 pos){
                return sampleCloudMap(pos) * sampleHeightGradient(pos) * _CloudDensity;
            }

            float calculateDensity(float3 pos, float dimensionalProfile){
                float noise = getBaseCloud(pos);
                float density = saturate(noise - (1.0 - (dimensionalProfile * _CloudFalloff)));
                return density;
            }

            float3 calculateLightEnergy(float3 pos, float cosTheta){
                float tau = 0.0;
                [unroll(5)]
                for(int l = 0; l < 5; l++){
                    float lightT = _LightStepSize * (l + 0.5);
                    float3 lightPos = pos + _LightDir * lightT;
                    float dimensionalProfile = calculateDimensionalProfile(lightPos);
                    float density = calculateDensity(lightPos, dimensionalProfile);
                    tau += (density * _ShadowDensity);
                    // tau += lightDensity *;
                }
                float primaryScattering = exp(-(_AbsorptionCoefficient + _ScatteringCoefficient) * tau * _LightStepSize);
                float phaseTerm = phase(_PhaseAsymmetry, cosTheta);

                return primaryScattering * phaseTerm;
            }


            fixed4 frag (v2f i) : SV_Target {
                float3 mainCol = tex2D(_MainTex, i.uv).rgb;
                float4 blueNoiseSample = sampleBlueNoise(i.uv);
                float2 pixelOffset = blueNoiseSample.rg;
                float distanceOffset = blueNoiseSample.b;

                // float test = (float)(_Frame % _NumSuperSamples) / (float)_NumSuperSamples;
                // return float4(test,test,test,1.0);


                Ray ray = getRayFromUV(i.uv, blueNoiseSample.rg, 1);
                Sphere lowerAtmosphere = {float3(0, 0, 0), SCALE_TO_EARTH_RADIUS == 1 ? EARTH_RADIUS + _AtmosphereLow : _AtmosphereLow};
                Sphere upperAtmosphere = {float3(0, 0, 0), SCALE_TO_EARTH_RADIUS == 1 ? EARTH_RADIUS + _AtmosphereHigh : _AtmosphereHigh};

                SphereHit lowerAtmosphereHit = raySphereIntersect(ray, lowerAtmosphere);
                SphereHit upperAtmosphereHit = raySphereIntersect(ray, upperAtmosphere);

                if(lowerAtmosphereHit.hit && lowerAtmosphereHit.exit < MAX_VIEW_DISTANCE){
                    // float stepSize = _StepSize;
                    // int ns = ceil((upperAtmosphereHit.exit - lowerAtmosphereHit.exit) / stepSize);
                    // stepSize = (upperAtmosphereHit.exit - lowerAtmosphereHit.exit) / ns;

                    //TODO: move this to CPU
                    float dist = upperAtmosphereHit.exit - lowerAtmosphereHit.exit;
                    float n = _RayMarchSteps - 1;
                    float a = 1.0f - pow(_StepGrowthRate, n + 1);
                    float b = 1.0f - _StepGrowthRate;

                    
                    // float stepSize = dist / (a / b);
                    float stepSize = _StepSize;

                    float frameSegment = (float)(_Frame % _NumSuperSamples) / (float)_NumSuperSamples;

                    float transparency = 1.0;
                    float3 result = float3(0, 0, 0);
                    float dimensionalProfile = 0.0;
                    float3 lightColor = float3(1, 1, 1);
                    float totalDistance = lowerAtmosphereHit.exit;

                    [unroll(50)]
                    for(int n = 0; n < _RayMarchSteps; n++){
                        // float t = lowerAtmosphereHit.exit + stepSize * (n + blueNoiseSample.b);
                        float t = lowerAtmosphereHit.exit + ((stepSize * n) + (frameSegment * stepSize) + ((stepSize / _NumSuperSamples) * blueNoiseSample.b));
                        float3 pos = ray.origin + ray.direction * t;

                        // float3 pos = ray.origin + ray.direction * (totalDistance + frameSegment * stepSize + (stepSize / _NumSuperSamples) * blueNoiseSample.b);


                        float dimensionalProfile = calculateDimensionalProfile(pos);
                        float density = calculateDensity(pos, dimensionalProfile);
                        if(density > 0.001){    

                            float extinction = (_AbsorptionCoefficient + _ScatteringCoefficient) * density;
                            float sampleAttenuation = exp(-extinction * stepSize);
                            
                            float cosTheta = dot(normalize(ray.direction), normalize(_LightDir));

                            // float3 ambientLight = pow(transparency, 0.5) * stepSize; // idk
                            float3 ambientLight = _AmbientColor * _AmbientStrength * pow(1.0 - dimensionalProfile, 0.5);
                            float multipleScattering = remap_f(dimensionalProfile * stepSize, 0.1, 1.0, 0.0, 1.0) * _MultipleScatteringStrength;
                            float3 directLight = _LightColor * calculateLightEnergy(pos, cosTheta) * _LightIntensity;
                            // float3 directLight = float3(0., 0., 0.);

                            float3 luminance = directLight + ambientLight + multipleScattering;

                            transparency *= sampleAttenuation;
                            result += transparency * luminance  * _ScatteringCoefficient * density * stepSize;
                        }

 
                        totalDistance += stepSize;
                        // stepSize *= _StepGrowthRate;
                    }
                    mainCol = ACESFilm(mainCol.rgb);
                    result = ACESFilm(result);

                    return lerp(float4(mainCol, 1.0), float4(result, 1.0), 1.0 - transparency);
                }

                mainCol = ACESFilm(mainCol.rgb);
                return float4(mainCol, 1.0);
            }
            ENDCG
        }
    }
}
