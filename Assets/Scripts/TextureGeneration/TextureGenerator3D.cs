using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class TextureGenerator3D : MonoBehaviour
{
    public struct Pixel {
        public Color color;
    }
    private Pixel[] pixels;
    public string textureName;
    public ComputeShader computeTextureMaker;
    public ApplyImageEffectTexture3D applyImageEffectTexture3D;
    public int resolution = 256;
    public bool genMipMaps = true;

    private Texture3D texture;
    public bool regenerateTexture = false;
    public bool saveTexture = false;


    void Start()
    {
        GenerateTexture();
    }

    void GenerateTexture(){
        Debug.Assert(computeTextureMaker != null, "Compute Shader not set");
        CreatePixelArray();
        FillPixelBuffer();
        PixelArrayToTexture();
        applyImageEffectTexture3D.SetTexture(texture);
    }

    private void CreatePixelArray(){
        pixels = new Pixel[resolution * resolution * resolution];
        for(int i = 0; i < pixels.Length; i++){
            pixels[i].color = new Color(0, 0, 0, 1);
        }
    }
    private void FillPixelBuffer(){
        ComputeBuffer pixelBuffer = new ComputeBuffer(pixels.Length, sizeof(float) * 4);
        pixelBuffer.SetData(pixels);
        computeTextureMaker.SetBuffer(0, "pixels", pixelBuffer);
        computeTextureMaker.SetFloat("resolution", resolution);
        computeTextureMaker.Dispatch(0, resolution, resolution, resolution);
        pixelBuffer.GetData(pixels);
        pixelBuffer.Dispose();
    }

    private void PixelArrayToTexture(){
        texture = new Texture3D(resolution, resolution, resolution, TextureFormat.RGBA32, genMipMaps);
        texture.filterMode = FilterMode.Point;
        texture.wrapMode = TextureWrapMode.Clamp;
        
        for(int x = 0; x < resolution; x++){
            for(int y = 0; y < resolution; y++){
                for(int z = 0; z < resolution; z++){
                    texture.SetPixel(x,y,z, pixels[x + y * resolution + z * resolution * resolution].color);
                }
            }
        }
        texture.Apply();
    }

    private void SaveTexture(){
        string dateTimeString = System.DateTime.Now.ToString("yyyy-MM-dd_HH-mm-ss");
        string folderPath = Application.dataPath + "/Textures/" + textureName;
        System.IO.Directory.CreateDirectory(folderPath);

        AssetDatabase.CreateAsset(texture, "Assets/Textures/" + textureName + "/"  + textureName + "_" + dateTimeString + ".asset" );
        Debug.Log("2D Texture created");
    }
    void Update()
    {
        if(saveTexture){
            SaveTexture();
            saveTexture = false;
        }
        if(regenerateTexture){
            GenerateTexture();
            regenerateTexture = false;
        }
    }
}
