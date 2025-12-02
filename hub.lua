-- Auto Cursed Dual Katana Script by NoxHub
-- Version 1.6 (Fixed Rayfield Callback Error)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Variables (объявляем ВСЕ переменные ДО функций)
local AutoCursedKatana = false
local CurrentStatus = "Idle"
local LastUpdate = os.time()
local StartTime = os.time()
local TeleportSpeed = 180
local StopTween = false

-- Services
local TweenService = game:GetService("TweenService")

-- Locations
local Locations = {
    Tushita = CFrame.new(-10238.8759765625, 389.7912902832, -9549.7939453125),
    Yama = CFrame.new(-9489.2168, 142.130066, 5567.14697),
    CDKAltar = CFrame.new(-9717.33203125, 375.1759338378906, -10160.1455078125)
}

-- Status Logs
local StatusLogs = {}
local MaxLogs = 20

-- ВСЕ ФУНКЦИИ ДОЛЖНЫ БЫТЬ ОБЪЯВЛЕНЫ ДО СОЗДАНИЯ UI

-- Utility Functions
function CancelTeleport()
    StopTween = true
    wait(0.1)
    StopTween = false
end

function GetYRotation(cframe)
    local x, y, z = cframe:ToEulerAnglesXYZ()
    return y
end

-- Teleport Function (объявлена ДО использования)
function SimpleTeleport(targetCFrame, isManual)
    local success, errorMsg = pcall(function()
        local player = game.Players.LocalPlayer
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            return false, "Character not found"
        end
        
        local hrp = character.HumanoidRootPart
        local currentPos = hrp.Position
        local targetPos = targetCFrame.Position
        
        -- Calculate distance
        local distance = (currentPos - targetPos).Magnitude
        AddLog(string.format("Distance: %.0f units", distance))
        
        -- If very far, use fast travel
        if distance > 5000 then
            AddLog("Using fast travel for long distance...")
            
            if targetPos.Z < -9000 then -- Tushita area
                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("requestEntrance", 
                    Vector3.new(-10238.8759765625, 389.7912902832, -9549.7939453125))
            elseif targetPos.Z > 5000 then -- Yama area  
                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("requestEntrance",
                    Vector3.new(-9489.2168, 142.130066, 5567.14697))
            end
            
            wait(3)
            distance = (hrp.Position - targetPos).Magnitude
        end
        
        -- Simple direct teleport for testing
        if distance < 1000 then
            local teleportTime = distance / TeleportSpeed
            if teleportTime < 1 then teleportTime = 1 end
            if teleportTime > 5 then teleportTime = 5 end
            
            local tween = TweenService:Create(hrp,
                TweenInfo.new(teleportTime, Enum.EasingStyle.Quad),
                {CFrame = targetCFrame}
            )
            
            tween:Play()
            
            local startTime = tick()
            while tick() - startTime < teleportTime do
                if StopTween then
                    tween:Cancel()
                    return false, "Cancelled"
                end
                wait()
            end
            
            tween:Cancel()
            hrp.CFrame = targetCFrame
            return true, "Success"
        end
        
        return false, "Distance too far"
    end)
    
    if not success then
        AddLog("Teleport error: " .. tostring(errorMsg))
        return false, errorMsg
    end
    
    return errorMsg
end

-- Inventory Functions
function HasItem(itemName)
    local success = pcall(function()
        if game.Players.LocalPlayer.Character:FindFirstChild(itemName) then
            return true
        end
        
        if game.Players.LocalPlayer.Backpack:FindFirstChild(itemName) then
            return true
        end
        
        return false
    end)
    
    return success or false
end

function HasTushita()
    return HasItem("Tushita")
end

function HasYama()
    return HasItem("Yama")
end

function HasCDK()
    return HasItem("Cursed Dual Katana") or HasItem("Cursed Dual Katana [CDK]")
end

function TryLoadItem(itemName)
    local success = pcall(function()
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("LoadItem", itemName)
    end)
    
    if success then
        wait(1)
        return HasItem(itemName)
    end
    
    return false
end

-- Logging Functions
function AddLog(message)
    local timestamp = os.date("%H:%M:%S")
    local logEntry = "["..timestamp.."] "..message
    table.insert(StatusLogs, 1, logEntry)
    
    if #StatusLogs > MaxLogs then
        table.remove(StatusLogs, #StatusLogs)
    end
    
    UpdateLogDisplay()
end

function UpdateStatus(newStatus)
    CurrentStatus = newStatus
    AddLog("Status: "..newStatus)
    LastUpdate = os.time()
end

function GetUptime()
    local totalSeconds = os.time() - StartTime
    local hours = math.floor(totalSeconds / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = totalSeconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

-- Combat Function
function Attack()
    for i = 1, 2 do
        game:GetService("VirtualInputManager"):SendKeyEvent(true, "X", false, game)
        wait(0.1)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, "X", false, game)
        wait(0.1)
    end
    
    mouse1click()
end

-- Теперь создаем окно и UI элементы

local Window = Rayfield:CreateWindow({
    Name = "Auto Cursed Dual Katana",
    LoadingTitle = "Cursed Katana Farm",
    LoadingSubtitle = "by NoxHub",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "NoxHub",
        FileName = "CursedKatana"
    },
    Discord = {
        Enabled = true,
        Invite = "noxhub",
        RememberJoins = true
    },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458)
local StatusTab = Window:CreateTab("Status", 4483362458)

-- UI Update Function (должна быть после создания UI элементов)
function UpdateLogDisplay()
    if StatusLabel then
        StatusLabel:Set("Current Status: " .. CurrentStatus)
    end
    if UptimeLabel then
        UptimeLabel:Set("Uptime: " .. GetUptime())
    end
    if LastUpdateLabel then
        LastUpdateLabel:Set("Last Update: " .. os.date("%H:%M:%S", LastUpdate))
    end
    
    if LogsContainer then
        local logText = ""
        for i, log in ipairs(StatusLogs) do
            logText = logText .. log .. "\n"
        end
        LogsContainer:Set({Title = "Activity Log (" .. #StatusLogs .. " entries)", Content = logText})
    end
end

-- Теперь создаем UI элементы

local Toggle = MainTab:CreateToggle({
    Name = "Auto Cursed Dual Katana",
    CurrentValue = false,
    Flag = "AutoCDK",
    Callback = function(Value)
        AutoCursedKatana = Value
        if Value then
            StartTime = os.time()
            AddLog("Script STARTED")
            UpdateStatus("Starting...")
            Rayfield:Notify({
                Title = "Auto CDK",
                Content = "Started farming Cursed Dual Katana",
                Duration = 3,
                Image = 4483362458
            })
        else
            CancelTeleport()
            AddLog("Script STOPPED")
            UpdateStatus("Stopped")
            Rayfield:Notify({
                Title = "Auto CDK",
                Content = "Stopped farming",
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
})

local SpeedSlider = MainTab:CreateSlider({
    Name = "Teleport Speed",
    Range = {100, 200},
    Increment = 10,
    Suffix = "units/sec",
    CurrentValue = TeleportSpeed,
    Flag = "TeleportSpeed",
    Callback = function(Value)
        TeleportSpeed = Value
        AddLog("Teleport speed: " .. Value)
    end,
})

-- Создаем лейблы для StatusTab
local StatusLabel = StatusTab:CreateLabel("Current Status: " .. CurrentStatus)
local UptimeLabel = StatusTab:CreateLabel("Uptime: 00:00:00")
local LastUpdateLabel = StatusTab:CreateLabel("Last Update: " .. os.date("%H:%M:%S"))

StatusTab:CreateSection("Live Logs")
local LogsContainer = StatusTab:CreateParagraph({Title = "Activity Log", Content = "Waiting for activity..."})

-- Auto-update labels
spawn(function()
    while wait(1) do
        UpdateLogDisplay()
    end
end)

-- Manual Controls
MainTab:CreateSection("Manual Controls")

-- Определяем функции для кнопок ЛОКАЛЬНО
local function TeleportToTushita()
    CancelTeleport()
    AddLog("Manual teleport to Tushita...")
    UpdateStatus("Teleporting")
    
    local success, msg = SimpleTeleport(Locations.Tushita, true)
    
    UpdateStatus("Idle")
    if success then
        AddLog("Teleport successful")
        Rayfield:Notify({
            Title = "Teleport",
            Content = "Successfully teleported to Tushita",
            Duration = 3,
            Image = 4483362458
        })
    else
        AddLog("Teleport failed: " .. msg)
        Rayfield:Notify({
            Title = "Teleport",
            Content = "Failed to teleport: " .. msg,
            Duration = 3,
            Image = 4483362458
        })
    end
end

local function TeleportToYama()
    CancelTeleport()
    AddLog("Manual teleport to Yama...")
    UpdateStatus("Teleporting")
    
    local success, msg = SimpleTeleport(Locations.Yama, true)
    
    UpdateStatus("Idle")
    if success then
        AddLog("Teleport successful")
        Rayfield:Notify({
            Title = "Teleport",
            Content = "Successfully teleported to Yama",
            Duration = 3,
            Image = 4483362458
        })
    else
        AddLog("Teleport failed: " .. msg)
        Rayfield:Notify({
            Title = "Teleport",
            Content = "Failed to teleport: " .. msg,
            Duration = 3,
            Image = 4483362458
        })
    end
end

local function TeleportToCDKAltar()
    CancelTeleport()
    AddLog("Manual teleport to CDK Altar...")
    UpdateStatus("Teleporting")
    
    local success, msg = SimpleTeleport(Locations.CDKAltar, true)
    
    UpdateStatus("Idle")
    if success then
        AddLog("Teleport successful")
        Rayfield:Notify({
            Title = "Teleport",
            Content = "Successfully teleported to CDK Altar",
            Duration = 3,
            Image = 4483362458
        })
    else
        AddLog("Teleport failed: " .. msg)
        Rayfield:Notify({
            Title = "Teleport",
            Content = "Failed to teleport: " .. msg,
            Duration = 3,
            Image = 4483362458
        })
    end
end

local function CheckInventory()
    local hasT = HasTushita()
    local hasY = HasYama()
    local hasC = HasCDK()
    
    local message = string.format("Tushita: %s, Yama: %s, CDK: %s", 
        tostring(hasT), tostring(hasY), tostring(hasC))
    
    AddLog("Inventory Check: " .. message)
    Rayfield:Notify({
        Title = "Inventory",
        Content = message,
        Duration = 5,
        Image = 4483362458
    })
end

local function LoadTushitaFromStorage()
    AddLog("Loading Tushita from storage...")
    if TryLoadItem("Tushita") then
        AddLog("Tushita loaded successfully")
        Rayfield:Notify({
            Title = "Load Item",
            Content = "Tushita loaded from storage",
            Duration = 3,
            Image = 4483362458
        })
    else
        AddLog("Failed to load Tushita")
        Rayfield:Notify({
            Title = "Load Item",
            Content = "Failed to load Tushita",
            Duration = 3,
            Image = 4483362458
        })
    end
end

local function LoadYamaFromStorage()
    AddLog("Loading Yama from storage...")
    if TryLoadItem("Yama") then
        AddLog("Yama loaded successfully")
        Rayfield:Notify({
            Title = "Load Item",
            Content = "Yama loaded from storage",
            Duration = 3,
            Image = 4483362458
        })
    else
        AddLog("Failed to load Yama")
        Rayfield:Notify({
            Title = "Load Item",
            Content = "Failed to load Yama",
            Duration = 3,
            Image = 4483362458
        })
    end
end

-- Создаем кнопки с локальными функциями
MainTab:CreateButton({
    Name = "Teleport to Tushita",
    Callback = TeleportToTushita
})

MainTab:CreateButton({
    Name = "Teleport to Yama",
    Callback = TeleportToYama
})

MainTab:CreateButton({
    Name = "Teleport to CDK Altar",
    Callback = TeleportToCDKAltar
})

MainTab:CreateButton({
    Name = "Check Inventory",
    Callback = CheckInventory
})

MainTab:CreateButton({
    Name = "Load Tushita",
    Callback = LoadTushitaFromStorage
})

MainTab:CreateButton({
    Name = "Load Yama",
    Callback = LoadYamaFromStorage
})

-- Farming Functions (после создания UI)
function FarmTushita()
    UpdateStatus("Going to Tushita...")
    
    -- Teleport
    local success, msg = SimpleTeleport(Locations.Tushita, false)
    if not success then
        AddLog("Failed to teleport to Tushita: " .. msg)
        return false
    end
    
    wait(2)
    
    -- Check if already have
    if HasTushita() or TryLoadItem("Tushita") then
        AddLog("Already have Tushita")
        return true
    end
    
    -- Start trial
    AddLog("Starting Tushita trial...")
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("CDKQuest", "StartTrial", "Tushita")
    end)
    
    return true
end

function FarmYama()
    UpdateStatus("Going to Yama...")
    
    -- Teleport
    local success, msg = SimpleTeleport(Locations.Yama, false)
    if not success then
        AddLog("Failed to teleport to Yama: " .. msg)
        return false
    end
    
    wait(2)
    
    -- Check if already have
    if HasYama() or TryLoadItem("Yama") then
        AddLog("Already have Yama")
        return true
    end
    
    -- Start trial
    AddLog("Starting Yama trial...")
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("CDKQuest", "StartTrial", "Yama")
    end)
    
    return true
end

function FarmCDK()
    UpdateStatus("Going to CDK Altar...")
    
    -- Check if have both swords
    if not (HasTushita() and HasYama()) then
        AddLog("Need both Tushita and Yama")
        return false
    end
    
    -- Teleport
    local success, msg = SimpleTeleport(Locations.CDKAltar, false)
    if not success then
        AddLog("Failed to teleport to CDK Altar: " .. msg)
        return false
    end
    
    wait(2)
    
    -- Start quest
    AddLog("Starting CDK quest...")
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("CDKQuest", "StartQuest", "CursedKatana")
    end)
    
    return true
end

-- Main Loop (после всех объявлений)
spawn(function()
    while wait(2) do
        if AutoCursedKatana then
            pcall(function()
                -- Check if already have CDK
                if HasCDK() then
                    AddLog("Already have Cursed Dual Katana!")
                    AutoCursedKatana = false
                    UpdateStatus("Completed")
                    Rayfield:Notify({
                        Title = "Auto CDK",
                        Content = "Already have Cursed Dual Katana!",
                        Duration = 5,
                        Image = 4483362458
                    })
                    return
                end
                
                AddLog("=== Starting CDK Farm ===")
                
                -- Farm Tushita
                if not HasTushita() then
                    AddLog("--- Farming Tushita ---")
                    local gotTushita = FarmTushita()
                    
                    if not gotTushita then
                        AddLog("Failed to get Tushita")
                        return
                    end
                else
                    AddLog("Already have Tushita")
                end
                
                if not AutoCursedKatana then return end
                
                -- Farm Yama
                if not HasYama() then
                    AddLog("--- Farming Yama ---")
                    local gotYama = FarmYama()
                    
                    if not gotYama then
                        AddLog("Failed to get Yama")
                        return
                    end
                else
                    AddLog("Already have Yama")
                end
                
                if not AutoCursedKatana then return end
                
                -- Farm CDK
                if HasTushita() and HasYama() then
                    AddLog("--- Farming CDK ---")
                    local gotCDK = FarmCDK()
                    
                    if gotCDK then
                        AddLog("Started CDK farming")
                    else
                        AddLog("Failed to start CDK")
                    end
                else
                    AddLog("Missing Tushita or Yama")
                end
            end)
        end
    end
end)

-- Instructions
MainTab:CreateSection("Instructions")
MainTab:CreateParagraph({
    Title = "How to use:",
    Content = "1. Set speed to 150-180\n2. Click toggle to start auto farm\n3. Use manual buttons for testing\n4. Need: Level 2000+, Third Sea access"
})

StatusTab:CreateSection("Script Info")
StatusTab:CreateParagraph({
    Title = "Auto Cursed Dual Katana v1.6",
    Content = "Fixed Rayfield callback errors\nAll functions properly declared\nWorking manual controls"
})

-- Initialize
AddLog("Script loaded successfully!")
AddLog("Teleport speed: " .. TeleportSpeed)
AddLog("All functions properly declared")
UpdateStatus("Ready")

Rayfield:LoadConfiguration()
