#!/usr/bin/env python3
"""
Realistic 3D Christmas Tree Creation in Blender
Creates a detailed Christmas tree with branches, ornaments, lights, and star
"""

import bpy
import os
import math
import random
from pathlib import Path

def create_realistic_christmas_tree():
    """Create a realistic 3D Christmas tree with proper geometry"""
    
    print("🎄 Creating Realistic 3D Christmas Tree...")
    
    # Clear existing objects
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    
    # Path to the Christmas tree image for texture
    image_path = "/Volumes/Folk_DAS/Apps/MacroAI/MacroAI Pro/MacroAI Pro/Assets.xcassets/christmas_tree_with_sunglasses.imageset/E1D08663-4ACF-4F0E-88BF-50AD554581D5.png"
    
    # Create the main tree trunk
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.1,
        depth=0.5,
        location=(0, 0, 0.25)
    )
    trunk = bpy.context.active_object
    trunk.name = "tree_trunk"
    
    # Add brown material to trunk
    trunk_mat = bpy.data.materials.new(name="TrunkMaterial")
    trunk_mat.use_nodes = True
    nodes = trunk_mat.node_tree.nodes
    nodes.clear()
    
    bsdf_node = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf_node.inputs['Base Color'].default_value = (0.4, 0.2, 0.1, 1.0)  # Brown
    bsdf_node.inputs['Roughness'].default_value = 0.8
    
    output_node = nodes.new(type='ShaderNodeOutputMaterial')
    trunk_mat.node_tree.links.new(bsdf_node.outputs['BSDF'], output_node.inputs['Surface'])
    
    if trunk.data.materials:
        trunk.data.materials[0] = trunk_mat
    else:
        trunk.data.materials.append(trunk_mat)
    
    # Create multiple tree layers (branches)
    tree_layers = []
    layer_count = 8
    base_radius = 0.8
    height_per_layer = 0.4
    
    for i in range(layer_count):
        # Create cone for each layer
        radius = base_radius * (1 - i * 0.15)  # Decreasing radius
        height = height_per_layer * (1 - i * 0.1)  # Decreasing height
        z_pos = 0.5 + i * height_per_layer * 0.8
        
        bpy.ops.mesh.primitive_cone_add(
            radius1=radius,
            radius2=radius * 0.7,
            depth=height,
            location=(0, 0, z_pos)
        )
        
        layer = bpy.context.active_object
        layer.name = f"tree_layer_{i}"
        tree_layers.append(layer)
        
        # Add green material to branches
        branch_mat = bpy.data.materials.new(name=f"BranchMaterial_{i}")
        branch_mat.use_nodes = True
        nodes = branch_mat.node_tree.nodes
        nodes.clear()
        
        bsdf_node = nodes.new(type='ShaderNodeBsdfPrincipled')
        # Vary green shades for realism
        green_intensity = 0.6 + (i * 0.05)
        bsdf_node.inputs['Base Color'].default_value = (0.1, green_intensity, 0.1, 1.0)
        bsdf_node.inputs['Roughness'].default_value = 0.7
        
        output_node = nodes.new(type='ShaderNodeOutputMaterial')
        branch_mat.node_tree.links.new(bsdf_node.outputs['BSDF'], output_node.inputs['Surface'])
        
        if layer.data.materials:
            layer.data.materials[0] = branch_mat
        else:
            layer.data.materials.append(branch_mat)
    
    # Create star on top
    bpy.ops.mesh.primitive_cone_add(
        radius1=0.2,
        radius2=0.0,
        depth=0.4,
        location=(0, 0, 4.0)
    )
    star = bpy.context.active_object
    star.name = "tree_star"
    
    # Add gold material to star
    star_mat = bpy.data.materials.new(name="StarMaterial")
    star_mat.use_nodes = True
    nodes = star_mat.node_tree.nodes
    nodes.clear()
    
    bsdf_node = nodes.new(type='ShaderNodeBsdfPrincipled')
    bsdf_node.inputs['Base Color'].default_value = (1.0, 0.8, 0.0, 1.0)  # Gold
    bsdf_node.inputs['Metallic'].default_value = 0.8
    bsdf_node.inputs['Roughness'].default_value = 0.2
    
    output_node = nodes.new(type='ShaderNodeOutputMaterial')
    star_mat.node_tree.links.new(bsdf_node.outputs['BSDF'], output_node.inputs['Surface'])
    
    if star.data.materials:
        star.data.materials[0] = star_mat
    else:
        star.data.materials.append(star_mat)
    
    # Add ornaments (spheres)
    ornaments = []
    for i in range(15):
        # Random position on tree
        angle = random.uniform(0, 2 * math.pi)
        radius = random.uniform(0.3, 1.2)
        height = random.uniform(0.8, 3.5)
        
        x = radius * math.cos(angle)
        y = radius * math.sin(angle)
        
        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=0.08,
            location=(x, y, height)
        )
        
        ornament = bpy.context.active_object
        ornament.name = f"ornament_{i}"
        ornaments.append(ornament)
        
        # Add colorful material to ornaments
        ornament_mat = bpy.data.materials.new(name=f"OrnamentMaterial_{i}")
        ornament_mat.use_nodes = True
        nodes = ornament_mat.node_tree.nodes
        nodes.clear()
        
        bsdf_node = nodes.new(type='ShaderNodeBsdfPrincipled')
        # Random colors for ornaments
        colors = [
            (1.0, 0.0, 0.0, 1.0),  # Red
            (0.0, 0.0, 1.0, 1.0),  # Blue
            (1.0, 1.0, 0.0, 1.0),  # Yellow
            (1.0, 0.0, 1.0, 1.0),  # Magenta
            (0.0, 1.0, 1.0, 1.0),  # Cyan
        ]
        color = random.choice(colors)
        bsdf_node.inputs['Base Color'].default_value = color
        bsdf_node.inputs['Metallic'].default_value = 0.3
        bsdf_node.inputs['Roughness'].default_value = 0.4
        
        output_node = nodes.new(type='ShaderNodeOutputMaterial')
        ornament_mat.node_tree.links.new(bsdf_node.outputs['BSDF'], output_node.inputs['Surface'])
        
        if ornament.data.materials:
            ornament.data.materials[0] = ornament_mat
        else:
            ornament.data.materials.append(ornament_mat)
    
    # Add lights (small spheres)
    lights = []
    for i in range(20):
        # Random position on tree
        angle = random.uniform(0, 2 * math.pi)
        radius = random.uniform(0.2, 1.0)
        height = random.uniform(0.6, 3.8)
        
        x = radius * math.cos(angle)
        y = radius * math.sin(angle)
        
        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=0.05,
            location=(x, y, height)
        )
        
        light = bpy.context.active_object
        light.name = f"light_{i}"
        lights.append(light)
        
        # Add glowing material to lights
        light_mat = bpy.data.materials.new(name=f"LightMaterial_{i}")
        light_mat.use_nodes = True
        nodes = light_mat.node_tree.nodes
        nodes.clear()
        
        # Emission shader for glow effect
        emission_node = nodes.new(type='ShaderNodeEmission')
        emission_node.inputs['Color'].default_value = (1.0, 1.0, 0.8, 1.0)  # Warm light
        emission_node.inputs['Strength'].default_value = 2.0
        
        output_node = nodes.new(type='ShaderNodeOutputMaterial')
        light_mat.node_tree.links.new(emission_node.outputs['Emission'], output_node.inputs['Surface'])
        
        if light.data.materials:
            light.data.materials[0] = light_mat
        else:
            light.data.materials.append(light_mat)
    
    # Add some lighting to the scene
    bpy.ops.object.light_add(type='SUN', location=(5, 5, 10))
    sun = bpy.context.active_object
    sun.data.energy = 3.0
    
    # Add ambient light
    bpy.ops.object.light_add(type='AREA', location=(0, 0, 8))
    ambient = bpy.context.active_object
    ambient.data.energy = 2.0
    ambient.data.size = 10.0
    
    # Add camera
    bpy.ops.object.camera_add(location=(3, -3, 2))
    camera = bpy.context.active_object
    camera.rotation_euler = (math.radians(60), 0, math.radians(45))
    bpy.context.scene.camera = camera
    
    # Add dance animation to the whole tree
    add_tree_dance_animation(tree_layers + ornaments + lights + [star])
    
    print("✅ Realistic 3D Christmas tree created successfully!")
    return tree_layers + ornaments + lights + [star, trunk]

def add_tree_dance_animation(objects):
    """Add dance animation to all tree objects"""
    
    print("💃 Adding dance animation...")
    
    for obj in objects:
        # Clear existing animations
        obj.animation_data_clear()
        
        # Create new animation data
        obj.animation_data_create()
        action = bpy.data.actions.new(name=f"{obj.name}_dance")
        obj.animation_data.action = action
        
        # Add scale animation (gentle dance)
        fcurve_scale_x = action.fcurves.new(data_path="scale", index=0)
        fcurve_scale_y = action.fcurves.new(data_path="scale", index=1)
        fcurve_scale_z = action.fcurves.new(data_path="scale", index=2)
        
        # Add rotation animation (sway)
        fcurve_rot_z = action.fcurves.new(data_path="rotation_euler", index=2)
        
        # Create keyframes for scale animation (60 frames = 2 seconds at 30fps)
        for frame in range(0, 60, 2):
            # Scale animation - gentler for realistic tree
            scale_factor = 1.0 + 0.02 * math.sin(frame * math.pi / 15)
            fcurve_scale_x.keyframe_points.insert(frame, scale_factor)
            fcurve_scale_y.keyframe_points.insert(frame, scale_factor)
            fcurve_scale_z.keyframe_points.insert(frame, scale_factor)
            
            # Rotation animation - subtle sway
            rot_factor = 0.02 * math.sin(frame * math.pi / 30)
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

def export_realistic_christmas_tree():
    """Export the realistic Christmas tree as GLB"""
    
    print("📦 Exporting realistic Christmas tree...")
    
    # Create output directory
    output_dir = Path("/Volumes/Folk_DAS/Apps/MacroAI/3D_Assets/christmas")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    glb_path = output_dir / "realistic_christmas_tree.glb"
    
    # Select all tree objects
    bpy.ops.object.select_all(action='DESELECT')
    
    # Select all tree-related objects
    tree_objects = [obj for obj in bpy.data.objects if obj.name.startswith(('tree_', 'ornament_', 'light_'))]
    for obj in tree_objects:
        obj.select_set(True)
    
    if tree_objects:
        bpy.context.view_layer.objects.active = tree_objects[0]
        
        # Export as GLB
        bpy.ops.export_scene.gltf(
            filepath=str(glb_path)
        )
        
        print(f"✅ Exported to {glb_path}")
        return glb_path
    else:
        print("❌ Tree objects not found")
        return None

# Main execution
if __name__ == "__main__":
    print("🎄 Realistic 3D Christmas Tree Creation")
    print("=" * 50)
    
    try:
        # Create the realistic 3D tree
        tree_objects = create_realistic_christmas_tree()
        
        if tree_objects:
            # Export as GLB
            export_path = export_realistic_christmas_tree()
            
            if export_path:
                print(f"\n🎉 Success! Realistic 3D Christmas tree created and exported!")
                print(f"📦 GLB File: {export_path}")
                print(f"🎭 Animation: Gentle dance (2-second loop)")
                print(f"🎨 Features: Multiple branches, ornaments, lights, star")
                print(f"🎯 Geometry: Realistic tree structure")
                print(f"💫 Ready for iOS AR integration!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc() 