#ifndef _RAYCAST_CGINC_
#define _RAYCAST_CGINC_

#include "./common.cginc"

//Raycast Parameters
sampler2D _BlueNoiseTexture;
int _RaycastBitMask;
float _RayMarchSteps;
float _RayMarchDistanceOffsetWeight;
float _RayOffsetWeight;

//Raycast Bitmask
#define WHITE_NOISE_OFFSET 0x1
#define NROOKS_OFFSET 0x2
#define UNIFORM_OFFSET 0x4
#define MARCH_OFFSET 0x8

//Macros
#define CHECK_RAYCAST_BITMASK(bit) (((_RaycastBitMask) & (bit)) != 0)

//Struct Definitions
struct Ray {
    float3 origin;
    float3 direction;
};

struct Sphere {
    float3 center;
    float radius;
};

struct SphereHit {
    int hit;
    float enter;
    float exit;
};

float4 sampleBlueNoise(float2 uv){
    float2 pixel = uv * float2(_ScreenParams.x / 256.0, _ScreenParams.y / 256.0) + 0.5;
    float4 blueNoiseSample = tex2D(_BlueNoiseTexture, pixel);
    return blueNoiseSample;
}

float updateMarchOffset(float offset, float step){
    return frac(offset + (step) / (_RayMarchSteps));
}

float3 getCameraOriginInWorld(){
    //Transform Camera Position to world space;
    float3 camOrigin = float3(0,0,0);
    float4 camWorldHomog = mul(unity_CameraToWorld, float4(camOrigin, 1.0));
    float3 camWorld = camWorldHomog.xyz / camWorldHomog.w;

    return camWorld;
}

float3 getCameraOriginInWorldScaled(){
    //Transform Camera Position to world space;
    float3 camOrigin = float3(0,0,0);
    float4 camWorldHomog = mul(unity_CameraToWorld, float4(camOrigin, 1.0));
    float3 camWorld = camWorldHomog.xyz / camWorldHomog.w;

    //Put camera on earth surface
    camWorld.y += EARTH_RADIUS;

    return camWorld;
}

float3 getPixelRayInWorld(float2 uv){

    //Move uv to center
    uv += float2((1.0 / _ScreenParams.x) * 0.5 , (1.0 / _ScreenParams.y) * 0.5);

    //Offset within pixel
    float2 offset = float2(0.0, 0.0);
    if(CHECK_RAYCAST_BITMASK(WHITE_NOISE_OFFSET)){
        offset += (whiteNoisePixelOffsets[_NumSuperSamples - 1][_Frame % _NumSuperSamples] - 0.5) * float2(1.0 / _ScreenParams.x, 1.0 / _ScreenParams.y);
    }
    else if(CHECK_RAYCAST_BITMASK(NROOKS_OFFSET)){
        offset += (nrooksPixelOffset[_NumSuperSamples - 1][_Frame % _NumSuperSamples] - 0.5) * float2(1.0 / _ScreenParams.x, 1.0 / _ScreenParams.y);
    }
    else if(CHECK_RAYCAST_BITMASK(UNIFORM_OFFSET)){
        offset += (uniformPixelOffsets[_NumSuperSamples - 1][_Frame % _NumSuperSamples] - 0.5) * float2(1.0 / _ScreenParams.x, 1.0 / _ScreenParams.y);
    }
    offset *= _RayOffsetWeight;
    uv += offset;

    //Convert to screen space uv (-1 - 1)
    uv = remap_f2(uv, 0, 1, -1, 1);

    //Account for aspect ratio and FOV
    uv *= tan_d(_CameraFOV * 0.5);
    uv.x *= _CameraAspect;

    //Get ray
    float3 ray = normalize(float3(uv.x, uv.y, 1.0));

    //Transform ray to world space
    float4 rayWorldHomog = mul(unity_CameraToWorld, float4(ray, 0.0));
    float3 rayWorld = normalize(rayWorldHomog.xyz);

    return rayWorld;
}

Ray getRayFromUV(float2 uv){
    Ray ray;
    ray.origin = getCameraOriginInWorld();
    ray.direction = getPixelRayInWorld(uv);
    return ray;
}

SphereHit raySphereIntersect(Ray ray, Sphere sphere){
    SphereHit hit = {0, 0.0, 0.0};
    float3 oc = ray.origin - sphere.center;
    float b = 2. * dot(oc, ray.direction);
    float c = dot(oc, oc) - sphere.radius * sphere.radius;
    float d = b * b - 4. * c;

    if(d >= 0.0){
        float sqrtD = sqrt(d);
        float t0 = (-b - sqrtD) * 0.5;
        float t1 = (-b + sqrtD) * 0.5;
        if(t0 >= 0.0){
            hit.hit = 1;
            hit.enter = t0;
            hit.exit = t1;
        }
        else if (t1 >= 0.0){
            hit.hit = 1;
            hit.enter = t1;
            hit.exit = t0;
        }
    }
    return hit;
}

float3 getMarchPosition(Ray ray, SphereHit hit, float step, float distPerStep, float offset){
    float3 pos = ray.origin + ray.direction * (hit.enter + step * distPerStep);
    if(CHECK_RAYCAST_BITMASK(MARCH_OFFSET)){
        pos = pos + ray.direction * frac(((offset) * distPerStep * _RayMarchDistanceOffsetWeight));
    }
    return pos;
}

#endif