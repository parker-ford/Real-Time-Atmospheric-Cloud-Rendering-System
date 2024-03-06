using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraController : MonoBehaviour
{
    public float moveNormalSpeed = 10f;
    public float moveFastSpeed = 20f;
    private float moveSpeed;
    public float rotationSpeed = 2000f;
    bool hasFocus;

    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
   
        CheckFocus();

        if(Input.GetMouseButton(1) && hasFocus){

            if(Input.GetKey(KeyCode.LeftShift)){
                moveSpeed = moveFastSpeed;
            }
            else{
                moveSpeed = moveNormalSpeed;
            }

            if(Input.GetKey(KeyCode.W)){
                transform.position += transform.forward * Time.deltaTime * moveSpeed;
            }
            if(Input.GetKey(KeyCode.S)){
                transform.position -= transform.forward * Time.deltaTime * moveSpeed;
            }
            if(Input.GetKey(KeyCode.D)){
                transform.position += transform.right * Time.deltaTime * moveSpeed;
            }
            if(Input.GetKey(KeyCode.A)){
                transform.position -= transform.right * Time.deltaTime * moveSpeed;
            }
            if(Input.GetKey(KeyCode.E)){
                transform.position += transform.up * Time.deltaTime * moveSpeed;
            }
            if(Input.GetKey(KeyCode.Q)){
                transform.position -= transform.up * Time.deltaTime * moveSpeed;
            }


            
            Cursor.lockState = CursorLockMode.Locked;
            Vector2 deltaMouse = new Vector2(-Input.GetAxis("Mouse X"), -Input.GetAxis("Mouse Y"));
            
            Quaternion qX = Quaternion.AngleAxis(-deltaMouse.x * Time.deltaTime * rotationSpeed, Vector3.up);
            Quaternion qY = Quaternion.AngleAxis(deltaMouse.y * Time.deltaTime * rotationSpeed, transform.right);
            Quaternion q = qX * qY;
            Matrix4x4 R = Matrix4x4.Rotate(q);
            Matrix4x4 invP = Matrix4x4.TRS(transform.position, Quaternion.identity, Vector3.one);
            R = invP * R * invP.inverse;
            Vector3 newCameraPos = R.MultiplyPoint(transform.localPosition);
            transform.localPosition = newCameraPos;
            transform.localRotation = q * transform.localRotation;
   

        }
        else{
            Cursor.lockState = CursorLockMode.None;
        }
    }

    void OnApplicationFocus(bool focus){
        hasFocus = focus;
    }

    void CheckFocus(){
        if(!hasFocus){
            Input.ResetInputAxes();
        }
    }
}
