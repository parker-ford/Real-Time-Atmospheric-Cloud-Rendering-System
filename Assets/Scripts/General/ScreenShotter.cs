using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ScreenShotter : MonoBehaviour
{
     void Update()
    {
        if (Input.GetKeyDown(KeyCode.P))
        {
            string folderPath = Application.dataPath + "/Screenshots/Noise/";
            System.IO.Directory.CreateDirectory(folderPath); // Ensure the folder exists
            string timestamp = System.DateTime.Now.ToString("yyyy-MM-dd_HH-mm-ss");
            string filePath = folderPath + "Screenshot_" + timestamp + ".png";
            ScreenCapture.CaptureScreenshot(filePath);
            Debug.Log("Screenshot saved to: " + filePath);
        }
    }
}
