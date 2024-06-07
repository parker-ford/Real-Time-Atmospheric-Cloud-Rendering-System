using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BaseCloudVisualizerController : MonoBehaviour
{
    // Start is called before the first frame update
    public ComputeShader shader;
    [Range(-0.5f, 1.5f)]
    public float coverage = 0.5f;
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        shader.SetFloat("_Coverage", coverage);
    }
}
