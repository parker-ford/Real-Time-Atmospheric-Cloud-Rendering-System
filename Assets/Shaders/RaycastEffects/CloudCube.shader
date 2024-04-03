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
            #include "../Includes/noise.cginc"

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
            sampler3D _DensityField;
            float3 _LightDir;
            float _AbsorptionCoefficient;
            float _ScatteringCoefficient;
            float _Density;
            float _StepSize;
            float _SphereRadius;
            float _PhaseAsymmetry;
            int _VolumeMode;
            float _LightIntensity;
            float _NoiseTiling;
            float _TransmissionCutoff;

            float phase(float g, float cosTheta){
                return 1.0 / (4.0 * PI) * (1.0 - g * g) / pow(1.0 + g * g - 2.0 * g * cosTheta, 1.5);
            }


            fixed4 unlitVolume(v2f i){
                float4 mainColor = float4(0.572, 0.772, 0.921, 1.0);
                float4 sphereCol = float4(0.8, 0.1, 0.5, 1);
                Ray ray = getRayFromUV(i.uv, float2(0,0), 0);
                Sphere sphere = {float3(0, 0, 0), _SphereRadius};
                SphereHit hit = raySphereIntersect(ray, sphere);
                if(hit.hit){
                    float dist = abs(hit.exit - hit.enter);
                    float transmittance = exp(-_AbsorptionCoefficient * dist);
                    return lerp(mainColor, sphereCol, 1.0 - transmittance);                
                }


                return mainColor;
            }

            fixed4 simpleLitVolume(v2f i){
                float4 mainColor = float4(0.572, 0.772, 0.921, 1.0);
                float4 sphereCol = float4(0.8, 0.1, 0.5, 1);
                float3 lightColor = float3(1.3, 0.3, 0.9);
                Ray ray = getRayFromUV(i.uv, float2(0,0), 0);
                Sphere sphere = {float3(0, 0, 0), _SphereRadius};
                SphereHit hit = raySphereIntersect(ray, sphere);

                if(hit.hit){
                    float dist = abs(hit.exit - hit.enter);
                    float transmittance = exp(-_AbsorptionCoefficient * dist);

                    float stepSize = _StepSize;                
                    int ns = ceil((hit.exit - hit.enter) / stepSize);
                    stepSize = (hit.exit - hit.enter) / ns;

                    float transparency = 1;
                    float3 result = float3(0,0,0);

                    for(int n = 0; n < ns; n++){
                        float t = hit.enter + stepSize * (n + 0.5);
                        float3 samplePos = ray.origin + ray.direction * t;

                        float sampleTransparency = exp(-_AbsorptionCoefficient * stepSize);
                        transparency *= sampleTransparency;

                        Ray lightRay = {samplePos, _LightDir};
                        SphereHit lightHit = raySphereIntersect(lightRay, sphere);
                        float lightAttenuation = exp(-_AbsorptionCoefficient * lightHit.exit);

                        result += transparency * lightColor * lightAttenuation * stepSize;
                    }

                    return lerp(mainColor, float4(result, 1.0), 1.0 - transparency);

                }

                return mainColor; 
            }

            fixed4 litVolume(v2f i){
                float4 mainColor = float4(0.572, 0.772, 0.921, 1.0);
                float4 sphereCol = float4(0.8, 0.1, 0.5, 1);
                float3 lightColor = float3(1.3, 0.3, 0.9);
                Ray ray = getRayFromUV(i.uv, float2(0,0), 0);
                Sphere sphere = {float3(0, 0, 0), _SphereRadius};
                SphereHit hit = raySphereIntersect(ray, sphere);

                if(hit.hit){
                    float stepSize = _StepSize;                
                    int ns = ceil((hit.exit - hit.enter) / stepSize);
                    stepSize = (hit.exit - hit.enter) / ns;

                    float transparency = 1;
                    float3 result = float3(0,0,0);

                    for(int n = 0; n < ns; n++){
                        float t = hit.enter + stepSize * (n + 0.5);
                        float3 samplePos = ray.origin + ray.direction * t;
                        float density = _Density;

                        float sampleAttenuation = exp(-(_AbsorptionCoefficient + _ScatteringCoefficient) * density * stepSize);
                        transparency *= sampleAttenuation;

                        Ray lightRay = {samplePos, _LightDir};
                        SphereHit lightHit = raySphereIntersect(lightRay, sphere);
                        float lightAttenuation = exp(-(_AbsorptionCoefficient + _ScatteringCoefficient) * density * lightHit.exit);

                        float cosTheta = dot(normalize(ray.direction), normalize(lightRay.direction));
                        // return float4(cosTheta, cosTheta, cosTheta, 1.0);
                        float phaseTerm = phase(_PhaseAsymmetry, cosTheta);
                        //return float4(phaseTerm, phaseTerm, phaseTerm, 1.0);

                        result += transparency * lightColor * phaseTerm * lightAttenuation * _ScatteringCoefficient * density * stepSize * _LightIntensity;
                    }

                    return lerp(mainColor, float4(result, 1.0), 1.0 - transparency);

                }

                return mainColor; 
            }

            fixed4 nonHomogeneousVolume(v2f i){
                float4 mainColor = float4(0.572, 0.772, 0.921, 1.0);
                float4 sphereCol = float4(0.8, 0.1, 0.5, 1);
                float3 lightColor = float3(1.3, 0.3, 0.9);
                Ray ray = getRayFromUV(i.uv, float2(0,0), 0);
                Sphere sphere = {float3(0, 0, 0), _SphereRadius};
                SphereHit hit = raySphereIntersect(ray, sphere);

                if(hit.hit){
                    float stepSize = _StepSize;                
                    int ns = ceil((hit.exit - hit.enter) / stepSize);
                    stepSize = (hit.exit - hit.enter) / ns;

                    float transparency = 1;
                    float3 result = float3(0,0,0);

                    [unroll(32)]
                    for(int n = 0; n < ns; n++){
                        float t = hit.enter + stepSize * (n + whiteNoise_2D(i.uv, 0));
                        float3 samplePos = ray.origin + ray.direction * t;
                        float density = tex3D(_DensityField, remap_f3(samplePos, 0, _NoiseTiling, 0.0, 1.0)).r;

                        float sampleAttenuation = exp(-(_AbsorptionCoefficient + _ScatteringCoefficient) * density * stepSize);
                        transparency *= sampleAttenuation;

                        Ray lightRay = {samplePos, _LightDir};
                        SphereHit lightHit = raySphereIntersect(lightRay, sphere);
                        float lightStepSize = 0.3;
                        float tau = 0;
                        for(int l = 0; l < 5; l++){
                            float lightT = lightStepSize * (l + whiteNoise_2D(i.uv, 0));
                            if(lightT > lightHit.exit) break;
                            float3 lightSamplePos = lightRay.origin + lightRay.direction * lightT;
                            float lightDensity = tex3D(_DensityField, remap_f3(lightSamplePos, 0, _NoiseTiling, 0.0, 1.0)).r;
                            tau += lightDensity;
                        }
                        // float lightAttenuation = exp(-(_AbsorptionCoefficient + _ScatteringCoefficient) * density * lightHit.exit);
                        float lightAttenuation = exp(-(_AbsorptionCoefficient + _ScatteringCoefficient) * tau * lightStepSize);

                        float cosTheta = dot(normalize(ray.direction), normalize(lightRay.direction));
                        float phaseTerm = phase(_PhaseAsymmetry, cosTheta);

                        result += transparency * lightColor * phaseTerm * lightAttenuation * _ScatteringCoefficient * density * stepSize * _LightIntensity;
                    }

                    if(transparency > _TransmissionCutoff){
                        return mainColor;
                    }

                    return lerp(mainColor, float4(result, 1.0), 1.0 - transparency);

                }

                return mainColor; 
            }
           

            fixed4 frag (v2f i) : SV_Target
            {

                if(_VolumeMode == 0){
                    return unlitVolume(i);
                }
                else if(_VolumeMode == 1){
                    return simpleLitVolume(i);
                }
                else if(_VolumeMode == 2){
                    return litVolume(i);
                }
                else if(_VolumeMode == 3){
                    return nonHomogeneousVolume(i);
                }

                return tex2D(_MainTex, i.uv);
            }
            ENDCG
        }
    }
}
