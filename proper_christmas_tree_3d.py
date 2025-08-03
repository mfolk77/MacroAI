import bpy
import bmesh
import math
import os
from pathlib import Path

def clear_scene():
    """Clear all objects from the scene"""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

def create_realistic_christmas_tree():
    """Create a detailed, realistic Christmas tree"""
    
    # Clear the scene
    clear_scene()
    
    # Create the main tree trunk
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.1, 
        depth=0.8, 
        location=(0, 0, 0.4)
    )
    trunk = bpy.context.active_object
    trunk.name = "tree_trunk"
    
    # Add bark material to trunk
    trunk_mat = bpy.data.materials.new(name="BarkMaterial")
    trunk_mat.use_nodes = True
    nodes = trunk_mat.node_tree.nodes
    nodes.clear()
    
    # Principled BSDF for bark
    principled = nodes.new(type='ShaderNodeBsdfPrincipled')
    principled.inputs['Base Color'].default_value = (0.3, 0.2, 0.1, 1.0)
    principled.inputs['Roughness'].default_value = 0.8
    trunk_mat.node_tree.links.new(
        principled.outputs['BSDF'],
        nodes.new(type='ShaderNodeOutputMaterial').inputs['Surface']
    )
    trunk.data.materials.append(trunk_mat)
    
    # Create multiple tree layers (branches)
    tree_layers = []
    layer_count = 8
    base_radius = 0.8
    height_per_layer = 0.4
    
    for i in range(layer_count):
        # Calculate layer properties
        layer_height = 0.8 + (i * height_per_layer)
        layer_radius = base_radius - (i * 0.08)
        layer_vertices = 12 + (i * 2)  # More vertices for lower layers
        
        # Create cone for this layer
        bpy.ops.mesh.primitive_cone_add(
            radius1=layer_radius,
            radius2=layer_radius * 0.7,
            depth=height_per_layer,
            vertices=layer_vertices,
            location=(0, 0, layer_height)
        )
        layer = bpy.context.active_object
        layer.name = f"tree_layer_{i}"
        tree_layers.append(layer)
        
        # Add slight rotation for natural look
        layer.rotation_euler.z = (i * 0.1) * math.pi / 180
    
    # Create detailed branch material
    branch_mat = bpy.data.materials.new(name="BranchMaterial")
    branch_mat.use_nodes = True
    nodes = branch_mat.node_tree.nodes
    nodes.clear()
    
    # Principled BSDF for branches
    principled = nodes.new(type='ShaderNodeBsdfPrincipled')
    principled.inputs['Base Color'].default_value = (0.1, 0.4, 0.1, 1.0)  # Dark green
    principled.inputs['Roughness'].default_value = 0.6
    
    # Add some variation with noise
    noise = nodes.new(type='ShaderNodeTexNoise')
    noise.inputs['Scale'].default_value = 5.0
    noise.inputs['Detail'].default_value = 2.0
    
    # Mix the noise with base color
    mix = nodes.new(type='ShaderNodeMixRGB')
    mix.blend_type = 'MULTIPLY'
    mix.inputs['Fac'].default_value = 0.3
    mix.inputs['Color1'].default_value = (0.1, 0.4, 0.1, 1.0)
    mix.inputs['Color2'].default_value = (0.05, 0.3, 0.05, 1.0)
    
    # Connect nodes
    branch_mat.node_tree.links.new(noise.outputs['Color'], mix.inputs['Fac'])
    branch_mat.node_tree.links.new(mix.outputs['Color'], principled.inputs['Base Color'])
    branch_mat.node_tree.links.new(
        principled.outputs['BSDF'],
        nodes.new(type='ShaderNodeOutputMaterial').inputs['Surface']
    )
    
    # Apply material to all layers
    for layer in tree_layers:
        layer.data.materials.append(branch_mat)
    
    # Create tree topper (star)
    bpy.ops.mesh.primitive_cone_add(
        radius1=0.15,
        radius2=0.0,
        depth=0.3,
        vertices=5,
        location=(0, 0, 3.2)
    )
    topper = bpy.context.active_object
    topper.name = "tree_topper"
    
    # Star material (gold)
    star_mat = bpy.data.materials.new(name="StarMaterial")
    star_mat.use_nodes = True
    nodes = star_mat.node_tree.nodes
    nodes.clear()
    
    principled = nodes.new(type='ShaderNodeBsdfPrincipled')
    principled.inputs['Base Color'].default_value = (1.0, 0.8, 0.0, 1.0)  # Gold
    principled.inputs['Metallic'].default_value = 0.8
    principled.inputs['Roughness'].default_value = 0.2
    principled.inputs['Emission Color'].default_value = (0.2, 0.15, 0.0, 1.0)
    principled.inputs['Emission Strength'].default_value = 0.5
    
    star_mat.node_tree.links.new(
        principled.outputs['BSDF'],
        nodes.new(type='ShaderNodeOutputMaterial').inputs['Surface']
    )
    topper.data.materials.append(star_mat)
    
    # Add ornaments (spheres)
    ornaments = []
    for i in range(12):
        angle = (i * 30) * math.pi / 180
        radius = 0.6 + (i % 3) * 0.2
        height = 1.0 + (i * 0.2)
        
        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=0.08,
            location=(radius * math.cos(angle), radius * math.sin(angle), height)
        )
        ornament = bpy.context.active_object
        ornament.name = f"ornament_{i}"
        ornaments.append(ornament)
        
        # Ornament material (red, blue, gold)
        colors = [(1.0, 0.0, 0.0, 1.0), (0.0, 0.0, 1.0, 1.0), (1.0, 0.8, 0.0, 1.0)]
        ornament_mat = bpy.data.materials.new(name=f"OrnamentMaterial_{i}")
        ornament_mat.use_nodes = True
        nodes = ornament_mat.node_tree.nodes
        nodes.clear()
        
        principled = nodes.new(type='ShaderNodeBsdfPrincipled')
        principled.inputs['Base Color'].default_value = colors[i % 3]
        principled.inputs['Metallic'].default_value = 0.3
        principled.inputs['Roughness'].default_value = 0.1
        
        ornament_mat.node_tree.links.new(
            principled.outputs['BSDF'],
            nodes.new(type='ShaderNodeOutputMaterial').inputs['Surface']
        )
        ornament.data.materials.append(ornament_mat)
    
    # Add lights
    # Main light
    bpy.ops.object.light_add(type='SUN', location=(5, 5, 10))
    sun = bpy.context.active_object
    sun.data.energy = 3.0
    sun.rotation_euler = (math.pi/4, 0, math.pi/4)
    
    # Fill light
    bpy.ops.object.light_add(type='AREA', location=(-3, -3, 5))
    fill = bpy.context.active_object
    fill.data.energy = 2.0
    fill.data.size = 5.0
    
    # Add camera
    bpy.ops.object.camera_add(location=(3, -3, 2))
    camera = bpy.context.active_object
    camera.rotation_euler = (math.pi/6, 0, math.pi/4)
    
    # Set camera as active
    bpy.context.scene.camera = camera
    
    # Select all tree parts
    all_parts = [trunk] + tree_layers + [topper] + ornaments
    for part in all_parts:
        part.select_set(True)
    
    # Parent all parts to trunk
    bpy.context.view_layer.objects.active = trunk
    bpy.ops.object.parent_set(type='OBJECT')
    
    return trunk

def add_realistic_animations(tree_root):
    """Add realistic Christmas tree animations"""
    
    # Get all child objects
    children = [obj for obj in bpy.context.scene.objects if obj.parent == tree_root]
    
    # Create animation data
    tree_root.animation_data_create()
    action = bpy.data.actions.new(name="christmas_tree_animation")
    tree_root.animation_data.action = action
    
    # Set up keyframes for gentle swaying
    scene = bpy.context.scene
    scene.frame_start = 1
    scene.frame_end = 120  # 5 seconds at 24fps
    
    # Gentle sway animation
    for frame in range(1, 121, 20):
        # Slight rotation
        tree_root.rotation_euler.z = math.sin(frame * 0.1) * 0.05
        tree_root.keyframe_insert(data_path="rotation_euler", frame=frame)
        
        # Slight scale variation
        scale_factor = 1.0 + math.sin(frame * 0.15) * 0.02
        tree_root.scale = (scale_factor, scale_factor, scale_factor)
        tree_root.keyframe_insert(data_path="scale", frame=frame)
    
    # Add ornament rotation animations
    ornaments = [obj for obj in children if "ornament" in obj.name]
    for i, ornament in enumerate(ornaments):
        ornament.animation_data_create()
        ornament_action = bpy.data.actions.new(name=f"ornament_sparkle_{i}")
        ornament.animation_data.action = ornament_action
        
        # Rotate ornaments
        for frame in range(1, 121, 15):
            ornament.rotation_euler.z = (frame * 0.1) + (i * 0.5)
            ornament.keyframe_insert(data_path="rotation_euler", frame=frame)

def export_high_quality_model():
    """Export the high-quality Christmas tree model"""
    
    # Create output directory
    output_dir = Path("/Volumes/Folk_DAS/Apps/MacroAI/3D_Assets/christmas")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Export as GLB (high quality)
    glb_path = output_dir / "christmas_tree_high_quality.glb"
    
    # Select all objects
    bpy.ops.object.select_all(action='SELECT')
    
    # Export with high quality settings
    bpy.ops.export_scene.gltf(
        filepath=str(glb_path),
        export_format='GLB',
        export_materials='EXPORT',
        export_animations=True,
        export_force_sampling=True,
        export_nla_strips=True,
        export_def_bones=False,
        export_current_frame=False,
        export_rest_position_armature=False,
        export_anim_single_armature=False,
        export_reset_pose_bones=True,
        export_anim_step=1.0,
        export_anim_simplify_factor=1.0,
        export_anim_optimize_size=0.0,
        export_tangents='NONE',
        export_morph=True,
        export_morph_normal=True,
        export_morph_tangent=False,
        export_lights=True,
        export_cameras=True,
        export_extras=True,
        export_yup=True,
        export_apply=False,
        export_texcoords=True,
        export_normals=True,
        export_colors=True,
        export_attributes=True
    )
    
    print(f"✅ High-quality Christmas tree exported to: {glb_path}")
    return str(glb_path)

def main():
    """Main function to create the realistic Christmas tree"""
    print("🎄 Creating realistic Christmas tree in Blender...")
    
    # Create the tree
    tree_root = create_realistic_christmas_tree()
    print("✅ Tree structure created")
    
    # Add animations
    add_realistic_animations(tree_root)
    print("✅ Animations added")
    
    # Export
    output_path = export_high_quality_model()
    print(f"✅ High-quality model exported: {output_path}")
    
    print("🎄 Realistic Christmas tree creation complete!")

if __name__ == "__main__":
    main() 