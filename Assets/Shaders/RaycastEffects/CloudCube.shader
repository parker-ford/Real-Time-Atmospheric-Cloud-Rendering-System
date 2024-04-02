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

            #define SUN_COLOR float3(1., 1., 1.)
            #define LIGHT_DIR float3(0, 1, 1)

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
            float3 _LightDir;
            float _AbsorptionCoefficient;
            float _StepSize;

           

            fixed4 frag (v2f i) : SV_Target
            {
                // float4 mainColor = tex2D(_MainTex, i.uv);
                // float4 sphereCol = float4(0,1,0,1);
                // float3 lightColor = float3(1.3, 0.3, 0.9);
                // Ray ray = getRayFromUV(i.uv, float2(0,0), 0);
                // Sphere sphere = {float3(0, 0, 0), 1};
                // SphereHit hit = raySphereIntersect(ray, sphere);

                // if(hit.hit){
                //     float dist = abs(hit.exit - hit.enter);
                //     float transmittance = exp(-_AbsorptionCoefficient * dist);

                //     float stepSize = _StepSize;
                //     int ns = ceil((hit.exit - hit.enter) / stepSize);
                //     stepSize = (hit.exit - hit.enter) / ns;

                //     float transparency = 1;
                //     float3 result = float3(0,0,0);

                //     for(int n = 0; n < ns; n++){
                //         float t = hit.exit - stepSize * (n + 0.5);
                //         float3 samplePos = ray.origin + ray.direction * t;
                //         float sampleTransparency = exp(-_AbsorptionCoefficient * stepSize);
                //         transparency *= sampleTransparency;
                //         Ray lightRay = {samplePos, _LightDir};  
                //         SphereHit lightHit = raySphereIntersect(lightRay, sphere);
                        
                //             float lightAttenuation = exp(-_AbsorptionCoefficient * lightHit.exit);
                //             result += lightColor * lightAttenuation * stepSize;
               

                //         result *= sampleTransparency;
                //     }

                //     return mainColor * transparency + float4(result, 1.0);
                // }

                // return mainColor;

                float4 mainColor = tex2D(_MainTex, i.uv);
                float4 sphereCol = float4(0,1,0,1);
                Ray ray = getRayFromUV(i.uv, float2(0,0), 0);
                Sphere sphere = {float3(0, 0, 0), 0.5};
                SphereHit hit = raySphereIntersect(ray, sphere);
                if(hit.inside){
                    return sphereCol;
                }
                return mainColor;
            }
            ENDCG
        }
    }
}
