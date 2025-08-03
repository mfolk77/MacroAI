#!/usr/bin/env python3
import os
import subprocess
from pathlib import Path

def add_3d_assets_to_xcode():
    """Add 3D assets to Xcode project using xcodebuild"""
    
    project_path = Path("MacroAI Pro/MacroAI Pro.xcodeproj")
    assets_path = Path("MacroAI Pro/MacroAI Pro/Resources/3D_Assets")
    
    print("🎯 Adding 3D assets to Xcode project...")
    
    if not project_path.exists():
        print("❌ Xcode project not found")
        return False
    
    if not assets_path.exists():
        print("❌ 3D assets directory not found")
        return False
    
    # List all GLB files
    glb_files = list(assets_path.rglob("*.glb"))
    print(f"📁 Found {len(glb_files)} GLB files:")
    
    for glb_file in glb_files:
        print(f"  - {glb_file}")
    
    # Use xcodebuild to add files
    for glb_file in glb_files:
        relative_path = glb_file.relative_to(Path("MacroAI Pro"))
        print(f"➕ Adding {relative_path} to project...")
        
        # Use xcodebuild to add the file
        cmd = [
            "xcodebuild",
            "-project", str(project_path),
            "-target", "MacroAI Pro",
            "-add-file", str(glb_file),
            "-add-file-path", str(relative_path)
        ]
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                print(f"✅ Added {relative_path}")
            else:
                print(f"⚠️ Could not add {relative_path}: {result.stderr}")
        except Exception as e:
            print(f"❌ Error adding {relative_path}: {e}")
    
    print("🎉 3D assets addition complete!")
    return True

if __name__ == "__main__":
    add_3d_assets_to_xcode() 