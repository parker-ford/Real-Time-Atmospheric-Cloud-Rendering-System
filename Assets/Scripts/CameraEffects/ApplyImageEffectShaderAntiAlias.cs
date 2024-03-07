using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ApplyImageEffectShaderAntiAlias : MonoBehaviour
{
    public Shader shader;
    public Shader antiAliasingShader;
    public Shader blurShader; 
    private Material material;
    private Material antiAliasingMaterial;
    private Material blurMaterial;
    RenderTexture[] buffers;
    RenderTexture antiAliasedBuffer;
    [Range(1, 16)]
    public int numSamples = 1;
    private int maxSamples = 16;
    private int lastSamples = 0;
    private int frame = 0;
    public bool useBlur = true;


    void Start()
    {
        material = new Material(shader);
        antiAliasingMaterial = new Material(antiAliasingShader);
        blurMaterial = new Material(blurShader);

        Shader.SetGlobalInt("_NumSuperSamples", 1);
        Shader.SetGlobalFloat("_CameraFOV", Camera.main.fieldOfView);
        Shader.SetGlobalFloat("_CameraAspect", Camera.main.aspect);
    
        buffers = new RenderTexture[maxSamples];
        for(int i = 0; i < maxSamples; i++){
            buffers[i] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBFloat);
        }
        antiAliasedBuffer = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBFloat);

    }

    void OnRenderImage(RenderTexture source, RenderTexture destination){
        //Reset buffers if number of samples changes
        if(lastSamples != numSamples){
            for(int i = 0; i < maxSamples; i++){
                buffers[i].Release();
                buffers[i] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBFloat);
            }
            antiAliasedBuffer.Release();
            antiAliasedBuffer = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBFloat);
            frame = 0;
        }

        Shader.SetGlobalInt("_Frame", frame);
        Shader.SetGlobalInt("_NumSuperSamples", numSamples);
        // Shader.SetGlobalInt()

        if(material != null && antiAliasingMaterial != null && blurMaterial != null){
            //Before frame threshold
            if(frame < numSamples){
                Graphics.Blit(source, buffers[frame], material);
                antiAliasingMaterial.SetTexture("_FrameTex", buffers[frame]);
                RenderTexture temp = RenderTexture.GetTemporary(antiAliasedBuffer.width, antiAliasedBuffer.height, antiAliasedBuffer.depth, antiAliasedBuffer.format);
                Graphics.Blit(antiAliasedBuffer, temp, antiAliasingMaterial);
                Graphics.Blit(temp,antiAliasedBuffer);
                RenderTexture.ReleaseTemporary(temp);
            }
            else{

                //Subract oldest frame
                antiAliasingMaterial.SetInt("_Mode", 0);
                antiAliasingMaterial.SetTexture("_FrameTex", buffers[frame % numSamples]);
                RenderTexture temp = RenderTexture.GetTemporary(antiAliasedBuffer.width, antiAliasedBuffer.height, antiAliasedBuffer.depth, antiAliasedBuffer.format);
                Graphics.Blit(antiAliasedBuffer, temp,  antiAliasingMaterial);
                Graphics.Blit(temp,antiAliasedBuffer);
                RenderTexture.ReleaseTemporary(temp);

                //Add new frame
                Graphics.Blit(source, buffers[frame % numSamples], material);
                antiAliasingMaterial.SetInt("_Mode", 1);
                antiAliasingMaterial.SetTexture("_FrameTex", buffers[frame % numSamples]);
                temp = RenderTexture.GetTemporary(antiAliasedBuffer.width, antiAliasedBuffer.height, antiAliasedBuffer.depth, antiAliasedBuffer.format);
                Graphics.Blit(antiAliasedBuffer, temp, antiAliasingMaterial);
                Graphics.Blit(temp,antiAliasedBuffer);
                RenderTexture.ReleaseTemporary(temp);
            }

            if(useBlur){
                Graphics.Blit(antiAliasedBuffer, destination, blurMaterial);
            }
            else{
                Graphics.Blit(antiAliasedBuffer, destination);
            }
        }
        else{
            Graphics.Blit(source,destination);
            Debug.LogError("Image effect material is null");
        }

        lastSamples = numSamples;
        frame++;
    }
}
