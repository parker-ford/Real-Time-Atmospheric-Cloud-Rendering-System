#ifndef _RAYCAST_CGINC_
#define _RAYCAST_CGINC_

#include "./common.cginc"

//Raycast Parameters
sampler2D _BlueNoiseTexture;
int _RaycastBitMask;
float _RayMarchSteps;
float _RayMarchDistanceOffsetWeight;
float _PixelOffsetWeight;
float _BlueNoiseOffsetWeight;

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

struct Cube {
    float3 center;
    float3 size;
};

struct CubeHit {
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

float3 getPixelRayInWorld(float2 uv, float2 pixelOffset){

    //Move uv to center
    uv += float2((1.0 / _ScreenParams.x) * 0.5 , (1.0 / _ScreenParams.y) * 0.5);

    //Offset within pixel
    pixelOffset = pixelOffset * (1.0 / _ScreenParams.xy) * _BlueNoiseOffsetWeight;

    //Offset from frame
    float2 frameOffset = float2(0.0, 0.0);
    if(CHECK_RAYCAST_BITMASK(WHITE_NOISE_OFFSET)){
        frameOffset = (whiteNoisePixelOffsets[_NumSuperSamples - 1][_Frame % _NumSuperSamples] - 0.5) * float2(1.0 / _ScreenParams.x, 1.0 / _ScreenParams.y);
    }
    else if(CHECK_RAYCAST_BITMASK(NROOKS_OFFSET)){
        frameOffset = (nrooksPixelOffset[_NumSuperSamples - 1][_Frame % _NumSuperSamples] - 0.5) * float2(1.0 / _ScreenParams.x, 1.0 / _ScreenParams.y);
    }
    else if(CHECK_RAYCAST_BITMASK(UNIFORM_OFFSET)){
        frameOffset = (uniformPixelOffsets[_NumSuperSamples - 1][_Frame % _NumSuperSamples] - 0.5) * float2(1.0 / _ScreenParams.x, 1.0 / _ScreenParams.y);
    }
    frameOffset *= _PixelOffsetWeight;

    float2 offset = pixelOffset + frameOffset;
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

Ray getRayFromUV(float2 uv, float2 pixelOffset){
    Ray ray;
    ray.origin = getCameraOriginInWorld();
    ray.direction = getPixelRayInWorld(uv, pixelOffset);
    return ray;
}

Ray getRayFromUV(float2 uv, float2 pixelOffset, uint scaled){
    Ray ray;
    if(scaled == 1){
        ray.origin = getCameraOriginInWorldScaled();
    }
    else{
        ray.origin = getCameraOriginInWorld();
    }
    ray.direction = getPixelRayInWorld(uv, pixelOffset);
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

CubeHit rayCubeIntersect(Ray ray, Cube cube){
    CubeHit hit = {0, 0.0, 0.0};
    float3 tMin = (cube.center - cube.size * 0.5 - ray.origin) / ray.direction;
    float3 tMax = (cube.center + cube.size * 0.5 - ray.origin) / ray.direction;

    if (tMin.x > tMax.x) { float tmp = tMin.x; tMin.x = tMax.x; tMax.x = tmp; }
    if (tMin.y > tMax.y) { float tmp = tMin.y; tMin.y = tMax.y; tMax.y = tmp; }
    if (tMin.z > tMax.z) { float tmp = tMin.z; tMin.z = tMax.z; tMax.z = tmp; }

    float tEnter = max(max(tMin.x, tMin.y), tMin.z);
    float tExit = min(min(tMax.x, tMax.y), tMax.z);

    if (tEnter < 0.0 || tEnter > tExit) {
        return hit;
    }

    hit.hit = 1;
    hit.enter = tEnter;
    hit.exit = tExit;
    return hit;

}

float3 getMarchPosition(Ray ray, SphereHit hit, float step, float distPerStep, float offset){
    float3 pos = ray.origin + ray.direction * (hit.enter + step * distPerStep);
    float distOffset = 0.0;
    if(CHECK_RAYCAST_BITMASK(MARCH_OFFSET)){
        distOffset += offset * _RayMarchDistanceOffsetWeight;
        distOffset += (float)(_Frame % _NumSuperSamples) / (float)_NumSuperSamples;
        distOffset = frac(distOffset) * distPerStep * _RayMarchDistanceOffsetWeight;
        pos = pos + ray.direction * distOffset;
    }
    return pos;
}

#endif