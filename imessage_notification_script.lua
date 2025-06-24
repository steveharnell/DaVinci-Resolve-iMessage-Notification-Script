-- Alternative method: Monitor render status via project changes
function getAlternativeRenderStatus()
    -- Check if we can get timeline render status
    local timeline = project:GetCurrentTimeline()
    if timeline then
        -- Try to get render status from timeline
        local renderStatus = timeline:GetRenderJobStatus()
        if renderStatus then
            return renderStatus
        end
    end
    
    -- Check project-level render status
    if project.GetRenderJobStatus then
        return project:GetRenderJobStatus()
    end
    
    return nil
end

-- Function to detect render completion by checking output directory
function checkOutputDirectory(targetDir, jobName, fullOutputName, debugMode, stabilityWait, stabilityThreshold)
    if not targetDir or targetDir == "" then
        return false
    end
    
    -- Parse the full output name to get all possible filenames
    local possibleNames = {}
    
    -- Add the main filename
    table.insert(possibleNames, jobName)
    
    -- If fullOutputName contains "and more", it might be multiple files
    if fullOutputName and fullOutputName:find("and more") then
        -- Extract all filenames before "and more"
        local filesPart = fullOutputName:match("(.+)%s+and more")
        if filesPart then
            for filename in filesPart:gmatch("([^%s,]+)") do
                table.insert(possibleNames, filename)
            end
        end
    end
    
    -- Common export extensions to check
    local extensions = {".mxf", ".mov", ".mp4", ".avi", ".mkv", ".prores", ".dnxhd"}
    
    for _, baseName in ipairs(possibleNames) do
        -- First check if the file exists as-is (already has extension)
        local fullPath = targetDir .. "/" .. baseName
        local command = 'test -f "' .. fullPath .. '" && echo "exists"'
        local result = executeCommand(command)
        
        if result == "exists" then
            -- Check if file is actually complete by monitoring file size stability
            if isFileCompletelyWritten(fullPath, debugMode, stabilityWait, stabilityThreshold) then
                if debugMode then
                    print("   ✅ Found completed file: " .. fullPath)
                end
                return true, fullPath
            elseif debugMode then
                print("   🔄 File exists but still being written: " .. baseName)
            end
        end
        
        -- If not found as-is, try adding extensions
        local baseNameNoExt = baseName:match("([^%.]+)") -- Remove extension if present
        for _, ext in ipairs(extensions) do
            local filename = baseNameNoExt .. ext
            fullPath = targetDir .. "/" .. filename
            command = 'test -f "' .. fullPath .. '" && echo "exists"'
            result = executeCommand(command)
            
            if result == "exists" then
                if isFileCompletelyWritten(fullPath, debugMode, stabilityWait, stabilityThreshold) then
                    if debugMode then
                        print("   ✅ Found completed file: " .. fullPath)
                    end
                    return true, fullPath
                elseif debugMode then
                    print("   🔄 File exists but still being written: " .. filename)
                end
            end
        end
    end
    
    return false
end

-- Function to check if file is completely written (not still being rendered)
function isFileCompletelyWritten(filepath, debugMode, stabilityWait, stabilityThreshold)
    -- Get current file size
    local sizeCommand = 'stat -f%z "' .. filepath .. '" 2>/dev/null'
    local currentSize = executeCommand(sizeCommand)
    
    if not currentSize or currentSize == "" then
        return false
    end
    
    -- Wait a configurable amount and check size again
    os.execute("sleep " .. stabilityWait)
    
    local newSize = executeCommand(sizeCommand)
    
    if not newSize or newSize == "" then
        return false
    end
    
    -- Also check modification time - file should not have been modified very recently
    local modCommand = 'stat -f "%m" "' .. filepath .. '" 2>/dev/null'
    local modTime = executeCommand(modCommand)
    
    if modTime then
        local currentTime = os.time()
        local fileTime = tonumber(modTime)
        local timeSinceModified = currentTime - fileTime
        
        if debugMode then
            print("   📊 File size check: " .. currentSize .. " -> " .. newSize .. " bytes")
            print("   ⏰ Last modified: " .. timeSinceModified .. " seconds ago")
        end
        
        -- File is complete if:
        -- 1. Size hasn't changed in the last few seconds AND
        -- 2. File hasn't been modified recently
        if currentSize == newSize and timeSinceModified > stabilityThreshold then
            return true
        end
    end
    
    return false
end-- DaVinci Resolve iMessage Export Notification Script
-- Simplified version that only sends iMessage notifications when exports complete

-- Connect to DaVinci Resolve
local resolve = Resolve()
local projectManager = resolve:GetProjectManager()
local project = projectManager:GetCurrentProject()

if not project then
    print("❌ Error: No project loaded. Please load a project and try again.")
    return
end

-- CONFIGURATION
local CONFIG = {
    -- iMessage settings
    iMessageRecipient = "your-email@icloud.com", -- Your iCloud email or phone number
    
    -- Monitoring settings
    checkInterval = 15,                    -- Check every 15 seconds
    maxWaitTime = 14400,                   -- Maximum wait time (4 hours)
    
    -- Message customization
    includeProjectName = true,
    includeRenderTime = true,
    includeFileSize = true,
    sendProgressUpdates = false,           -- Send updates at 25%, 50%, 75%
    
    -- File completion detection
    fileStabilityWait = 5,                 -- Seconds to wait before checking file size again
    fileStabilityThreshold = 10,           -- File must be unmodified for this many seconds
    
    -- Debug mode
    debugMode = true,
}

-- Results tracking
local monitoring = {
    startTime = os.time(),
    initialJobs = {},
    sentUpdates = {},
    isMonitoring = false,
}

-- Function to execute macOS commands
function executeCommand(command)
    local handle = io.popen(command)
    if handle then
        local result = handle:read("*a")
        handle:close()
        return result:gsub("\n$", "")
    end
    return nil
end

-- Function to send iMessage
function sendiMessage(message)
    local recipient = CONFIG.iMessageRecipient
    
    -- AppleScript to send iMessage
    local applescript = string.format([[
        tell application "Messages"
            set targetService to 1st service whose service type = iMessage
            set targetBuddy to buddy "%s" of targetService
            send "%s" to targetBuddy
        end tell
    ]], recipient, message:gsub('"', '\\"'):gsub('\n', '\\n'))
    
    local command = "osascript -e '" .. applescript .. "'"
    local result = executeCommand(command)
    
    if CONFIG.debugMode then
        print("💬 iMessage sent to: " .. recipient)
        print("   Message: " .. message:gsub('\n', ' | '))
    end
    
    return result
end

-- Function to get file size in human readable format
function getFileSize(filepath)
    local command = 'stat -f%z "' .. filepath .. '" 2>/dev/null'
    local sizeBytes = executeCommand(command)
    
    if not sizeBytes or sizeBytes == "" then
        return nil
    end
    
    local size = tonumber(sizeBytes)
    if not size then return nil end
    
    local units = {"B", "KB", "MB", "GB", "TB"}
    local unitIndex = 1
    
    while size >= 1024 and unitIndex < #units do
        size = size / 1024
        unitIndex = unitIndex + 1
    end
    
    return string.format("%.1f %s", size, units[unitIndex])
end

-- Function to format duration
function formatDuration(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    
    if hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    elseif minutes > 0 then
        return string.format("%dm %ds", minutes, secs)
    else
        return string.format("%ds", secs)
    end
end

-- Function to get current render queue status
function getRenderQueueStatus()
    -- Try multiple API methods to get render queue
    local renderQueue = nil
    
    -- Method 1: GetRenderJobList
    if project.GetRenderJobList then
        renderQueue = project:GetRenderJobList()
    end
    
    -- Method 2: Alternative API call
    if not renderQueue and project.GetRenderQueue then
        renderQueue = project:GetRenderQueue()
    end
    
    if not renderQueue then
        if CONFIG.debugMode then
            print("   🔍 No render queue found via API")
        end
        return {}
    end
    
    local jobs = {}
    for i, job in ipairs(renderQueue) do
        if CONFIG.debugMode then
            print("   🔍 Raw job data " .. i .. ":")
            for key, value in pairs(job) do
                print("      " .. tostring(key) .. ": " .. tostring(value))
            end
        end
        
        -- Extract the actual filename from OutputFilename (it might contain "and more")
        local outputFilename = job.OutputFilename or job.outputFilename or ""
        local actualFilename = outputFilename:match("([^%s]+)") or ("Job_" .. i)
        
        local status = {
            id = job.JobId or job.jobId or job.Id or i,
            name = actualFilename,
            fullOutputName = outputFilename,
            status = job.JobStatus or job.jobStatus or job.Status or job.status or "Rendering",
            progress = tonumber(job.CompletionPercentage or job.completionPercentage or job.Progress or job.progress or 0),
            targetDir = job.TargetDir or job.targetDir or job.OutputDir or job.outputDir or "",
            timelineName = job.TimelineName or "Unknown Timeline",
            renderMode = job.RenderMode or "Unknown Mode",
            videoFormat = job.VideoFormat or "Unknown Format",
            isRender = job.IsRender or job.isRender or true,
        }
        jobs[status.id] = status
    end
    
    return jobs
end

-- Function to create completion message
function createCompletionMessage(job, success, renderTime)
    local lines = {}
    
    -- Status line with emoji
    if success then
        table.insert(lines, "✅ Export Complete!")
    else
        table.insert(lines, "❌ Export Failed!")
    end
    
    -- Project info
    if CONFIG.includeProjectName then
        local projectName = project:GetName() or "Unknown Project"
        table.insert(lines, "📽️ " .. projectName)
    end
    
    -- File info
    table.insert(lines, "📁 " .. job.name)
    
    -- Render time
    if CONFIG.includeRenderTime and renderTime then
        table.insert(lines, "⏱️ " .. formatDuration(renderTime))
    end
    
    -- File size (only for successful exports)
    if CONFIG.includeFileSize and success and job.targetDir ~= "" then
        local fullPath = job.targetDir .. "/" .. job.name
        local fileSize = getFileSize(fullPath)
        if fileSize then
            table.insert(lines, "💾 " .. fileSize)
        end
    end
    
    return table.concat(lines, "\n")
end

-- Function to create progress message
function createProgressMessage(job, progress)
    local progressBar = ""
    local filled = math.floor(progress / 10)
    for i = 1, 10 do
        if i <= filled then
            progressBar = progressBar .. "▓"
        else
            progressBar = progressBar .. "░"
        end
    end
    
    return string.format("🎬 Rendering: %s\n%s %d%%", job.name, progressBar, progress)
end

-- Main monitoring function
function monitorRenderQueue()
    print("🎬 Starting iMessage export monitoring...")
    print("Recipient: " .. CONFIG.iMessageRecipient)
    print("Check interval: " .. CONFIG.checkInterval .. " seconds")
    print("")
    
    -- Get initial job status
    monitoring.initialJobs = getRenderQueueStatus()
    monitoring.startTime = os.time()
    monitoring.isMonitoring = true
    
    if not next(monitoring.initialJobs) then
        print("❌ No render jobs found in queue")
        return
    end
    
    local jobCount = 0
    for _ in pairs(monitoring.initialJobs) do jobCount = jobCount + 1 end
    
    print("📊 Found " .. jobCount .. " job(s) in render queue:")
    for id, job in pairs(monitoring.initialJobs) do
        print("   • " .. job.name .. " (" .. job.status .. ")")
        print("     Timeline: " .. job.timelineName)
        print("     Output: " .. job.targetDir)
        print("     Format: " .. job.videoFormat)
        monitoring.sentUpdates[id] = {completed = false}
    end
    print("")
    
    -- Send initial message
    if jobCount == 1 then
        local job = next(monitoring.initialJobs)
        sendiMessage("🎬 Starting export: " .. monitoring.initialJobs[job].name)
    else
        sendiMessage("🎬 Starting " .. jobCount .. " exports in DaVinci Resolve")
    end
    
    -- Monitoring loop
    local iterations = 0
    local maxIterations = math.floor(CONFIG.maxWaitTime / CONFIG.checkInterval)
    
    while monitoring.isMonitoring and iterations < maxIterations do
        iterations = iterations + 1
        
        -- Wait before checking
        os.execute("sleep " .. CONFIG.checkInterval)
        
        -- Get current status
        local currentJobs = getRenderQueueStatus()
        local elapsedTime = os.time() - monitoring.startTime
        
        if CONFIG.debugMode then
            print("⏰ Check " .. iterations .. " (" .. formatDuration(elapsedTime) .. " elapsed)")
        end
        
        -- Check each initial job
        for id, initialJob in pairs(monitoring.initialJobs) do
            local currentJob = currentJobs[id]
            
            if currentJob then
                -- Job still exists - primarily check for file completion
                if CONFIG.debugMode then
                    print("   📊 Job " .. id .. ": " .. currentJob.name .. " (" .. currentJob.status .. ")")
                    print("      Target: " .. currentJob.targetDir)
                    print("      Output: " .. currentJob.fullOutputName)
                end
                
                -- Primary method: Check output directory for completed files
                if currentJob.targetDir ~= "" and not monitoring.sentUpdates[id].completed then
                    local isComplete, filePath = checkOutputDirectory(
                        currentJob.targetDir, 
                        currentJob.name, 
                        currentJob.fullOutputName, 
                        CONFIG.debugMode,
                        CONFIG.fileStabilityWait,
                        CONFIG.fileStabilityThreshold
                    )
                    if isComplete then
                        monitoring.sentUpdates[id].completed = true
                        print("✅ Job completed (file detected): " .. currentJob.name)
                        print("   📁 File: " .. (filePath or "Unknown"))
                        local message = createCompletionMessage(currentJob, true, elapsedTime)
                        sendiMessage(message)
                    end
                end
                
                -- Secondary method: Status change (if API provides it)
                if (initialJob.status ~= "Complete" and currentJob.status == "Complete") or
                   (currentJob.progress >= 100 and initialJob.progress < 100) then
                    if not monitoring.sentUpdates[id].completed then
                        monitoring.sentUpdates[id].completed = true
                        print("✅ Job completed (status change): " .. currentJob.name)
                        local message = createCompletionMessage(currentJob, true, elapsedTime)
                        sendiMessage(message)
                    end
                    
                -- Failure detection
                elseif (initialJob.status ~= "Failed" and currentJob.status == "Failed") or
                       (currentJob.status == "Error") then
                    if not monitoring.sentUpdates[id].completed then
                        monitoring.sentUpdates[id].completed = true
                        print("❌ Job failed: " .. currentJob.name)
                        local message = createCompletionMessage(currentJob, false, elapsedTime)
                        sendiMessage(message)
                    end
                    
                -- Progress updates (if enabled and progress is available)
                elseif CONFIG.sendProgressUpdates and currentJob.progress > 0 then
                    local progress = currentJob.progress
                    local milestones = {25, 50, 75}
                    
                    for _, milestone in ipairs(milestones) do
                        if progress >= milestone and not monitoring.sentUpdates[id][milestone] then
                            monitoring.sentUpdates[id][milestone] = true
                            local message = createProgressMessage(currentJob, progress)
                            sendiMessage(message)
                            print("📈 Progress update sent: " .. currentJob.name .. " " .. progress .. "%")
                            break
                        end
                    end
                end
                
            else
                -- Job no longer in queue (completed and removed)
                if not monitoring.sentUpdates[id].completed then
                    monitoring.sentUpdates[id].completed = true
                    print("✅ Job completed and removed from queue: " .. initialJob.name)
                    local message = createCompletionMessage(initialJob, true, elapsedTime)
                    sendiMessage(message)
                end
            end
        end
        
        -- Check if all jobs are done
        local allDone = true
        for id, initialJob in pairs(monitoring.initialJobs) do
            if not monitoring.sentUpdates[id].completed then
                local currentJob = currentJobs[id]
                if currentJob and currentJob.status ~= "Complete" and currentJob.status ~= "Failed" and currentJob.progress < 100 then
                    allDone = false
                    break
                end
            end
        end
        
        if allDone then
            print("🎉 All render jobs completed!")
            monitoring.isMonitoring = false
            
            -- Send final summary if multiple jobs
            local completedCount = 0
            for _ in pairs(monitoring.initialJobs) do completedCount = completedCount + 1 end
            
            if completedCount > 1 then
                local summaryMessage = string.format("🎉 All %d exports completed!\n⏱️ Total time: %s", 
                    completedCount, formatDuration(elapsedTime))
                sendiMessage(summaryMessage)
            end
            break
        end
    end
    
    -- Timeout handling
    if iterations >= maxIterations then
        print("⚠️  Monitoring stopped due to timeout")
        sendiMessage("⚠️ Export monitoring timed out after " .. formatDuration(CONFIG.maxWaitTime) .. ". Please check DaVinci Resolve manually.")
    end
    
    -- Final summary
    print("\n=== MONITORING COMPLETE ===")
    print("Total monitoring time: " .. formatDuration(os.time() - monitoring.startTime))
end

-- Function to test iMessage functionality
function testMessage()
    print("🧪 Testing iMessage functionality...")
    local testMsg = "🧪 Test message from DaVinci Resolve export monitor"
    sendiMessage(testMsg)
    print("✅ Test message sent!")
end

-- Main execution
function main()
    print("=== DaVinci Resolve iMessage Export Monitor ===")
    print("Recipient: " .. CONFIG.iMessageRecipient)
    print("Progress updates: " .. (CONFIG.sendProgressUpdates and "Enabled" or "Disabled"))
    print("")
    
    -- Send test message if in debug mode
    if CONFIG.debugMode then
        testMessage()
        print("")
    end
    
    monitorRenderQueue()
end

-- Run the script
main()