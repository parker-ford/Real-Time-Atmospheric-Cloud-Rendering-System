using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MarchDistanceDebug : MonoBehaviour
{
    public Transform start;
    public Transform end;
    public GameObject marker;
    [Range(1, 20)]
    public int numSteps = 10;
    [Range(1, 10)]
    public int frames = 1;

    private List<GameObject> markers = new List<GameObject>();
    private float dist = 0.0f;
    private Vector3 dir = Vector3.zero;
    [Range(1.00001f, 2.0f)]
    public float growthFactor = 1.5f;
    // Start is called before the first frame update
    void Start()
    {
        dir = (end.position - start.position).normalized;
        dist = Vector3.Distance(start.position, end.position);
        InitMarkers();
    }

    void InitMarkers()
    {
        //Delete markers
        foreach (GameObject m in markers)
        {
            Destroy(m);
        }
        markers.Clear();


        for (int i = 0; i < numSteps * frames; i++)
        {
            GameObject m = Instantiate(marker, Vector3.zero, Quaternion.identity);
            markers.Add(m);
        }
    }


    // Update is called once per frame
    private int lastNumSteps = 0;
    private int lastFrames = 0;
    void Update()
    {
        if (lastNumSteps != numSteps)
        {
            InitMarkers();
        }

        if (lastFrames != frames)
        {
            InitMarkers();
        }

        float n = numSteps - 1;
        float a = 1.0f - Mathf.Pow(growthFactor, n + 1);
        float b = 1.0f - growthFactor;


        for(int j = 0; j < frames; j++){
            float stepSize = dist / (a / b);
            float frameSegment = (float)(j % frames) / (float)frames;
            float totalDist = 0.0f;
            for (int i = 0; i < numSteps; i++)
                    {
                        // float t = ((float)i / (float)numSteps) * dist;
                        Vector3 pos = start.position + dir * (totalDist + frameSegment * stepSize);
                        markers[(j * numSteps) + i].transform.position = pos;
                        totalDist += stepSize;
                        stepSize *= growthFactor;
                        // markers[i].transform.localScale = Vector3.one * Mathf.Pow(growthFactor, i);
                    }
        }
        
        lastFrames = frames;
        lastNumSteps = numSteps;
    }


}
