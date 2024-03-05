using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ApplyImageEffectShader : MonoBehaviour
{
    public Shader shader;
    private Material material;

    void Start()
    {
        material = new Material(shader);
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination){
        if(material != null){
            Graphics.Blit(source, destination, material);
        }
        else{
            Graphics.Blit(source,destination);
        }
    }
}
