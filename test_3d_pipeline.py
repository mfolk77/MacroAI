#!/usr/bin/env python3
"""
3D Asset Pipeline Test Script
Tests the complete workflow from Blender MCP to iOS integration
"""

import os
import sys
import subprocess
import json
from pathlib import Path

def test_blender_connection():
    """Test if Blender MCP is properly connected"""
    print("🔍 Testing Blender MCP connection...")
    
    try:
        # Check if blender-mcp process is running
        result = subprocess.run(['ps', 'aux'], capture_output=True, text=True)
        if 'blender-mcp' in result.stdout:
            print("✅ blender-mcp process is running")
        else:
            print("❌ blender-mcp process not found")
            return False
        
        # Check if Blender is running
        result = subprocess.run(['ps', 'aux'], capture_output=True, text=True)
        if 'Blender.app' in result.stdout:
            print("✅ Blender is running")
        else:
            print("❌ Blender not running")
            return False
        
        return True
        
    except Exception as e:
        print(f"❌ Connection test failed: {e}")
        return False

def test_addon_installation():
    """Test if the Blender addon is properly installed"""
    print("\n🔍 Testing Blender addon installation...")
    
    addon_path = Path.home() / "Library/Application Support/Blender/4.4/scripts/addons/addon.py"
    
    if addon_path.exists():
        print(f"✅ Blender addon found at: {addon_path}")
        
        # Check file size
        size = addon_path.stat().st_size
        if size > 1000:  # Should be at least 1KB
            print(f"✅ Addon file size: {size} bytes")
            return True
        else:
            print(f"❌ Addon file seems too small: {size} bytes")
            return False
    else:
        print(f"❌ Blender addon not found at: {addon_path}")
        return False

def test_mcp_configuration():
    """Test MCP configuration in Cursor"""
    print("\n🔍 Testing MCP configuration...")
    
    mcp_config_path = Path.home() / ".cursor/mcp.json"
    
    if mcp_config_path.exists():
        print(f"✅ MCP config found at: {mcp_config_path}")
        
        try:
            with open(mcp_config_path, 'r') as f:
                config = json.load(f)
            
            if 'blender' in config.get('mcpServers', {}):
                print("✅ Blender MCP server configured")
                return True
            else:
                print("❌ Blender MCP server not configured")
                return False
                
        except Exception as e:
            print(f"❌ Error reading MCP config: {e}")
            return False
    else:
        print(f"❌ MCP config not found at: {mcp_config_path}")
        return False

def test_asset_creation():
    """Test creating a simple 3D asset"""
    print("\n🔍 Testing 3D asset creation...")
    
    # Create output directory
    output_dir = Path("/Volumes/Folk_DAS/Apps/MacroAI/3D_Assets")
    output_dir.mkdir(exist_ok=True)
    
    # Test creating a simple cube
    test_script = """
import json
import socket
import time

def test_create_cube():
    try:
        # Connect to Blender
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect(('localhost', 5000))
        
        # Create cube command
        command = {
            "type": "create_object",
            "params": {
                "object_type": "MESH",
                "primitive_type": "CUBE",
                "location": [0, 0, 0],
                "size": 1.0
            }
        }
        
        # Send command
        sock.send(json.dumps(command).encode())
        response = sock.recv(4096).decode()
        result = json.loads(response)
        
        if result.get('status') == 'success':
            print("✅ Cube created successfully")
            
            # Export as USDZ
            export_command = {
                "type": "export",
                "params": {
                    "format": "USDZ",
                    "filepath": "/Volumes/Folk_DAS/Apps/MacroAI/3D_Assets/test_cube.usdz",
                    "embed_textures": True,
                    "optimize_mesh": True
                }
            }
            
            sock.send(json.dumps(export_command).encode())
            response = sock.recv(4096).decode()
            result = json.loads(response)
            
            if result.get('status') == 'success':
                print("✅ USDZ export successful")
                return True
            else:
                print(f"❌ Export failed: {result}")
                return False
        else:
            print(f"❌ Cube creation failed: {result}")
            return False
            
    except Exception as e:
        print(f"❌ Test failed: {e}")
        return False
    finally:
        sock.close()

if __name__ == "__main__":
    test_create_cube()
"""
    
    # Write test script
    test_file = Path("/tmp/test_cube_creation.py")
    with open(test_file, 'w') as f:
        f.write(test_script)
    
    # Run test
    try:
        result = subprocess.run([sys.executable, str(test_file)], 
                              capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0 and "✅" in result.stdout:
            print("✅ 3D asset creation test passed")
            return True
        else:
            print(f"❌ 3D asset creation test failed: {result.stdout}")
            return False
            
    except subprocess.TimeoutExpired:
        print("❌ 3D asset creation test timed out")
        return False
    except Exception as e:
        print(f"❌ 3D asset creation test error: {e}")
        return False
    finally:
        test_file.unlink(missing_ok=True)

def test_ios_integration():
    """Test iOS integration components"""
    print("\n🔍 Testing iOS integration...")
    
    # Check if Asset3DManager.swift exists
    asset_manager_path = Path("/Volumes/Folk_DAS/Apps/MacroAI/MacroAI Pro/Asset3DManager.swift")
    
    if asset_manager_path.exists():
        print("✅ Asset3DManager.swift found")
        
        # Check file content
        with open(asset_manager_path, 'r') as f:
            content = f.read()
        
        if 'class Asset3DManager' in content:
            print("✅ Asset3DManager class found")
        else:
            print("❌ Asset3DManager class not found")
            return False
        
        if 'displayInAR' in content:
            print("✅ AR integration methods found")
        else:
            print("❌ AR integration methods not found")
            return False
        
        return True
    else:
        print(f"❌ Asset3DManager.swift not found at: {asset_manager_path}")
        return False

def test_file_formats():
    """Test if required file formats are supported"""
    print("\n🔍 Testing file format support...")
    
    # Check if we can create test files
    test_formats = ['usdz', 'glb', 'obj']
    output_dir = Path("/Volumes/Folk_DAS/Apps/MacroAI/3D_Assets")
    
    for format in test_formats:
        test_file = output_dir / f"test.{format}"
        try:
            # Create a dummy file to test write permissions
            test_file.write_text("test")
            test_file.unlink()
            print(f"✅ {format.upper()} format write test passed")
        except Exception as e:
            print(f"❌ {format.upper()} format write test failed: {e}")
            return False
    
    return True

def generate_test_report():
    """Generate a comprehensive test report"""
    print("\n" + "="*60)
    print("🏥 3D ASSET PIPELINE TEST REPORT")
    print("="*60)
    
    tests = [
        ("Blender MCP Connection", test_blender_connection),
        ("Blender Addon Installation", test_addon_installation),
        ("MCP Configuration", test_mcp_configuration),
        ("3D Asset Creation", test_asset_creation),
        ("iOS Integration", test_ios_integration),
        ("File Format Support", test_file_formats)
    ]
    
    results = []
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ {test_name} test crashed: {e}")
            results.append((test_name, False))
    
    # Print results
    print("\n📊 TEST RESULTS:")
    print("-" * 40)
    
    passed = 0
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{test_name:<30} {status}")
        if result:
            passed += 1
    
    print("-" * 40)
    print(f"Total: {len(results)} | Passed: {passed} | Failed: {len(results) - passed}")
    
    # Overall status
    if passed == len(results):
        print("\n🎉 ALL TESTS PASSED! 3D pipeline is ready.")
        print("\nNext steps:")
        print("1. Run: python3 create_medical_assets.py")
        print("2. Copy USDZ files to your iOS app bundle")
        print("3. Test AR Quick Look in your app")
    else:
        print(f"\n⚠️  {len(results) - passed} test(s) failed. Check the issues above.")
        print("\nTroubleshooting:")
        print("1. Make sure Blender is running with the addon enabled")
        print("2. Check that blender-mcp server is running")
        print("3. Verify MCP configuration in Cursor")
        print("4. Ensure proper file permissions")

def main():
    """Run all tests"""
    print("🏥 3D Asset Pipeline Test Suite")
    print("Testing complete workflow from Blender to iOS...")
    
    generate_test_report()

if __name__ == "__main__":
    main() 