--========================================================
--  Yama / Tushita Mastery Checker GUI (standalone)
--========================================================

-- === НАСТРОЙКИ ===
local UPDATE_DELAY = 0.5 -- как часто обновлять инфу (в секундах)

-- === СЕРВИСЫ ===
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- === ГЛОБАЛЬНЫЙ ФЛАГ ВКЛ/ВЫКЛ ===
_G.YTMasteryChecker_Enabled = _G.YTMasteryChecker_Enabled or false

-- === ФУНКЦИЯ ПОИСКА МЕЧА И ЕГО MASTERY ===
local function getSwordMastery(swordName)
    if not LocalPlayer.Character then return nil end

    -- пробуем найти меч в руках
    local tool = LocalPlayer.Character:FindFirstChild(swordName)

    -- если нет в руках — ищем в рюкзаке
    if not tool and LocalPlayer:FindFirstChild("Backpack") then
        tool = LocalPlayer.Backpack:FindFirstChild(swordName)
    end

    if tool then
        -- у боевых стилей из 12k мастери хранится в .Level.Value
        local levelVal = tool:FindFirstChild("Level") or tool:FindFirstChild("Mastery")
        if levelVal and levelVal:IsA("NumberValue") then
            return levelVal.Value
        end
    end

    return nil
end

-- ======================================================
--  СОЗДАНИЕ GUI
-- ======================================================

-- удаляем старый GUI если уже есть
do
    local old = (LocalPlayer.PlayerGui:FindFirstChild("YamaTushitaMasteryGui")
        or (game.CoreGui and game.CoreGui:FindFirstChild("YamaTushitaMasteryGui")))
    if old then
        old:Destroy()
    end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "YamaTushitaMasteryGui"

-- защита GUI (как обычно в эксплойтах)
local ok, _ = pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = game.CoreGui
    elseif gethui then
        screenGui.Parent = gethui()
    else
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end)
if not ok then
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- рамка
local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 250, 0, 140)
frame.Position = UDim2.new(0, 20, 0, 200)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Thickness = 1
stroke.Transparency = 0.2
stroke.Parent = frame

-- заголовок
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -10, 0, 24)
title.Position = UDim2.new(0, 5, 0, 4)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "Yama / Tushita Mastery"
title.Parent = frame

-- разделитель
local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, -10, 0, 1)
sep.Position = UDim2.new(0, 5, 0, 30)
sep.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
sep.BorderSizePixel = 0
sep.Parent = frame

-- статус (ON/OFF)
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -10, 0, 20)
statusLabel.Position = UDim2.new(0, 5, 0, 34)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Text = "Статус: OFF"
statusLabel.Parent = frame

-- текст Yama
local yamaLabel = Instance.new("TextLabel")
yamaLabel.Name = "YamaLabel"
yamaLabel.Size = UDim2.new(1, -10, 0, 22)
yamaLabel.Position = UDim2.new(0, 5, 0, 60)
yamaLabel.BackgroundTransparency = 1
yamaLabel.Font = Enum.Font.Gotham
yamaLabel.TextSize = 14
yamaLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
yamaLabel.TextXAlignment = Enum.TextXAlignment.Left
yamaLabel.Text = "Yama: —"
yamaLabel.Parent = frame

-- текст Tushita
local tushitaLabel = Instance.new("TextLabel")
tushitaLabel.Name = "TushitaLabel"
tushitaLabel.Size = UDim2.new(1, -10, 0, 22)
tushitaLabel.Position = UDim2.new(0, 5, 0, 84)
tushitaLabel.BackgroundTransparency = 1
tushitaLabel.Font = Enum.Font.Gotham
tushitaLabel.TextSize = 14
tushitaLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
tushitaLabel.TextXAlignment = Enum.TextXAlignment.Left
tushitaLabel.Text = "Tushita: —"
tushitaLabel.Parent = frame

-- кнопка ON/OFF
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 80, 0, 26)
toggleButton.Position = UDim2.new(1, -85, 1, -30)
toggleButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 14
toggleButton.Text = "OFF"
toggleButton.AutoButtonColor = true
toggleButton.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = toggleButton

-- обновление визуала кнопки/статуса
local function refreshButtonVisual()
    if _G.YTMasteryChecker_Enabled then
        toggleButton.Text = "ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
        statusLabel.Text = "Статус: ON"
        statusLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
    else
        toggleButton.Text = "OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
        statusLabel.Text = "Статус: OFF"
        statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        -- когда выкл — можно очистить текст, если хочешь
        -- yamaLabel.Text = "Yama: —"
        -- tushitaLabel.Text = "Tushita: —"
    end
end
refreshButtonVisual()

-- обработчик клика
toggleButton.MouseButton1Click:Connect(function()
    _G.YTMasteryChecker_Enabled = not _G.YTMasteryChecker_Enabled
    refreshButtonVisual()
end)

-- ======================================================
--  ЦИКЛ ОБНОВЛЕНИЯ MASTERY
-- ======================================================
task.spawn(function()
    while task.wait(UPDATE_DELAY) do
        if _G.YTMasteryChecker_Enabled then
            local yamaM = getSwordMastery("Yama")
            local tushitaM = getSwordMastery("Tushita")

            if yamaM ~= nil then
                yamaLabel.Text = "Yama: " .. tostring(yamaM)
            else
                yamaLabel.Text = "Yama: не найден меч"
            end

            if tushitaM ~= nil then
                tushitaLabel.Text = "Tushita: " .. tostring(tushitaM)
            else
                tushitaLabel.Text = "Tushita: не найден меч"
            end
        end
    end
end)

print("[Yama/Tushita Mastery GUI] Загружен.")
