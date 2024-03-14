Shader "Parker/Texture2D"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Tex ("Texture", 2D) = "white" {}
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

            #define RGBA_BIT 0x1
            #define R_BIT 0x2
            #define G_BIT 0x4
            #define B_BIT 0x8
            #define A_BIT 0x10


            #include "UnityCG.cginc"
            #include "../Includes/common.cginc"

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
            sampler2D _Tex;
            int _ChannelBitmask;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = float4(0, 0, 0, 0);
                if(CHECK_BIT(_ChannelBitmask, RGBA_BIT))
                {
                    col = tex2D(_Tex, i.uv);
                }
                else if(CHECK_BIT(_ChannelBitmask, R_BIT))
                {
                    col.r = tex2D(_Tex, i.uv).r;
                    col.g = col.r;
                    col.b = col.r;
                    col.a = 1;
                }
                else if(CHECK_BIT(_ChannelBitmask, G_BIT))
                {
                    col.g = tex2D(_Tex, i.uv).g;
                    col.r = col.g;
                    col.b = col.g;
                    col.a = 1;
                }
                else if(CHECK_BIT(_ChannelBitmask, B_BIT))
                {
                    col.b = tex2D(_Tex, i.uv).b;
                    col.r = col.b;
                    col.g = col.b;
                    col.a = 1;
                }
                else if(CHECK_BIT(_ChannelBitmask, A_BIT))
                {
                    col.a = tex2D(_Tex, i.uv).a;
                    col.r = col.a;
                    col.g = col.a;
                    col.b = col.a;
                    col.a = 1;
                }

                return col;
            }
            ENDCG
        }
    }
}
