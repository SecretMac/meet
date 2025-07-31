-- Prevent multiple executions
if _G.TrollScriptExecuted then
    warn("Troll script is already executed!")
    return
end
_G.TrollScriptExecuted = true

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local workspace = game:GetService("Workspace")

-- Wait for LocalPlayer to exist
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui")

-- Load packets with retry mechanism
local packets
local function loadPackets()
    local maxRetries = 5
    local retryDelay = 1
    for i = 1, maxRetries do
        local success, result = pcall(function()
            return require(ReplicatedStorage:WaitForChild("LocalModules", 10).Backend.Packets)
        end)
        if success then
            return result
        else
            warn("Failed to load packets (Attempt " .. i .. "/" .. maxRetries .. "): " .. tostring(result))
            task.wait(retryDelay)
        end
    end
    error("Failed to load packets after " .. maxRetries .. " attempts")
end
packets = loadPackets()

-- Wait 5 seconds after loading LocalPlayer and packets
task.wait(5)

-- Invisible Characters
local blob = "\u{000D}" -- newline
local blob2 = "\u{001E}" -- invisible character

-- Script URL for re-execution
local scriptUrl = "https://raw.githubusercontent.com/SecretMac/meet/refs/heads/main/auto.lua"

-- Queue teleport compatibility across executors
local queueTeleport = (syn and syn.queue_on_teleport) or
                     (fluxus and fluxus.queue_on_teleport) or
                     queue_on_teleport or
                     function() warn("queue_on_teleport not supported by this executor!") end

-- Chat Function
local function chatMessage(str)
    str = tostring(str)
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        TextChatService.TextChannels.RBXGeneral:SendAsync(str)
    else
        ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(str, "All")
    end
end

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TrollGui"
ScreenGui.Parent = playerGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 290)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -145)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(50, 50, 60)
UIStroke.Transparency = 0.5
UIStroke.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Server Troll Control"
TitleLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 22
TitleLabel.Parent = MainFrame

local PlayerCountLabel = Instance.new("TextLabel")
PlayerCountLabel.Size = UDim2.new(1, -20, 0, 30)
PlayerCountLabel.Position = UDim2.new(0, 10, 0, 40)
PlayerCountLabel.BackgroundTransparency = 1
PlayerCountLabel.Text = "Players: " .. #Players:GetPlayers()
PlayerCountLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
PlayerCountLabel.Font = Enum.Font.Gotham
PlayerCountLabel.TextSize = 18
PlayerCountLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerCountLabel.Parent = MainFrame

local TimerLabel = Instance.new("TextLabel")
TimerLabel.Size = UDim2.new(1, -20, 0, 30)
TimerLabel.Position = UDim2.new(0, 10, 0, 70)
TimerLabel.BackgroundTransparency = 1
TimerLabel.Text = "Server Hop: 60s"
TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
TimerLabel.Font = Enum.Font.Gotham
TimerLabel.TextSize = 18
TimerLabel.TextXAlignment = Enum.TextXAlignment.Left
TimerLabel.Parent = MainFrame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 100, 0, 40)
ToggleButton.Position = UDim2.new(0.25, -50, 0, 100)
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
ToggleButton.Text = "Troll: ON"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.Gotham
ToggleButton.TextSize = 18
ToggleButton.Parent = MainFrame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 10)
ButtonCorner.Parent = ToggleButton

local ButtonStroke = Instance.new("UIStroke")
ButtonStroke.Thickness = 1
ButtonStroke.Color = Color3.fromRGB(70, 70, 80)
ButtonStroke.Parent = ToggleButton

local TeleportButton = Instance.new("TextButton")
TeleportButton.Size = UDim2.new(0, 100, 0, 40)
TeleportButton.Position = UDim2.new(0.75, -50, 0, 100)
TeleportButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
TeleportButton.Text = "Teleport: ON"
TeleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TeleportButton.Font = Enum.Font.Gotham
TeleportButton.TextSize = 18
TeleportButton.Parent = MainFrame

local TeleportButtonCorner = Instance.new("UICorner")
TeleportButtonCorner.CornerRadius = UDim.new(0, 10)
TeleportButtonCorner.Parent = TeleportButton

local TeleportButtonStroke = Instance.new("UIStroke")
TeleportButtonStroke.Thickness = 1
TeleportButtonStroke.Color = Color3.fromRGB(70, 70, 80)
TeleportButtonStroke.Parent = TeleportButton

local ChatButton = Instance.new("TextButton")
ChatButton.Size = UDim2.new(0, 100, 0, 40)
ChatButton.Position = UDim2.new(0.5, -50, 0, 150)
ChatButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
ChatButton.Text = "Chat: OFF"
ChatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ChatButton.Font = Enum.Font.Gotham
ChatButton.TextSize = 18
ChatButton.Parent = MainFrame

local ChatButtonCorner = Instance.new("UICorner")
ChatButtonCorner.CornerRadius = UDim.new(0, 10)
ChatButtonCorner.Parent = ChatButton

local ChatButtonStroke = Instance.new("UIStroke")
ChatButtonStroke.Thickness = 1
ChatButtonStroke.Color = Color3.fromRGB(70, 70, 80)
ChatButtonStroke.Parent = ChatButton

local MessageButton = Instance.new("TextButton")
MessageButton.Size = UDim2.new(0, 100, 0, 40)
MessageButton.Position = UDim2.new(0.5, -50, 0, 200)
MessageButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
MessageButton.Text = "Send Msg"
MessageButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MessageButton.Font = Enum.Font.Gotham
MessageButton.TextSize = 18
MessageButton.Parent = MainFrame

local MessageButtonCorner = Instance.new("UICorner")
MessageButtonCorner.CornerRadius = UDim.new(0, 10)
MessageButtonCorner.Parent = MessageButton

local MessageButtonStroke = Instance.new("UIStroke")
MessageButtonStroke.Thickness = 1
MessageButtonStroke.Color = Color3.fromRGB(70, 70, 80)
MessageButtonStroke.Parent = MessageButton

local InputFrame = Instance.new("Frame")
InputFrame.Size = UDim2.new(0, 200, 0, 100)
InputFrame.Position = UDim2.new(0.5, -100, 0, 240)
InputFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
InputFrame.BorderSizePixel = 0
InputFrame.Parent = MainFrame
InputFrame.Visible = false

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 8)
InputCorner.Parent = InputFrame

local InputStroke = Instance.new("UIStroke")
InputStroke.Thickness = 1
InputStroke.Color = Color3.fromRGB(50, 50, 60)
InputStroke.Parent = InputFrame

local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(1, -20, 0, 30)
InputBox.Position = UDim2.new(0, 10, 0, 10)
InputBox.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputBox.Font = Enum.Font.Gotham
InputBox.TextSize = 16
InputBox.PlaceholderText = "Enter server message..."
InputBox.Text = ""
InputBox.Parent = InputFrame

local InputBoxCorner = Instance.new("UICorner")
InputBoxCorner.CornerRadius = UDim.new(0, 6)
InputBoxCorner.Parent = InputBox

local SendButton = Instance.new("TextButton")
SendButton.Size = UDim2.new(0, 80, 0, 30)
SendButton.Position = UDim2.new(0.5, -40, 0, 50)
SendButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
SendButton.Text = "Send"
SendButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SendButton.Font = Enum.Font.Gotham
SendButton.TextSize = 16
SendButton.Parent = InputFrame

local SendButtonCorner = Instance.new("UICorner")
SendButtonCorner.CornerRadius = UDim.new(0, 6)
SendButtonCorner.Parent = SendButton

-- Notification System
local NotificationContainer = Instance.new("Frame")
NotificationContainer.Size = UDim2.new(0, 200, 0, 300)
NotificationContainer.Position = UDim2.new(1, -210, 1, -310)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.Parent = ScreenGui

local NotificationLayout = Instance.new("UIListLayout")
NotificationLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotificationLayout.Padding = UDim.new(0, 5)
NotificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotificationLayout.Parent = NotificationContainer

local function createNotification(text, color)
    local NotificationFrame = Instance.new("Frame")
    NotificationFrame.Size = UDim2.new(0, 200, 0, 50)
    NotificationFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    NotificationFrame.BackgroundTransparency = 0.2
    NotificationFrame.BorderSizePixel = 0
    NotificationFrame.Parent = NotificationContainer
    NotificationFrame.LayoutOrder = -tick()

    local NotificationCorner = Instance.new("UICorner")
    NotificationCorner.CornerRadius = UDim.new(0, 8)
    NotificationCorner.Parent = NotificationFrame

    local NotificationStroke = Instance.new("UIStroke")
    NotificationStroke.Thickness = 1
    NotificationStroke.Color = Color3.fromRGB(50, 50, 60)
    NotificationStroke.Transparency = 0.5
    NotificationStroke.Parent = NotificationFrame

    local NotificationText = Instance.new("TextLabel")
    NotificationText.Size = UDim2.new(1, -10, 1, -10)
    NotificationText.Position = UDim2.new(0, 5, 0, 5)
    NotificationText.BackgroundTransparency = 1
    NotificationText.Text = text
    NotificationText.TextColor3 = color
    NotificationText.Font = Enum.Font.Gotham
    NotificationText.TextSize = 16
    NotificationText.TextWrapped = true
    NotificationText.TextXAlignment = Enum.TextXAlignment.Left
    NotificationText.Parent = NotificationFrame

    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(NotificationFrame, tweenInfo, {BackgroundTransparency = 0}):Play()
    task.spawn(function()
        task.wait(3)
        TweenService:Create(NotificationFrame, tweenInfo, {BackgroundTransparency = 0.8}):Play()
        task.wait(0.3)
        NotificationFrame:Destroy()
    end)
end

-- Dragging Functionality
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(
        startPos.X.Scale, startPos.X.Offset + delta.X,
        startPos.Y.Scale, startPos.Y.Offset + delta.Y
    )
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Message Input Logic
MessageButton.MouseButton1Click:Connect(function()
    InputFrame.Visible = not InputFrame.Visible
    if InputFrame.Visible then
        InputBox.Text = ""
        InputBox:CaptureFocus()
    end
end)

SendButton.MouseButton1Click:Connect(function()
    local message = InputBox.Text
    if message ~= "" then
        chatMessage(blob2 .. string.rep(blob, 100) .. "[Server]: " .. message)
        InputFrame.Visible = false
    end
end)

-- Anti-Lag System
local function removeJacketAccessories()
    while true do
        for _, plr in pairs(Players:GetPlayers()) do
            local character = workspace:FindFirstChild(plr.Name)
            if character then
                local accessories = {}
                for _, item in pairs(character:GetChildren()) do
                    if item:IsA("Accessory") and item.Name == "Accessory" and item.AccessoryType == Enum.AccessoryType.Jacket then
                        table.insert(accessories, item)
                    end
                end
                for _, item in pairs(accessories) do
                    item:Destroy()
                    createNotification("Destroyed Jacket Accessory on " .. plr.Name, Color3.fromRGB(255, 165, 0))
                end
            end
        end
        task.wait(0.1)
    end
end

task.spawn(removeJacketAccessories)

-- Fly and Noclip System
local noclipConnection
local bodyVelocity
local function setFlyAndNoclip(enabled)
    if enabled then
        local character = player.Character
        if character and character.Parent then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                bodyVelocity.Parent = rootPart
            end
            noclipConnection = RunService.Stepped:Connect(function()
                if character and character.Parent then
                    for _, part in pairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    elseif noclipConnection or bodyVelocity then
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        if bodyVelocity then
            bodyVelocity:Destroy()
            bodyVelocity = nil
        end
        local character = player.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- Teleport System
local currentPlayers = {}
local function updateCurrentPlayers()
    currentPlayers = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            table.insert(currentPlayers, plr)
        end
    end
    PlayerCountLabel.Text = "Players: " .. #Players:GetPlayers()
end

Players.PlayerAdded:Connect(function(plr)
    updateCurrentPlayers()
    createNotification(plr.Name .. " joined", Color3.fromRGB(100, 255, 100))
end)

Players.PlayerRemoving:Connect(function(plr)
    updateCurrentPlayers()
    createNotification(plr.Name .. " left", Color3.fromRGB(255, 100, 100))
end)

local teleportActive = true
local function getNearestPlayer()
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end

    local nearestPlayer = nil
    local minDistance = math.huge
    for _, plr in pairs(currentPlayers) do
        local targetCharacter = workspace:FindFirstChild(plr.Name)
        local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            local distance = (rootPart.Position - targetRoot.Position).Magnitude
            if distance < minDistance then
                minDistance = distance
                nearestPlayer = plr
            end
        end
    end
    return nearestPlayer
end

local function teleportLoop()
    while teleportActive do
        local character = player.Character
        if character and character.Parent then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local nearestPlayer = getNearestPlayer()
                if nearestPlayer then
                    local targetCharacter = workspace:FindFirstChild(nearestPlayer.Name)
                    local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
                    if targetRoot then
                        rootPart.CFrame = CFrame.new(targetRoot.Position.X, targetRoot.Position.Y - 10, targetRoot.Position.Z)
                    end
                end
            end
        end
        task.wait(0.1)
    end
end

task.spawn(teleportLoop)
setFlyAndNoclip(true)

-- Troll Logic
local trollActive = true
local chatActive = false
local seriousMessages = {
    "[Server]: Mining Crypto, The longer you stay the richer i get.",
    "[Server]: Your device is forced to mine crypto.",
    "[Server]: Your device is going to explode. Leave now",
    "[Server]: Using all resources to harm your device",
    "[Server]: Your device is controlled for crypto mining."
}

local function copyAvatar()
    local success, userId = pcall(function()
        return Players:GetUserIdFromNameAsync("0w5")
    end)
    if success and userId then
        packets.CopyUser:Fire(userId)
        local outfitGui = playerGui:FindFirstChild("Outfit")
        if outfitGui then
            outfitGui.Enabled = (userId ~= player.UserId)
        end
    else
        warn("Failed to copy avatar for username: 0w5")
    end
end

local function toolLoop()
    while trollActive do
        local backpack = player.Backpack
        local character = player.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        if humanoid and backpack then
            for _, tool in pairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    humanoid:EquipTool(tool)
                    task.wait()
                end
            end
            humanoid:UnequipTools()
            task.wait()
        else
            task.wait(0.1)
        end
    end
end

task.spawn(toolLoop)
copyAvatar()

-- Timer Logic
local timeRemaining = 60
local function startTimer(initialTime, onComplete)
    timeRemaining = initialTime or 60
    TimerLabel.Text = "Server Hop: " .. math.ceil(timeRemaining) .. "s"
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        timeRemaining = timeRemaining - RunService.Heartbeat:Wait()
        if timeRemaining <= 0 then
            connection:Disconnect()
            TimerLabel.Text = "Server Hop: Now"
            if onComplete then
                onComplete()
            end
        else
            TimerLabel.Text = "Server Hop: " .. math.ceil(timeRemaining) .. "s"
        end
    end)
    
    return connection
end

-- Server Hop Function
local function serverHop()
    local retryDelay = 3
    local attempt = 1
    local timerConnection

    local function attemptHop()
        local originalJobId = game.JobId
        createNotification("Fetching servers (Attempt " .. attempt .. ")...", Color3.fromRGB(255, 165, 0))
        local servers = {}
        local success, response = pcall(function()
            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        end)
        if success and response then
            for _, v in pairs(response.data) do
                if v.playing < v.maxPlayers and v.id ~= game.JobId then
                    table.insert(servers, v.id)
                end
            end
        else
            createNotification("Failed to fetch servers. Retrying in " .. retryDelay .. "s...", Color3.fromRGB(255, 100, 100))
            if timerConnection then timerConnection:Disconnect() end
            timerConnection = startTimer(retryDelay, attemptHop)
            attempt = attempt + 1
            return
        end

        if #servers > 0 then
            local randomServer = servers[math.random(1, #servers)]
            createNotification("Attempting to join server " .. randomServer .. "...", Color3.fromRGB(255, 165, 0))
            
            -- Queue the script for re-execution
            local queueSuccess, queueError = pcall(function()
                queueTeleport([[
                    loadstring(game:HttpGet("]] .. scriptUrl .. [["))()
                ]])
            end)
            if queueSuccess then
                createNotification("Script queued for re-execution!", Color3.fromRGB(100, 255, 100))
            else
                createNotification("Failed to queue script: " .. tostring(queueError), Color3.fromRGB(255, 100, 100))
                warn("Queue teleport failed: " .. tostring(queueError))
            end

            -- Attempt teleport
            local success, result = pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, player)
            end)
            if not success then
                createNotification("Teleport failed: " .. tostring(result) .. ". Retrying in " .. retryDelay .. "s...", Color3.fromRGB(255, 100, 100))
                if timerConnection then timerConnection:Disconnect() end
                timerConnection = startTimer(retryDelay, attemptHop)
                attempt = attempt + 1
            else
                -- Wait to check if teleport was successful
                task.wait(3)
                if game.JobId == originalJobId then
                    createNotification("Still in same server. Retrying in " .. retryDelay .. "s...", Color3.fromRGB(255, 100, 100))
                    if timerConnection then timerConnection:Disconnect() end
                    timerConnection = startTimer(retryDelay, attemptHop)
                    attempt = attempt + 1
                else
                    createNotification("Successfully joined new server!", Color3.fromRGB(100, 255, 100))
                    if timerConnection then timerConnection:Disconnect() end
                    TimerLabel.Text = "Server Hop: Success"
                end
            end
        else
            createNotification("No available servers. Retrying in " .. retryDelay .. "s...", Color3.fromRGB(255, 100, 100))
            if timerConnection then timerConnection:Disconnect() end
            timerConnection = startTimer(retryDelay, attemptHop)
            attempt = attempt + 1
        end
    end

    attemptHop()
end

-- Start initial server hop with timer
startTimer(60, serverHop)

-- Ensure script is queued on teleport
player.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Started then
        local success, err = pcall(function()
            queueTeleport([[
                loadstring(game:HttpGet("]] .. scriptUrl .. [["))()
            ]])
        end)
        if success then
            createNotification("Script queued for teleport!", Color3.fromRGB(100, 255, 100))
        else
            warn("Teleport queue failed: " .. tostring(err))
            createNotification("Failed to queue script for teleport: " .. tostring(err), Color3.fromRGB(255, 100, 100))
        end
    end
end)

-- Button Connections
ToggleButton.MouseButton1Click:Connect(function()
    trollActive = not trollActive
    if trollActive then
        updateCurrentPlayers()
        copyAvatar()
        task.spawn(toolLoop)
        if chatActive then
            local randomMessage = seriousMessages[math.random(1, #seriousMessages)]
            chatMessage(blob2 .. string.rep(blob, 100) .. randomMessage)
        end
        ToggleButton.Text = "Troll: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    else
        ToggleButton.Text = "Troll: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end
end)

TeleportButton.MouseButton1Click:Connect(function()
    teleportActive = not teleportActive
    if teleportActive then
        updateCurrentPlayers()
        task.spawn(teleportLoop)
        setFlyAndNoclip(true)
        TeleportButton.Text = "Teleport: ON"
        TeleportButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    else
        setFlyAndNoclip(false)
        TeleportButton.Text = "Teleport: OFF"
        TeleportButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    end
end)

ChatButton.MouseButton1Click:Connect(function()
    chatActive = not chatActive
    if chatActive then
        ChatButton.Text = "Chat: ON"
        ChatButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    else
        ChatButton.Text = "Chat: OFF"
        ChatButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    end
end)

-- Initial Player List Update
updateCurrentPlayers()
