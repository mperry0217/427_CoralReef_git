using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace UnderwaterEffect
{
    public class FloatingCamera : MonoBehaviour
    {
        public float speed = 5.0f;
        public float sensitivity = 2.0f;
        [Tooltip("Multiply the camera speed by this amount when left-shift is held")]
        public float speedMultiplier = 3.0f;

        private Vector3 moveDirection;
        private Vector2 rotation = Vector2.zero;

        void Update()
        {
            // Update move direction based on input
            moveDirection = new Vector3(Input.GetAxis("Horizontal"), 0, Input.GetAxis("Vertical"));
            moveDirection += Vector3.up * (Input.GetKey(KeyCode.E) ? 1 : 0);
            moveDirection += Vector3.up * (Input.GetKey(KeyCode.Q) ? -1 : 0);

            // Normalize and scale movement. Speed up the camera movement if holding left-shift.
            moveDirection = transform.TransformDirection(moveDirection);
            moveDirection *= speed * Time.deltaTime * (Input.GetKey(KeyCode.LeftShift) ? speedMultiplier : 1); ;

            // Apply movement
            transform.position += moveDirection;

            // Get mouse movement
            rotation.y += Input.GetAxis("Mouse X");
            rotation.x += -Input.GetAxis("Mouse Y");

            // Apply rotation
            transform.eulerAngles = (Vector2)rotation * sensitivity;
        }
    }
}
