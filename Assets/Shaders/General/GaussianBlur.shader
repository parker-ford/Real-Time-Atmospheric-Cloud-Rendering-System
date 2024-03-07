Shader "Parker/GaussianBlur"
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
            int _Mode;

            float4 blur3x3(v2f i){
                float weights3x3[9] = { 1.0/16, 2.0/16, 1.0/16,
                                     2.0/16, 4.0/16, 2.0/16,
                                     1.0/16, 2.0/16, 1.0/16 };

                fixed4 color = fixed4(0,0,0,0);
                int index = 0;
                for (int x = -1; x <= 1; x++){
                    for (int y = -1; y <= 1; y++){
                        color += weights3x3[index] * tex2D(_MainTex, i.uv + float2(x, y) / _ScreenParams.xy);
                        index++;
                    }
                }

                return color;
            }

            float4 blur5x5(v2f i){
                float weights5x5[25] = { 1.0/273,  4.0/273,  7.0/273,  4.0/273, 1.0/273,
                      4.0/273, 16.0/273, 26.0/273, 16.0/273, 4.0/273,
                      7.0/273, 26.0/273, 41.0/273, 26.0/273, 7.0/273,
                      4.0/273, 16.0/273, 26.0/273, 16.0/273, 4.0/273,
                      1.0/273,  4.0/273,  7.0/273,  4.0/273, 1.0/273 };

                fixed4 color = fixed4(0,0,0,0);
                int index = 0;
                for (int x = -2; x <= 2; x++){
                    for (int y = -2; y <= 2; y++){
                        color += weights5x5[index] * tex2D(_MainTex, i.uv + (float2(x, y)  / _ScreenParams.xy));
                        index++;
                    }
                }

                return color;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                if(_Mode == 0){
                    return blur3x3(i);
                } else {
                    return blur5x5(i);
                }
            }
            ENDCG
        }
    }
}
