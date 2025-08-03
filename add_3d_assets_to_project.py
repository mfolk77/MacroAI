#!/usr/bin/env python3
import os
import subprocess
import plistlib
from pathlib import Path

def add_3d_assets_to_xcode():
    """Add 3D assets to the Xcode project"""
    
    # Paths
    project_dir = Path("MacroAI Pro")
    assets_dir = project_dir / "MacroAI Pro" / "3D_Assets"
    project_file = project_dir / "MacroAI Pro.xcodeproj" / "project.pbxproj"
    
    print("🎯 Adding 3D assets to Xcode project...")
    
    # Check if assets exist
    if not assets_dir.exists():
        print("❌ 3D_Assets directory not found")
        return False
    
    # List all GLB files
    glb_files = list(assets_dir.rglob("*.glb"))
    print(f"📁 Found {len(glb_files)} GLB files:")
    
    for glb_file in glb_files:
        print(f"  - {glb_file.relative_to(project_dir)}")
    
    # Use Xcode command line tools to add files
    for glb_file in glb_files:
        relative_path = glb_file.relative_to(project_dir)
        target_path = f"MacroAI Pro/{relative_path}"
        
        print(f"➕ Adding {target_path} to project...")
        
        # Use xcodebuild to add the file
        cmd = [
            "xcodebuild",
            "-project", "MacroAI Pro.xcodeproj",
            "-target", "MacroAI Pro",
            "-add-file", str(glb_file),
            "-add-file-path", target_path
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                print(f"✅ Added {target_path}")
            else:
                print(f"⚠️ Could not add {target_path}: {result.stderr}")
        except Exception as e:
            print(f"❌ Error adding {target_path}: {e}")
    
    print("🎉 3D assets addition complete!")
    return True

if __name__ == "__main__":
    add_3d_assets_to_xcode() 