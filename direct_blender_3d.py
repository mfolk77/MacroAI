#!/usr/bin/env python3
"""
Direct 3D Christmas Tree Creation
Creates a 3D animated Christmas tree from PNG image using Blender Python API
"""

import bpy
import os
import math
from pathlib import Path

def create_christmas_tree_3d():
    """Create a 3D animated Christmas tree from the PNG image"""
    
    # Clear existing objects
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    
    # Path to the Christmas tree image
    image_path = "/Volumes/Folk_DAS/Apps/MacroAI/MacroAI Pro/MacroAI Pro/Assets.xcassets/christmas_tree_with_sunglasses.imageset/E1D08663-4ACF-4F0E-88BF-50AD554581D5.png"
    
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
    """Export the Christmas tree as USDZ"""
    
    # Create output directory
    output_dir = Path("/Volumes/Folk_DAS/Apps/MacroAI/3D_Assets/christmas")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    usdz_path = output_dir / "christmas_tree.usdz"
    
    # Select the tree object
    tree_obj = bpy.data.objects.get("christmas_tree")
    if tree_obj:
        bpy.ops.object.select_all(action='DESELECT')
        tree_obj.select_set(True)
        bpy.context.view_layer.objects.active = tree_obj
        
        # Export as USDZ
        bpy.ops.export_scene.usdz(
            filepath=str(usdz_path),
            export_animations=True,
            export_materials=True,
            export_textures=True
        )
        
        print(f"✅ Exported to {usdz_path}")
        return usdz_path
    else:
        print("❌ Christmas tree object not found")
        return None

def main():
    """Main function to create and export the 3D Christmas tree"""
    print("🎄 Creating 3D Animated Christmas Tree")
    print("=" * 50)
    
    try:
        # Create the 3D tree
        tree_obj = create_christmas_tree_3d()
        
        # Export as USDZ
        export_path = export_christmas_tree()
        
        if export_path:
            print(f"\n🎉 Success! 3D Christmas tree created and exported!")
            print(f"📦 File: {export_path}")
            print(f"🎭 Animation: Dance (2-second loop)")
            print(f"🎨 Texture: Original PNG with sunglasses")
            
            # Also export as GLB for compatibility
            glb_path = export_path.parent / "christmas_tree.glb"
            bpy.ops.export_scene.gltf(
                filepath=str(glb_path),
                export_format='GLB',
                export_animations=True,
                export_materials=True,
                export_textures=True
            )
            print(f"📦 GLB File: {glb_path}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main() 