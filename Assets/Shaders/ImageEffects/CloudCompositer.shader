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


            float luminance(float3 color) {
                return dot(color, float3(0.299f, 0.587f, 0.114f));
            }

            float3 debugHDR(float3 color) {
                if(color.r > 1.0f || color.g > 1.0f || color.b > 1.0f)
                {
                    return color;
                }

                return float3(0, 0, 0);
            }

            float _P, _HiVal;
            float3 schlick(float3 color){
                float Lin = luminance(color);

                float Lout = (_P * Lin) / (_P * Lin - Lin + _HiVal);

                float3 Cout = color / Lin * Lout;

                return float4(saturate(Cout), 1.0f);
            }

            float _Ldmax;
            float3 ward(float3 color){
                float Lin = luminance(color);

                float m = (1.219f + pow(_Ldmax / 2.0f, 0.4f)) / (1.219f + pow(Lin, 0.4f));
                m = pow(m, 2.5f); 

                float Lout = m / _Ldmax * Lin;

                float3 Cout = color / Lin * Lout;

                return float4(saturate(Cout), 1.0f);
            }

            float3 reinhard(float3 color){
                float Lin = luminance(color);

                float Lout = Lin / (1.0f + Lin);

                float3 Cout = color / Lin * Lout;

                return float4(saturate(Cout), 1.0f);
            }

            float _Cwhite;
            float3 reinhardExtended(float3 color){
                float Lin = luminance(color);

                float Lout = (Lin * (1.0 + Lin / (_Cwhite * _Cwhite))) / (1.0 + Lin);

                float3 Cout = color / Lin * Lout;
                
                return float4(saturate(Cout), 1.0f);
            }

            // float _A, _B, _C, _D, _E, _F, _W;
            // float3 filmicToneMap(float3 color){
            //     return ((color*(_A*color+_C*_B)+_D*_E)/(color*(_A*color+_B)+_D*_F))-_E/_F;
            // }

            float3 ACESFilm(float3 x)
            {
                float a = 2.51f;
                float b = 0.03f;
                float c = 2.43f;
                float d = 0.59f;
                float e = 0.14f;
                return saturate((x*(a*x+b))/(x*(c*x+d)+e));
            }

            

            float3 filmic(float3 color){
                float ExposureBias = 1.0f;
                float3 curr = ExposureBias * ACESFilm(color);

                float3 whiteScale = 1.0f / ACESFilm(float3(10.0, 10.0, 10.0));

                float3 Cout = curr * whiteScale;
                // float3 Cout = curr;
                
                return float4(saturate(Cout), 1.0f);
            }

            float _M, _a, _m, _l, _c, _b;

            float3 uchimura(float3 color){
                float l0 = ((_M - _m) * _l) / _a;
                float S0 = _m + l0;
                float S1 = _m + _a * l0;
                float C2 = (_a * _M) / (_M - S1);
                float CP = -C2 / _M;

                float3 w0 = 1.0f - smoothstep(float3(0.0f, 0.0f, 0.0f), float3(_m, _m, _m), color);
                float3 w2 = step(float3(_m + l0, _m + l0, _m + l0), color);
                float3 w1 = float3(1.0f, 1.0f, 1.0f) - w0 - w2;

                float3 T = _m * pow(color / _m, _c) + _b;
                float3 L = _m + _a * (color - _m);
                float3 S = _M - (_M - S1) * exp(CP * (color - S0));

                float3 Cout = T * w0 + L * w1 + S * w2;
                
                return float4(saturate(Cout), 1.0f);
            }

            float3 narkowiczACES(float3 color){
                float3 Cout = (color*(2.51f*color+0.03f))/(color*(2.43f*color+0.59f)+0.14f);

                return float4(saturate(Cout), 1.0f);
            }


            static const float3x3 ACESInputMat =
            {
                {0.59719, 0.35458, 0.04823},
                {0.07600, 0.90834, 0.01566},
                {0.02840, 0.13383, 0.83777}
            };

            static const float3x3 ACESOutputMat =
            {
                { 1.60475, -0.53108, -0.07367},
                {-0.10208,  1.10813, -0.00605},
                {-0.00327, -0.07276,  1.07602}
            };

            float3 RRTAndODTFit(float3 v) {
                float3 a = v * (v + 0.0245786f) - 0.000090537f;
                float3 b = v * (0.983729f * v + 0.4329510f) + 0.238081f;
                return a / b;
            }

            float3 hillACES(float3 color){
                color = mul(ACESInputMat, color);

                color = RRTAndODTFit(color);

                float3 Cout = mul(ACESOutputMat, color);

                return float4(saturate(Cout), 1.0f);
            }

            int _ToneMapper;
            float3 toneMapper(float3 color){
                if(_ToneMapper == 1)
                {
                    return debugHDR(color);
                }
                else if(_ToneMapper == 2)
                {
                    return schlick(color);
                }
                else if(_ToneMapper == 3)
                {
                    return ward(color);
                }
                else if(_ToneMapper == 4)
                {
                    return reinhard(color);
                }
                else if(_ToneMapper == 5)
                {
                    return reinhardExtended(color);
                }
                else if(_ToneMapper == 6)
                {
                    return filmic(color);
                }
                else if(_ToneMapper == 7)
                {
                    return uchimura(color);
                }
                else if(_ToneMapper == 8)
                {
                    return narkowiczACES(color);
                }
                else if(_ToneMapper == 9)
                {
                    return hillACES(color);
                }

                return saturate(color);
            }

            float3 _Exposure, _Contrast, _Brightness, _Saturation, _MidPoint;
            float3 colorCorrector(float3 color){
                color = max(0.0f, color * _Exposure);
                color = max(0.0f, _Contrast * (color - _MidPoint) + _MidPoint + _Brightness);
                color = max(0.0f, lerp(luminance(color), color, _Saturation));
                return color;
            }

            float _Gamma;
            float3 gammaCorrector(float3 color){
                return pow(color, _Gamma);
            }


            // float3 LinearToSrgb(float3 linearRGB) {
            //     float3 srgb;
            //     srgb = pow(linearRGB, 1.0 / 2.4);
            //     srgb = max(1.055 * srgb - 0.055, 0.0);
            //     return srgb;
            // }

            // float3 sRGBToACEScg(float3 srgb) {
            //     // Matrix to convert from sRGB to ACEScg
            //     const float3x3 sRGB_to_ACEScg = {
            //         {0.713, 0.293, -0.06},
            //         {-0.165, 1.165, 0.045},
            //         {0.128, 0.05, 0.892}
            //     };

            //     return mul(sRGB_to_ACEScg, srgb);
            // }

            // // Main conversion function from linear RGB to ACEScg
            // float3 ConvertToACES(float3 linearRGB) {
            //     // Convert linear RGB to sRGB first
            //     float3 srgb = LinearToSrgb(linearRGB);
                
            //     // Then convert sRGB to ACEScg
            //     return sRGBToACEScg(srgb);
            // }

            // float3 ReinhardModified(float3 color) {
            //     color /= (color + 1.0);
            //     color.b = pow(color.b, 0.9); // Decrease the gamma for the blue channel to make it more vibrant
            //     return color;
            // }

            // float3 LottesToneMapping(float3 color) {
            //     float3 x = max(0, color - 0.004);
            //     float3 result = (x*(6.2*x + 0.5)) / (x*(6.2*x + 1.7) + 0.06);
            //     result.b = pow(result.b, 0.85); // More vibrant blues
            //     return result;
            // }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 mainCol = tex2D(_MainTex, i.uv).rgb;
                float3 cloud = tex2D(_CloudTex, i.uv).rgb;
                float mask = saturate(tex2D(_CloudMask, i.uv).r);
                float depth = tex2D(_CloudDepth, i.uv).r;

                float3 col = lerp(mainCol, cloud, (1 - mask));
                col = lerp(col, mainCol, depth);
                col = colorCorrector(col);
                col = toneMapper(col);
                col = gammaCorrector(col);

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
