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
            sampler3D _LowFrequencyCloudNoise;
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
            float _CloudFalloff;
            int _LightSteps;
            int _UseACES;
            float _LightMarchDistance;
            float _ShadowDensity;
            float3 _ExtinctionColor;

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

            float3 ACESFilm(float3 x) {
                float a = 2.51f;
                float b = 0.03f;
                float c = 2.43f;
                float d = 0.59f;
                float e = 0.14f;
                return clamp((x*(a*x+b))/(x*(c*x+d)+e), 0.0, 1.0);
            }

            float calculateDimensionalProfile(SphereHit hit){
                return (hit.exit - hit.enter) * _Density;
            }

            float calculateDensity(float3 samplePos, float dimensionalProfile){
                float3 noisePos;
                noisePos = remap_f3(samplePos.xyz, 0, _NoiseTiling, 0.0, 1.0);
                float4 lowFreqNoise = tex3D(_LowFrequencyCloudNoise, noisePos);
                float lowFreqFBM = (lowFreqNoise.g * 0.625) + (lowFreqNoise.b * 0.25) + (lowFreqNoise.a * 0.125);
                float noise = remap_f(lowFreqNoise.r, (1.0 - lowFreqFBM), 1.0, 0.0, 1.0);
                // return saturate(noise - (1.0 - (dimensionalProfile * _CloudFalloff)));
                return dimensionalProfile;
            }

            float3 multipleOctaveScattering(float density, float cosTheta) {
                float attenuation = 0.2;
                float contribution = 0.2;
                float phaseAttenuation = 0.5;

                float a = 1.0;
                float b = 1.0;
                float c = 1.0;
                float g = 0.85;
                float scatteringOctaves = 4.0;

                float luminance = 0;

                for(float i = 0; i < scatteringOctaves; i++){
                    float phaseFunction = phase(0.3 * c, cosTheta);
                    float3 beers = exp(-density * (_AbsorptionCoefficient + _ScatteringCoefficient) * a);

                    luminance += b * phaseFunction * beers;

                    a *= attenuation;
                    b *= contribution;
                    c *= (1.0 - phaseAttenuation);
                }

                return luminance;
            }

            float3 calculateLightEnergy(float3 samplePos, Sphere sphere, float cosTheta, v2f i){

                        Ray lightRay = {samplePos, _LightDir};
                        SphereHit lightHit = raySphereIntersect(lightRay, sphere);
                        float lightStepSize = (_LightMarchDistance / _LightSteps) * 0.15f;
                        float currDist = 0;
                        float tau = 0;
                        [unroll(10)]
                        for(int l = 0; l < _LightSteps; l++){
                            float lightT = lightStepSize * (l + whiteNoise_2D(i.uv, 0));
                            if(lightT > lightHit.exit) break;
                            float3 lightSamplePos = lightRay.origin + lightRay.direction * currDist;
                            float dimensionalProfile = calculateDimensionalProfile(lightHit);
                            float lightDensity = calculateDensity(lightSamplePos, dimensionalProfile);
                            tau += (lightDensity * lightStepSize);
                            lightStepSize *= 1.45f;
                            currDist += lightStepSize;
                        }
                        float3 lightAttenuation = exp(-(_AbsorptionCoefficient + _ScatteringCoefficient) * (tau) * _ShadowDensity);
                        // float lightAttenuation = multipleOctaveScattering(tau, cosTheta);
                        float phaseTerm = phase(_PhaseAsymmetry, cosTheta);

                        //TODO Multipl Scattering

                        return lightAttenuation * phaseTerm;
            }


            fixed4 cloudVolume(v2f i){
                // float4 mainColor = float4(0.572, 0.772, 0.921, 1.0);
                float3 mainColor = tex2D(_MainTex, i.uv).rgb;
                float4 sphereCol = float4(0.8, 0.1, 0.5, 1);
                float3 lightColor = float3(1., 1., 1.);
                Ray ray = getRayFromUV(i.uv, float2(0,0), 0);
                Sphere sphere = {float3(0, 0, 0), _SphereRadius};
                SphereHit hit = raySphereIntersect(ray, sphere);

                if(hit.hit){
                    float stepSize = _StepSize;                
                    int ns = ceil((hit.exit - hit.enter) / stepSize);
                    stepSize = (hit.exit - hit.enter) / ns;

                    float transparency = 1;
                    // float dimensionalProfile = 0;
                    float3 result = float3(.1,.1,.1);
                    float distanceTraveled = 0;

                    [unroll(32)]
                    for(int n = 0; n < ns; n++){

                        float t = hit.enter + stepSize * (n + whiteNoise_2D(i.uv, 0));
                        float3 samplePos = ray.origin + ray.direction * t;
                        float dimensionalProfile = calculateDimensionalProfile(hit);
                        float density = calculateDensity(samplePos, dimensionalProfile);
                        if(density > 0.001){

                            float sampleAttenuation = exp(-(_AbsorptionCoefficient + _ScatteringCoefficient) * density * stepSize);
                            float cosTheta = dot(normalize(ray.direction), normalize(_LightDir));

                            // float3 directLight = lightColor * calculateLightEnergy(samplePos, sphere, cosTheta, i) * _LightIntensity;
                            float directLight = 0;
                            float3 ambientLight = pow(1.0 - dimensionalProfile, 0.5);
                            float3 luminance = directLight + ambientLight;
                            float3 integScatter = density * (luminance - luminance * sampleAttenuation) / density;

                            result += transparency * integScatter;
                            transparency *= sampleAttenuation;
                        }

                        
                    }

                    result = ACESFilm(result);
                    mainColor = ACESFilm(mainColor);
                    return lerp(float4(mainColor, 1.0), float4(result, 1.0), 1.0 - transparency);

                }

                mainColor = ACESFilm(mainColor);
                return float4(mainColor, 1.0); 
            }
           

            fixed4 frag (v2f i) : SV_Target
            {

                // if(_VolumeMode == 0){
                //     return unlitVolume(i);
                // }
                // else if(_VolumeMode == 1){
                //     return simpleLitVolume(i);
                // }
                // else if(_VolumeMode == 2){
                //     return litVolume(i);
                // }
                // else if(_VolumeMode == 3){
                //     return nonHomogeneousVolume(i);
                // }
                // else if(_VolumeMode == 4){
                    return cloudVolume(i);
                //}

                return tex2D(_MainTex, i.uv);
            }
            ENDCG
        }
    }
}
