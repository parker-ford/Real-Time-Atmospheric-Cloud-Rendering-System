using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ApplyImageEffectTexture2D : MonoBehaviour
{
    [NonSerialized]
    public Texture2D texture;
    private Material material;

    const int RGBA_BIT = 0x1;
    const int R_BIT = 0x2;
    const int G_BIT = 0x4;
    const int B_BIT = 0x8;
    const int A_BIT = 0x10;

    public enum Channel{
        R,
        G ,
        B ,
        A ,
        RGBA 
    }
    public Channel channel = Channel.RGBA;

    public void SetTexture(Texture2D texture)
    {
        this.texture = texture;
        if (material != null)
        {
            Destroy(material);
        }
        material = new Material(Shader.Find("Parker/Texture2D"));
        material.SetTexture("_Tex", texture);
    }

   void OnRenderImage(RenderTexture source, RenderTexture destination){
        if(material != null){
            Graphics.Blit(source, destination, material);
        }
        else{
            Debug.Log("No material set");
            Graphics.Blit(source,destination);
        }
    }

    void Update(){
        int layerMask = 0;
        switch(channel){
            case Channel.R:
                layerMask = R_BIT;
                break;
            case Channel.G:
                layerMask = G_BIT;
                break;
            case Channel.B:
                layerMask = B_BIT;
                break;
            case Channel.A:
                layerMask = A_BIT;
                break;
            case Channel.RGBA:
                layerMask = RGBA_BIT;
                break;
        }
        Shader.SetGlobalInt("_ChannelBitmask", layerMask);
    }
}
