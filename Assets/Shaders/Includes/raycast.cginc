#ifndef _RAYCAST_CGINC_
#define _RAYCAST_CGINC_

#include "./common.cginc"

//Raycast Parameters
sampler2D _BlueNoiseTexture;
int _RaycastBitMask;
float _RaymarchSteps;
float _RayOffsetWeight;

//Raycast Bitmask
#define WHITE_NOISE_OFFSET 0x1
#define NROOKS_OFFSET 0x2
#define UNIFORM_OFFSET 0x4

//Macros
#define CHECK_RAYMARCH_BITMASK(bit) (((_RaycastBitMask) & (1 << (bit))) != 0)

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
    if(CHECK_RAYMARCH_BITMASK(WHITE_NOISE_OFFSET)){
        offset += (whiteNoisePixelOffsets[_NumSuperSamples - 1][_Frame % _NumSuperSamples] - 0.5) * float2(1.0 / _ScreenParams.x, 1.0 / _ScreenParams.y);
    }
    else if(CHECK_RAYMARCH_BITMASK(NROOKS_OFFSET)){
        offset += (nrooksPixelOffset[_NumSuperSamples - 1][_Frame % _NumSuperSamples] - 0.5) * float2(1.0 / _ScreenParams.x, 1.0 / _ScreenParams.y);
    }
    else if(CHECK_RAYMARCH_BITMASK(UNIFORM_OFFSET)){
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
        hit.hit = 1;
        hit.enter = (-b - sqrt(d)) * 0.5;
        hit.exit = (-b + sqrt(d)) * 0.5;
    }
    return hit;
}

#endif