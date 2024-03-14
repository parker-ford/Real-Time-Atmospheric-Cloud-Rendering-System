using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SingleCloudGradientController : MonoBehaviour
{
    // Start is called before the first frame update
    public ComputeShader shader;
    public float spread = 0.5f;
    public float offset = 0.5f;
    public float upperSlope = 1.0f;
    public float lowerSlope = 1.0f;
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        shader.SetFloat("spread", spread);
        shader.SetFloat("offset", offset);
        shader.SetFloat("upperSlope", upperSlope);
        shader.SetFloat("lowerSlope", lowerSlope);
    }
}
