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
                float4 mainCol = tex2D(_MainTex, i.uv);
                Ray ray = getRayFromUV(i.uv);
                Sphere sphere = { _SphereCenter, _SphereRadius };
                SphereHit hit = raySphereIntersect(ray, sphere);
                float4 col = float4(0, 0, 0, 1);
                if(hit.hit)
                {
                    col = float4(1, 0, 0, 1);
                }

                return lerp(col, mainCol, _BlendFactor);

            }
            ENDCG
        }
    }
}
