using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class TextureMaker2D : MonoBehaviour
{
    public struct Pixel {
        public Color color;
    }
    private Pixel[] pixels;
    public string textureName;
    public ComputeShader computeTextureMaker;
    public int resolution = 256;
    public bool genMipMaps = true;

    private Texture2D texture;
    public bool regenerateTexture = false;
    public bool saveTexture = false;



    void Start()
    {
        GenerateTexture();
    }

    void GenerateTexture(){
        CreatePixelArray();
        FillPixelBuffer();
        PixelArrayToTexture();
    }

    private void CreatePixelArray(){
        pixels = new Pixel[resolution * resolution];
        for(int i = 0; i < pixels.Length; i++){
            pixels[i].color = new Color(0, 0, 0, 1);
        }
    }
    private void FillPixelBuffer(){
        ComputeBuffer pixelBuffer = new ComputeBuffer(pixels.Length, sizeof(float) * 4);
        pixelBuffer.SetData(pixels);
        computeTextureMaker.SetBuffer(0, "pixels", pixelBuffer);
        computeTextureMaker.SetFloat("resolution", resolution);
        computeTextureMaker.Dispatch(0, resolution, resolution, 1);
        pixelBuffer.GetData(pixels);
        pixelBuffer.Dispose();
    }

    private void PixelArrayToTexture(){
        texture = new Texture2D(resolution, resolution, TextureFormat.RGBA32, genMipMaps);
        for(int x = 0; x < resolution; x++){
            for(int y = 0; y < resolution; y++){
                texture.SetPixel(x, y, pixels[x + y * resolution].color);
            }
        }
        texture.Apply();
    }

    private void SaveTexture(){
        string dateTimeString = System.DateTime.Now.ToString("yyyy-MM-dd_HH-mm-ss");
        string folderPath = Application.dataPath + "/Textures/" + textureName;
        System.IO.Directory.CreateDirectory(folderPath);

        AssetDatabase.CreateAsset(texture, "Assets/Textures/" + textureName + "/"  + textureName + "_" + dateTimeString + ".asset" );
        Debug.Log("3D Texture created");
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
