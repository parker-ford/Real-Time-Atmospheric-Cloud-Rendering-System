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

            int _LightStepCount;

            float3 _CloudColor;
            float3 _ExtinctionColor;
            float3 _LightColor;

            int _UseHeightGradient;

            float getHeightFract(float3 p){
                p.y -= EARTH_RADIUS;
                float res = (p.y - _AtmosphereLow) / (_AtmosphereHigh - _AtmosphereLow);
                return min(res, 1.0);
            }

            float sampleDensity(float3 pos){
                float2 cloudMapSamplePos = remap_f2(pos.xz, 0, _NoiseTiling, 0, 1);
                float cloudHeight = getHeightFract(pos);
                if(_UseHeightGradient == 1){
                    return tex2D(_CloudMap, cloudMapSamplePos).r * tex2D(_CloudHeightGradient, float2(0.0, cloudHeight)).r;
                }
                else{
                    return tex2D(_CloudMap, cloudMapSamplePos).r;
                }
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
                float distPerStep = _StepSize;
                // float distPerStep = (_AtmosphereHigh - _AtmosphereLow) / _RayMarchSteps;

                SphereHit lowerAtmosphereHit = raySphereIntersect(ray, lowerAtmosphere);
                SphereHit upperAtmosphereHit = raySphereIntersect(ray, upperAtmosphere);

                float currRayDist = 0;
                if (lowerAtmosphereHit.hit && lowerAtmosphereHit.enter < MAX_VIEW_DISTANCE)
                {
                    float3 enterPos = ray.origin + ray.direction * lowerAtmosphereHit.enter;
                    float3 exitPos = ray.origin + ray.direction * upperAtmosphereHit.enter;

                    float startDist = lowerAtmosphereHit.enter;
                    float endDist = upperAtmosphereHit.enter;


                    // float extinctionCoefficient = _AbsorptionCoefficient + _ScatteringCoefficient;
                    // float accumulatedDensity = 0.0;
                    // float thickness = 0.0;
                    float distanceTraveled = startDist;
                    float3 color = float3(0,0,0);
                    float alpha = 1.0;

                    float3 pos = ray.origin + ray.direction * distanceTraveled;
                    float v = sampleDensity(pos);

                    [unroll(100)]
                    while(v == 0 && distanceTraveled < endDist){
                        distanceTraveled += (2 * distPerStep);
                        pos = ray.origin + ray.direction * distanceTraveled;
                        v = sampleDensity(pos);
                    }

                    

                    if(v){
                        distanceTraveled -= (2 * distPerStep);
                        float thickness = 0.0;

                        color = _CloudColor;
                        float extinctionCoefficient = _AbsorptionCoefficient + _ScatteringCoefficient;

                        float lightDistPerStep = _LightStepSize;
                        float accumulatedDensity = 0.0;

                        uint stepCount = 0;
                        [unroll(30)]
                        while(stepCount < _RayMarchSteps && distanceTraveled < endDist){
                            pos = ray.origin + ray.direction * distanceTraveled;
                            v = sampleDensity(pos);
                            float sampledDensity = v;
                            accumulatedDensity += sampledDensity * _CloudDensity;

                            ++stepCount;
                            distanceTraveled += distPerStep;
                            thickness += sampledDensity * distPerStep;
                            alpha = exp(-thickness * accumulatedDensity * extinctionCoefficient);

                            if(v > 0.001){
                                float tau = 0.0f;
                                float lightPos = pos;
                                int lightRayStep = 0;
                                float lightStepSize = _LightStepSize;
                                [unroll(10)]
                                while(lightRayStep < _LightStepCount){
                                    tau += v * _ShadowDensity;
                                    lightPos -= lightStepSize * float3(0, -1, -1);
                                    v = sampleDensity(lightPos);
                                    lightRayStep++;
                                }

                                float3 lightAttenuation = exp(-(tau / _ExtinctionColor) * extinctionCoefficient * _ShadowDensity);
                                color +=  lightAttenuation * alpha * _ScatteringCoefficient * _CloudDensity * sampledDensity;
                            }

                            // if(alpha < _AlphaThreshold){
                            //     break;
                            // }
                        }
                    }


                    

                //     [unroll(20)]
                //     for(int rayMarchStep = 0; rayMarchStep < _RayMarchSteps; rayMarchStep++){
                //         float3 pos;
                //         pos = getMarchPosition(ray, lowerAtmosphereHit, rayMarchStep, distPerStep, distanceOffset);

                //         float3 samplePos = remap_f3(pos, 0, _NoiseTiling, 0, 1);
                //         samplePos.y = getHeightFract(pos);

                //         float sampledDensity = sampleDensity(samplePos);

                //         accumulatedDensity += sampledDensity * _CloudDensity;
                //         thickness += sampledDensity * distPerStep;
                //         distance += distPerStep;
                //         alpha = exp(-thickness * accumulatedDensity * extinctionCoefficient);

                //         if(sampledDensity > 0.001){
                //             float lightAccumulatedDensity = 0.0;
                //             float3 lightDir = normalize(float3(1, 1, 0));
                //             [unroll(10)]
                //             for(int lightRayStep = 0; lightRayStep < 10; lightRayStep++){
                //                 float3 lightPos = pos + lightDir * (float)lightRayStep * _LightStepSize;
                //                 float3 lightSamplePos = remap_f3(lightPos, 0, _NoiseTiling, 0, 1);
                //                 lightSamplePos.y = getHeightFract(lightPos);
                //                 lightAccumulatedDensity += sampleDensity(lightSamplePos);
                //             }
                //             float lightAttenuation = exp(-(lightAccumulatedDensity) * extinctionCoefficient * _ShadowDensity);
                //             // return float4(lightAttenuation, 1);
                //             color +=  _LightColor * lightAttenuation * alpha * _ScatteringCoefficient * _CloudDensity * sampledDensity * _LightIntensity;
                //             // color += _LightColor * lightAttenuation * alpha * _ScatteringCoefficient * _CloudDensity * sampledDensity;
                //         }
                //     }
                //     alpha = 1 - alpha;
                //     // return lerp(mainCol, float4(0,0,0,1), saturate(alpha));
                //     return lerp(mainCol, float4(saturate(color), 1.0), saturate(alpha));

                    // if(alpha < _AlphaThreshold){
                    //     alpha = 0;
                    // }
                    color = 1 - color;
                    alpha = 1 - alpha;
                    color = saturate(color);
                    alpha = saturate(alpha);
                    // return float4(color, 1.0);
                    return lerp(mainCol, float4(color, 1.0), alpha);
                    // return lerp(mainCol, float4(1.0,1.0,1.0, 1.0), alpha);
                }


                return mainCol;
            }
            ENDCG
        }
    }
}
