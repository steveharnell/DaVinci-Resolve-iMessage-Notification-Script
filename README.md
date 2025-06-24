# DaVinci Resolve iMessage Export Notifications

A Lua script for DaVinci Resolve that automatically sends iMessage notifications when your exports complete. Perfect for long renders when you need to step away from your workstation.

## What it does

- 📱 **Sends iMessage notifications** when exports finish (success or failure)
- 🎯 **Smart completion detection** - monitors actual file creation and stability
- 📊 **Rich export details** - includes project name, render time, file size, and format
- 🔄 **Progress updates** (optional) - get notified at 25%, 50%, 75% completion
- ⏰ **Reliable monitoring** - won't trigger false positives during active rendering

## Key Features

### Intelligent File Detection
- **Waits for file stability** - ensures export is truly complete, not just started
- **Handles multiple formats** - supports .mxf, .mov, .mp4, .prores, etc.
- **File size monitoring** - confirms file has stopped growing before notifying
- **Cross-checks modification time** - ensures file hasn't been touched recently

### Rich Notifications
- ✅ **Success**: "Export Complete! 📽️ ProjectName 📁 filename.mov ⏱️ 5m 23s 💾 2.1 GB"
- ❌ **Failure**: Clear failure notifications with project details
- 📈 **Progress** (optional): "🎬 Rendering: filename.mov ▓▓▓▓▓░░░░░ 50%"

## Installation

### Prerequisites
- **macOS** (uses AppleScript for iMessage integration)
- **DaVinci Resolve** with Lua scripting support
- **Messages app** configured with your Apple ID

### Setup
1. **Download the script** (`imessage_notification_script.lua`)

2. **Copy to DaVinci Resolve scripts folder**:
   ```
   ~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/
   ```

3. **Configure your recipient** in the script (LINE 147):
   ```lua
   local CONFIG = {
       iMessageRecipient = "your-email@icloud.com", -- Your iCloud email or phone number
       -- ... other settings
   }
   ```

4. **Restart DaVinci Resolve** (if already running)

## Configuration

Edit the `CONFIG` section at the top of the script:

```lua
local CONFIG = {
    -- REQUIRED: Your iMessage recipient
    iMessageRecipient = "your-email@icloud.com",  -- or "5551234567"
    
    -- Monitoring settings
    checkInterval = 15,                           -- Check every 15 seconds
    maxWaitTime = 14400,                          -- 4 hour timeout
    
    -- Message content
    includeProjectName = true,                    -- Show project name
    includeRenderTime = true,                     -- Show render duration
    includeFileSize = true,                       -- Show final file size
    sendProgressUpdates = false,                  -- Enable for progress notifications
    
    -- File detection (advanced)
    fileStabilityWait = 5,                        -- Wait between size checks
    fileStabilityThreshold = 10,                  -- File stable for X seconds
    
    -- Debug mode
    debugMode = true,                             -- Shows detailed console output
}
```

## Usage

### Quick Start
1. **Set up your export** in DaVinci Resolve's Deliver page
2. **Start the render queue**
3. **Run the script** via **Workspace → Scripts**
4. **Go do other things** - you'll get notified when done!

### Example Workflow
```
1. Add clips to render queue
2. Run: imessage_export_notifications.lua
3. Script detects exports and sends: "🎬 Starting export: MyProject.mov"
4. Walk away from computer
5. Get notified: "✅ Export Complete! 📽️ MyProject 📁 MyProject.mov ⏱️ 12m 34s 💾 4.2 GB"
```

## How It Works

### Detection Method
1. **Monitors render queue** via DaVinci Resolve API
2. **Watches output directory** for file creation
3. **Confirms file stability** by checking size changes
4. **Validates completion** using modification timestamps

### Smart Completion Logic
- ✅ File exists in target directory
- ✅ File size hasn't changed for 5+ seconds
- ✅ File hasn't been modified for 10+ seconds
- ✅ Only then sends completion notification

## Sample Notifications

### Export Start
> 🎬 Starting export: Documentary_Final.mov

### Progress Update (if enabled)
> 🎬 Rendering: Documentary_Final.mov  
> ▓▓▓▓▓▓▓░░░ 75%

### Successful Completion
> ✅ Export Complete!  
> 📽️ Documentary Project  
> 📁 Documentary_Final.mov  
> ⏱️ 23m 45s  
> 💾 8.7 GB

### Failed Export
> ❌ Export Failed!  
> 📽️ Documentary Project  
> 📁 Documentary_Final.mov  
> ⏱️ 5m 12s

## Troubleshooting

### "No render jobs found"
- Ensure you have jobs in your render queue before running the script
- Check that you're on the Deliver page with active render jobs

### "iMessage not sending"
- Verify Messages app is configured with your Apple ID
- Test sending a manual iMessage to your recipient first
- Check that your recipient format is correct (email or phone number)

### "False completion notifications"
- Increase `fileStabilityThreshold` for larger files
- Increase `fileStabilityWait` for slower storage

### Script won't run
- Ensure script has `.lua` extension
- Check DaVinci Resolve has access to scripts folder
- Try running from Console first: **Workspace → Console**

## Advanced Configuration

### Multiple Recipients
To send to multiple devices, modify the `sendiMessage` function:
```lua
local recipients = {"your-email@icloud.com", "5551234567"}
for _, recipient in ipairs(recipients) do
    -- send to each recipient
end
```

### Custom Message Format
Modify the `createCompletionMessage` function to customize notification content.

### Integration with Other Apps
The script can be modified to trigger other actions:
- Send emails via macOS Mail
- Post to Slack channels
- Trigger IFTTT webhooks

## System Requirements

- **macOS** 10.14 or later
- **DaVinci Resolve** (any recent version with Lua support)
- **Messages app** with iMessage configured
- **Apple ID** signed in to Messages

## Contributing

Feel free to submit issues or pull requests to improve functionality:
- Add support for other notification methods
- Improve file detection algorithms
- Add support for batch export monitoring

## License

This script is provided as-is for educational and production use. Modify as needed for your workflow.
