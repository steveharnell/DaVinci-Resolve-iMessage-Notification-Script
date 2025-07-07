-- DaVinci Resolve iMessage Notification Script

-- 1. Set the iMessage recipient (phone number or Apple ID email):
local recipient = "+15551234567"  -- <-- replace with your target number/email

-- 2. Helper to send an iMessage via AppleScript:
local function sendiMessage(text)
    text = text:gsub('"', "'")  -- escape quotes
    local appleScript = 'tell application "Messages" to send "'.. text ..'" to buddy "'.. recipient ..'" of (1st service whose service type = iMessage)'
    os.execute('osascript -e "'.. appleScript:gsub('"', '\\"') .. '"')
end

-- 3. Test-message function
local function sendTestMessage()
    sendiMessage("🧪Test Message from DaVinci Resolve Notification")
end

-- Fire off the test message immediately:
sendTestMessage()

-- 4. Get current project
local projectManager = resolve:GetProjectManager()
local project = projectManager:GetCurrentProject()
if not project then
    print("No project loaded.")
    return
end

local projectName = project:GetName()
local modeInt = project:GetCurrentRenderMode()  -- 0 = Individual, 1 = Single
local renderModeStr = (modeInt == 1) and "Single Clip" or "Individual Clips"

-- 5. Retrieve render jobs
local jobs = project:GetRenderJobList()
if not jobs or #jobs == 0 then
    print("No render jobs in the queue.")
    return
end

-- 6. Initialize startTimes table and record start times for each job
local startTimes = {}
for _, jobInfo in ipairs(jobs) do
    local jobId = jobInfo["JobId"]
    startTimes[jobId] = os.time()
end

-- Start rendering all queued jobs
project:StartRendering()

-- 7. Monitor jobs and notify on completion
local notified = {}
while true do
    local stillRendering = project:IsRenderingInProgress()

    for _, jobInfo in ipairs(jobs) do
        local jobId = jobInfo["JobId"]
        if jobId and not notified[jobId] then
            local statusInfo = project:GetRenderJobStatus(jobId)
            if statusInfo then
                local state = statusInfo["JobStatus"]  -- "Complete", "Failed", or "Cancelled"
                if state == "Complete" or state == "Failed" or state == "Cancelled" then
                    -- Calculate duration
                    local elapsed = os.time() - (startTimes[jobId] or os.time())
                    local hh = math.floor(elapsed / 3600)
                    local mm = math.floor((elapsed % 3600) / 60)
                    local ss = elapsed % 60
                    local timeStr = string.format("%02d:%02d:%02d", hh, mm, ss)

                    -- Choose appropriate emoji
                    local emoji = (state == "Complete" and "✅")
                                or (state == "Cancelled" and "🛑")
                                or "❌"  -- for Failed

                    -- Human-readable status
                    local statusText = (state == "Complete" and "completed successfully")
                                     or (state == "Cancelled" and "cancelled")
                                     or "failed"

                    -- Compose and send
                    local message = string.format(
                        "📽️ Project '%s' render job %s %s. ⏱️ Time: %s. Mode: %s.",
                        projectName, emoji, statusText, timeStr, renderModeStr
                    )
                    sendiMessage(message)
                    print("Notified:", message)
                    notified[jobId] = true
                end
            end
        end
    end

    if not stillRendering then break end
    os.execute("sleep 1")
end

print("All render jobs processed; exiting.")
