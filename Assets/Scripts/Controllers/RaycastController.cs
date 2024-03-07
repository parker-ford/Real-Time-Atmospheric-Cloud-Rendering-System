using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RaycastController : MonoBehaviour
{
   
    public GameObject sphere;
    public Shader shader;
   
    
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {

        Shader.SetGlobalVector("_SphereCenter", sphere.transform.position);
        Shader.SetGlobalFloat("_SphereRadius", sphere.transform.localScale.y / 2.0f);

    }
}
