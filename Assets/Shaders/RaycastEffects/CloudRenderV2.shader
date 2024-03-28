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

            float getHeightFract(float3 p){
                p.y -= EARTH_RADIUS;
                return (p.y - _AtmosphereLow) / (_AtmosphereHigh - _AtmosphereLow);
            }

            float sampleDensity(float3 samplePos){
                return tex2D(_CloudMap, samplePos.xz).r * tex2D(_CloudHeightGradient,float2(0.0, samplePos.y)).r;
                // return tex2D(_CloudMap, samplePos.xz).r;
            }

            float marchTowardsLight(float3 pos){
                Ray ray = {pos.xyz, normalize(float3(1, 1, 0))};
                float distPerStep = 10.0; //idk about this
                float totalDensity = 0;
                float totalDist = 0;
                SphereHit hit = {0, 0, 0};
                [unroll(5)]
                for(int i = 0; i < 5; i++){
                    float3 currPos;
                    currPos = getMarchPosition(ray, hit, i, distPerStep, 0);
                    float cloudDensity = sampleDensity(currPos);

                    totalDensity += cloudDensity;
                    totalDist += distPerStep;
                }
                return  exp(-totalDensity * totalDist);
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
                float distPerStep = (_AtmosphereHigh - _AtmosphereLow) / _RayMarchSteps;
                SphereHit lowerAtmosphereHit = raySphereIntersect(ray, lowerAtmosphere);
                SphereHit upperAtmosphereHit = raySphereIntersect(ray, upperAtmosphere);

                float currRayDist = 0;
                if (lowerAtmosphereHit.hit && lowerAtmosphereHit.enter < MAX_VIEW_DISTANCE)
                {
                    float3 enterPos = ray.origin + ray.direction * lowerAtmosphereHit.enter;
                    float3 exitPos = ray.origin + ray.direction * upperAtmosphereHit.enter;
                    float density = 0;
                    float distance = 0;
                    float3 color = float3(0,0,0);
                    float3 sunColor = float3(1,1,1);
                    [unroll(10)]
                    for(int rayMarchStep = 0; rayMarchStep < _RayMarchSteps; rayMarchStep++){
                        float3 pos;
                        pos = getMarchPosition(ray, lowerAtmosphereHit, rayMarchStep, distPerStep, distanceOffset);
                        float3 samplePos = remap_f3(pos, 0, _NoiseTiling, 0, 1);
                        samplePos.y = getHeightFract(pos);
                        density += sampleDensity(samplePos) * distPerStep;
                        distance += distPerStep;
                        color += marchTowardsLight(pos) * float3(1,1,1) * exp(-distance * density);
                    }
                    float alpha = 1 - exp(-distance * density);
                    return lerp(mainCol, float4(color, 1.0), min(density, 1));

           
                    
                }
                return mainCol;
            }
            ENDCG
        }
    }
}
