using System.Collections;
using System.Collections.Generic;
using UnityEngine;



public class CloudMarchDebugger : MonoBehaviour
{
    private const float EARTH_RADIUS = 6371.0f;
    struct SphereHit{
        public int hit;
        public int inside;
        public float enter;
        public float exit;
    };

    struct Sphere{
        public Vector3 center;
        public float radius;
    };

    struct MyRay{
        public Vector3 origin;
        public Vector3 direction;
    };

    public CloudRendererV2Controller cloudRenderer;
    public ApplyRaycastParameters raycastParameters;
    
    private MyRay ray;
    // Start is called before the first frame update


    SphereHit raySphereIntersect(MyRay ray, Sphere sphere){
        // SphereHit hit = {0, 0, 0.0, 0.0};
        SphereHit hit = new SphereHit();
        Vector3 oc = ray.origin - sphere.center;
        float b = 2.0f * Vector3.Dot(oc, ray.direction);
        float c = Vector3.Dot(oc, oc) - sphere.radius * sphere.radius;
        float d = b * b - 4.0f * c;

        if(d >= 0.0){
            float sqrtD = Mathf.Sqrt(d);
            float t0 = (-b - sqrtD) * 0.5f;
            float t1 = (-b + sqrtD) * 0.5f;
            if(t0 >= 0.0){
                hit.hit = 1;
                hit.enter = t0;
                hit.exit = t1;
            }
            else if (t1 >= 0.0){
                hit.hit = 1;
                hit.inside = 1;
                hit.enter = 0;
                hit.exit = t1;
            }
        }
        return hit;
    }


    void Start()
    {
       

    }

    void TestRay(){
        ray.direction = Camera.main.transform.forward;
        ray.origin = Camera.main.transform.position;
        ray.origin.y += EARTH_RADIUS;

        Sphere lowerAtmosphere = new Sphere();
        lowerAtmosphere.center = Vector3.zero;
        lowerAtmosphere.radius = EARTH_RADIUS + cloudRenderer.atmosphereLow;

        Sphere upperAtmosphere = new Sphere();
        upperAtmosphere.center = Vector3.zero;
        upperAtmosphere.radius = EARTH_RADIUS + cloudRenderer.atmosphereHigh;

        SphereHit lowerAtmosphereHit = raySphereIntersect(ray, lowerAtmosphere);
        SphereHit upperAtmosphereHit = raySphereIntersect(ray, upperAtmosphere);

        float dist = upperAtmosphereHit.exit - lowerAtmosphereHit.exit;

        Debug.Log("Distance: " + dist);

        float n = raycastParameters.rayMarchSteps - 1;
        float a = 1.0f - Mathf.Pow(cloudRenderer.stepGrowthRate, n + 1);
        float b = 1.0f - cloudRenderer.stepGrowthRate;

        float stepSize = dist / (a / b);

        Debug.Log("Step Size: " + stepSize);


    }

    // Update is called once per frame
    void Update()
    {
        //check if spacebar is pressed
        if(Input.GetKeyDown(KeyCode.Space)){
            TestRay();
        }
    }
}
