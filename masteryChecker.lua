--========================================================
--  Yama / Tushita Mastery DEBUG-CHECKER
--  Делает 15 разных проверок и пишет лог
--========================================================

-- === СЕРВИСЫ ===
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- === ПАРАМЕТРЫ ЛОГА ===
local SWORDS = { "Yama", "Tushita" }
local CHECKS = {}  -- сюда положим все проверки

--========================================================
--  ХЕЛПЕРЫ
--========================================================

local function safeFind(parent, childName)
    if not parent then return nil end
    local ok, res = pcall(function()
        return parent:FindFirstChild(childName)
    end)
    if ok then return res end
    return nil
end

local function getTool(swordName)
    local char = LocalPlayer.Character
    local tool
    if char then
        tool = safeFind(char, swordName)
        if tool then return tool end
    end
    local backpack = safeFind(LocalPlayer, "Backpack")
    if backpack then
        tool = safeFind(backpack, swordName)
        if tool then return tool end
    end
    return nil
end

local function getData()
    return safeFind(LocalPlayer, "Data")
end

local function getStats()
    local data = getData()
    return safeFind(data, "Stats")
end

local function numberOrNil(v)
    if typeof(v) == "number" then return v end
    if typeof(v) == "Instance" and v:IsA("NumberValue") then
        return v.Value
    end
    return nil
end

--========================================================
--  ОПРЕДЕЛЕНИЕ ПРОВЕРОК (15 ШТУК)
--  Каждая функа должна вернуть: число или nil
--========================================================

-- 1) Tool.Level NumberValue
table.insert(CHECKS, {
    label = "Tool.Level",
    func = function(swordName)
        local tool = getTool(swordName)
        if not tool then return nil end
        local lvl = safeFind(tool, "Level")
        return numberOrNil(lvl)
    end
})

-- 2) Tool.Mastery NumberValue
table.insert(CHECKS, {
    label = "Tool.Mastery",
    func = function(swordName)
        local tool = getTool(swordName)
        if not tool then return nil end
        local m = safeFind(tool, "Mastery")
        return numberOrNil(m)
    end
})

-- 3) Любой NumberValue внутри Tool (первый попавшийся)
table.insert(CHECKS, {
    label = "Tool.FirstNumberValue",
    func = function(swordName)
        local tool = getTool(swordName)
        if not tool then return nil end
        for _, v in ipairs(tool:GetChildren()) do
            if v:IsA("NumberValue") then
                return v.Value
            end
        end
        return nil
    end
})

-- 4) Data.Sword[swordName].Level
table.insert(CHECKS, {
    label = "Data.Sword[sword].Level",
    func = function(swordName)
        local data = getData()
        if not data then return nil end
        local swordFolder = safeFind(data, "Sword")
        if not swordFolder then return nil end
        local entry = safeFind(swordFolder, swordName)
        if not entry then return nil end
        local lvl = safeFind(entry, "Level")
        return numberOrNil(lvl)
    end
})

-- 5) Data.SwordMastery[swordName] (часто так называют)
table.insert(CHECKS, {
    label = "Data.SwordMastery[sword]",
    func = function(swordName)
        local data = getData()
        if not data then return nil end
        local sm = safeFind(data, "SwordMastery")
        if not sm then return nil end
        local val = safeFind(sm, swordName)
        return numberOrNil(val)
    end
})

-- 6) Data[swordName].Level
table.insert(CHECKS, {
    label = "Data[sword].Level",
    func = function(swordName)
        local data = getData()
        if not data then return nil end
        local swordNode = safeFind(data, swordName)
        if not swordNode then return nil end
        local lvl = safeFind(swordNode, "Level")
        return numberOrNil(lvl)
    end
})

-- 7) Data[swordName] как NumberValue
table.insert(CHECKS, {
    label = "Data[sword] NumberValue",
    func = function(swordName)
        local data = getData()
        if not data then return nil end
        local val = safeFind(data, swordName)
        return numberOrNil(val)
    end
})

-- 8) Data.Stats[swordName].Level  (если мечи как отдельные статы)
table.insert(CHECKS, {
    label = "Data.Stats[sword].Level",
    func = function(swordName)
        local stats = getStats()
        if not stats then return nil end
        local swordStat = safeFind(stats, swordName)
        if not swordStat then return nil end
        local lvl = safeFind(swordStat, "Level")
        return numberOrNil(lvl)
    end
})

-- 9) Data.Stats[swordName] NumberValue
table.insert(CHECKS, {
    label = "Data.Stats[sword] Num",
    func = function(swordName)
        local stats = getStats()
        if not stats then return nil end
        local val = safeFind(stats, swordName)
        return numberOrNil(val)
    end
})

-- 10) Любой NumberValue в Data с EXACT именем меча
table.insert(CHECKS, {
    label = "Data.Desc Name == sword",
    func = function(swordName)
        local data = getData()
        if not data then return nil end
        for _, v in ipairs(data:GetDescendants()) do
            if v:IsA("NumberValue") and v.Name == swordName then
                return v.Value
            end
        end
        return nil
    end
})

-- 11) NumberValue, у которого родитель называется мечом и сам называется "Level"
table.insert(CHECKS, {
    label = "Parent==sword, Name=Level",
    func = function(swordName)
        local data = getData()
        if not data then return nil end
        for _, v in ipairs(data:GetDescendants()) do
            if v:IsA("NumberValue") 
                and v.Name == "Level" 
                and v.Parent 
                and v.Parent.Name == swordName then
                return v.Value
            end
        end
        return nil
    end
})

-- 12) NumberValue, где имя содержит имя меча (Yama/Tushita внутри Name)
table.insert(CHECKS, {
    label = "Name contains sword",
    func = function(swordName)
        local data = getData()
        if not data then return nil end
        for _, v in ipairs(data:GetDescendants()) do
            if v:IsA("NumberValue") and string.find(string.lower(v.Name), string.lower(swordName), 1, true) then
                return v.Value
            end
        end
        return nil
    end
})

-- 13) Любой NumberValue в Backpack с именем меча
table.insert(CHECKS, {
    label = "Backpack child Num",
    func = function(swordName)
        local backpack = safeFind(LocalPlayer, "Backpack")
        if not backpack then return nil end
        local val = safeFind(backpack, swordName)
        return numberOrNil(val)
    end
})

-- 14) В Tool ищем NumberValue с именем "Mastery" или "Mast" (часто кастом)
table.insert(CHECKS, {
    label = "Tool.Master* NumberValue",
    func = function(swordName)
        local tool = getTool(swordName)
        if not tool then return nil end
        for _, v in ipairs(tool:GetDescendants()) do
            if v:IsA("NumberValue") then
                local n = string.lower(v.Name)
                if string.find(n, "master", 1, true) then
                    return v.Value
                end
            end
        end
        return nil
    end
})

-- 15) Пробуем вытащить мастери через Remotes (если вдруг есть такой вызов)
table.insert(CHECKS, {
    label = "Remote guess (CommF_)",
    func = function(swordName)
        local remotes = safeFind(ReplicatedStorage, "Remotes")
        if not remotes then return nil end
        local comm = safeFind(remotes, "CommF_")
        if not comm then return nil end
        -- Полностью гадательный вариант, поэтому только в pcall
        local ok, res = pcall(function()
            -- если ничего нет, просто вернёт nil
            return comm:InvokeServer("GetMastery", swordName)
                or comm:InvokeServer("GetWeaponMastery", swordName)
        end)
        if not ok then return nil end
        return numberOrNil(res)
    end
})

--========================================================
--  GUI
--========================================================

-- удаляем старый GUI, если есть
do
    local old = (LocalPlayer.PlayerGui:FindFirstChild("YTMasteryDebugGui")
        or (game.CoreGui and game.CoreGui:FindFirstChild("YTMasteryDebugGui")))
    if old then old:Destroy() end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "YTMasteryDebugGui"

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

-- Главное окно
local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 650, 0, 260) -- ширина ~650, текстовое поле ~600
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
title.Text = "Yama / Tushita Mastery DEBUG"
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
statusLabel.Text = "Нажми RUN для запуска всех проверок."
statusLabel.Parent = frame

-- Кнопка RUN
local runButton = Instance.new("TextButton")
runButton.Name = "RunButton"
runButton.Size = UDim2.new(0, 80, 0, 26)
runButton.Position = UDim2.new(1, -90, 0, 32)
runButton.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
runButton.TextColor3 = Color3.fromRGB(255, 255, 255)
runButton.Font = Enum.Font.GothamBold
runButton.TextSize = 14
runButton.Text = "RUN"
runButton.AutoButtonColor = true
runButton.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = runButton

-- ЛОГ-ПАНЕЛЬ (ширина под ~600px текста)
local logFrame = Instance.new("ScrollingFrame")
logFrame.Name = "LogFrame"
logFrame.Size = UDim2.new(1, -20, 0, 180)
logFrame.Position = UDim2.new(0, 10, 0, 60)
logFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
logFrame.ScrollBarThickness = 6
logFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
logFrame.BorderSizePixel = 0
logFrame.Parent = frame

local logCorner = Instance.new("UICorner")
logCorner.CornerRadius = UDim.new(0, 6)
logCorner.Parent = logFrame

local logText = Instance.new("TextLabel")
logText.Name = "LogText"
logText.Size = UDim2.new(1, -10, 0, 0) -- высоту будем менять по TextBounds
logText.Position = UDim2.new(0, 5, 0, 0)
logText.BackgroundTransparency = 1
logText.Font = Enum.Font.Code
logText.TextSize = 14
logText.TextXAlignment = Enum.TextXAlignment.Left
logText.TextYAlignment = Enum.TextYAlignment.Top
logText.TextColor3 = Color3.fromRGB(230, 230, 230)
logText.TextWrapped = false -- чтобы не ломало строку, ширины ~600 хватит
logText.Text = ""
logText.Parent = logFrame

local function setLogText(txt)
    logText.Text = txt
    -- пересчитываем высоту
    task.wait() -- ждём TextBounds
    local tb = logText.TextBounds
    logText.Size = UDim2.new(1, -10, 0, tb.Y + 10)
    logFrame.CanvasSize = UDim2.new(0, 0, 0, tb.Y + 10)
    logFrame.CanvasPosition = Vector2.new(0, math.max(0, tb.Y - logFrame.AbsoluteWindowSize.Y))
end

local function appendLog(line)
    if logText.Text == "" then
        setLogText(line)
    else
        setLogText(logText.Text .. "\n" .. line)
    end
end

--========================================================
--  ЗАПУСК ВСЕХ ПРОВЕРОК
--========================================================

local running = false

local function runAllChecks()
    if running then return end
    running = true

    setLogText("")
    statusLabel.Text = "Выполняю проверки..."

    appendLog("=== START DEBUG CHECKS ===")
    appendLog("Всего проверок: " .. tostring(#CHECKS))
    appendLog("Оружия: Yama, Tushita")
    appendLog("")

    for idx, check in ipairs(CHECKS) do
        for _, swordName in ipairs(SWORDS) do
            local valueStr = "не найдено"
            local ok, result = pcall(function()
                return check.func(swordName)
            end)
            if ok and result ~= nil then
                valueStr = tostring(result)
            elseif not ok then
                valueStr = "ошибка (" .. tostring(result) .. ")"
            end

            appendLog(
                string.format(
                    "Проверка #%d [%s], %s mastery: %s",
                    idx,
                    check.label,
                    swordName,
                    valueStr
                )
            )
        end
        appendLog("") -- пустая строка между проверками
        task.wait(0.01)
    end

    appendLog("=== END DEBUG CHECKS ===")
    statusLabel.Text = "Готово. Сфотай лог и скинь мне скрин."

    running = false
end

runButton.MouseButton1Click:Connect(runAllChecks)

print("[YTMasteryDebug] Loaded. Нажми RUN в GUI.")
