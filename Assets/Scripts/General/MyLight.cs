using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MyLight : MonoBehaviour
{
    public Vector3 lightDir = new Vector3(0, 1, 0);
    public float distance = 100;
    public GameObject sun;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        sun.transform.position = lightDir.normalized * distance;
    }

    public Vector3 getLightDir()
    {
        return lightDir.normalized;
    }
}
