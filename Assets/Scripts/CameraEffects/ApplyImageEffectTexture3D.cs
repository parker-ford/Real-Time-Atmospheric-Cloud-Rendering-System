using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ApplyImageEffectTexture3D : MonoBehaviour
{

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
        material.SetInt("_ChannelBitmask", layerMask);
    }
}
