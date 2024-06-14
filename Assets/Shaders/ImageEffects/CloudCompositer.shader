Shader "Hidden/CloudCompositer"
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
            sampler2D _CloudTex;
            sampler2D _CloudMask;
            sampler2D _CloudDepth;

            int _DebugTexture;
            int _DebugColor;


            fixed4 frag (v2f i) : SV_Target
            {
                float3 mainCol = tex2D(_MainTex, i.uv).rgb;
                float3 cloud = tex2D(_CloudTex, i.uv).rgb;
                float mask = saturate(tex2D(_CloudMask, i.uv).r);
                float depth = tex2D(_CloudDepth, i.uv).r;

                float3 col = lerp(mainCol, cloud, (1 - mask));
                col = lerp(col, mainCol, depth);

                if (_DebugTexture == 1)
                {
                    // col = float4(mask, mask, mask, 1);
                    return float4(cloud, 1.0);
                }
                else if (_DebugTexture == 2)
                {
                    return float4(mask, mask, mask, 1);
                }
                else if (_DebugTexture == 3)
                {
                    return float4(depth, depth, depth, 1);
                }

                return float4(col, 1.0);

            }
            ENDCG
        }
    }
}
