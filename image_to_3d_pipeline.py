#!/usr/bin/env python3
"""
Image to 3D Animation Pipeline
Converts PNG images to 3D animated models and integrates them into MacroAI Pro themes
"""

import os
import json
import socket
import time
import subprocess
import shutil
from pathlib import Path
from PIL import Image
import cv2
import numpy as np

class ImageTo3DPipeline:
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
    
    def process_image_to_3d(self, image_path, theme_name, animation_type="dance"):
        """Convert PNG image to 3D animated model"""
        print(f"🎨 Processing {image_path} for {theme_name} theme...")
        
        # Step 1: Analyze image
        image_data = self.analyze_image(image_path)
        
        # Step 2: Create 3D model in Blender
        model_name = self.create_3d_model_from_image(image_path, image_data)
        
        # Step 3: Add animations
        self.add_animations(model_name, animation_type)
        
        # Step 4: Export as USDZ
        usdz_path = self.export_model(model_name, theme_name)
        
        # Step 5: Update theme configuration
        self.update_theme_config(theme_name, model_name, usdz_path)
        
        return usdz_path
    
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
        """Create 3D model based on image analysis"""
        print(f"🎯 Creating 3D model for {image_data['shape_type']} shape...")
        
        # Determine base geometry based on shape analysis
        if image_data['shape_type'] == "triangle":
            # Create cone for triangular shapes (like Christmas trees)
            command = {
                "type": "create_object",
                "params": {
                    "object_type": "MESH",
                    "primitive_type": "CONE",
                    "location": [0, 0, 0],
                    "radius": 1.0,
                    "height": 2.0
                }
            }
        elif image_data['shape_type'] == "circle":
            # Create sphere for circular shapes
            command = {
                "type": "create_object",
                "params": {
                    "object_type": "MESH",
                    "primitive_type": "SPHERE",
                    "location": [0, 0, 0],
                    "radius": 1.0
                }
            }
        elif image_data['shape_type'] == "rectangle":
            # Create cube for rectangular shapes
            command = {
                "type": "create_object",
                "params": {
                    "object_type": "MESH",
                    "primitive_type": "CUBE",
                    "location": [0, 0, 0],
                    "size": 1.0
                }
            }
        else:
            # Create cylinder for complex shapes
            command = {
                "type": "create_object",
                "params": {
                    "object_type": "MESH",
                    "primitive_type": "CYLINDER",
                    "location": [0, 0, 0],
                    "radius": 0.5,
                    "height": 1.5
                }
            }
        
        # Send command to Blender
        result = self.send_blender_command(command)
        if not result or result.get('status') != 'success':
            raise Exception("Failed to create 3D model")
        
        # Apply texture from image
        self.apply_image_texture(image_path)
        
        # Generate model name
        model_name = Path(image_path).stem
        return model_name
    
    def apply_image_texture(self, image_path):
        """Apply the original image as texture to the 3D model"""
        print(f"🎨 Applying texture from {image_path}")
        
        # Copy image to Blender's texture directory
        texture_dir = Path("/tmp/blender_textures")
        texture_dir.mkdir(exist_ok=True)
        
        texture_path = texture_dir / Path(image_path).name
        shutil.copy2(image_path, texture_path)
        
        # Apply texture command
        command = {
            "type": "apply_texture",
            "params": {
                "texture_path": str(texture_path),
                "mapping": "UV",
                "wrap": "REPEAT"
            }
        }
        
        result = self.send_blender_command(command)
        if not result or result.get('status') != 'success':
            print("⚠️ Texture application failed, continuing with material...")
            # Fallback to material color
            self.apply_material_color()
    
    def apply_material_color(self):
        """Apply material color as fallback"""
        command = {
            "type": "apply_material",
            "params": {
                "material_name": "ImageMaterial",
                "color": [0.8, 0.8, 0.8],
                "metallic": 0.0,
                "roughness": 0.5
            }
        }
        
        self.send_blender_command(command)
    
    def add_animations(self, model_name, animation_type):
        """Add animations to the 3D model"""
        print(f"💃 Adding {animation_type} animation...")
        
        if animation_type == "dance":
            # Add dancing animation
            self.add_dance_animation()
        elif animation_type == "bounce":
            # Add bouncing animation
            self.add_bounce_animation()
        elif animation_type == "spin":
            # Add spinning animation
            self.add_spin_animation()
        elif animation_type == "pulse":
            # Add pulsing animation
            self.add_pulse_animation()
        else:
            # Default to dance
            self.add_dance_animation()
    
    def add_dance_animation(self):
        """Add dancing animation to the model"""
        # Scale animation
        scale_command = {
            "type": "add_animation",
            "params": {
                "animation_type": "scale",
                "keyframes": [
                    {"frame": 0, "value": 1.0},
                    {"frame": 15, "value": 1.1},
                    {"frame": 30, "value": 1.0}
                ],
                "loop": True
            }
        }
        self.send_blender_command(scale_command)
        
        # Rotation animation
        rotation_command = {
            "type": "add_animation",
            "params": {
                "animation_type": "rotation",
                "keyframes": [
                    {"frame": 0, "value": 0},
                    {"frame": 30, "value": 5},
                    {"frame": 60, "value": 0}
                ],
                "loop": True
            }
        }
        self.send_blender_command(rotation_command)
    
    def add_bounce_animation(self):
        """Add bouncing animation"""
        bounce_command = {
            "type": "add_animation",
            "params": {
                "animation_type": "location",
                "keyframes": [
                    {"frame": 0, "value": [0, 0, 0]},
                    {"frame": 15, "value": [0, 0, 0.2]},
                    {"frame": 30, "value": [0, 0, 0]}
                ],
                "loop": True
            }
        }
        self.send_blender_command(bounce_command)
    
    def add_spin_animation(self):
        """Add spinning animation"""
        spin_command = {
            "type": "add_animation",
            "params": {
                "animation_type": "rotation",
                "keyframes": [
                    {"frame": 0, "value": 0},
                    {"frame": 60, "value": 360}
                ],
                "loop": True
            }
        }
        self.send_blender_command(spin_command)
    
    def add_pulse_animation(self):
        """Add pulsing animation"""
        pulse_command = {
            "type": "add_animation",
            "params": {
                "animation_type": "scale",
                "keyframes": [
                    {"frame": 0, "value": 1.0},
                    {"frame": 20, "value": 1.2},
                    {"frame": 40, "value": 1.0}
                ],
                "loop": True
            }
        }
        self.send_blender_command(pulse_command)
    
    def export_model(self, model_name, theme_name):
        """Export the 3D model as USDZ"""
        print(f"📦 Exporting {model_name} as USDZ...")
        
        # Create theme-specific output directory
        theme_output_dir = self.output_dir / theme_name
        theme_output_dir.mkdir(parents=True, exist_ok=True)
        
        usdz_path = theme_output_dir / f"{model_name}.usdz"
        
        export_command = {
            "type": "export",
            "params": {
                "format": "USDZ",
                "filepath": str(usdz_path),
                "embed_textures": True,
                "optimize_mesh": True,
                "include_animations": True
            }
        }
        
        result = self.send_blender_command(export_command)
        if not result or result.get('status') != 'success':
            raise Exception(f"Failed to export USDZ: {result}")
        
        print(f"✅ Exported to {usdz_path}")
        return usdz_path
    
    def update_theme_config(self, theme_name, model_name, usdz_path):
        """Update theme configuration with new 3D model"""
        print(f"🎨 Updating {theme_name} theme configuration...")
        
        # Load existing theme config
        theme_config_path = self.themes_dir / f"{theme_name}.json"
        
        if theme_config_path.exists():
            with open(theme_config_path, 'r') as f:
                theme_config = json.load(f)
        else:
            # Create new theme config
            theme_config = {
                "id": theme_name,
                "name": f"{theme_name.title()} Theme",
                "description": f"Custom {theme_name} theme with 3D animations",
                "isPremium": True,
                "colors": {
                    "primary": "#007AFF",
                    "secondary": "#FF6B6B",
                    "accent": "#FFD93D",
                    "background": "#F8F9FA"
                }
            }
        
        # Add 3D model configuration
        if "3dModels" not in theme_config:
            theme_config["3dModels"] = {}
        
        theme_config["3dModels"][model_name] = {
            "usdzPath": str(usdz_path),
            "animationType": "dance",
            "scale": 1.0,
            "position": [0, 0, 0],
            "rotation": [0, 0, 0]
        }
        
        # Add special effects
        theme_config["specialEffects"] = {
            "particles": "sparkles",
            "celebrationAnimation": f"{model_name}_dance",
            "overfillEffect": "glow_effect"
        }
        
        # Save updated config
        with open(theme_config_path, 'w') as f:
            json.dump(theme_config, f, indent=2)
        
        print(f"✅ Updated {theme_config_path}")
    
    def create_swift_integration(self, theme_name, model_name):
        """Create Swift code for iOS integration"""
        print(f"📱 Creating Swift integration for {model_name}...")
        
        swift_code = f"""
import SwiftUI
import QuickLook
import SceneKit

struct {model_name.title()}View: View {{
    @State private var showingAR = false
    
    var body: some View {{
        VStack {{
            // 3D Model Display
            SceneKitView(modelName: "{model_name}")
                .frame(height: 300)
                .cornerRadius(12)
                .shadow(radius: 8)
            
            // AR Button
            Button("View in AR") {{
                showingAR = true
            }}
            .buttonStyle(.borderedProminent)
            .padding()
        }}
        .sheet(isPresented: $showingAR) {{
            ARQuickLookView(modelName: "{model_name}")
        }}
    }}
}}

struct SceneKitView: UIViewRepresentable {{
    let modelName: String
    
    func makeUIView(context: Context) -> SCNView {{
        let sceneView = SCNView()
        sceneView.scene = SCNScene()
        
        if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "usdz") {{
            do {{
                let scene = try SCNScene(url: modelURL, options: nil)
                sceneView.scene = scene
                
                // Add lighting
                let lightNode = SCNNode()
                lightNode.light = SCNLight()
                lightNode.light?.type = .omni
                lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
                scene.rootNode.addChildNode(lightNode)
                
                // Add ambient lighting
                let ambientLightNode = SCNNode()
                ambientLightNode.light = SCNLight()
                ambientLightNode.light?.type = .ambient
                ambientLightNode.light?.color = UIColor.darkGray
                scene.rootNode.addChildNode(ambientLightNode)
                
            }} catch {{
                print("Failed to load 3D model: \\(error)")
            }}
        }}
        
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        return sceneView
    }}
    
    func updateUIView(_ uiView: SCNView, context: Context) {{
        // Updates if needed
    }}
}}

struct ARQuickLookView: UIViewControllerRepresentable {{
    let modelName: String
    
    func makeUIViewController(context: Context) -> QLPreviewController {{
        let previewController = QLPreviewController()
        previewController.dataSource = context.coordinator
        return previewController
    }}
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {{
        // Updates if needed
    }}
    
    func makeCoordinator() -> Coordinator {{
        Coordinator(modelName: modelName)
    }}
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {{
        let modelName: String
        
        init(modelName: String) {{
            self.modelName = modelName
        }}
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {{
            return 1
        }}
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {{
            guard let url = Bundle.main.url(forResource: modelName, withExtension: "usdz") else {{
                return URL(fileURLWithPath: "") as QLPreviewItem
            }}
            return url as QLPreviewItem
        }}
    }}
}}

#Preview {{
    {model_name.title()}View()
}}
"""
        
        # Save Swift file
        swift_path = self.project_root / "MacroAI Pro/MacroAI Pro" / f"{model_name.title()}View.swift"
        with open(swift_path, 'w') as f:
            f.write(swift_code)
        
        print(f"✅ Created {swift_path}")
    
    def process_batch_images(self, image_folder, theme_name):
        """Process all PNG images in a folder"""
        print(f"📁 Processing batch images from {image_folder} for {theme_name} theme...")
        
        image_folder_path = Path(image_folder)
        if not image_folder_path.exists():
            raise ValueError(f"Image folder not found: {image_folder}")
        
        # Find all PNG images
        png_files = list(image_folder_path.glob("*.png"))
        jpg_files = list(image_folder_path.glob("*.jpg"))
        image_files = png_files + jpg_files
        
        if not image_files:
            raise ValueError(f"No image files found in {image_folder}")
        
        results = []
        for image_file in image_files:
            try:
                usdz_path = self.process_image_to_3d(image_file, theme_name)
                self.create_swift_integration(theme_name, image_file.stem)
                results.append({
                    "image": str(image_file),
                    "usdz": str(usdz_path),
                    "status": "success"
                })
            except Exception as e:
                print(f"❌ Failed to process {image_file}: {e}")
                results.append({
                    "image": str(image_file),
                    "usdz": None,
                    "status": "failed",
                    "error": str(e)
                })
        
        return results
    
    def close(self):
        """Close Blender connection"""
        if self.blender_client:
            self.blender_client.close()

def main():
    """Main pipeline execution"""
    print("🎨 Image to 3D Animation Pipeline")
    print("=" * 50)
    
    pipeline = ImageTo3DPipeline()
    
    if not pipeline.connect_to_blender():
        print("❌ Cannot connect to Blender. Make sure the addon is enabled.")
        return
    
    try:
        # Example usage
        print("\n📋 Usage Examples:")
        print("1. Process single image:")
        print("   pipeline.process_image_to_3d('my_image.png', 'christmas', 'dance')")
        print("\n2. Process batch images:")
        print("   pipeline.process_batch_images('/path/to/images', 'christmas')")
        print("\n3. Available animation types: dance, bounce, spin, pulse")
        
        # You can uncomment and modify these examples:
        
        # # Process a single image
        # usdz_path = pipeline.process_image_to_3d(
        #     "path/to/your/image.png",
        #     "christmas",
        #     "dance"
        # )
        # print(f"✅ Created: {usdz_path}")
        
        # # Process batch images
        # results = pipeline.process_batch_images(
        #     "/path/to/image/folder",
        #     "christmas"
        # )
        # print(f"✅ Processed {len(results)} images")
        
    finally:
        pipeline.close()

if __name__ == "__main__":
    main() 