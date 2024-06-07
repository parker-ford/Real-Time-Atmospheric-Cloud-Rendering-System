#ifndef _NOISE_CGINC_
#define _NOISE_CGINC_


#include "./common.cginc"

int seedGen_ui3(int3 input){
    int seed1 = input.x * 2654435761u;
    int seed2 = input.y * 2246822519u;
    int seed3 = input.z * 3266489917u;

    return seed1 + seed2 + seed3;
}

int seedGen_ui2(int2 input){
    int seed1 = input.x * 2654435761u;
    int seed2 = input.y * 2246822519u;

    return seed1 + seed2;
}

float2 map_f2(float2 v, float cellSize){
    float i = 1.0 / cellSize;
    float2 _v = float2(0,0);
    _v.x = remap_f(v.x, 0.0, i, 0.0, 1.0);
    _v.y = remap_f(v.y, 0.0, i, 0.0, 1.0);
    return _v;
}


float2 gradientVector_2D(float2 input){

    //TODO: Maybe make more gradient vectors
    float2 vectors[8] = {
        float2(1.0, 1.0),
        float2(1.0, -1.0),
        float2(-1.0, 1.0),
        float2(-1.0, -1.0),
        float2(1.0, 0.0),
        float2(0.0, -1.0),
        float2(0.0, 1.0),
        float2(-1.0, 0.0),
    };

    int seed = seedGen_ui2(int2(input.x * _ScreenParams.x, input.y * _ScreenParams.y));
    int r = pcgHash_ui(seed);
    r = pcgHash_ui(r);
    float2 v = vectors[r & 7];

    return v;
}

float3 gradientVector_3D(float3 input){
    float3 vectors[12] = {
        float3(1.0, 1.0, 0.0),
        float3(-1.0, 1.0, 0.0),
        float3(1.0, -1.0, 0.0),
        float3(-1.0, -1.0, 0.0),
        float3(1.0, 0.0, 1.0),
        float3(-1.0, 0.0, 1.0),
        float3(1.0, 0.0, -1.0),
        float3(-1.0, 0.0, -1.0),
        float3(0.0, 1.0, 1.0),
        float3(0.0, -1.0, 1.0),
        float3(0.0, 1.0, -1.0),
        float3(0.0, -1.0, -1.0)
    };

    //TODO: May need to fix this. Assumes all dimensions are the same
    uint seed = seedGen_ui3(uint3(input.x * _ScreenParams.x, input.y * _ScreenParams.x, input.z * _ScreenParams.x));
    uint r = pcgHash_ui(seed);
    r = pcgHash_ui(r);

    float3 v = vectors[r % 12];

    return v;
}

float fade(float x){
    return ((6.*x - 15.)*x + 10.)*x*x*x;
}

float perlinNoise_2D(float2 p, float cellSize) {

    //Interval between cells
    float i = 1.0 / cellSize;

    //Cell that this pixel lies in
    float2 id = floor(p * cellSize) / cellSize;

    //Cordinates of cell corners
    float2 tl = float2(id.x, id.y);
    float2 tr = float2(id.x + i, id.y);;
    float2 bl = float2(id.x, id.y + i);
    float2 br = float2(id.x + i, id.y + i);

    //Wrap around
    tl = modulo(tl, float2(1,1));
    tr = modulo(tr, float2(1,1));
    bl = modulo(bl, float2(1,1));
    br = modulo(br, float2(1,1));

    //Vector from corners of cell to point
    float2 v_tl = remap_f2(float2(p.x - id.x, p.y - id.y), 0.0, i, 0.0, 1.0);
    float2 v_tr = remap_f2(float2(p.x - id.x - i, p.y - id.y), 0.0, i, 0.0, 1.0);
    float2 v_bl = remap_f2(float2(p.x - id.x, p.y - id.y - i), 0.0, i, 0.0, 1.0);
    float2 v_br = remap_f2(float2(p.x - id.x - i, p.y - id.y - i), 0.0, i, 0.0, 1.0);

    //Gradient vectors at each cell corner
    float2 gv_tl = gradientVector_2D(tl);
    float2 gv_tr = gradientVector_2D(tr);
    float2 gv_bl = gradientVector_2D(bl);
    float2 gv_br = gradientVector_2D(br);

    //Fade value
    float fx = fade((p.x * cellSize) - floor(p.x * cellSize));
    float fy = fade((p.y * cellSize) - floor(p.y * cellSize));

    //Dot product of corner gradient and vector to point
    float dot_tl = dot(v_tl, gv_tl);
    float dot_tr = dot(v_tr, gv_tr);
    float dot_bl = dot(v_bl, gv_bl);
    float dot_br = dot(v_br, gv_br);

    //Bilinear interpolation
    float n_t = lerp(dot_tl, dot_tr, fx);
    float n_b = lerp(dot_bl, dot_br, fx);
    float n = lerp(n_t, n_b, fy);

    return n;
}

float perlinNoise_2D(float2 p, float cellSize, int f) {

    //Interval between cells
    float i = 1.0 / cellSize;

    //Cell that this pixel lies in
    float2 id = floor(p * cellSize) / cellSize;

    //Cordinates of cell corners
    float2 tl = float2(id.x, id.y);
    float2 tr = float2(id.x + i, id.y);;
    float2 bl = float2(id.x, id.y + i);
    float2 br = float2(id.x + i, id.y + i);

    //Wrap around
    tl = modulo(tl, float2(f,f));
    tr = modulo(tr, float2(f,f));
    bl = modulo(bl, float2(f,f));
    br = modulo(br, float2(f,f));

    //Vector from corners of cell to point
    float2 v_tl = remap_f2(float2(p.x - id.x, p.y - id.y), 0.0, i, 0.0, 1.0);
    float2 v_tr = remap_f2(float2(p.x - id.x - i, p.y - id.y), 0.0, i, 0.0, 1.0);
    float2 v_bl = remap_f2(float2(p.x - id.x, p.y - id.y - i), 0.0, i, 0.0, 1.0);
    float2 v_br = remap_f2(float2(p.x - id.x - i, p.y - id.y - i), 0.0, i, 0.0, 1.0);

    //Gradient vectors at each cell corner
    float2 gv_tl = gradientVector_2D(tl);
    float2 gv_tr = gradientVector_2D(tr);
    float2 gv_bl = gradientVector_2D(bl);
    float2 gv_br = gradientVector_2D(br);

    //Fade value
    float fx = fade((p.x * cellSize) - floor(p.x * cellSize));
    float fy = fade((p.y * cellSize) - floor(p.y * cellSize));

    //Dot product of corner gradient and vector to point
    float dot_tl = dot(v_tl, gv_tl);
    float dot_tr = dot(v_tr, gv_tr);
    float dot_bl = dot(v_bl, gv_bl);
    float dot_br = dot(v_br, gv_br);

    //Bilinear interpolation
    float n_t = lerp(dot_tl, dot_tr, fx);
    float n_b = lerp(dot_bl, dot_br, fx);
    float n = lerp(n_t, n_b, fy);

    return n;
}

//Based on iqs blog post: https://iquilezles.org/articles/fbm/
float perlinNoise_2D_fbm(float2 p, float H, float freq, float numOctaves){
    float G = exp2(-H);
    float f = 1.0;
    float a = 1.0;
    float t = 0.0;
    for(int i = 0; i < numOctaves; i++){
        t += a * perlinNoise_2D(p * f, freq, f);
        f *= 2.0;
        a *= G;
    }

    return t;
}

float perlinNoise_3D(float3 p, float cellSize){
    
    //Interval between cells
    float i = 1.0 / cellSize;

    //Cell that point lies in
    float3 id = floor(p * cellSize) / cellSize;

    //Coordinates of cell corners in 3D
    float3 c000 = float3(id.x, id.y, id.z);
    float3 c001 = float3(id.x, id.y, id.z + i);
    float3 c010 = float3(id.x, id.y + i, id.z);
    float3 c011 = float3(id.x, id.y + i, id.z + i);
    float3 c100 = float3(id.x + i, id.y, id.z);
    float3 c101 = float3(id.x + i, id.y, id.z + i);
    float3 c110 = float3(id.x + i, id.y + i, id.z);
    float3 c111 = float3(id.x + i, id.y + i, id.z + i);

    //Wrap around
    float3 c000_w = modulo(c000, float3(1,1,1));
    float3 c001_w = modulo(c001, float3(1,1,1));
    float3 c010_w = modulo(c010, float3(1,1,1));
    float3 c011_w = modulo(c011, float3(1,1,1));
    float3 c100_w = modulo(c100, float3(1,1,1));
    float3 c101_w = modulo(c101, float3(1,1,1));
    float3 c110_w = modulo(c110, float3(1,1,1));
    float3 c111_w = modulo(c111, float3(1,1,1));

    //Vectors from corners to point
    float3 v000 = remap_f3(p - c000, 0.0, i, 0.0, 1.0);
    float3 v001 = remap_f3(p - c001, 0.0, i, 0.0, 1.0);
    float3 v010 = remap_f3(p - c010, 0.0, i, 0.0, 1.0);
    float3 v011 = remap_f3(p - c011, 0.0, i, 0.0, 1.0);
    float3 v100 = remap_f3(p - c100, 0.0, i, 0.0, 1.0);
    float3 v101 = remap_f3(p - c101, 0.0, i, 0.0, 1.0);
    float3 v110 = remap_f3(p - c110, 0.0, i, 0.0, 1.0);
    float3 v111 = remap_f3(p - c111, 0.0, i, 0.0, 1.0);

    //Gradient vectors at each corner of cell
    float3 gv000 = gradientVector_3D(c000_w);
    float3 gv001 = gradientVector_3D(c001_w);
    float3 gv010 = gradientVector_3D(c010_w);
    float3 gv011 = gradientVector_3D(c011_w);
    float3 gv100 = gradientVector_3D(c100_w);
    float3 gv101 = gradientVector_3D(c101_w);
    float3 gv110 = gradientVector_3D(c110_w);
    float3 gv111 = gradientVector_3D(c111_w);

    //Fade values
    float fx = fade(fract(p.x * cellSize));
    float fy = fade(fract(p.y * cellSize));
    float fz = fade(fract(p.z * cellSize));

    //Dot products
    float dot000 = dot(v000, gv000);
    float dot001 = dot(v001, gv001);
    float dot010 = dot(v010, gv010);
    float dot011 = dot(v011, gv011);
    float dot100 = dot(v100, gv100);
    float dot101 = dot(v101, gv101);
    float dot110 = dot(v110, gv110);
    float dot111 = dot(v111, gv111);

    //Trilinear interpolation
    float n1 = lerp(dot000, dot100, fx);
    float n2 = lerp(dot010, dot110, fx);
    float n3 = lerp(dot001, dot101, fx);
    float n4 = lerp(dot011, dot111, fx);

    float n5 = lerp(n1, n2, fy);
    float n6 = lerp(n3, n4, fy);

    float n = lerp(n5, n6, fz);

    return n;
}

float perlinNoise_3D(float3 p, float cellSize, int f){
    
    //Interval between cells
    float i = 1.0 / cellSize;

    //Cell that point lies in
    float3 id = floor(p * cellSize) / cellSize;

    //Coordinates of cell corners in 3D
    float3 c000 = float3(id.x, id.y, id.z);
    float3 c001 = float3(id.x, id.y, id.z + i);
    float3 c010 = float3(id.x, id.y + i, id.z);
    float3 c011 = float3(id.x, id.y + i, id.z + i);
    float3 c100 = float3(id.x + i, id.y, id.z);
    float3 c101 = float3(id.x + i, id.y, id.z + i);
    float3 c110 = float3(id.x + i, id.y + i, id.z);
    float3 c111 = float3(id.x + i, id.y + i, id.z + i);

    //Wrap around
    float3 c000_w = modulo(c000, float3(f,f,f));
    float3 c001_w = modulo(c001, float3(f,f,f));
    float3 c010_w = modulo(c010, float3(f,f,f));
    float3 c011_w = modulo(c011, float3(f,f,f));
    float3 c100_w = modulo(c100, float3(f,f,f));
    float3 c101_w = modulo(c101, float3(f,f,f));
    float3 c110_w = modulo(c110, float3(f,f,f));
    float3 c111_w = modulo(c111, float3(f,f,f));

    //Vectors from corners to point
    float3 v000 = remap_f3(p - c000, 0, i, 0, 1);
    float3 v001 = remap_f3(p - c001, 0, i, 0, 1);
    float3 v010 = remap_f3(p - c010, 0, i, 0, 1);
    float3 v011 = remap_f3(p - c011, 0, i, 0, 1);
    float3 v100 = remap_f3(p - c100, 0, i, 0, 1);
    float3 v101 = remap_f3(p - c101, 0, i, 0, 1);
    float3 v110 = remap_f3(p - c110, 0, i, 0, 1);
    float3 v111 = remap_f3(p - c111, 0, i, 0, 1);

    //Gradient vectors at each corner of cell
    float3 gv000 = gradientVector_3D(c000_w);
    float3 gv001 = gradientVector_3D(c001_w);
    float3 gv010 = gradientVector_3D(c010_w);
    float3 gv011 = gradientVector_3D(c011_w);
    float3 gv100 = gradientVector_3D(c100_w);
    float3 gv101 = gradientVector_3D(c101_w);
    float3 gv110 = gradientVector_3D(c110_w);
    float3 gv111 = gradientVector_3D(c111_w);

    //Fade values
    float fx = fade(fract(p.x * cellSize));
    float fy = fade(fract(p.y * cellSize));
    float fz = fade(fract(p.z * cellSize));

    //Dot products
    float dot000 = dot(v000, gv000);
    float dot001 = dot(v001, gv001);
    float dot010 = dot(v010, gv010);
    float dot011 = dot(v011, gv011);
    float dot100 = dot(v100, gv100);
    float dot101 = dot(v101, gv101);
    float dot110 = dot(v110, gv110);
    float dot111 = dot(v111, gv111);

    //Trilinear interpolation
    float n1 = lerp(dot000, dot100, fx);
    float n2 = lerp(dot010, dot110, fx);
    float n3 = lerp(dot001, dot101, fx);
    float n4 = lerp(dot011, dot111, fx);

    float n5 = lerp(n1, n2, fy);
    float n6 = lerp(n3, n4, fy);

    float n = lerp(n5, n6, fz);

    return n;
}

//Based on iqs blog post: https://iquilezles.org/articles/fbm/
float perlinNoise_3D_fbm(float3 p, float H, float freq, float numOctaves){
    float G = exp2(-H);
    float f = 1.0;
    float a = 1.0;
    float t = 0.0;
    for(int i = 0; i < numOctaves; i++){
        t += a * perlinNoise_3D(p * f, freq, f);
        f *= 2.0;
        a *= G;
    }

    return t;
}

float worleyNoise_3D(float3 p, float cellSize, float intervalOffset){
    //Interval between cells
    float interval = 1.0 / cellSize;

    //Initial min distance
    float minDist = intervalOffset;

    //Initial cell that point resides in
    float3 baseCell = floor(p * cellSize) / cellSize;

    //Loop through all surrounding cells
    for(int x = -1; x <= 1; x++){
        for(int y = -1; y <= 1; y++){
            for(int z = -1; z <= 1; z++){

                //Get neighboring cell
                float3 cell = baseCell + float3(float(x) * interval, float(y) * interval, float(z) * interval);

                //Wrap cell around edges
                float3 wrappedCell = modulo(cell, float3(1.0, 1.0, 1.0));

                //Generate pseudo random offset based on cell
                uint seed = seedGen_ui3(uint3(cell.x * _ScreenParams.x, cell.y * _ScreenParams.y, cell.z * _ScreenParams.y));
                float3 rand = random_3D(seed);

                //Find distance to cell
                float3 cellPosition = cell + (rand * interval);
                float3 toCell = cellPosition - p;
                if(length(toCell) < minDist){
                    minDist = length(toCell);
                }
            }
        }
    }

    float result = minDist / intervalOffset;
    return result;

}

float worleyNoise_3D(float3 p, float cellSize){
    //Interval between cells
    float interval = 1.0 / cellSize;

    //Initial min distance
    float minDist = 1000000000;

    //Initial cell that point resides in
    // float3 baseCell = floor(p * cellSize) / cellSize;

    //Loop through all surrounding cells
    for(int x = -1; x <= 1; x++){
        for(int y = -1; y <= 1; y++){
            for(int z = -1; z <= 1; z++){

                //Get neighboring cell
                // float3 cell = baseCell + float3(float(x) * interval, float(y) * interval, float(z) * interval);
                float3 cell = floor(p * cellSize) + float3(float(x), float(y), float(z));

                //Wrap cell around edges
                float3 wrappedCell = modulo(cell, float3(cellSize, cellSize, cellSize));

                //Generate pseudo random offset based on cell
                uint seed = seedGen_ui3(uint3(wrappedCell.x * _ScreenParams.x, wrappedCell.y * _ScreenParams.y, wrappedCell.z * _ScreenParams.y));
                float3 rand = random_3D(seed);

                //Find distance to cell
                // float3 cellPosition = cell + (rand * interval);
                float3 toCell = (p * cellSize) - cell - rand;
                minDist = min(minDist, dot(toCell, toCell));
                // if(length(toCell) < minDist){
                //     minDist = length(toCell);
                // }
            }
        }
    }
    // float maxDist = interval * sqrt(3.0);
    // float result = minDist / interval;
    minDist = min(minDist, 1.0);
    minDist = max(minDist, 0.0);
    return minDist;

    // float3 pCell = p * cellSize;
    // float d = 1000000.0;
    // for(int x = -1; x <= 1; x++){
    //     for(int y = -1; y <= 1; y++){
    //         for(int z = -1; z <= 1; z++){
    //             float3 tp = floor(pCell) + float3(x, y, z);
    //             float3 wrappedCell = modulo(tp, float3(cellSize, cellSize, cellSize));
    //             uint seed = seedGen_ui3(uint3(wrappedCell.x * _ScreenParams.x, wrappedCell.y * _ScreenParams.y, wrappedCell.z * _ScreenParams.y));
    //             float3 rand = random_3D(seed);
    //             tp = pCell - tp - rand;
    //             d = min(d, dot(tp, tp));
    //         }
    //     }
    // }
    // d = min(d, 1.0);
    // d = max(d, 0.0);
    // return d;
}

float worleyNoise_3D_fbm(float3 p, float H, float freq, float numOctaves){
    // float G = exp2(-H);
    // float f = 1.0;
    // float a = 1.0;
    // float t = 0.0;
    // for(int i = 0; i < numOctaves; i++){
    //     t += a * worleyNoise_3D(p * f, freq);
    //     f *= 2.0;
    //     a *= G;
    // }

    // return t;

    float noise = 0;
    noise += worleyNoise_3D(p, freq) * .8;
    noise += worleyNoise_3D(p, freq * 2) * .25;
    noise += worleyNoise_3D(p, freq * 4) * .125;

    return noise;
}

float worleyNoise_3D_fbm(float3 p, float intervalOffset, float H, float freq, float numOctaves){
    float G = exp2(-H);
    float f = 1.0;
    float a = 1.0;
    float t = 0.0;
    for(int i = 0; i < numOctaves; i++){
        t += a * worleyNoise_3D(p * f, freq, intervalOffset);
        f *= 2.0;
        a *= G;
    }

    return t;
}

float worleyNoise_2D(float2 p, float cellSize, float intervalOffset){

    //Interval between cells
    float interval = 1.0 / cellSize;

    //Initial min distance
    float minDist = intervalOffset;

    //Initial cell that point resides in
    float2 baseCell = floor(p * cellSize) / cellSize;

    //Loop through all surrounding cells
    for(int x = -1; x <= 1; x++){
        for(int y = -1; y <= 1; y++){

            //Get neighboring cell
            float2 cell = baseCell + float2(float(x) * interval, float(y) * interval);

            //Generate pseudo random offset based on cell
            uint seed = seedGen_ui2(uint2(cell.x * _ScreenParams.x, cell.y * _ScreenParams.y));
            float2 rand = random_2D(seed);

            //Wrap cell around edges
            float2 wrappedCell = modulo(cell, float2(1.0, 1.0));

            //Find distance to cell
            float2 cellPosition = cell + (rand * interval);
            float2 toCell = cellPosition - p;
            if(length(toCell) < minDist){
                minDist = length(toCell);
            }
        }
    }

    float result = minDist / intervalOffset;
    return result;
}

float worleyNoise_2D(float2 p, float cellSize, float2 scale, int seedOffset){

    p *= scale;

    //Interval between cells
    float interval = 1.0 / cellSize;

    //Initial min distance
    float minDist = interval;

    //Initial cell that point resides in
    float2 baseCell = floor(p * cellSize) / cellSize;

    //Loop through all surrounding cells
    for(int x = -1; x <= 1; x++){
        for(int y = -1; y <= 1; y++){

            //Get neighboring cell
            float2 cellOffset = float2(float(x) * interval, float(y) * interval);
            float2 cell = baseCell + cellOffset;

            //Wrap cell around edges
            // float2 wrappedCell = modulo(cell, float2(1.0, 1.0));
            float2 wrappedCell = modulo(cell, scale);

            //Generate pseudo random offset based on cell
            uint seed = seedGen_ui2(uint2(wrappedCell.x * _ScreenParams.x, wrappedCell.y * _ScreenParams.y));
            float2 rand = random_2D(seed + seedOffset);

            //Find distance to cell
            float2 cellPosition = cell + (rand * interval);
            float2 toCell = cellPosition - p;
            if(length(toCell) < minDist){
                minDist = length(toCell);
            }
        }
    }

    float result = minDist / interval;
    return result;
}


float worleyNoise_2D(float2 p, float cellSize){

    //Interval between cells
    float interval = 1.0 / cellSize;

    //Initial min distance
    float minDist = interval;

    //Initial cell that point resides in
    float2 baseCell = floor(p * cellSize) / cellSize;

    //Loop through all surrounding cells
    for(int x = -1; x <= 1; x++){
        for(int y = -1; y <= 1; y++){

            //Get neighboring cell
            float2 cellOffset = float2(float(x) * interval, float(y) * interval);
            float2 cell = baseCell + cellOffset;

            //Wrap cell around edges
            float2 wrappedCell = modulo(cell, float2(1.0, 1.0));

            //Generate pseudo random offset based on cell
            uint seed = seedGen_ui2(uint2(wrappedCell.x * _ScreenParams.x, wrappedCell.y * _ScreenParams.y));
            float2 rand = random_2D(seed);

            //Find distance to cell
            float2 cellPosition = cell + (rand * interval);
            float2 toCell = cellPosition - p;
            if(length(toCell) < minDist){
                minDist = length(toCell);
            }
        }
    }

    float result = minDist / interval;
    return result;
}

//Based on iqs blog post: https://iquilezles.org/articles/fbm/
float worleyNoise_2D_fbm(float2 p, float H, float freq, float numOctaves){
    // float G = exp2(-H);
    // float f = 1.0;
    // float a = 1.0;
    // float t = 0.0;
    // for(int i = 0; i < numOctaves; i++){
    //     t += a * worleyNoise_2D(p * f, freq);
    //     f *= 2.0;
    //     a *= G;
    // }

    // return t;

    float noise = 0;
    noise += worleyNoise_2D(p, freq) * .8;
    noise += worleyNoise_2D(p, freq * 2) * .25;
    noise += worleyNoise_2D(p, freq * 4) * .125;

    return noise;

        // return worleyNoise(p*freq, freq) * .625 +
        // 	 worleyNoise(p*freq*2., freq*2.) * .25 +
        // 	 worleyNoise(p*freq*4., freq*4.) * .125;
}

//Based on iqs blog post: https://iquilezles.org/articles/fbm/
float worleyNoise_2D_fbm(float2 p, float intervalOffset, float H, float freq, float numOctaves){
    float G = exp2(-H);
    float f = 1.0;
    float a = 1.0;
    float t = 0.0;
    for(int i = 0; i < numOctaves; i++){
        t += a * worleyNoise_2D(p * f, freq);
        f *= 2.0;
        a *= G;
    }

    return t;
}

float perlinWorley_3D(float3 uvw){
    float noise = 0;
    float perlinNoise = perlinNoise_3D_fbm(uvw, 0.8, 2, 7);
    perlinNoise = abs(perlinNoise);

    float worleyNoise = worleyNoise_3D_fbm(uvw, 0.7, 4, 5);
    worleyNoise = 1 - worleyNoise;

    noise = remap_f(perlinNoise, 0.0, 1.0, worleyNoise, 1.0);

    return noise;
}

float perlinWorley_2D(float2 uv){
    float noise = 0;
    float perlinNoise = perlinNoise_2D_fbm(uv, 0.8, 2, 7);
    perlinNoise = abs(perlinNoise);

    float worleyNoise = worleyNoise_2D_fbm(uv, 0.7, 4, 5);
    worleyNoise = 1 - worleyNoise;

    noise = remap_f(perlinNoise, 0.0, 1.0, worleyNoise, 1.0);

    return noise;
}

uint seedCount = 0;
float whiteNoise_2D(float2 p, uint seedOffset){
    int seed = seedGen_ui2(uint2(uint(p.x * _ScreenParams.x), uint(p.y * _ScreenParams.y)));
    seedCount++;
    //return normalize_ui(pcgHash_ui(seed * seedOffset + seedCount));
    return normalize_ui(pcgHash_ui(seed * seedCount));
}

#endif