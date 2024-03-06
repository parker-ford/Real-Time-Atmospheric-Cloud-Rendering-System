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
            float _SphereRadius;
            float3 _SphereCenter;
            float _BlendFactor;

            fixed4 frag (v2f i) : SV_Target
            {
                float4 blueNoiseSample = sampleBlueNoise(i.uv);
                float rayMarchOffset = blueNoiseSample.b;

                float4 mainCol = tex2D(_MainTex, i.uv);
                Ray ray = getRayFromUV(i.uv);
                Sphere sphere = { _SphereCenter, _SphereRadius };
                SphereHit hit = raySphereIntersect(ray, sphere);
                float4 col = float4(0, 0, 0, 1);
                if(hit.hit)
                {
                    float distPerStep = 1.0 / (_RayMarchSteps - 1.0);
                    float result = 0.0;
                    for(int stp = 0; stp < _RayMarchSteps; stp++, rayMarchOffset = updateMarchOffset(rayMarchOffset, stp)){
                        float3 pos = getMarchPosition(ray, hit, stp, distPerStep, rayMarchOffset);
                        float dist = length(pos - sphere.center);
                        dist = remap_f(dist, 0.0, sphere.radius, 1.0, 0.25);
                        result += (step(0.0, dist) * 0.25);
                        result += (step(0.25, dist) * 0.25);
                        result += (step(0.5, dist) * 0.25);
                        result += (step(0.75, dist) * 0.25);
                        // if(dist < 0.25){
                        //     result += 0.25;
                        // }
                        // else if(dist < 0.5){
                        //     result += 0.5;
                        // }
                        // else if(dist < 0.75){
                        //     result += 0.75;
                        // }
                        // else if(dist < 1.0){
                        //     result += 1.00;
                        // }
                    }
                    result /= _RayMarchSteps;
                    col = float4(result, 0, 0, 1.0);

                }

                return lerp(col, mainCol, _BlendFactor);

            }
            ENDCG
        }
    }
}
