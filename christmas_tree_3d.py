#!/usr/bin/env python3
"""
3D Christmas Tree Creation Script for Blender
Run this script directly in Blender to create a 3D animated Christmas tree
"""

import bpy
import os
import math
from pathlib import Path

def create_christmas_tree_3d():
    """Create a 3D animated Christmas tree from the PNG image"""
    
    print("🎄 Creating 3D Christmas Tree...")
    
    # Clear existing objects
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    
    # Path to the Christmas tree image
    image_path = "/Volumes/Folk_DAS/Apps/MacroAI/MacroAI Pro/MacroAI Pro/Assets.xcassets/christmas_tree_with_sunglasses.imageset/E1D08663-4ACF-4F0E-88BF-50AD554581D5.png"
    
    # Check if image exists
    if not os.path.exists(image_path):
        print(f"❌ Image not found: {image_path}")
        return None
    
    # Create cone for Christmas tree shape
    bpy.ops.mesh.primitive_cone_add(
        radius1=1.2,
        radius2=0.0,
        depth=2.5,
        location=(0, 0, 1.25)
    )
    
    # Get the created object
    tree_obj = bpy.context.active_object
    tree_obj.name = "christmas_tree"
    
    # Add material with the image texture
    mat = bpy.data.materials.new(name="ChristmasTreeMaterial")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    
    # Clear default nodes
    nodes.clear()
    
    # Add texture node
    tex_node = nodes.new(type='ShaderNodeTexImage')
    tex_node.image = bpy.data.images.load(image_path)
    
    # Add principled BSDF
    bsdf_node = nodes.new(type='ShaderNodeBsdfPrincipled')
    
    # Add output node
    output_node = nodes.new(type='ShaderNodeOutputMaterial')
    
    # Link nodes
    links.new(tex_node.outputs['Color'], bsdf_node.inputs['Base Color'])
    links.new(bsdf_node.outputs['BSDF'], output_node.inputs['Surface'])
    
    # Assign material to object
    if tree_obj.data.materials:
        tree_obj.data.materials[0] = mat
    else:
        tree_obj.data.materials.append(mat)
    
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
    
    # Add dance animation
    add_dance_animation(tree_obj)
    
    print("✅ 3D Christmas tree created successfully!")
    return tree_obj

def add_dance_animation(obj):
    """Add dance animation to the object"""
    
    print("💃 Adding dance animation...")
    
    # Clear existing animations
    obj.animation_data_clear()
    
    # Create new animation data
    obj.animation_data_create()
    action = bpy.data.actions.new(name="christmas_tree_dance")
    obj.animation_data.action = action
    
    # Add scale animation (dance)
    fcurve_scale_x = action.fcurves.new(data_path="scale", index=0)
    fcurve_scale_y = action.fcurves.new(data_path="scale", index=1)
    fcurve_scale_z = action.fcurves.new(data_path="scale", index=2)
    
    # Add rotation animation (sway)
    fcurve_rot_z = action.fcurves.new(data_path="rotation_euler", index=2)
    
    # Create keyframes for scale animation (60 frames = 2 seconds at 30fps)
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
    
    print("✅ Dance animation added successfully!")

def export_christmas_tree():
    """Export the Christmas tree as GLB"""
    
    print("📦 Exporting Christmas tree...")
    
    # Create output directory
    output_dir = Path("/Volumes/Folk_DAS/Apps/MacroAI/3D_Assets/christmas")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    glb_path = output_dir / "christmas_tree.glb"
    
    # Select the tree object
    tree_obj = bpy.data.objects.get("christmas_tree")
    if tree_obj:
        bpy.ops.object.select_all(action='DESELECT')
        tree_obj.select_set(True)
        bpy.context.view_layer.objects.active = tree_obj
        
        # Export as GLB (works great for iOS too!)
        bpy.ops.export_scene.gltf(
            filepath=str(glb_path)
        )
        
        print(f"✅ Exported to {glb_path}")
        
        return glb_path
    else:
        print("❌ Christmas tree object not found")
        return None

# Main execution
if __name__ == "__main__":
    print("🎄 3D Christmas Tree Creation")
    print("=" * 40)
    
    try:
        # Create the 3D tree
        tree_obj = create_christmas_tree_3d()
        
        if tree_obj:
            # Export as USDZ
            export_path = export_christmas_tree()
            
            if export_path:
                print(f"\n🎉 Success! 3D Christmas tree created and exported!")
                print(f"📦 GLB File: {export_path}")
                print(f"🎭 Animation: Dance (2-second loop)")
                print(f"🎨 Texture: Original PNG with sunglasses")
                print(f"🎯 Shape: Cone (perfect for Christmas tree)")
                print(f"💫 Ready for iOS AR integration!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc() 