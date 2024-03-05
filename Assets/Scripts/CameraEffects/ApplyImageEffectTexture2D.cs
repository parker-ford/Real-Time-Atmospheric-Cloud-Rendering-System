using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ApplyImageEffectTexture2D : MonoBehaviour
{
    [NonSerialized]
    public Texture2D texture;
    private Material material;
    // Start is called before the first frame update
    void Start()
    {
        
    }
    public void SetTexture(Texture2D texture)
    {
        this.texture = texture;
        material = new Material(Shader.Find("Parker/Texture2D"));
        material.SetTexture("_Tex", texture);
    }

   void OnRenderImage(RenderTexture source, RenderTexture destination){
        if(material != null){
            Debug.Log("Applying Image Effect");
            Graphics.Blit(source, destination, material);
        }
        else{
            Debug.Log("No material set");
            Graphics.Blit(source,destination);
        }
    }
}
