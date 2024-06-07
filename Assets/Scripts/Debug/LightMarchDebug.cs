using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightMarchDebug : MonoBehaviour
{
    public bool active = false;
    public GameObject marker;
    public CloudCubeController cloudCubeController;
    public Vector3 startPosition = Vector3.zero;

    private float stepSize;
    private float numSteps;
    private float lightDistance;
    private Vector3 lightDir;
    private float cloudRadius;

    private List<GameObject> markers = new List<GameObject>();

    // Start is called before the first frame update
    void Start()
    {

        numSteps = cloudCubeController.lightSteps;
        lightDir = cloudCubeController.myLight.getLightDir();
        lightDistance = cloudCubeController.lightMarchDistance;
        stepSize = lightDistance / numSteps;
        cloudRadius = cloudCubeController.sphereRadius;

        InstantiateMarkers();
        SetMarkerPositions();
        SetMarkerActive();
    }

    void InstantiateMarkers()
    {

        //Clear existing markers
        foreach (GameObject marker in markers)
        {
            Destroy(marker);
        }
        markers.Clear();

        for (int i = 0; i < numSteps; i++)
        {
            GameObject newMarker = Instantiate(marker);
            newMarker.transform.localScale = new Vector3(cloudRadius * .05f, cloudRadius * .05f, cloudRadius * .05f);
            newMarker.transform.position = transform.position + transform.forward * i * stepSize;
            markers.Add(newMarker);
        }
    }

    void SetMarkerPositions(){
        float currDist = 0;
        float localStepSize = stepSize * 0.15f;
        for (int i = 0; i < numSteps; i++)
        {
            markers[i].transform.position = startPosition + lightDir * currDist;
            localStepSize *= 1.45f;
            currDist += localStepSize;
        }
    }

    void SetMarkerActive(){
        for (int i = 0; i < numSteps; i++)
        {
            markers[i].SetActive(active);
        }
    }

    private bool lastActive = false;
    private Vector3 lastPosition = Vector3.zero;

    // Update is called once per frame
    void Update()
    {
        if(active != lastActive){
            SetMarkerActive();
        }
        SetMarkerPositions();


        lastActive = active;
        lastPosition = startPosition;
    }
}
