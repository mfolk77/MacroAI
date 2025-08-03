#!/usr/bin/env python3
"""
Simple 3D Pipeline using Blender MCP execute_code command
Creates 3D models from images using Blender Python API
"""

import json
import socket
import time
import subprocess
import shutil
from pathlib import Path
from PIL import Image
import cv2
import numpy as np

class Simple3DPipeline:
    def __init__(self):
        self.project_root = Path("/Volumes/Folk_DAS/Apps/MacroAI")
        self.assets_dir = self.project_root / "MacroAI Pro/MacroAI Pro/Assets.xcassets"
        self.themes_dir = self.project_root / "MacroAI Pro/MacroAI Pro/Resources/Themes"
        self.output_dir = self.project_root / "3D_Assets"
        self.blender_client = None
        
    def connect_to_blender(self):
        """Connect to Blender MCP server"""
        try:
            self.blender_client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.blender_client.connect(('localhost', 5000))
            print("✅ Connected to Blender MCP server")
            return True
        except Exception as e:
            print(f"❌ Failed to connect to Blender: {e}")
            return False
    
    def send_blender_command(self, command):
        """Send command to Blender"""
        try:
            self.blender_client.send(json.dumps(command).encode())
            response = self.blender_client.recv(4096).decode()
            return json.loads(response)
        except Exception as e:
            print(f"❌ Command failed: {e}")
            return None
    
    def analyze_image(self, image_path):
        """Analyze image to determine 3D modeling approach"""
        print(f"🔍 Analyzing image: {image_path}")
        
        # Load image
        img = cv2.imread(str(image_path))
        if img is None:
            raise ValueError(f"Could not load image: {image_path}")
        
        # Convert to RGB
        img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        
        # Get image dimensions
        height, width = img.shape[:2]
        
        # Analyze colors and shapes
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # Detect edges
        edges = cv2.Canny(gray, 50, 150)
        
        # Find contours
        contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        # Analyze shape complexity
        if contours:
            largest_contour = max(contours, key=cv2.contourArea)
            area = cv2.contourArea(largest_contour)
            perimeter = cv2.arcLength(largest_contour, True)
            
            # Determine if it's more circular, rectangular, or complex
            if len(largest_contour) > 4:
                # Approximate the contour to a polygon
                epsilon = 0.02 * perimeter
                approx = cv2.approxPolyDP(largest_contour, epsilon, True)
                
                if len(approx) == 3:
                    shape_type = "triangle"
                elif len(approx) == 4:
                    shape_type = "rectangle"
                elif len(approx) > 4:
                    shape_type = "complex"
                else:
                    shape_type = "circle"
            else:
                shape_type = "circle"
        else:
            shape_type = "complex"
        
        # Analyze dominant colors
        img_pil = Image.fromarray(img_rgb)
        colors = img_pil.getcolors(maxcolors=256)
        if colors:
            dominant_color = max(colors, key=lambda x: x[0])[1]
        else:
            dominant_color = (128, 128, 128)
        
        return {
            "width": width,
            "height": height,
            "shape_type": shape_type,
            "dominant_color": dominant_color,
            "area": area if contours else 0,
            "complexity": len(contours) if contours else 0
        }
    
    def create_3d_model_from_image(self, image_path, image_data):
        """Create 3D model using Blender Python API"""
        print(f"🎯 Creating 3D model for {image_data['shape_type']} shape...")
        
        # Copy image to a temporary location for Blender
        temp_dir = Path("/tmp/blender_textures")
        temp_dir.mkdir(exist_ok=True)
        
        texture_path = temp_dir / Path(image_path).name
        shutil.copy2(image_path, texture_path)
        
        # Create Blender Python code based on shape analysis
        if image_data['shape_type'] == "triangle":
            blender_code = f'''
import bpy
import math

# Clear existing objects
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

# Create cone for triangular shape (like Christmas tree)
bpy.ops.mesh.primitive_cone_add(
    radius1=1.0,
    radius2=0.0,
    depth=2.0,
    location=(0, 0, 1)
)

# Get the created object
obj = bpy.context.active_object
obj.name = "{Path(image_path).stem}"

# Add material
mat = bpy.data.materials.new(name="ImageMaterial")
mat.use_nodes = True
nodes = mat.node_tree.nodes
links = mat.node_tree.links

# Clear default nodes
nodes.clear()

# Add texture node
tex_node = nodes.new(type='ShaderNodeTexImage')
tex_node.image = bpy.data.images.load("{texture_path}")

# Add principled BSDF
bsdf_node = nodes.new(type='ShaderNodeBsdfPrincipled')

# Add output node
output_node = nodes.new(type='ShaderNodeOutputMaterial')

# Link nodes
links.new(tex_node.outputs['Color'], bsdf_node.inputs['Base Color'])
links.new(bsdf_node.outputs['BSDF'], output_node.inputs['Surface'])

# Assign material to object
if obj.data.materials:
    obj.data.materials[0] = mat
else:
    obj.data.materials.append(mat)

# Add some basic lighting
bpy.ops.object.light_add(type='SUN', location=(5, 5, 10))
sun = bpy.context.active_object
sun.data.energy = 5.0

# Add camera
bpy.ops.object.camera_add(location=(3, -3, 2))
camera = bpy.context.active_object
camera.rotation_euler = (math.radians(60), 0, math.radians(45))

# Set camera as active
bpy.context.scene.camera = camera

print("3D model created successfully")
'''
        elif image_data['shape_type'] == "circle":
            blender_code = f'''
import bpy
import math

# Clear existing objects
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

# Create sphere for circular shape
bpy.ops.mesh.primitive_uv_sphere_add(
    radius=1.0,
    location=(0, 0, 0)
)

# Get the created object
obj = bpy.context.active_object
obj.name = "{Path(image_path).stem}"

# Add material
mat = bpy.data.materials.new(name="ImageMaterial")
mat.use_nodes = True
nodes = mat.node_tree.nodes
links = mat.node_tree.links

# Clear default nodes
nodes.clear()

# Add texture node
tex_node = nodes.new(type='ShaderNodeTexImage')
tex_node.image = bpy.data.images.load("{texture_path}")

# Add principled BSDF
bsdf_node = nodes.new(type='ShaderNodeBsdfPrincipled')

# Add output node
output_node = nodes.new(type='ShaderNodeOutputMaterial')

# Link nodes
links.new(tex_node.outputs['Color'], bsdf_node.inputs['Base Color'])
links.new(bsdf_node.outputs['BSDF'], output_node.inputs['Surface'])

# Assign material to object
if obj.data.materials:
    obj.data.materials[0] = mat
else:
    obj.data.materials.append(mat)

# Add lighting
bpy.ops.object.light_add(type='SUN', location=(5, 5, 10))
sun = bpy.context.active_object
sun.data.energy = 5.0

# Add camera
bpy.ops.object.camera_add(location=(3, -3, 2))
camera = bpy.context.active_object
camera.rotation_euler = (math.radians(60), 0, math.radians(45))

# Set camera as active
bpy.context.scene.camera = camera

print("3D model created successfully")
'''
        else:
            # Default to cylinder for complex shapes
            blender_code = f'''
import bpy
import math

# Clear existing objects
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

# Create cylinder for complex shape
bpy.ops.mesh.primitive_cylinder_add(
    radius=0.5,
    depth=1.5,
    location=(0, 0, 0.75)
)

# Get the created object
obj = bpy.context.active_object
obj.name = "{Path(image_path).stem}"

# Add material
mat = bpy.data.materials.new(name="ImageMaterial")
mat.use_nodes = True
nodes = mat.node_tree.nodes
links = mat.node_tree.links

# Clear default nodes
nodes.clear()

# Add texture node
tex_node = nodes.new(type='ShaderNodeTexImage')
tex_node.image = bpy.data.images.load("{texture_path}")

# Add principled BSDF
bsdf_node = nodes.new(type='ShaderNodeBsdfPrincipled')

# Add output node
output_node = nodes.new(type='ShaderNodeOutputMaterial')

# Link nodes
links.new(tex_node.outputs['Color'], bsdf_node.inputs['Base Color'])
links.new(bsdf_node.outputs['BSDF'], output_node.inputs['Surface'])

# Assign material to object
if obj.data.materials:
    obj.data.materials[0] = mat
else:
    obj.data.materials.append(mat)

# Add lighting
bpy.ops.object.light_add(type='SUN', location=(5, 5, 10))
sun = bpy.context.active_object
sun.data.energy = 5.0

# Add camera
bpy.ops.object.camera_add(location=(3, -3, 2))
camera = bpy.context.active_object
camera.rotation_euler = (math.radians(60), 0, math.radians(45))

# Set camera as active
bpy.context.scene.camera = camera

print("3D model created successfully")
'''
        
        # Send the code to Blender
        command = {
            "type": "execute_code",
            "params": {
                "code": blender_code
            }
        }
        
        result = self.send_blender_command(command)
        if not result or result.get('status') != 'success':
            raise Exception(f"Failed to create 3D model: {result}")
        
        print("✅ 3D model created successfully")
        return Path(image_path).stem
    
    def add_animations(self, model_name, animation_type):
        """Add animations to the 3D model"""
        print(f"💃 Adding {animation_type} animation...")
        
        if animation_type == "dance":
            animation_code = f'''
import bpy
import math

# Get the object
obj = bpy.data.objects.get("{model_name}")
if not obj:
    print("Object not found")
    exit()

# Clear existing animations
obj.animation_data_clear()

# Create new animation data
obj.animation_data_create()
action = bpy.data.actions.new(name="{model_name}_dance")
obj.animation_data.action = action

# Add scale animation (dance)
fcurve_scale_x = action.fcurves.new(data_path="scale", index=0)
fcurve_scale_y = action.fcurves.new(data_path="scale", index=1)
fcurve_scale_z = action.fcurves.new(data_path="scale", index=2)

# Add rotation animation (sway)
fcurve_rot_z = action.fcurves.new(data_path="rotation_euler", index=2)

# Create keyframes for scale animation (30 frames = 1 second at 30fps)
for frame in range(0, 60, 2):
    # Scale animation
    scale_factor = 1.0 + 0.05 * math.sin(frame * math.pi / 15)
    fcurve_scale_x.keyframe_points.insert(frame, scale_factor)
    fcurve_scale_y.keyframe_points.insert(frame, scale_factor)
    fcurve_scale_z.keyframe_points.insert(frame, scale_factor)
    
    # Rotation animation
    rot_factor = 0.05 * math.sin(frame * math.pi / 30)
    fcurve_rot_z.keyframe_points.insert(frame, rot_factor)

# Set interpolation to linear for smooth animation
for fcurve in [fcurve_scale_x, fcurve_scale_y, fcurve_scale_z, fcurve_rot_z]:
    for keyframe in fcurve.keyframe_points:
        keyframe.interpolation = 'LINEAR'

# Set animation to loop
action.use_cyclic = True

# Set render settings
bpy.context.scene.frame_start = 0
bpy.context.scene.frame_end = 60
bpy.context.scene.render.fps = 30

print("Dance animation added successfully")
'''
        elif animation_type == "bounce":
            animation_code = f'''
import bpy
import math

# Get the object
obj = bpy.data.objects.get("{model_name}")
if not obj:
    print("Object not found")
    exit()

# Clear existing animations
obj.animation_data_clear()

# Create new animation data
obj.animation_data_create()
action = bpy.data.actions.new(name="{model_name}_bounce")
obj.animation_data.action = action

# Add location animation (bounce)
fcurve_loc_z = action.fcurves.new(data_path="location", index=2)

# Create keyframes for bounce animation
for frame in range(0, 60, 2):
    # Bounce animation
    bounce_height = 0.2 * math.sin(frame * math.pi / 15)
    fcurve_loc_z.keyframe_points.insert(frame, bounce_height)

# Set interpolation to linear for smooth animation
for keyframe in fcurve_loc_z.keyframe_points:
    keyframe.interpolation = 'LINEAR'

# Set animation to loop
action.use_cyclic = True

# Set render settings
bpy.context.scene.frame_start = 0
bpy.context.scene.frame_end = 60
bpy.context.scene.render.fps = 30

print("Bounce animation added successfully")
'''
        else:
            # Default to dance
            animation_code = f'''
import bpy
import math

# Get the object
obj = bpy.data.objects.get("{model_name}")
if not obj:
    print("Object not found")
    exit()

# Clear existing animations
obj.animation_data_clear()

# Create new animation data
obj.animation_data_create()
action = bpy.data.actions.new(name="{model_name}_dance")
obj.animation_data.action = action

# Add scale animation
fcurve_scale_x = action.fcurves.new(data_path="scale", index=0)
fcurve_scale_y = action.fcurves.new(data_path="scale", index=1)
fcurve_scale_z = action.fcurves.new(data_path="scale", index=2)

# Create keyframes for scale animation
for frame in range(0, 60, 2):
    scale_factor = 1.0 + 0.05 * math.sin(frame * math.pi / 15)
    fcurve_scale_x.keyframe_points.insert(frame, scale_factor)
    fcurve_scale_y.keyframe_points.insert(frame, scale_factor)
    fcurve_scale_z.keyframe_points.insert(frame, scale_factor)

# Set interpolation to linear for smooth animation
for fcurve in [fcurve_scale_x, fcurve_scale_y, fcurve_scale_z]:
    for keyframe in fcurve.keyframe_points:
        keyframe.interpolation = 'LINEAR'

# Set animation to loop
action.use_cyclic = True

# Set render settings
bpy.context.scene.frame_start = 0
bpy.context.scene.frame_end = 60
bpy.context.scene.render.fps = 30

print("Animation added successfully")
'''
        
        # Send animation code to Blender
        command = {
            "type": "execute_code",
            "params": {
                "code": animation_code
            }
        }
        
        result = self.send_blender_command(command)
        if not result or result.get('status') != 'success':
            print(f"⚠️ Animation addition failed: {result}")
        else:
            print("✅ Animation added successfully")
    
    def export_model(self, model_name, theme_name):
        """Export the 3D model as USDZ"""
        print(f"📦 Exporting {model_name} as USDZ...")
        
        # Create theme-specific output directory
        theme_output_dir = self.output_dir / theme_name
        theme_output_dir.mkdir(parents=True, exist_ok=True)
        
        usdz_path = theme_output_dir / f"{model_name}.usdz"
        
        # Export code for Blender
        export_code = f'''
import bpy
import os

# Get the object
obj = bpy.data.objects.get("{model_name}")
if not obj:
    print("Object not found for export")
    exit()

# Select the object
bpy.ops.object.select_all(action='DESELECT')
obj.select_set(True)
bpy.context.view_layer.objects.active = obj

# Export as USDZ
bpy.ops.export_scene.usdz(
    filepath="{usdz_path}",
    export_animations=True,
    export_skins=True,
    export_all_influences=True,
    export_materials=True,
    export_textures=True,
    export_face_forward=True,
    export_convert_orientation=True,
    export_scale=1.0,
    export_apply_scale=True,
    export_primitive_attributes=True,
    export_use_instancing=True,
    export_use_metadata=True,
    export_use_hair=True,
    export_use_particles=True,
    export_use_uv=True,
    export_use_normals=True,
    export_use_materials=True,
    export_use_textures=True,
    export_use_face_forward=True,
    export_use_convert_orientation=True,
    export_use_apply_scale=True,
    export_use_primitive_attributes=True,
    export_use_instancing=True,
    export_use_metadata=True,
    export_use_hair=True,
    export_use_particles=True,
    export_use_uv=True,
    export_use_normals=True,
    export_use_materials=True,
    export_use_textures=True
)

print(f"Exported to {{usdz_path}}")
'''
        
        # Send export code to Blender
        command = {
            "type": "execute_code",
            "params": {
                "code": export_code
            }
        }
        
        result = self.send_blender_command(command)
        if not result or result.get('status') != 'success':
            print(f"⚠️ USDZ export failed: {result}")
            # Try alternative export method
            return self.export_as_glb(model_name, theme_name)
        
        print(f"✅ Exported to {usdz_path}")
        return usdz_path
    
    def export_as_glb(self, model_name, theme_name):
        """Export as GLB as fallback"""
        print(f"📦 Exporting {model_name} as GLB...")
        
        theme_output_dir = self.output_dir / theme_name
        theme_output_dir.mkdir(parents=True, exist_ok=True)
        
        glb_path = theme_output_dir / f"{model_name}.glb"
        
        export_code = f'''
import bpy
import os

# Get the object
obj = bpy.data.objects.get("{model_name}")
if not obj:
    print("Object not found for export")
    exit()

# Select the object
bpy.ops.object.select_all(action='DESELECT')
obj.select_set(True)
bpy.context.view_layer.objects.active = obj

# Export as GLB
bpy.ops.export_scene.gltf(
    filepath="{glb_path}",
    export_format='GLB',
    export_animations=True,
    export_skins=True,
    export_all_influences=True,
    export_materials=True,
    export_textures=True,
    export_face_forward=True,
    export_convert_orientation=True,
    export_scale=1.0,
    export_apply_scale=True,
    export_primitive_attributes=True,
    export_use_instancing=True,
    export_use_metadata=True,
    export_use_hair=True,
    export_use_particles=True,
    export_use_uv=True,
    export_use_normals=True,
    export_use_materials=True,
    export_use_textures=True,
    export_use_face_forward=True,
    export_use_convert_orientation=True,
    export_use_apply_scale=True,
    export_use_primitive_attributes=True,
    export_use_instancing=True,
    export_use_metadata=True,
    export_use_hair=True,
    export_use_particles=True,
    export_use_uv=True,
    export_use_normals=True,
    export_use_materials=True,
    export_use_textures=True
)

print(f"Exported to {{glb_path}}")
'''
        
        command = {
            "type": "execute_code",
            "params": {
                "code": export_code
            }
        }
        
        result = self.send_blender_command(command)
        if not result or result.get('status') != 'success':
            raise Exception(f"Failed to export model: {result}")
        
        print(f"✅ Exported to {glb_path}")
        return glb_path
    
    def process_image_to_3d(self, image_path, theme_name, animation_type="dance"):
        """Convert PNG image to 3D animated model"""
        print(f"🎨 Processing {image_path} for {theme_name} theme...")
        
        # Step 1: Analyze image
        image_data = self.analyze_image(image_path)
        
        # Step 2: Create 3D model in Blender
        model_name = self.create_3d_model_from_image(image_path, image_data)
        
        # Step 3: Add animations
        self.add_animations(model_name, animation_type)
        
        # Step 4: Export as USDZ/GLB
        export_path = self.export_model(model_name, theme_name)
        
        print(f"🎉 Successfully created 3D model: {export_path}")
        return export_path
    
    def close(self):
        """Close Blender connection"""
        if self.blender_client:
            self.blender_client.close()

def main():
    """Test the simple 3D pipeline"""
    print("🎨 Simple 3D Pipeline Test")
    print("=" * 40)
    
    pipeline = Simple3DPipeline()
    
    if not pipeline.connect_to_blender():
        print("❌ Cannot connect to Blender. Make sure the addon is enabled.")
        return
    
    try:
        # Test with Christmas tree image
        christmas_tree_path = Path("/Volumes/Folk_DAS/Apps/MacroAI/MacroAI Pro/MacroAI Pro/Assets.xcassets/christmas_tree_with_sunglasses.imageset/E1D08663-4ACF-4F0E-88BF-50AD554581D5.png")
        
        if christmas_tree_path.exists():
            print(f"✅ Found Christmas tree image: {christmas_tree_path}")
            
            # Process the image
            export_path = pipeline.process_image_to_3d(
                christmas_tree_path,
                "christmas",
                "dance"
            )
            
            print(f"\n🎉 Pipeline completed successfully!")
            print(f"📦 3D Model: {export_path}")
            
        else:
            print(f"❌ Christmas tree image not found: {christmas_tree_path}")
    
    except Exception as e:
        print(f"❌ Pipeline failed: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        pipeline.close()

if __name__ == "__main__":
    main() 