Shader "Parker/TemporalAntiAliasing"
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
            sampler2D _FrameTex;
            int _NumSuperSamples;
            int _Frame;
            int _Mode;


            fixed4 frag (v2f i) : SV_Target
            {
                //Before frame threshold
                if(_Frame < _NumSuperSamples){
                    return tex2D(_MainTex, i.uv) + (tex2D(_FrameTex, i.uv) / (float)_NumSuperSamples);
                }
                else{
                    //Adding
                    if(_Mode == 1){
                        return tex2D(_MainTex, i.uv) + (tex2D(_FrameTex, i.uv) / _NumSuperSamples);
                    }
                    //Subtracting
                    else{
                        return tex2D(_MainTex, i.uv) - (tex2D(_FrameTex, i.uv) / _NumSuperSamples);
                    }
                }
            }
            ENDCG
        }
    }
}
