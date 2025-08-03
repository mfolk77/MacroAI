#!/usr/bin/env python3
"""
Simple test for Blender MCP connection
"""

import json
import socket
import time

def test_blender_connection():
    """Test basic Blender MCP connection"""
    print("🔍 Testing Blender MCP Connection")
    print("=" * 40)
    
    try:
        # Connect to Blender
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.connect(('localhost', 5000))
        print("✅ Connected to Blender MCP server")
        
        # Test 1: Get scene info
        print("\n📋 Test 1: Getting scene info...")
        command = {
            "type": "get_scene_info",
            "params": {}
        }
        
        client.send(json.dumps(command).encode())
        response = client.recv(4096).decode()
        result = json.loads(response)
        
        print(f"Response: {result}")
        
        # Test 2: Execute simple Blender code
        print("\n🎯 Test 2: Creating a simple cube...")
        simple_code = '''
import bpy

# Clear existing objects
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

# Create a simple cube
bpy.ops.mesh.primitive_cube_add(location=(0, 0, 0))
cube = bpy.context.active_object
cube.name = "test_cube"

# Add a material
mat = bpy.data.materials.new(name="TestMaterial")
mat.use_nodes = True
nodes = mat.node_tree.nodes
bsdf = nodes["Principled BSDF"]
bsdf.inputs["Base Color"].default_value = (1, 0, 0, 1)  # Red color

# Assign material to cube
if cube.data.materials:
    cube.data.materials[0] = mat
else:
    cube.data.materials.append(mat)

print("Test cube created successfully")
'''
        
        command = {
            "type": "execute_code",
            "params": {
                "code": simple_code
            }
        }
        
        client.send(json.dumps(command).encode())
        response = client.recv(4096).decode()
        result = json.loads(response)
        
        print(f"Response: {result}")
        
        # Test 3: Get object info
        print("\n📋 Test 3: Getting object info...")
        command = {
            "type": "get_object_info",
            "params": {
                "name": "test_cube"
            }
        }
        
        client.send(json.dumps(command).encode())
        response = client.recv(4096).decode()
        result = json.loads(response)
        
        print(f"Response: {result}")
        
        print("\n🎉 All tests completed successfully!")
        
    except Exception as e:
        print(f"❌ Test failed: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        if 'client' in locals():
            client.close()

if __name__ == "__main__":
    test_blender_connection() 