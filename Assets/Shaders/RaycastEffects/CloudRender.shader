Shader "Parker/CloudRender"
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
            sampler2D _HeightDensityGradient;
            sampler2D _BaseCloud2D;
            float _NoiseTiling;
            float _DensityAbsorption;
            int _FlipTransmittance;
            int _CloudCoverageMode;
            float _CloudCoverage;
            float _AtmosphereLow;
            float _AtmosphereHigh;
            int _BaseCloudMode;
            int _UseLighting;
            float _LightAbsorption;
            float _LightIntensity;
            int _CloudDensityAsTransparency;
            float _CloudEdgeCutOff;
            int _CloudHeightDensityMode;

            float getHeightFract(float3 p){
                p.y -= EARTH_RADIUS;
                return (p.y - _AtmosphereLow) / (_AtmosphereHigh - _AtmosphereLow);
            }

            float getBaseCloud(float4 pos){
                float3 samplePos;
                samplePos = remap_f3(pos.xyz, -_NoiseTiling, _NoiseTiling, 0.0, 1.0);
                float baseCloud = 0;
                if(_BaseCloudMode == 0){
                    baseCloud = tex3D(_LowFrequencyCloudNoise, samplePos).r;
                }
                else if(_BaseCloudMode == 1){
                    float4 lowFreqNoise = tex3D(_LowFrequencyCloudNoise, samplePos);
                    float3 lowFreqFBM = (lowFreqNoise.g * 0.625) + (lowFreqNoise.b * 0.25) + (lowFreqNoise.a * 0.125);
                    baseCloud = remap_f(lowFreqNoise.r, (1.0 - lowFreqFBM), 1.0, 0.0, 1.0);
                }
                else if(_BaseCloudMode == 2){
                    baseCloud = tex2D(_BaseCloud2D, samplePos.xz).r;
                }
                return baseCloud;
            }

            float getHeightDensity(float4 pos, float density){
                if(_CloudHeightDensityMode == 1){
                    float heightFract = getHeightFract(pos.xyz);
                    float heightDensity = tex2D(_HeightDensityGradient, float2(heightFract, 0)).r;
                    density = lerp(density, heightDensity, heightFract);
                    //density *= heightDensity;
                    //density *= (1.0 - heightFract);
                }
                return density;
            }

            float getCloudCoverage(float density){
                if(_CloudCoverageMode == 1){
                    density = smoothstep( 0., CLOUDS_BASE_EDGE_SOFTNESS, density+(_CloudCoverage- 1.) );
                }
                if(_CloudCoverageMode == 2){
                   density = remap_f(density, (1.0  -_CloudCoverage), 1., 0.0, 1.0) * (_CloudCoverage);
                }
                if(_CloudCoverageMode == 3){
                    density *= step((1.0 - _CloudCoverage), density);
                }
                return density;
            }

            float sampleCloudDensity(float4 pos){
                float density = getBaseCloud(pos);
                density = getHeightDensity(pos, density);
                density = getCloudCoverage(density);
                return clamp(density, 0.0, 1.0);
            }

            float marchTowardsLight(float4 pos){
                Ray ray = {pos.xyz, normalize(float3(1, 1, 0))};
                float distPerStep = 50.0; //idk about this
                float totalDensity = 1.0;
                SphereHit hit = {0, 0, 0};
                for(int i = 0; i < 5; i++){
                    float4 currPos;
                    currPos.xyz = getMarchPosition(ray, hit, i, distPerStep, 0);
                    currPos.w = length(currPos - ray.origin);
                    float cloudDensity = sampleCloudDensity(currPos);
                    totalDensity *= exp(-cloudDensity * distPerStep * _LightAbsorption);
                }
                return _LightIntensity * totalDensity;
            }      

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 mainCol = tex2D(_MainTex, i.uv);
                float4 blueNoiseSample = sampleBlueNoise(i.uv);
                float2 pixelOffset = blueNoiseSample.rg;
                float distanceOffset = blueNoiseSample.b;

                Ray ray = getRayFromUV(i.uv, blueNoiseSample.rg, 1);
                Sphere lowerAtmosphere = {float3(0, 0, 0), SCALE_TO_EARTH_RADIUS == 1 ? EARTH_RADIUS + _AtmosphereLow : _AtmosphereLow};
                Sphere upperAtmosphere = {float3(0, 0, 0), SCALE_TO_EARTH_RADIUS == 1 ? EARTH_RADIUS + _AtmosphereHigh : _AtmosphereHigh};
                SphereHit lowerAtmosphereHit = raySphereIntersect(ray, lowerAtmosphere);
                SphereHit upperAtmosphereHit = raySphereIntersect(ray, upperAtmosphere);
                float currRayDist = 0;
                if (lowerAtmosphereHit.hit && lowerAtmosphereHit.enter < MAX_VIEW_DISTANCE)
                {
                    float3 enterPos = ray.origin + ray.direction * lowerAtmosphereHit.enter;
                    float3 exitPos = ray.origin + ray.direction * upperAtmosphereHit.enter;
                    float dist = length(exitPos - enterPos);
                    float distPerStep = dist / _RayMarchSteps;
                    float totalTransmittance = 0.0;
                    float transmittance = 1.0;
                    float3 scatteredLight = float3(0.0, 0.0, 0.0);
                    [unroll(20)]
                    for(int rayMarchStep = 0; rayMarchStep < _RayMarchSteps; rayMarchStep++){
                        float4 pos;
                        pos.xyz = getMarchPosition(ray, lowerAtmosphereHit, rayMarchStep, distPerStep, distanceOffset);
                        pos.w = length(pos - ray.origin);
                        float cloudDensity = sampleCloudDensity(pos);
                        if(cloudDensity > 0.0){
                            float dTrans = exp(-cloudDensity * (1.0/_RayMarchSteps) * _DensityAbsorption);
                            transmittance *= dTrans;
                            
                            float3 luminance = float3(1,1,1) * marchTowardsLight(pos);
                            float3 dScatter = (luminance - luminance * dTrans) * (1.0 - cloudDensity);
                            scatteredLight += transmittance * dScatter;
                        }
                        //if( transmittance <= CLOUDS_MIN_TRANSMITTANCE ) break;
                    }
                    if(_FlipTransmittance == 1){
                        transmittance = 1 - transmittance;
                    }

                    float4 finalColor = float4(0.8,0.8,0.8,1);
                    if(_UseLighting == 1){
                        finalColor = float4(scatteredLight, 1.0);
                    }
                    float finalAlpha = step(_CloudEdgeCutOff, transmittance);
                    if(_CloudDensityAsTransparency == 1){
                       finalAlpha = transmittance;
                    }


                    return lerp(mainCol, finalColor, finalAlpha);

           
                    
                }
                return mainCol;
            }
            ENDCG
        }
    }
}
