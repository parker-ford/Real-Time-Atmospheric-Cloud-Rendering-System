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
            float _NoiseTiling;
            float _DensityAbsorption;
            int _FlipTransmittance;
            int _CloudCoverageMode;

            float getHeightFract(float3 p){
                p.y -= EARTH_RADIUS;
                return (p.y - LOW_ATMOSPHERE_RADIUS_HEIGHT) / (HIGH_ATMOSPHERE_RADIUS_HEIGHT - LOW_ATMOSPHERE_RADIUS_HEIGHT);
            }

            float getBaseCloud(float4 pos){
                float3 samplePos;
                samplePos = remap_f3(pos.xyz, -_NoiseTiling, _NoiseTiling, 0.0, 1.0);
                float baseCloud = tex3D(_LowFrequencyCloudNoise, samplePos).r;
                return baseCloud;
            }

            float getHeightDensity(float density){
                return density;
            }

            float getCloudCoverage(float density){
                if(_CloudCoverageMode == 1){
                    density = smoothstep( 0., CLOUDS_BASE_EDGE_SOFTNESS, density+(CLOUDS_COVERAGE-1.) );
                }
                if(_CloudCoverageMode == 2){
                   density = remap_f(density, CLOUD_COVERAGE, 1., 0.0, 1.0) * (CLOUD_COVERAGE);
                }
                return density;
            }

            float sampleCloudDensity(float4 pos){
                
                //float4 samplePos;
                // samplePos.xz = remap_f2(pos.xz, -LOW_FREQUENCY_CLOUD_NOISE_SIZE, LOW_FREQUENCY_CLOUD_NOISE_SIZE, 0.0, 1.0);
                // samplePos.y = getHeightFract(pos);
                // //mip level
                // samplePos.w = remap_f(pos.w, LOW_ATMOSPHERE_RADIUS_HEIGHT, MAX_VIEW_DISTANCE, 0, 6);

                // float4 lowFreqNoise = tex3Dlod(_LowFrequencyCloudNoise, samplePos);
                // float3 lowFreqFBM = (lowFreqNoise.g * 0.625) + (lowFreqNoise.b * 0.25) + (lowFreqNoise.a * 0.125);
                // float baseCloud = remap_f(lowFreqNoise.r, -(1.0 - lowFreqFBM), 1.0, 0.0, 1.0);

                // //float densityHeight = getDensityHeight(samplePos.y);
                // //baseCloud *= densityHeight;

                // float cloudCoverage = CLOUD_COVERAGE;
                // float baseCloudWithCoverage = remap_f(baseCloud, cloudCoverage, 1., 0., 1.);
                // baseCloud = baseCloudWithCoverage * cloudCoverage;

                // return saturate(baseCloud);

                // float3 samplePos;
                // samplePos = remap_f3(pos.xyz, -_NoiseTiling, _NoiseTiling, 0.0, 1.0);
                // float height = getHeightFract(pos.xyz);
                // float heightDensity = tex2D(_HeightDensityGradient, float2(height, 0)).r;
                // //return heightDensity;
                // heightDensity = 1.0;
                // float density = tex3D(_LowFrequencyCloudNoise, samplePos).r;
                // density = smoothstep(0.0, .1, density+(CLOUD_COVERAGE - 1.0));
                //return clamp(density, 0.0, 1.0);

                float density = getBaseCloud(pos);
                density = getHeightDensity(density);
                density = getCloudCoverage(density);
                return clamp(density, 0.0, 1.0);
            }

            

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 mainCol = tex2D(_MainTex, i.uv);
                float4 blueNoiseSample = sampleBlueNoise(i.uv);
                float2 pixelOffset = blueNoiseSample.rg;
                float distanceOffset = blueNoiseSample.b;

                Ray ray = getRayFromUV(i.uv, blueNoiseSample.rg, 1);
                Sphere lowerAtmosphere = {float3(0, 0, 0), SCALE_TO_EARTH_RADIUS == 1 ? EARTH_RADIUS + LOW_ATMOSPHERE_RADIUS_HEIGHT : LOW_ATMOSPHERE_RADIUS_HEIGHT};
                Sphere upperAtmosphere = {float3(0, 0, 0), SCALE_TO_EARTH_RADIUS == 1 ? EARTH_RADIUS + HIGH_ATMOSPHERE_RADIUS_HEIGHT : HIGH_ATMOSPHERE_RADIUS_HEIGHT};
                SphereHit lowerAtmosphereHit = raySphereIntersect(ray, lowerAtmosphere);
                SphereHit upperAtmosphereHit = raySphereIntersect(ray, upperAtmosphere);
                float currRayDist = 0;
                if (lowerAtmosphereHit.hit && lowerAtmosphereHit.enter < MAX_VIEW_DISTANCE)
                {
                    float3 enterPos = ray.origin + ray.direction * lowerAtmosphereHit.enter;
                    float3 exitPos = ray.origin + ray.direction * upperAtmosphereHit.enter;
                    float dist = length(exitPos - enterPos);
                    float distPerStep = dist / _RayMarchSteps;
                    // distPerStep /= 4.0;
                    float totalTransmittance = 0.0;
                    // float4 intScatterTrans = float4(1,1,1,1);
                    float transmittance = 1.0;

                    [unroll(20)]
                    for(int rayMarchStep = 0; rayMarchStep < _RayMarchSteps; rayMarchStep++){
                        float4 pos;
                        pos.xyz = getMarchPosition(ray, lowerAtmosphereHit, rayMarchStep, distPerStep, distanceOffset);
                        pos.w = length(pos - ray.origin);
                        float cloudDensity = sampleCloudDensity(pos);
                        if(cloudDensity > 0.0){
                            float dTrans = exp(-cloudDensity * (1.0/_RayMarchSteps) * _DensityAbsorption);
                            transmittance *= dTrans;
                        }
                        if( transmittance <= CLOUDS_MIN_TRANSMITTANCE ) break;
                    }
                    if(_FlipTransmittance == 1){
                        transmittance = 1 - transmittance;
                    }
                    return lerp(mainCol, float4(1,1,1,1), transmittance);
                }
                return mainCol;
            }
            ENDCG
        }
    }
}
