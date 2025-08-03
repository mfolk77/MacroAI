#!/usr/bin/env python3
"""
Simple Image Processing Script
Easily convert PNG images to 3D animated models
"""

import sys
from pathlib import Path
from image_to_3d_pipeline import ImageTo3DPipeline

def main():
    print("🎨 Image to 3D Animation Pipeline")
    print("=" * 50)
    
    if len(sys.argv) < 2:
        print("Usage: python3 process_images.py <image_path> [theme_name] [animation_type]")
        print("\nExamples:")
        print("  python3 process_images.py my_image.png")
        print("  python3 process_images.py my_image.png christmas")
        print("  python3 process_images.py my_image.png christmas dance")
        print("\nAnimation types: dance, bounce, spin, pulse")
        return
    
    # Get arguments
    image_path = Path(sys.argv[1])
    theme_name = sys.argv[2] if len(sys.argv) > 2 else "custom"
    animation_type = sys.argv[3] if len(sys.argv) > 3 else "dance"
    
    # Validate image path
    if not image_path.exists():
        print(f"❌ Image not found: {image_path}")
        return
    
    if not image_path.suffix.lower() in ['.png', '.jpg', '.jpeg']:
        print(f"❌ Unsupported image format: {image_path.suffix}")
        print("Supported formats: PNG, JPG, JPEG")
        return
    
    print(f"🎨 Processing: {image_path}")
    print(f"🎭 Theme: {theme_name}")
    print(f"💃 Animation: {animation_type}")
    print("-" * 40)
    
    # Initialize pipeline
    pipeline = ImageTo3DPipeline()
    
    if not pipeline.connect_to_blender():
        print("❌ Cannot connect to Blender. Make sure the addon is enabled.")
        print("\nTo enable the Blender addon:")
        print("1. Open Blender")
        print("2. Go to Edit > Preferences > Add-ons")
        print("3. Search for 'Blender MCP'")
        print("4. Check the box to enable it")
        print("5. Click 'Connect to Claude' in the sidebar")
        return
    
    try:
        # Process the image
        usdz_path = pipeline.process_image_to_3d(image_path, theme_name, animation_type)
        
        # Create Swift integration
        model_name = image_path.stem
        pipeline.create_swift_integration(theme_name, model_name)
        
        print(f"\n✅ Successfully created 3D model!")
        print(f"📦 USDZ file: {usdz_path}")
        print(f"📱 Swift file: MacroAI Pro/MacroAI Pro/{model_name.title()}View.swift")
        
        print(f"\n🎉 Integration complete!")
        print("\nNext steps:")
        print("1. Copy the USDZ file to your iOS app bundle")
        print("2. Add the Swift file to your Xcode project")
        print("3. Test the AR integration in your app")
        
    except Exception as e:
        print(f"❌ Processing failed: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        pipeline.close()

def batch_process():
    """Process all images in a folder"""
    print("📁 Batch Image Processing")
    print("=" * 40)
    
    if len(sys.argv) < 3:
        print("Usage: python3 process_images.py --batch <folder_path> [theme_name]")
        print("\nExample: python3 process_images.py --batch /path/to/images christmas")
        return
    
    folder_path = Path(sys.argv[2])
    theme_name = sys.argv[3] if len(sys.argv) > 3 else "custom"
    
    if not folder_path.exists():
        print(f"❌ Folder not found: {folder_path}")
        return
    
    # Find all image files
    image_files = []
    for ext in ['*.png', '*.jpg', '*.jpeg']:
        image_files.extend(folder_path.glob(ext))
    
    if not image_files:
        print(f"❌ No image files found in {folder_path}")
        return
    
    print(f"📁 Found {len(image_files)} images in {folder_path}")
    print(f"🎭 Theme: {theme_name}")
    print("-" * 40)
    
    # Initialize pipeline
    pipeline = ImageTo3DPipeline()
    
    if not pipeline.connect_to_blender():
        print("❌ Cannot connect to Blender. Make sure the addon is enabled.")
        return
    
    try:
        # Process all images
        results = pipeline.process_batch_images(str(folder_path), theme_name)
        
        print(f"\n📊 Batch Processing Results:")
        successful = 0
        for result in results:
            status = "✅" if result["status"] == "success" else "❌"
            print(f"{status} {Path(result['image']).name}")
            if result["status"] == "success":
                print(f"   → {Path(result['usdz']).name}")
                successful += 1
            else:
                print(f"   → Error: {result.get('error', 'Unknown error')}")
        
        print(f"\n🎉 Batch processing complete!")
        print(f"✅ Successful: {successful}/{len(results)}")
        
        if successful > 0:
            print(f"\n📦 USDZ files saved to: /Volumes/Folk_DAS/Apps/MacroAI/3D_Assets/{theme_name}/")
            print(f"📱 Swift files saved to: MacroAI Pro/MacroAI Pro/")
        
    except Exception as e:
        print(f"❌ Batch processing failed: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        pipeline.close()

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--batch":
        batch_process()
    else:
        main() 