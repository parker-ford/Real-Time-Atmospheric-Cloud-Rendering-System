Shader "Parker/CloudCube"
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
            sampler3D _Noise;
            float _DensityAbsorption;
            int _CloudCubeMode;
            float _NoiseTiling;

            float sampleCloudDensity(float3 samplePos){
                
                float4 lowFreqNoise = tex3D(_LowFrequencyCloudNoise, samplePos);
                float3 lowFreqFBM = (lowFreqNoise.g * 0.625) + (lowFreqNoise.b * 0.25) + (lowFreqNoise.a * 0.125);
                float baseCloud = remap_f(lowFreqNoise.r, -(1.0 - lowFreqFBM), 1.0, 0.0, 1.0);

                return saturate(baseCloud);
            }

            float4 distanceBeers(v2f i){
                fixed4 mainCol = tex2D(_MainTex, i.uv);
                float4 cubeCol = float4(0.0, 1.0, 0.0, 1.0);
                float4 blueNoiseSample = sampleBlueNoise(i.uv);
                float2 pixelOffset = blueNoiseSample.rg;
                float distanceOffset = blueNoiseSample.b;
                Ray ray = getRayFromUV(i.uv, pixelOffset);
                Cube cube = {float3(0, 0, 0), {2.0,2.0,2.0}};
                CubeHit hit = rayCubeIntersect(ray, cube);
                float density = 0;
                if(hit.hit){
                    float3 enterPos = ray.origin + hit.enter * ray.direction;
                    float3 exitPos = ray.origin + hit.exit * ray.direction;
                    float distance = length(exitPos - enterPos);
                    density = 1 - exp(-distance * _DensityAbsorption);
                }

                return lerp(mainCol, cubeCol, density);
            }

            float4 noiseBeers(v2f i){
                fixed4 mainCol = tex2D(_MainTex, i.uv);
                float4 cubeCol = float4(0.0, 1.0, 0.0, 1.0);
                float4 blueNoiseSample = sampleBlueNoise(i.uv);
                float2 pixelOffset = blueNoiseSample.rg;
                float distanceOffset = blueNoiseSample.b;
                Ray ray = getRayFromUV(i.uv, pixelOffset);
                Cube cube = {float3(0, 0, 0), {2.0,2.0,2.0}};
                CubeHit hit = rayCubeIntersect(ray, cube);
                float density = 0;
                float totalDensity = 0;
                if(hit.hit){
                    float3 enterPos = ray.origin + hit.enter * ray.direction;
                    float3 exitPos = ray.origin + hit.exit * ray.direction;
                    float distance = length(exitPos - enterPos);
                    float distPerStep = distance / _RayMarchSteps;
                    [unroll(20)]
                    for(int currStep = 0; currStep < _RayMarchSteps; currStep++){
                        float3 pos = getMarchPosition(ray, hit, currStep, distPerStep, distanceOffset);
                        float3 samplePos = remap_f3(pos, -_NoiseTiling, _NoiseTiling, 0, 1);
                        totalDensity += tex3D(_Noise, samplePos).r * distPerStep;
                    }
                    density = 1 - exp(-totalDensity * _DensityAbsorption);
                }

                return lerp(mainCol, cubeCol, density);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                if(_CloudCubeMode == 0){
                    return distanceBeers(i);
                }
                if(_CloudCubeMode == 1){
                    return noiseBeers(i);
                }

                return fixed4(1.0, 0.0, 0.0, 1.0);
            }
            ENDCG
        }
    }
}
