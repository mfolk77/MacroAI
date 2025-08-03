#!/usr/bin/env python3
"""
Test the Image to 3D Pipeline with existing Christmas tree image
"""

from image_to_3d_pipeline import ImageTo3DPipeline
from pathlib import Path

def test_christmas_tree_pipeline():
    """Test the pipeline with the existing Christmas tree image"""
    print("🎄 Testing Image to 3D Pipeline with Christmas Tree")
    print("=" * 60)
    
    pipeline = ImageTo3DPipeline()
    
    if not pipeline.connect_to_blender():
        print("❌ Cannot connect to Blender. Make sure the addon is enabled.")
        return
    
    try:
        # Find the Christmas tree image
        christmas_tree_path = Path("/Volumes/Folk_DAS/Apps/MacroAI/MacroAI Pro/MacroAI Pro/Assets.xcassets/christmas_tree_with_sunglasses.imageset/E1D08663-4ACF-4F0E-88BF-50AD554581D5.png")
        
        if not christmas_tree_path.exists():
            print(f"❌ Christmas tree image not found at: {christmas_tree_path}")
            print("Looking for alternative images...")
            
            # Look for any PNG in the imageset
            imageset_dir = Path("/Volumes/Folk_DAS/Apps/MacroAI/MacroAI Pro/MacroAI Pro/Assets.xcassets/christmas_tree_with_sunglasses.imageset")
            png_files = list(imageset_dir.glob("*.png"))
            
            if png_files:
                christmas_tree_path = png_files[0]
                print(f"✅ Found image: {christmas_tree_path}")
            else:
                print("❌ No PNG images found in christmas_tree_with_sunglasses.imageset")
                return
        else:
            print(f"✅ Found Christmas tree image: {christmas_tree_path}")
        
        # Process the image through the pipeline
        print("\n🎨 Processing Christmas tree image...")
        
        usdz_path = pipeline.process_image_to_3d(
            christmas_tree_path,
            "christmas",
            "dance"
        )
        
        print(f"\n✅ Successfully created 3D model: {usdz_path}")
        
        # Create Swift integration
        pipeline.create_swift_integration("christmas", "christmas_tree_with_sunglasses")
        
        print("\n🎉 Pipeline test completed successfully!")
        print("\nNext steps:")
        print("1. Copy the USDZ file to your iOS app bundle")
        print("2. Add the generated Swift file to your Xcode project")
        print("3. Test the AR integration in your app")
        
    except Exception as e:
        print(f"❌ Pipeline test failed: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        pipeline.close()

def test_batch_processing():
    """Test batch processing with multiple images"""
    print("\n📁 Testing Batch Processing")
    print("=" * 40)
    
    pipeline = ImageTo3DPipeline()
    
    if not pipeline.connect_to_blender():
        print("❌ Cannot connect to Blender.")
        return
    
    try:
        # Create a test images folder
        test_images_dir = Path("/Volumes/Folk_DAS/Apps/MacroAI/test_images")
        test_images_dir.mkdir(exist_ok=True)
        
        # Copy Christmas tree image to test folder
        source_image = Path("/Volumes/Folk_DAS/Apps/MacroAI/MacroAI Pro/MacroAI Pro/Assets.xcassets/christmas_tree_with_sunglasses.imageset/E1D08663-4ACF-4F0E-88BF-50AD554581D5.png")
        
        if source_image.exists():
            import shutil
            test_image = test_images_dir / "christmas_tree_test.png"
            shutil.copy2(source_image, test_image)
            print(f"✅ Copied test image to: {test_image}")
            
            # Process batch
            results = pipeline.process_batch_images(str(test_images_dir), "christmas")
            
            print(f"\n📊 Batch Processing Results:")
            for result in results:
                status = "✅" if result["status"] == "success" else "❌"
                print(f"{status} {result['image']}")
                if result["status"] == "success":
                    print(f"   → {result['usdz']}")
                else:
                    print(f"   → Error: {result.get('error', 'Unknown error')}")
        else:
            print("❌ Source image not found for batch test")
    
    except Exception as e:
        print(f"❌ Batch processing test failed: {e}")
    
    finally:
        pipeline.close()

def create_sample_images():
    """Create sample images for testing"""
    print("\n🎨 Creating Sample Images for Testing")
    print("=" * 40)
    
    from PIL import Image, ImageDraw
    
    # Create test images directory
    test_dir = Path("/Volumes/Folk_DAS/Apps/MacroAI/sample_images")
    test_dir.mkdir(exist_ok=True)
    
    # Create different shaped images
    images_to_create = [
        ("circle.png", "circle", (200, 200)),
        ("triangle.png", "triangle", (200, 200)),
        ("square.png", "rectangle", (200, 200)),
        ("complex.png", "complex", (200, 200))
    ]
    
    for filename, shape_type, size in images_to_create:
        img = Image.new('RGB', size, color='white')
        draw = ImageDraw.Draw(img)
        
        if shape_type == "circle":
            # Draw a circle
            draw.ellipse([20, 20, size[0]-20, size[1]-20], fill='red', outline='darkred', width=3)
        elif shape_type == "triangle":
            # Draw a triangle
            points = [(size[0]//2, 20), (20, size[1]-20), (size[0]-20, size[1]-20)]
            draw.polygon(points, fill='green', outline='darkgreen', width=3)
        elif shape_type == "rectangle":
            # Draw a rectangle
            draw.rectangle([20, 20, size[0]-20, size[1]-20], fill='blue', outline='darkblue', width=3)
        else:  # complex
            # Draw a star-like shape
            center = (size[0]//2, size[1]//2)
            radius = 60
            points = []
            for i in range(10):
                angle = i * 36 * 3.14159 / 180
                r = radius if i % 2 == 0 else radius // 2
                x = center[0] + r * math.cos(angle)
                y = center[1] + r * math.sin(angle)
                points.append((x, y))
            draw.polygon(points, fill='purple', outline='darkpurple', width=3)
        
        filepath = test_dir / filename
        img.save(filepath)
        print(f"✅ Created {filename}")
    
    print(f"\n📁 Sample images created in: {test_dir}")
    print("You can now test the pipeline with these images!")

if __name__ == "__main__":
    import math
    
    print("🎨 Image to 3D Pipeline Test Suite")
    print("=" * 50)
    
    # Test 1: Single image processing
    test_christmas_tree_pipeline()
    
    # Test 2: Batch processing
    test_batch_processing()
    
    # Test 3: Create sample images
    create_sample_images()
    
    print("\n🎉 All tests completed!")
    print("\n📋 Usage Instructions:")
    print("1. Place your PNG images in a folder")
    print("2. Run: python3 image_to_3d_pipeline.py")
    print("3. Follow the prompts to process your images")
    print("4. The pipeline will create USDZ files and Swift integration code") 