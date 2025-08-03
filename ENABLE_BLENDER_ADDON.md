# 🔧 Enable Blender MCP Addon

## Current Status
- ✅ Blender is running
- ✅ Blender MCP server is running on port 5000
- ✅ Addon is installed
- ❌ Addon needs to be enabled in Blender

## Steps to Enable the Addon

### 1. Open Blender
Blender is already running (PID: 60562)

### 2. Enable the Addon
1. In Blender, go to **Edit > Preferences**
2. Click on the **Add-ons** tab
3. In the search box, type **"Blender MCP"**
4. Find **"Interface: Blender MCP"** in the list
5. **Check the box** to enable it
6. Click **Save Preferences**

### 3. Connect to Claude
1. In the 3D View, press **N** to open the sidebar
2. Look for the **"BlenderMCP"** tab
3. Click **"Connect to Claude"** button
4. You should see a status message indicating connection

### 4. Test Connection
After enabling the addon, run:
```bash
python3 test_simple_blender.py
```

## Expected Results
Once the addon is enabled, you should see:
- ✅ Connection successful
- ✅ Scene info retrieved
- ✅ 3D cube created
- ✅ Object info retrieved

## Troubleshooting
If the addon doesn't appear:
1. Check if the addon file exists: `~/Library/Application Support/Blender/4.4/scripts/addons/addon.py`
2. Restart Blender
3. Check Blender's system console for error messages

## Next Steps
Once the addon is enabled, we can:
1. Test the Christmas tree 3D conversion
2. Create animated 3D models
3. Export USDZ files for iOS integration 