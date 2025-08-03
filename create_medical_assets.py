#!/usr/bin/env python3
"""
Medical Device 3D Asset Generator
Creates healthcare/education 3D models optimized for iOS
"""

import json
import socket
import time
import os

class BlenderMCPClient:
    def __init__(self, host='localhost', port=5000):
        self.host = host
        self.port = port
        self.socket = None
    
    def connect(self):
        """Connect to Blender MCP server"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.connect((self.host, self.port))
            print("✅ Connected to Blender MCP server")
            return True
        except Exception as e:
            print(f"❌ Failed to connect: {e}")
            return False
    
    def send_command(self, command):
        """Send command to Blender"""
        try:
            self.socket.send(json.dumps(command).encode())
            response = self.socket.recv(4096).decode()
            return json.loads(response)
        except Exception as e:
            print(f"❌ Command failed: {e}")
            return None
    
    def create_cube(self, size=1.0, location=[0, 0, 0]):
        """Create a cube"""
        command = {
            "type": "create_object",
            "params": {
                "object_type": "MESH",
                "primitive_type": "CUBE",
                "location": location,
                "size": size
            }
        }
        return self.send_command(command)
    
    def create_cylinder(self, radius=0.5, height=2.0, location=[0, 0, 0]):
        """Create a cylinder"""
        command = {
            "type": "create_object",
            "params": {
                "object_type": "MESH",
                "primitive_type": "CYLINDER",
                "location": location,
                "radius": radius,
                "height": height
            }
        }
        return self.send_command(command)
    
    def create_sphere(self, radius=1.0, location=[0, 0, 0]):
        """Create a sphere"""
        command = {
            "type": "create_object",
            "params": {
                "object_type": "MESH",
                "primitive_type": "SPHERE",
                "location": location,
                "radius": radius
            }
        }
        return self.send_command(command)
    
    def apply_material(self, material_name, color=[0.8, 0.8, 0.8], metallic=0.0, roughness=0.5):
        """Apply material to selected object"""
        command = {
            "type": "apply_material",
            "params": {
                "material_name": material_name,
                "color": color,
                "metallic": metallic,
                "roughness": roughness
            }
        }
        return self.send_command(command)
    
    def export_usdz(self, filepath):
        """Export as USDZ format"""
        command = {
            "type": "export",
            "params": {
                "format": "USDZ",
                "filepath": filepath,
                "embed_textures": True,
                "optimize_mesh": True
            }
        }
        return self.send_command(command)
    
    def delete_object(self, object_name=None):
        """Delete selected or specified object"""
        command = {
            "type": "delete_object",
            "params": {
                "object_name": object_name
            }
        }
        return self.send_command(command)
    
    def close(self):
        """Close connection"""
        if self.socket:
            self.socket.close()

def create_medical_devices():
    """Create medical device 3D models"""
    
    # Connect to Blender
    client = BlenderMCPClient()
    if not client.connect():
        print("❌ Cannot connect to Blender. Make sure the addon is enabled.")
        return
    
    # Create output directory
    output_dir = "/Volumes/Folk_DAS/Apps/MacroAI/3D_Assets"
    os.makedirs(output_dir, exist_ok=True)
    
    # Medical device definitions
    devices = [
        {
            "name": "stethoscope",
            "type": "cylinder",
            "params": {"radius": 0.1, "height": 0.8, "location": [0, 0, 0]},
            "material": {"name": "Stethoscope_Metal", "color": [0.7, 0.7, 0.7], "metallic": 1.0, "roughness": 0.1}
        },
        {
            "name": "syringe",
            "type": "cylinder", 
            "params": {"radius": 0.05, "height": 0.3, "location": [0, 0, 0]},
            "material": {"name": "Syringe_Plastic", "color": [0.9, 0.9, 0.9], "metallic": 0.0, "roughness": 0.8}
        },
        {
            "name": "thermometer",
            "type": "cylinder",
            "params": {"radius": 0.02, "height": 0.15, "location": [0, 0, 0]},
            "material": {"name": "Thermometer_Glass", "color": [0.8, 0.9, 1.0], "metallic": 0.0, "roughness": 0.1}
        },
        {
            "name": "anatomy_heart",
            "type": "sphere",
            "params": {"radius": 0.5, "location": [0, 0, 0]},
            "material": {"name": "Heart_Tissue", "color": [0.8, 0.2, 0.2], "metallic": 0.0, "roughness": 0.9}
        },
        {
            "name": "surgical_scalpel",
            "type": "cube",
            "params": {"size": 0.8, "location": [0, 0, 0]},
            "material": {"name": "Scalpel_Metal", "color": [0.8, 0.8, 0.8], "metallic": 1.0, "roughness": 0.2}
        }
    ]
    
    print("🏥 Creating medical device 3D models...")
    
    for device in devices:
        print(f"\n📋 Creating {device['name']}...")
        
        # Create base geometry
        if device['type'] == 'cylinder':
            result = client.create_cylinder(**device['params'])
        elif device['type'] == 'sphere':
            result = client.create_sphere(**device['params'])
        elif device['type'] == 'cube':
            result = client.create_cube(**device['params'])
        
        if result and result.get('status') == 'success':
            print(f"  ✅ Created {device['name']} geometry")
            
            # Apply material
            material = device['material']
            result = client.apply_material(**material)
            
            if result and result.get('status') == 'success':
                print(f"  ✅ Applied {material['name']} material")
                
                # Export as USDZ
                usdz_path = os.path.join(output_dir, f"{device['name']}.usdz")
                result = client.export_usdz(usdz_path)
                
                if result and result.get('status') == 'success':
                    print(f"  ✅ Exported to {usdz_path}")
                else:
                    print(f"  ❌ Export failed for {device['name']}")
            else:
                print(f"  ❌ Material application failed for {device['name']}")
        else:
            print(f"  ❌ Geometry creation failed for {device['name']}")
        
        # Clean up
        client.delete_object()
        time.sleep(1)  # Small delay between creations
    
    client.close()
    print(f"\n🎉 Medical device creation complete! Assets saved to: {output_dir}")

def create_educational_models():
    """Create educational 3D models"""
    
    client = BlenderMCPClient()
    if not client.connect():
        print("❌ Cannot connect to Blender. Make sure the addon is enabled.")
        return
    
    output_dir = "/Volumes/Folk_DAS/Apps/MacroAI/3D_Assets/Educational"
    os.makedirs(output_dir, exist_ok=True)
    
    # Educational model definitions
    models = [
        {
            "name": "dna_helix",
            "type": "cylinder",
            "params": {"radius": 0.1, "height": 2.0, "location": [0, 0, 0]},
            "material": {"name": "DNA_Blue", "color": [0.2, 0.4, 0.8], "metallic": 0.0, "roughness": 0.7}
        },
        {
            "name": "cell_membrane",
            "type": "sphere",
            "params": {"radius": 0.8, "location": [0, 0, 0]},
            "material": {"name": "Cell_Membrane", "color": [0.9, 0.8, 0.6], "metallic": 0.0, "roughness": 0.9}
        },
        {
            "name": "bone_structure",
            "type": "cylinder",
            "params": {"radius": 0.15, "height": 1.5, "location": [0, 0, 0]},
            "material": {"name": "Bone_White", "color": [0.95, 0.95, 0.9], "metallic": 0.0, "roughness": 0.8}
        }
    ]
    
    print("📚 Creating educational 3D models...")
    
    for model in models:
        print(f"\n📋 Creating {model['name']}...")
        
        # Create geometry and export (same process as medical devices)
        if model['type'] == 'cylinder':
            result = client.create_cylinder(**model['params'])
        elif model['type'] == 'sphere':
            result = client.create_sphere(**model['params'])
        
        if result and result.get('status') == 'success':
            material = model['material']
            client.apply_material(**material)
            
            usdz_path = os.path.join(output_dir, f"{model['name']}.usdz")
            result = client.export_usdz(usdz_path)
            
            if result and result.get('status') == 'success':
                print(f"  ✅ Created {model['name']}.usdz")
        
        client.delete_object()
        time.sleep(1)
    
    client.close()
    print(f"\n🎓 Educational model creation complete! Assets saved to: {output_dir}")

if __name__ == "__main__":
    print("🏥 Medical Device & Educational 3D Asset Generator")
    print("=" * 50)
    
    # Test connection first
    client = BlenderMCPClient()
    if client.connect():
        print("✅ Blender MCP connection successful!")
        client.close()
        
        # Create assets
        create_medical_devices()
        create_educational_models()
        
        print("\n🎉 Asset generation complete!")
        print("\nNext steps:")
        print("1. Copy USDZ files to your iOS app bundle")
        print("2. Test AR Quick Look integration")
        print("3. Add to Xcode project resources")
        
    else:
        print("❌ Blender MCP connection failed!")
        print("\nTroubleshooting:")
        print("1. Make sure Blender is running")
        print("2. Enable the Blender MCP addon")
        print("3. Click 'Connect to Claude' in Blender sidebar")
        print("4. Restart the blender-mcp server if needed") 