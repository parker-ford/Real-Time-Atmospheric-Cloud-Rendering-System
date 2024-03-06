using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RaycastController : MonoBehaviour
{
    public GameObject sphere;
    public Shader shader;
    [Range(0.0f, 1.0f)]
    public float blendFactor = 0.0f;
    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        Shader.SetGlobalVector("_SphereCenter", sphere.transform.position);
        Shader.SetGlobalFloat("_SphereRadius", sphere.transform.localScale.y / 2.0f);
        Shader.SetGlobalFloat("_BlendFactor", blendFactor);
    }
}
