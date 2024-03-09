Shader "Parker/RaycastSphere"
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
            sampler2D _TestTex;
            float _SphereRadius;
            float3 _SphereCenter;
            float3 _SphereCenter2;
            float _BlendFactor;
            float4 _Color;

            float4 intersectBoundarySphere(v2f i){
                float4 blueNoiseSample = sampleBlueNoise(i.uv);
                float rayMarchOffset = blueNoiseSample.b;
                float2 pixelOffset = blueNoiseSample.rg - 0.5;

                float4 mainCol = tex2D(_MainTex, i.uv);
                Ray ray = getRayFromUV(i.uv, pixelOffset);
                Sphere sphere = { _SphereCenter, _SphereRadius };
                SphereHit hit = raySphereIntersect(ray, sphere);
                float4 color = float4(0, 0, 0, 1);
                if(hit.hit)
                {
                    float distPerStep = 1.0 / (_RayMarchSteps - 1.0);
                    for(int stp = 0; stp < _RayMarchSteps; stp++){
                        float3 pos = getMarchPosition(ray, hit, stp, distPerStep, rayMarchOffset);
                        float distToCenter = length(_SphereCenter - pos);
                        if(distToCenter < _SphereRadius * 0.2){
                            color += float4(1, 0, 0, 1);
                        }
                        else if(distToCenter < _SphereRadius * 0.4){
                            color += float4(0, 1, 0, 1);
                        }
                        else if(distToCenter < _SphereRadius * 0.6){
                            color += float4(0, 0, 1, 1);
                        }
                        else if(distToCenter < _SphereRadius * 0.8){
                            color += float4(1, 0, 1, 1);
                        }
                        else{
                            color += float4(0, 1, 1, 1);
                        }
                        // rayMarchOffset = updateMarchOffset(rayMarchOffset, stp);
                    }
                    color /= _RayMarchSteps;
                    return color;
                }

                // return lerp(mainCol, _Color, result);
                return float4(0, 0, 0, 0);
            }

            float4 intersectTextureSphere(v2f i){
                float4 blueNoiseSample = sampleBlueNoise(i.uv);
                float rayMarchOffset = blueNoiseSample.b;
                float2 pixelOffset = blueNoiseSample.rg - 0.5;

                float4 mainCol = tex2D(_MainTex, i.uv);
                Ray ray = getRayFromUV(i.uv, pixelOffset);
                Sphere sphere = { _SphereCenter2, _SphereRadius };
                SphereHit hit = raySphereIntersect(ray, sphere);
                float4 col = float4(0, 0, 0, 1);
                float result = 0.0;
                if(hit.hit)
                {           
                    float3 p = ray.origin + hit.enter * ray.direction;
                    float3 n = (p - _SphereCenter2);
                    float2 samplePos = remap_f2(n.xy, -_SphereRadius, _SphereRadius, 0, 1);
                    return tex2D(_TestTex, samplePos);
                }


                return float4(0, 0, 0, 0);

            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 mainCol = tex2D(_MainTex, i.uv);
                float4 col = intersectBoundarySphere(i) + intersectTextureSphere(i);
                return lerp(mainCol, col, col.a);
            }
            ENDCG
        }
    }
}
