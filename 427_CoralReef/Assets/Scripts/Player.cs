using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class Player : MonoBehaviour
{
    public float movementSpeed, rotationSpeed;
    public float originalSpeed;
    public Rigidbody playerRigidbody;


    // Start is called before the first frame update
    void Start()
    {
        originalSpeed = movementSpeed;
    }

    // Update is called once per frame
    void FixedUpdate()
    {
        float verticalInput = Input.GetAxis("Vertical");
        Vector3 movement = (transform.forward * verticalInput) * movementSpeed;
        movement.y = playerRigidbody.velocity.y;
        playerRigidbody.velocity = movement;

    }

    void Update()
    {
        float rotationInput = Input.GetAxis("Horizontal");
        transform.Rotate(0, rotationInput * rotationSpeed * Time.deltaTime, 0);
    }


    void OnTriggerEnter(Collider other)
    {
        Debug.Log("Scene Change");

        if (SceneManager.GetActiveScene().name == "Terrain1")
        {
            SceneManager.LoadScene("Terrain 2");
        }

        if (SceneManager.GetActiveScene().name == "Terrain 2")
        {
            SceneManager.LoadScene("Terrain1");
        }
    }
}

// credit to Omogonix on Youtube for rough outline of code //
