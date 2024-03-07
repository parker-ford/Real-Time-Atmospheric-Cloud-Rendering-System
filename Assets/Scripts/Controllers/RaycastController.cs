using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RaycastController : MonoBehaviour
{
   
    public GameObject sphere;
    public GameObject sphere2;
    public Shader shader;
    public Color color;
    public Texture2D testTexture;
   
    
    void Start()
    {
        sphere.GetComponent<MeshRenderer>().enabled = false;
        sphere2.GetComponent<MeshRenderer>().enabled = false;
    }

    // Update is called once per frame
    void Update()
    {

        Shader.SetGlobalVector("_SphereCenter", sphere.transform.position);
        Shader.SetGlobalVector("_SphereCenter2", sphere2.transform.position);
        Shader.SetGlobalFloat("_SphereRadius", sphere.transform.localScale.y / 2.0f);
        Shader.SetGlobalColor("_Color", color);
        Shader.SetGlobalTexture("_TestTex", testTexture);
    }
}
