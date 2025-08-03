# 3D Asset Pipeline for iOS Integration

## Setup Instructions

### 1. Blender Addon Installation
```bash
# Download the Blender MCP addon
curl -L -o ~/Library/Application\ Support/Blender/4.4/scripts/addons/addon.py \
  https://raw.githubusercontent.com/ahujasid/blender-mcp/main/addon.py
```

### 2. Enable the Addon in Blender
1. Open Blender
2. Go to Edit > Preferences > Add-ons
3. Search for "Blender MCP"
4. Enable the addon by checking the box
5. In the 3D View sidebar (press N), find "BlenderMCP" tab
6. Click "Connect to Claude"

### 3. MCP Server Configuration
The MCP server is already configured in `~/.cursor/mcp.json`:
```json
{
  "blender": {
    "command": "uvx blender-mcp",
    "env": {}
  }
}
```

## Asset Creation Workflow

### Step 1: Create Basic 3D Objects
```python
# Create a simple cube
create_cube(size=2.0, location=[0, 0, 0])

# Create a sphere
create_sphere(radius=1.0, location=[3, 0, 0])

# Create a cylinder
create_cylinder(radius=0.5, height=2.0, location=[-3, 0, 0])
```

### Step 2: Apply Materials for iOS
```python
# Create metallic material
create_material(name="iOS_Metallic", 
               type="METAL", 
               color=[0.8, 0.8, 0.8],
               metallic=1.0,
               roughness=0.2)

# Create plastic material
create_material(name="iOS_Plastic",
               type="PLASTIC",
               color=[0.2, 0.6, 1.0],
               metallic=0.0,
               roughness=0.8)
```

### Step 3: Optimize for Mobile
```python
# Reduce polygon count
decimate_mesh(object_name="Cube", ratio=0.5)

# Apply smooth shading
set_smooth_shading(object_name="Cube")

# Add edge split modifier for sharp edges
add_edge_split_modifier(object_name="Cube", angle=30)
```

### Step 4: Export for iOS
```python
# Export as USDZ (preferred for AR)
export_usdz(filepath="/path/to/output/model.usdz")

# Export as GLB (for SceneKit)
export_glb(filepath="/path/to/output/model.glb")

# Export as OBJ (fallback)
export_obj(filepath="/path/to/output/model.obj")
```

## iOS Integration Pipeline

### 1. USDZ for AR Quick Look
```swift
import ARKit
import QuickLook

// Display 3D model in AR
func showARModel() {
    guard let url = Bundle.main.url(forResource: "model", withExtension: "usdz") else { return }
    
    let previewController = QLPreviewController()
    previewController.dataSource = self
    present(previewController, animated: true)
}
```

### 2. SceneKit Integration
```swift
import SceneKit

// Load 3D model in SceneKit
func loadSceneKitModel() {
    guard let scene = SCNScene(named: "model.usdz") else { return }
    sceneView.scene = scene
}
```

### 3. RealityKit Integration
```swift
import RealityKit

// Load 3D model in RealityKit
func loadRealityKitModel() async {
    guard let url = Bundle.main.url(forResource: "model", withExtension: "usdz") else { return }
    
    do {
        let entity = try await Entity.load(contentsOf: url)
        arView.scene.addAnchor(AnchorEntity(world: .zero).withChild(entity))
    } catch {
        print("Failed to load model: \(error)")
    }
}
```

## Production Asset Guidelines

### Performance Optimization
- **Polygon Count**: Keep under 10K triangles for mobile
- **Texture Size**: 1024x1024 max for mobile
- **Material Count**: Limit to 4 materials per model
- **LOD**: Create multiple detail levels

### File Formats
1. **USDZ** - Primary format for AR Quick Look
2. **GLB** - Secondary format for SceneKit
3. **OBJ** - Fallback format for compatibility

### Export Settings
```python
# USDZ Export Settings
export_settings = {
    "format": "USDZ",
    "compression": True,
    "embed_textures": True,
    "optimize_mesh": True,
    "scale": 1.0
}

# GLB Export Settings  
export_settings = {
    "format": "GLB",
    "embed_textures": True,
    "optimize_mesh": True,
    "scale": 1.0
}
```

## Batch Processing Workflow

### 1. Create Asset List
```python
assets_to_create = [
    {"name": "medical_device", "type": "cylinder", "size": [1, 1, 3]},
    {"name": "anatomy_model", "type": "sphere", "size": [2, 2, 2]},
    {"name": "surgical_tool", "type": "cube", "size": [0.5, 0.5, 2]}
]
```

### 2. Batch Generation Script
```python
def batch_create_assets(asset_list):
    for asset in asset_list:
        # Create base geometry
        create_object(asset["type"], asset["size"])
        
        # Apply materials
        apply_material("iOS_Metallic")
        
        # Optimize
        decimate_mesh(ratio=0.5)
        
        # Export
        export_usdz(f"/output/{asset['name']}.usdz")
        
        # Clean up
        delete_object()
```

### 3. Quality Control
```python
def validate_asset(filepath):
    # Check file size
    file_size = os.path.getsize(filepath)
    if file_size > 10 * 1024 * 1024:  # 10MB limit
        print(f"Warning: {filepath} is too large")
    
    # Check polygon count
    poly_count = get_polygon_count()
    if poly_count > 10000:
        print(f"Warning: {filepath} has too many polygons")
```

## Integration with MacroAI Pro

### 1. Add 3D Assets to Bundle
```bash
# Copy assets to app bundle
cp /path/to/3d/assets/*.usdz MacroAI\ Pro/MacroAI\ Pro/Resources/3D/
```

### 2. Update Xcode Project
```swift
// Add to Info.plist
<key>NSPhotoLibraryUsageDescription</key>
<string>This app uses AR to display 3D models</string>

// Add to entitlements
com.apple.developer.ar.quick-look
```

### 3. Create Asset Manager
```swift
class Asset3DManager {
    static let shared = Asset3DManager()
    
    func loadModel(named name: String) -> URL? {
        return Bundle.main.url(forResource: name, withExtension: "usdz")
    }
    
    func displayInAR(modelName: String, in viewController: UIViewController) {
        guard let url = loadModel(named: modelName) else { return }
        
        let previewController = QLPreviewController()
        previewController.dataSource = ARPreviewDataSource(url: url)
        viewController.present(previewController, animated: true)
    }
}
```

## Testing Workflow

### 1. Connection Test
```bash
python3 test_blender_mcp.py
```

### 2. Asset Creation Test
```python
# Test creating a simple medical device model
create_cylinder(radius=0.5, height=3.0, location=[0, 0, 0])
apply_material("iOS_Metallic")
export_usdz("/tmp/test_device.usdz")
```

### 3. iOS Integration Test
```swift
// Test loading in iOS app
let assetManager = Asset3DManager.shared
if let modelURL = assetManager.loadModel(named: "test_device") {
    print("✅ Model loaded successfully")
} else {
    print("❌ Model failed to load")
}
```

## Troubleshooting

### Common Issues
1. **Blender not responding**: Restart Blender and re-enable addon
2. **MCP connection failed**: Check if blender-mcp server is running
3. **Export errors**: Ensure proper file permissions and paths
4. **iOS loading issues**: Verify USDZ format and bundle inclusion

### Debug Commands
```bash
# Check Blender process
ps aux | grep blender

# Check MCP server
ps aux | grep blender-mcp

# Test socket connection
nc -z localhost 5000
``` 