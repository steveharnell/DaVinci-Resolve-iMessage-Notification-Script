# DaVinci Resolve iMessage Export Notifications

A Lua script for DaVinci Resolve that automatically sends iMessage notifications when your exports complete. Specifically designed for large, multi-hour renders and batch export workflows.

## What it does

- 📱 **Sends iMessage notifications** when exports finish (success or failure)
- 🎯 **Smart completion detection** - monitors file creation, stability, and queue removal
- 📊 **Rich export details** - includes project name, render time, file size, and format
- ⏰ **Handles large exports** - designed for multi-hour ProRes renders and batch jobs
- 🔄 **Multiple detection methods** - file monitoring + job queue tracking for reliability
- 🎬 **Batch export support** - monitors multiple simultaneous render jobs

## Key Features

### Intelligent Export Detection
- **File stability monitoring** - ensures exports are truly complete, not just started
- **Job queue tracking** - detects when render jobs are removed (completion signal)
- **Multi-hour support** - configured for 8+ hour monitoring with smart timeouts
- **Large file handling** - proper validation for multi-GB ProRes files
- **"and more" support** - handles jobs that export multiple files

### Rich Notifications
- ✅ **Success**: "Export Complete! 📽️ ProjectName 📁 filename.mov ⏱️ 2h 15m 💾 12.3 GB"
- ❌ **Failure**: Clear failure notifications with timeline and format details
- 🎬 **Batch Summary**: "All 5 exports completed! ⏱️ Total time: 6h 23m"
- 📈 **Progress** (optional): Real-time updates at 25%, 50%, 75% completion

### Production-Ready Features
- **External drive support** - works with network and external storage
- **Timeout protection** - won't run indefinitely (8-hour default)
- **Multiple export formats** - MXF, MOV, ProRes, DNxHD, etc.
- **Timeline-specific exports** - shows which timeline completed

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

3. **Configure your recipient** in the script:
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
    maxWaitTime = 28800,                          -- 8 hour timeout for large exports
    
    -- Message content
    includeProjectName = true,                    -- Show project name
    includeRenderTime = true,                     -- Show render duration
    includeFileSize = true,                       -- Show final file size
    sendProgressUpdates = false,                  -- Enable for progress notifications
    
    -- Large file detection (for multi-hour exports)
    fileStabilityWait = 15,                       -- Wait between size checks
    fileStabilityThreshold = 30,                  -- File stable for X seconds
    enableJobRemovalDetection = true,             -- Detect job queue removal
    
    -- Debug mode
    debugMode = true,                             -- Shows detailed console output
}
```

## Usage

### Large Export Workflow
1. **Set up your render queue** with multiple jobs
2. **Start all renders** in DaVinci Resolve's Deliver page  
3. **Run the script** via **Workspace → Scripts**
4. **Walk away** - perfect for overnight or weekend renders
5. **Get notified** as each export completes

### Example Multi-Job Workflow
```
1. Add 5 timelines to render queue (ProRes exports)
2. Run: imessage_export_notifications.lua
3. Script detects: "🎬 Starting 5 exports in DaVinci Resolve"
4. Leave computer running overnight
5. Wake up to notifications:
   - "✅ Export Complete! 📽️ DAY01 📁 A_0001C001_250624_093430_p1F0F.mov ⏱️ 2h 15m 💾 12.3 GB"
   - "✅ Export Complete! 📽️ DAY02 📁 A_0002C001_250625_043143_p1F0F.mov ⏱️ 3h 22m 💾 18.7 GB"
   - ... etc for each timeline
   - "🎉 All 5 exports completed! ⏱️ Total time: 12h 45m"
```

## How It Works

### Dual Detection Method
1. **File System Monitoring**:
   - Watches output directories for file creation
   - Monitors file size stability (handles large files properly)
   - Validates file modification timestamps
   - Handles "OutputFilename: file.mov and more" scenarios

2. **Render Queue Tracking**:
   - Monitors job status changes in DaVinci Resolve API
   - Detects when jobs are removed from queue (completion signal)
   - Tracks job progress and metadata

### Smart Completion Logic
- ✅ **File exists** in target directory
- ✅ **File size stable** for 15+ seconds (configurable)
- ✅ **File unmodified** for 30+ seconds (configurable)  
- ✅ **File substantial** (>1KB, not just a stub)
- ✅ **Job removed** from render queue
- ✅ Only then sends completion notification

## Sample Notifications

### Large Export Start
> 🎬 Starting 5 exports in DaVinci Resolve

### Individual Completion
> ✅ Export Complete!  
> 📽️ DAY03  
> 📁 A_0003C001_250626_090327_p1F0F.mov  
> ⏱️ 4h 22m  
> 💾 23.1 GB

### Batch Summary
> 🎉 All 5 exports completed!  
> ⏱️ Total time: 12h 45m

### Progress Update (if enabled)
> 🎬 Rendering: A_0004C001_250627_093722_p1F0F.mov  
> ▓▓▓▓▓▓▓░░░ 75%

### Export Failure
> ❌ Export Failed!  
> 📽️ DAY05  
> 📁 A_0005C001_250628_093506_p1F0F.mov  
> ⏱️ 45m

## Troubleshooting

### "No render jobs found"
- Ensure jobs are in render queue before running script
- Verify you're on Deliver page with active jobs

### "Export completed but no notification"
For large files:
- Increase `fileStabilityWait` to 30+ seconds
- Increase `fileStabilityThreshold` to 60+ seconds
- Enable `enableJobRemovalDetection = true`

### "False completion notifications"  
- Script detects file creation early
- Increase stability thresholds in CONFIG
- Check that external drives aren't causing file system delays

### "Script times out before completion"
- Increase `maxWaitTime` for very long exports
- Default is 8 hours, increase to 12+ for massive projects

### "Multiple jobs not detected properly"
- Enable debug mode to see job detection details
- Check console output for job IDs and status
- Ensure all jobs show unique `OutputFilename` entries

## Advanced Configuration

### Very Large Projects (8+ hour exports)
```lua
maxWaitTime = 43200,              -- 12 hours
fileStabilityWait = 30,           -- 30 second checks  
fileStabilityThreshold = 120,     -- 2 minute stability
```

### External/Network Storage
```lua
fileStabilityWait = 20,           -- Account for network delays
fileStabilityThreshold = 60,      -- Longer stability for network drives
```

### Multiple Recipients
Modify the `sendiMessage` function to send to multiple contacts:
```lua
local recipients = {"your-email@icloud.com", "5551234567", "colleague@icloud.com"}
```

## System Requirements

- **macOS** 10.14 or later
- **DaVinci Resolve** (any recent version with Lua support)
- **Messages app** with iMessage configured
- **Apple ID** signed in to Messages
- **External storage** (optional) - supports network drives

## Real-World Use Cases

### Documentary Post-Production
- Export 10+ timelines overnight to ProRes 422 LT
- Get notified which ones completed vs. failed
- Perfect for unattended batch processing

### Commercial/Music Video Delivery
- Export multiple format deliverables (ProRes, H.264, etc.)
- Monitor progress during client calls
- Ensure all deliverables complete before deadline

### Color Grading Workflows  
- Export graded timelines to review formats
- Get notifications when ready for client review
- Coordinate with remote teams on completion status

## Performance Notes

- **Minimal system impact** - checks every 15 seconds
- **Network friendly** - works with external/network storage
- **Memory efficient** - designed for long-running monitoring
- **Resolve compatible** - doesn't interfere with other DaVinci operations

## Contributing

Submit issues or pull requests to improve:
- Additional notification methods (Slack, email, etc.)
- Enhanced large file detection algorithms  
- Support for other export queue types
- Integration with render farm workflows

## License

This script is provided as-is for educational and production use. Modify as needed for your workflow.

---

**💡 Pro Tip**: Perfect for busy post facilities! Start your overnight batch exports, run this script, and wake up knowing exactly which deliverables completed successfully. No more checking exports manually or discovering failed renders the next morning.
