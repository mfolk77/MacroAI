#!/usr/bin/env python3
"""
Test script for Blender MCP connectivity
Creates a simple 3D cube to verify the connection works
"""

import json
import socket
import time

def test_blender_connection():
    """Test connection to Blender MCP server"""
    try:
        # Connect to Blender MCP server
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect(('localhost', 5000))
        
        # Test command to create a cube
        test_command = {
            "type": "create_object",
            "params": {
                "object_type": "MESH",
                "primitive_type": "CUBE",
                "location": [0, 0, 0],
                "size": 2.0
            }
        }
        
        # Send command
        sock.send(json.dumps(test_command).encode())
        
        # Get response
        response = sock.recv(4096).decode()
        print(f"Response: {response}")
        
        sock.close()
        return True
        
    except Exception as e:
        print(f"Connection failed: {e}")
        return False

if __name__ == "__main__":
    print("Testing Blender MCP connection...")
    success = test_blender_connection()
    if success:
        print("✅ Blender MCP connection successful!")
    else:
        print("❌ Blender MCP connection failed!") 