# Blender MCP Setup Guide

## Current Status ✅
- ✅ Blender MCP server is running
- ✅ Blender is running
- ✅ Addon is installed
- ✅ MCP configuration is correct
- ✅ iOS integration is ready

## Next Step: Enable the Addon in Blender

### Step 1: Open Blender
1. Make sure Blender is running (it is ✅)

### Step 2: Enable the Addon
1. In Blender, go to **Edit > Preferences**
2. Click on **Add-ons** tab
3. In the search box, type **"Blender MCP"**
4. Find **"Interface: Blender MCP"** in the list
5. **Check the box** to enable it
6. Click **Save Preferences**

### Step 3: Connect to Claude
1. In the 3D View, press **N** to open the sidebar
2. Look for the **"BlenderMCP"** tab
3. Click **"Connect to Claude"** button
4. You should see a status message indicating connection

### Step 4: Test Connection
After enabling the addon, run:
```bash
python3 test_blender_mcp.py
```

## Expected Results
Once the addon is enabled, you should see:
- ✅ Connection successful
- ✅ Can create 3D objects
- ✅ Can export USDZ files

## Troubleshooting

### If "Blender MCP" doesn't appear in addons:
1. Restart Blender
2. Check that the addon file exists: `~/Library/Application Support/Blender/4.4/scripts/addons/addon.py`

### If connection fails:
1. Make sure Blender is running
2. Check that the addon is enabled
3. Click "Connect to Claude" in the sidebar
4. Restart the blender-mcp server if needed

### If MCP tools don't appear in Cursor:
1. Restart Cursor
2. Check the MCP configuration in `~/.cursor/mcp.json`
3. Verify the blender-mcp server is running

## Quick Test
Once everything is set up, run:
```bash
python3 create_medical_assets.py
```

This will create medical device 3D models and export them as USDZ files ready for iOS integration. 