--========================================================
--  Yama / Tushita Mastery Checker (getInventory.Mastery)
--  автообновление каждые 10 секунд
--========================================================

local UPDATE_INTERVAL = 10 -- сек между обновлениями

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

----------------------------------------------------------
-- GUI
----------------------------------------------------------
do
    local old = (LocalPlayer.PlayerGui:FindFirstChild("YT_MasteryGui")
        or (game.CoreGui and game.CoreGui:FindFirstChild("YT_MasteryGui")))
    if old then old:Destroy() end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "YT_MasteryGui"

local okProtect = pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = game.CoreGui
    elseif gethui then
        screenGui.Parent = gethui()
    else
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end)
if not okProtect then
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 260, 0, 120)
frame.Position = UDim2.new(0, 20, 0, 200)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Thickness = 1
stroke.Transparency = 0.25
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -10, 0, 24)
title.Position = UDim2.new(0, 5, 0, 4)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Yama / Tushita Mastery"
title.Parent = frame

local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, -10, 0, 1)
sep.Position = UDim2.new(0, 5, 0, 30)
sep.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
sep.BorderSizePixel = 0
sep.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 18)
statusLabel.Position = UDim2.new(0, 5, 0, 32)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 13
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Text = "Статус: ON (интервал 10с)"
statusLabel.Parent = frame

local yamaLabel = Instance.new("TextLabel")
yamaLabel.Name = "YamaLabel"
yamaLabel.Size = UDim2.new(1, -10, 0, 22)
yamaLabel.Position = UDim2.new(0, 5, 0, 54)
yamaLabel.BackgroundTransparency = 1
yamaLabel.Font = Enum.Font.Gotham
yamaLabel.TextSize = 14
yamaLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
yamaLabel.TextXAlignment = Enum.TextXAlignment.Left
yamaLabel.Text = "Yama Mastery: —"
yamaLabel.Parent = frame

local tushitaLabel = Instance.new("TextLabel")
tushitaLabel.Name = "TushitaLabel"
tushitaLabel.Size = UDim2.new(1, -10, 0, 22)
tushitaLabel.Position = UDim2.new(0, 5, 0, 76)
tushitaLabel.BackgroundTransparency = 1
tushitaLabel.Font = Enum.Font.Gotham
tushitaLabel.TextSize = 14
tushitaLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
tushitaLabel.TextXAlignment = Enum.TextXAlignment.Left
tushitaLabel.Text = "Tushita Mastery: —"
tushitaLabel.Parent = frame

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 70, 0, 24)
toggleButton.Position = UDim2.new(1, -75, 0, 4)
toggleButton.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 13
toggleButton.Text = "ON"
toggleButton.AutoButtonColor = true
toggleButton.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = toggleButton

local enabled = true

local function refreshToggleVisual()
    if enabled then
        toggleButton.Text = "ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
        statusLabel.Text = ("Статус: ON (интервал %ds)"):format(UPDATE_INTERVAL)
        statusLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
    else
        toggleButton.Text = "OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
        statusLabel.Text = "Статус: OFF"
        statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end
refreshToggleVisual()

toggleButton.MouseButton1Click:Connect(function()
    enabled = not enabled
    refreshToggleVisual()
end)

----------------------------------------------------------
-- Функция получения мастери из getInventory
----------------------------------------------------------
local function getMasteryFromInventory()
    local yamaM, tushitaM

    local ok, inv = pcall(function()
        return CommF:InvokeServer("getInventory")
    end)

    if not ok or not inv then
        return nil, nil
    end

    for _, item in pairs(inv) do
        if item and item.Type == "Sword" then
            if item.Name == "Yama" then
                yamaM = item.Mastery
            elseif item.Name == "Tushita" then
                tushitaM = item.Mastery
            end
        end
    end

    return yamaM, tushitaM
end

----------------------------------------------------------
-- Цикл автообновления
----------------------------------------------------------
task.spawn(function()
    while true do
        if enabled then
            local yamaM, tushitaM = getMasteryFromInventory()

            if yamaM ~= nil then
                yamaLabel.Text = "Yama Mastery: " .. tostring(yamaM)
            else
                yamaLabel.Text = "Yama Mastery: не найдено"
            end

            if tushitaM ~= nil then
                tushitaLabel.Text = "Tushita Mastery: " .. tostring(tushitaM)
            else
                tushitaLabel.Text = "Tushita Mastery: не найдено"
            end
        end

        task.wait(UPDATE_INTERVAL)
    end
end)

print("[Yama/Tushita Mastery Checker] загружен.")
