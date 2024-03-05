using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ApplyImageEffectTexture3D : MonoBehaviour
{
    [NonSerialized]
    public Texture3D texture;
    private Material material;
    [Range(0,1)]
    public float slice = 0f;

    public void SetTexture(Texture3D texture)
    {
        this.texture = texture;
        material = new Material(Shader.Find("Parker/Texture3D"));
        material.SetTexture("_Tex", texture);
    }

   void OnRenderImage(RenderTexture source, RenderTexture destination){
        if(material != null){
            Graphics.Blit(source, destination, material);
        }
        else{
            Graphics.Blit(source,destination);
        }
    }

    void Update(){
        if(material != null){
            material.SetFloat("_Slice", slice);
        }
    }
}
