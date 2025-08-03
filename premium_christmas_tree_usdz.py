import bpy
import math
import os
from pathlib import Path

def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

def create_premium_christmas_tree():
    """Create a premium Christmas tree matching the reference image"""
    clear_scene()
    
    # Create smooth conical tree (not stacked triangles)
    bpy.ops.mesh.primitive_cone_add(
        radius1=1.2,
        radius2=0.0,
        depth=3.0,
        vertices=32,
        location=(0, 0, 1.5)
    )
    tree = bpy.context.active_object
    tree.name = "christmas_tree"
    
    # Add subdivision surface for smoothness
    subsurf = tree.modifiers.new(name="Subdivision", type='SUBSURF')
    subsurf.levels = 2
    subsurf.render_levels = 3
    
    # Premium green material
    tree_mat = bpy.data.materials.new(name="TreeMaterial")
    tree_mat.use_nodes = True
    nodes = tree_mat.node_tree.nodes
    nodes.clear()
    
    principled = nodes.new(type='ShaderNodeBsdfPrincipled')
    principled.inputs['Base Color'].default_value = (0.1, 0.6, 0.2, 1.0)  # Vibrant green
    principled.inputs['Roughness'].default_value = 0.3
    principled.inputs['Metallic'].default_value = 0.0
    
    tree_mat.node_tree.links.new(
        principled.outputs['BSDF'],
        nodes.new(type='ShaderNodeOutputMaterial').inputs['Surface']
    )
    tree.data.materials.append(tree_mat)
    
    # Add trunk
    bpy.ops.mesh.primitive_cylinder_add(
        radius=0.1,
        depth=0.3,
        location=(0, 0, 0.15)
    )
    trunk = bpy.context.active_object
    trunk.name = "tree_trunk"
    
    trunk_mat = bpy.data.materials.new(name="TrunkMaterial")
    trunk_mat.use_nodes = True
    nodes = trunk_mat.node_tree.nodes
    nodes.clear()
    
    principled = nodes.new(type='ShaderNodeBsdfPrincipled')
    principled.inputs['Base Color'].default_value = (0.3, 0.2, 0.1, 1.0)
    principled.inputs['Roughness'].default_value = 0.8
    
    trunk_mat.node_tree.links.new(
        principled.outputs['BSDF'],
        nodes.new(type='ShaderNodeOutputMaterial').inputs['Surface']
    )
    trunk.data.materials.append(trunk_mat)
    
    # Add ornaments (red and gold spheres)
    ornaments = []
    for i in range(15):
        angle = (i * 24) * math.pi / 180
        radius = 0.8 + (i % 3) * 0.2
        height = 0.5 + (i * 0.15)
        
        bpy.ops.mesh.primitive_uv_sphere_add(
            radius=0.06,
            location=(radius * math.cos(angle), radius * math.sin(angle), height)
        )
        ornament = bpy.context.active_object
        ornament.name = f"ornament_{i}"
        ornaments.append(ornament)
        
        # Red or gold material
        is_gold = i % 2 == 0
        color = (1.0, 0.0, 0.0, 1.0) if not is_gold else (1.0, 0.8, 0.0, 1.0)
        metallic = 0.8 if is_gold else 0.3
        
        ornament_mat = bpy.data.materials.new(name=f"OrnamentMaterial_{i}")
        ornament_mat.use_nodes = True
        nodes = ornament_mat.node_tree.nodes
        nodes.clear()
        
        principled = nodes.new(type='ShaderNodeBsdfPrincipled')
        principled.inputs['Base Color'].default_value = color
        principled.inputs['Metallic'].default_value = metallic
        principled.inputs['Roughness'].default_value = 0.1
        
        ornament_mat.node_tree.links.new(
            principled.outputs['BSDF'],
            nodes.new(type='ShaderNodeOutputMaterial').inputs['Surface']
        )
        ornament.data.materials.append(ornament_mat)
    
    # Add golden star topper
    bpy.ops.mesh.primitive_cone_add(
        radius1=0.15,
        radius2=0.0,
        depth=0.3,
        vertices=5,
        location=(0, 0, 3.15)
    )
    star = bpy.context.active_object
    star.name = "star_topper"
    
    star_mat = bpy.data.materials.new(name="StarMaterial")
    star_mat.use_nodes = True
    nodes = star_mat.node_tree.nodes
    nodes.clear()
    
    principled = nodes.new(type='ShaderNodeBsdfPrincipled')
    principled.inputs['Base Color'].default_value = (1.0, 0.8, 0.0, 1.0)
    principled.inputs['Metallic'].default_value = 0.9
    principled.inputs['Roughness'].default_value = 0.1
    principled.inputs['Emission Color'].default_value = (0.2, 0.15, 0.0, 1.0)
    principled.inputs['Emission Strength'].default_value = 0.3
    
    star_mat.node_tree.links.new(
        principled.outputs['BSDF'],
        nodes.new(type='ShaderNodeOutputMaterial').inputs['Surface']
    )
    star.data.materials.append(star_mat)
    
    # Add lighting
    bpy.ops.object.light_add(type='SUN', location=(5, 5, 10))
    sun = bpy.context.active_object
    sun.data.energy = 3.0
    sun.rotation_euler = (math.pi/4, 0, math.pi/4)
    
    # Add camera
    bpy.ops.object.camera_add(location=(3, -3, 2))
    camera = bpy.context.active_object
    camera.rotation_euler = (math.pi/6, 0, math.pi/4)
    bpy.context.scene.camera = camera
    
    # Parent all to tree
    all_parts = [trunk, star] + ornaments
    for part in all_parts:
        part.select_set(True)
    
    bpy.context.view_layer.objects.active = tree
    bpy.ops.object.parent_set(type='OBJECT')
    
    return tree

def add_premium_animation(tree_root):
    """Add premium, subtle animations"""
    tree_root.animation_data_create()
    action = bpy.data.actions.new(name="christmas_tree_animation")
    tree_root.animation_data.action = action
    
    scene = bpy.context.scene
    scene.frame_start = 1
    scene.frame_end = 120
    
    # Gentle sway
    for frame in range(1, 121, 20):
        tree_root.rotation_euler.z = math.sin(frame * 0.1) * 0.03
        tree_root.keyframe_insert(data_path="rotation_euler", frame=frame)
    
    # Subtle scale
    for frame in range(1, 121, 30):
        scale_factor = 1.0 + math.sin(frame * 0.15) * 0.01
        tree_root.scale = (scale_factor, scale_factor, scale_factor)
        tree_root.keyframe_insert(data_path="scale", frame=frame)

def export_usdc():
    """Export as USDC for conversion to USDZ"""
    output_dir = Path("/Volumes/Folk_DAS/Apps/MacroAI/3D_Assets/christmas")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    usdc_path = output_dir / "christmas_tree.usdc"
    
    bpy.ops.object.select_all(action='SELECT')
    
    # Export as USDC
    bpy.ops.export_scene.usd(
        filepath=str(usdc_path),
        export_materials=True,
        export_animations=True,
        export_instances=True,
        export_visible_only=False,
        export_uvs=True,
        export_normals=True,
        export_mesh=True,
        export_curves=True,
        export_cameras=True,
        export_lights=True,
        export_subdiv=True,
        export_all_materials=True,
        export_material_binding=True,
        export_world_transform=True,
        export_apply=True,
        export_relative_paths=True,
        export_path_mode='COPY',
        export_texture_dir='',
        export_overwrite=True
    )
    
    print(f"✅ USDC exported: {usdc_path}")
    return str(usdc_path)

def convert_to_usdz(usdc_path):
    """Convert USDC to USDZ using Apple's tools"""
    usdc_path = Path(usdc_path)
    usdz_path = usdc_path.with_suffix('.usdz')
    
    # Use Apple's usdconvert tool
    cmd = f"/Applications/Xcode.app/Contents/Developer/usr/bin/usdconvert {usdc_path} {usdz_path}"
    
    import subprocess
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ USDZ created: {usdz_path}")
            return str(usdz_path)
        else:
            print(f"❌ USDZ conversion failed: {result.stderr}")
            return None
    except Exception as e:
        print(f"❌ USDZ conversion error: {e}")
        return None

def main():
    print("🎄 Creating premium USDZ Christmas tree...")
    
    tree_root = create_premium_christmas_tree()
    print("✅ Premium tree created")
    
    add_premium_animation(tree_root)
    print("✅ Premium animation added")
    
    usdc_path = export_usdc()
    print("✅ USDC exported")
    
    usdz_path = convert_to_usdz(usdc_path)
    if usdz_path:
        print(f"🎉 Premium USDZ ready: {usdz_path}")
    else:
        print("⚠️ USDZ conversion failed, using USDC")

if __name__ == "__main__":
    main() 