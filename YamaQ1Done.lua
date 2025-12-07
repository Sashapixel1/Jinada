--========================================================
-- Auto Yama Quest 1 (Mythological Pirate → CDKQuest Evil)
--========================================================

---------------------
-- СЕРВИСЫ
---------------------
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local VirtualUser       = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local remote      = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

---------------------
-- ФЛАГИ / СОСТОЯНИЕ
---------------------
local AutoYamaQuest1 = false
local CurrentStatus  = "Idle"

local IsTeleporting  = false
local StopTween      = false
local NoclipEnabled  = false

local lastTrialTry       = 0      -- антиспам StartTrial Evil
local TrialTryCooldown   = 5      -- раз в 5 сек
local lastTPLog          = ""     -- чтобы не спамить одинаковыми логами

---------------------
-- НАСТРОЙКИ
---------------------
local TeleportSpeed   = 300
local StandOffset     = CFrame.new(0, 0, -2) -- как в 12к (сзади НПС)
local MythPirateName  = "Mythological Pirate"
local MythPirateIslandCFrame = CFrame.new(-13451.46484375, 543.712890625, -6961.0029296875)

---------------------
-- ЛОГИ / GUI
---------------------
local StatusLogs = {}
local MaxLogs    = 120

local ScreenGui, MainFrame
local StatusLabel
local ToggleButton
local LogsText

local function AddLog(msg)
    local timestamp = os.date("%H:%M:%S")
    local entry     = "[" .. timestamp .. "] " .. tostring(msg)
    table.insert(StatusLogs, 1, entry)
    if #StatusLogs > MaxLogs then
        table.remove(StatusLogs, #StatusLogs)
    end
    if LogsText then
        LogsText.Text = table.concat(StatusLogs, "\n")
    end
end

local function UpdateStatus(text)
    if text ~= CurrentStatus then
        CurrentStatus = text
        if StatusLabel then
            StatusLabel.Text = "Статус: " .. tostring(text)
        end
        AddLog("Статус: " .. tostring(text))
    else
        CurrentStatus = text
        if StatusLabel then
            StatusLabel.Text = "Статус: " .. tostring(text)
        end
    end
end

---------------------
-- ANTI AFK
---------------------
spawn(function()
    while task.wait(60) do
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

---------------------
-- NOCLIP
---------------------
spawn(function()
    while task.wait(0.1) do
        if NoclipEnabled then
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end)

---------------------
-- ТЕЛЕПОРТ
---------------------
local function SimpleTeleport(targetCFrame, label)
    if IsTeleporting then return end
    IsTeleporting = true
    StopTween     = false

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        IsTeleporting = false
        return
    end

    local hrp      = char.HumanoidRootPart
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local logMsg   = string.format("Телепорт к %s (%.0f stud)", label or "цели", distance)

    if logMsg ~= lastTPLog then
        AddLog(logMsg)
        lastTPLog = logMsg
    end

    local travelTime = distance / TeleportSpeed
    if travelTime < 0.5 then travelTime = 0.5 end
    if travelTime > 60  then travelTime = 60  end

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(travelTime, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame}
    )
    tween:Play()

    local start = tick()
    while tick() - start < travelTime do
        if StopTween then
            tween:Cancel()
            IsTeleporting = false
            AddLog("Телепорт прерван (StopTween).")
            return
        end

        local c = LocalPlayer.Character
        hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not c or not hrp then
            tween:Cancel()
            IsTeleporting = false
            return
        end

        hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
        hrp.CanCollide = false

        task.wait(0.2)
    end

    tween:Cancel()
    local c = LocalPlayer.Character
    hrp = c and c:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = targetCFrame
        hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
        hrp.CanCollide = false
    end

    IsTeleporting = false
end

LocalPlayer.CharacterAdded:Connect(function(char)
    IsTeleporting = false
    StopTween     = false
    AddLog("Персонаж возрождён, жду HRP...")
    char:WaitForChild("HumanoidRootPart", 10)
    AddLog("HRP найден, продолжаю Auto Yama Quest 1 (если включен).")
end)

---------------------
-- ПОИСК Mythological Pirate
---------------------
local function GetMythologicalPirate()
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return nil end

    for _, v in ipairs(enemiesFolder:GetChildren()) do
        if v.Name == MythPirateName
           and v:FindFirstChild("Humanoid")
           and v:FindFirstChild("HumanoidRootPart")
           and v.Humanoid.Health > 0 then
            return v
        end
    end

    return nil
end

---------------------
-- ЛОГИКА QUEST YAMA 1
---------------------
local function RunYamaQuest1()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hrp then
        UpdateStatus("Жду появления персонажа...")
        return
    end

    local pirate = GetMythologicalPirate()

    if pirate then
        UpdateStatus("Нашёл Mythological Pirate, подлетаю к нему.")
        local pHRP = pirate:FindFirstChild("HumanoidRootPart")
        if pHRP then
            -- подлетаем к НПС
            SimpleTeleport(pHRP.CFrame * StandOffset, MythPirateName)
            task.wait(0.5)

            -- остаёмся рядом, как в 12к (topos loop), но без жесткого цикла
            local dist = (pHRP.Position - hrp.Position).Magnitude
            if dist > 5 then
                hrp.CFrame = pHRP.CFrame * StandOffset
            end

            -- пробуем стартануть Evil trial (CDKQuest StartTrial Evil)
            local now = tick()
            if now - lastTrialTry >= TrialTryCooldown then
                lastTrialTry = now
                AddLog("Пробую запустить CDKQuest StartTrial 'Evil'.")
                pcall(function()
                    remote:InvokeServer("CDKQuest", "StartTrial", "Evil")
                end)
            end

            -- дальше квест уже сам переводит тебя в нужную фазу (статуя / скелеты и т.д.)
        end
    else
        UpdateStatus("Mythological Pirate не найден, лечу к острову квеста.")
        SimpleTeleport(MythPirateIslandCFrame, "Остров Mythological Pirate")
    end
end

---------------------
-- GUI
---------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoYamaQuest1Gui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 420, 0, 260)
    MainFrame.Position = UDim2.new(0, 40, 0, 200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 24)
    Title.BackgroundColor3 = Color3.fromRGB(30,30,30)
    Title.Text = "Auto Yama Quest 1 (Mythological Pirate / Evil Trial)"
    Title.TextColor3 = Color3.new(1,1,1)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 16
    Title.Parent = MainFrame

    StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -20, 0, 22)
    StatusLabel.Position = UDim2.new(0, 10, 0, 30)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.new(1,1,1)
    StatusLabel.Font = Enum.Font.SourceSans
    StatusLabel.TextSize = 14
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Text = "Статус: " .. CurrentStatus
    StatusLabel.Parent = MainFrame

    ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 200, 0, 32)
    ToggleButton.Position = UDim2.new(0, 10, 0, 60)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
    ToggleButton.TextColor3 = Color3.new(1,1,1)
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.TextSize = 16
    ToggleButton.Text = "Auto Yama Quest 1: OFF"
    ToggleButton.Parent = MainFrame

    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 150)
    LogsFrame.Position = UDim2.new(0, 10, 0, 100)
    LogsFrame.BackgroundColor3 = Color3.fromRGB(15,15,15)
    LogsFrame.BorderSizePixel = 0
    LogsFrame.Parent = MainFrame

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -4, 1, -4)
    scroll.Position = UDim2.new(0, 2, 0, 2)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new(0, 0, 4, 0)
    scroll.ScrollBarThickness = 4
    scroll.Parent = LogsFrame

    LogsText = Instance.new("TextLabel")
    LogsText.Size = UDim2.new(1, -4, 0, 20)
    LogsText.Position = UDim2.new(0, 0, 0, 0)
    LogsText.BackgroundTransparency = 1
    LogsText.TextColor3 = Color3.new(1,1,1)
    LogsText.Font = Enum.Font.Code
    LogsText.TextSize = 12
    LogsText.TextXAlignment = Enum.TextXAlignment.Left
    LogsText.TextYAlignment = Enum.TextYAlignment.Top
    LogsText.TextWrapped = false
    LogsText.Text = ""
    LogsText.Parent = scroll

    ToggleButton.MouseButton1Click:Connect(function()
        AutoYamaQuest1 = not AutoYamaQuest1
        if AutoYamaQuest1 then
            ToggleButton.Text = "Auto Yama Quest 1: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0,120,0)
            NoclipEnabled = true
            StopTween     = false
            UpdateStatus("Ищу Mythological Pirate / запускаю Evil Trial.")
            AddLog("Auto Yama Quest 1 включён.")
        else
            ToggleButton.Text = "Auto Yama Quest 1: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
            NoclipEnabled = false
            StopTween     = true
            UpdateStatus("Остановлен")
            AddLog("Auto Yama Quest 1 выключен.")
        end
    end)

    AddLog("GUI Auto Yama Quest 1 загружен.")
end

CreateGui()

---------------------
-- ОСНОВНОЙ ЦИКЛ
---------------------
spawn(function()
    while task.wait(0.5) do
        local ok, err = pcall(function()
            if AutoYamaQuest1 then
                RunYamaQuest1()
            end
        end)
        if not ok then
            AddLog("Ошибка в основном цикле: " .. tostring(err))
        end
    end
end)
