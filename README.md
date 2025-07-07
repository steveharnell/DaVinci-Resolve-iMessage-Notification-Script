# DaVinci Resolve iMessage Notification Script

## Description

This Lua script automatically monitors your DaVinci Resolve render queue and sends iMessage notifications when render jobs complete, fail, or are cancelled. Perfect for long renders when you want to step away from your computer and get notified on your phone or other Apple devices.

## Features

- 📱 Sends iMessage notifications with render status
- ⏱️ Tracks and reports render duration (HH:MM:SS format)
- 📽️ Includes project name and render mode in notifications
- ✅ Different emojis for completed, failed, or cancelled renders
- 🧪 Built-in test message to verify setup

### 1. Setup Instructions

**Download the script** (`imessage_export_notifications.lua`)

**Copy to DaVinci Resolve scripts folder**:
   ```
   ~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/
   ```

**Configure Recipient
Edit line 3 in the script to set your phone number or Apple ID email:
```lua
local recipient = "+15551234567"  -- Replace with your number or email
```

### 2. Enable Messages Access
- Ensure DaVinci Resolve has permission to control Messages app
- You may need to grant accessibility permissions in System Preferences > Security & Privacy > Privacy > Accessibility

### 3. Run the Script
1. Open DaVinci Resolve
2. Load your project with render jobs in the queue
3. Go to **Workspace** > **Scripts** > **Browse Scripts...**
4. Navigate to and run this script
5. You should immediately receive a test message (🧪Test Message from DaVinci Resolve Render Queue Notification)

## Usage

1. **Queue your render jobs** in DaVinci Resolve as normal
2. **Run the script** - it will automatically start rendering all queued jobs
3. **Step away** - you'll receive notifications as each job completes

## Message Format

Notifications include:
- Project name 📽️
- Status emoji (✅ completed, ❌ failed, 🛑 cancelled)
- Human-readable status
- Total render time ⏱️ 
- Render mode (Individual Clips or Single Clip)

**Example notification:**
```
📽️ Project 'My Film' render job ✅ completed successfully. ⏱️ Time: 01:23:45. Mode: Individual Clips.
```

## Requirements

- macOS with Messages app
- DaVinci Resolve (tested with recent versions)
- iMessage account configured

## Notes

- The script will monitor jobs until all are complete
- Only works on macOS due to AppleScript dependency
- Script exits automatically when all jobs finish
