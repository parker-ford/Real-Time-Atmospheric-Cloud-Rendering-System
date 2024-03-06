using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ApplyImageEffectShader : MonoBehaviour
{
    public Shader shader;
    private Material material;
    private int frame;

    void Start()
    {
        material = new Material(shader);
        Shader.SetGlobalInt("_NumSuperSamples", 1);
        Shader.SetGlobalFloat("_CameraFOV", Camera.main.fieldOfView);
        Shader.SetGlobalFloat("_CameraAspect", Camera.main.aspect);
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination){
        Shader.SetGlobalFloat("_Frame", frame);
        if(material != null){
            Graphics.Blit(source, destination, material);
        }
        else{
            Graphics.Blit(source,destination);
        }
        frame++;
    }
}
