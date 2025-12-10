--========================================================
--  CFrame Tracker GUI
--  Показывает текущий CFrame персонажа и логирует его
--========================================================

---------------------
-- СЕРВИСЫ
---------------------
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")

local LocalPlayer  = Players.LocalPlayer

---------------------
-- ПЕРЕМЕННЫЕ GUI / ЛОГА
---------------------
local ScreenGui, MainFrame
local CurrentCFLabel
local LogsText

local Logs    = {}
local MaxLogs = 200

local function AddLog(line)
    table.insert(Logs, 1, line)
    if #Logs > MaxLogs then
        table.remove(Logs, #Logs)
    end
    if LogsText then
        LogsText.Text = table.concat(Logs, "\n")
    end
    print(line)
end

---------------------
-- СОЗДАНИЕ GUI
---------------------
local function CreateGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CFrameTrackerGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = pg

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 450, 0, 260)
    MainFrame.Position = UDim2.new(0, 30, 0, 120)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    title.Text = "CFrame Tracker"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.Parent = MainFrame

    CurrentCFLabel = Instance.new("TextLabel")
    CurrentCFLabel.Size = UDim2.new(1, -20, 0, 40)
    CurrentCFLabel.Position = UDim2.new(0, 10, 0, 30)
    CurrentCFLabel.BackgroundTransparency = 1
    CurrentCFLabel.TextColor3 = Color3.new(1, 1, 1)
    CurrentCFLabel.Font = Enum.Font.Code
    CurrentCFLabel.TextSize = 14
    CurrentCFLabel.TextXAlignment = Enum.TextXAlignment.Left
    CurrentCFLabel.TextYAlignment = Enum.TextYAlignment.Top
    CurrentCFLabel.TextWrapped = true
    CurrentCFLabel.Text = "CFrame: —"
    CurrentCFLabel.Parent = MainFrame

    local logsFrame = Instance.new("Frame")
    logsFrame.Size = UDim2.new(1, -20, 0, 170)
    logsFrame.Position = UDim2.new(0, 10, 0, 80)
    logsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    logsFrame.BorderSizePixel = 0
    logsFrame.Parent = MainFrame

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -4, 1, -4)
    scroll.Position = UDim2.new(0, 2, 0, 2)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new(0, 0, 5, 0)
    scroll.ScrollBarThickness = 4
    scroll.Parent = logsFrame

    LogsText = Instance.new("TextLabel")
    LogsText.Size = UDim2.new(1, -4, 0, 20)
    LogsText.Position = UDim2.new(0, 0, 0, 0)
    LogsText.BackgroundTransparency = 1
    LogsText.TextColor3 = Color3.new(1, 1, 1)
    LogsText.Font = Enum.Font.Code
    LogsText.TextSize = 12
    LogsText.TextXAlignment = Enum.TextXAlignment.Left
    LogsText.TextYAlignment = Enum.TextYAlignment.Top
    LogsText.TextWrapped = false
    LogsText.Text = ""
    LogsText.Parent = scroll

    AddLog("[CFrameTracker] GUI загружен.")
end

CreateGui()

---------------------
-- ОБНОВЛЕНИЕ CFrame
---------------------
local lastUpdate = 0

RunService.Heartbeat:Connect(function()
    -- Обновляем не на каждом тике, а раз ~0.2 секунды
    if tick() - lastUpdate < 0.2 then return end
    lastUpdate = tick()

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")

    if not (char and hrp) then
        if CurrentCFLabel then
            CurrentCFLabel.Text = "CFrame: персонаж не найден"
        end
        return
    end

    local cf = hrp.CFrame
    if CurrentCFLabel then
        CurrentCFLabel.Text = "CFrame:\n" .. tostring(cf)
    end

    -- Логируем только позицию, чтобы строка была короче
    local pos = cf.Position
    local ts  = os.date("%H:%M:%S")
    local line = string.format("[%s] (X=%.2f, Y=%.2f, Z=%.2f)", ts, pos.X, pos.Y, pos.Z)
    AddLog(line)
end)

---------------------
-- ВОССТАНОВЛЕНИЕ ПОСЛЕ СМЕРТИ
---------------------
LocalPlayer.CharacterAdded:Connect(function(char)
    AddLog("[CFrameTracker] Персонаж возрождён.")
    char:WaitForChild("HumanoidRootPart", 10)
end)
