using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CloudGradientController : MonoBehaviour
{
    public ComputeShader shader;
    public Texture2D leftTexture;
    public Texture2D midTexture;
    public Texture2D rightTexture;

    // Start is called before the first frame update
    void Awake()
    {
        shader.SetTexture(0, "LeftTexture", leftTexture);
        shader.SetTexture(0, "MidTexture", midTexture);
        shader.SetTexture(0, "RightTexture", rightTexture);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
