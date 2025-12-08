--========================================================
--  Yama / Tushita LEVEL DEBUG-CHECKER
--  Ищет именно Level Yama и Tushita, лог в GUI
--========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local SWORDS = { "Yama", "Tushita" }

local CommF
pcall(function()
    CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
end)

----------------------------------------------------------
--  GUI
----------------------------------------------------------
do
    local old = (LocalPlayer.PlayerGui:FindFirstChild("YTLevelDebugGui")
        or (game.CoreGui and game.CoreGui:FindFirstChild("YTLevelDebugGui")))
    if old then old:Destroy() end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "YTLevelDebugGui"

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
frame.Size = UDim2.new(0, 650, 0, 260) -- ширина ~650 (текст ~600)
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
title.Text = "Yama / Tushita LEVEL DEBUG"
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

-- ЛОГ на ~600px текста
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
logText.Size = UDim2.new(1, -10, 0, 0)
logText.Position = UDim2.new(0, 5, 0, 0)
logText.BackgroundTransparency = 1
logText.Font = Enum.Font.Code
logText.TextSize = 14
logText.TextXAlignment = Enum.TextXAlignment.Left
logText.TextYAlignment = Enum.TextYAlignment.Top
logText.TextColor3 = Color3.fromRGB(230, 230, 230)
logText.TextWrapped = false -- важно: не переносим по ширине
logText.Text = ""
logText.Parent = logFrame

local function setLogText(txt)
    logText.Text = txt
    task.wait()
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

----------------------------------------------------------
--  ХЕЛПЕРЫ
----------------------------------------------------------
local function safeFind(parent, name)
    if not parent then return nil end
    local ok, res = pcall(function()
        return parent:FindFirstChild(name)
    end)
    if ok then return res end
    return nil
end

local function safeDescendants(root)
    if not root then return {} end
    local ok, res = pcall(function()
        return root:GetDescendants()
    end)
    if ok then return res end
    return {}
end

local function numberOrNil(v)
    if typeof(v) == "number" then
        return v
    end
    if typeof(v) == "Instance" and v:IsA("NumberValue") then
        return v.Value
    end
    return nil
end

local function getTool(swordName)
    local char = LocalPlayer.Character
    if char then
        local t = safeFind(char, swordName)
        if t then return t, "Character" end
    end
    local backpack = safeFind(LocalPlayer, "Backpack")
    if backpack then
        local t = safeFind(backpack, swordName)
        if t then return t, "Backpack" end
    end
    return nil, nil
end

local function getData()
    return safeFind(LocalPlayer, "Data")
end

local function getStats()
    local data = getData()
    return safeFind(data, "Stats")
end

----------------------------------------------------------
--  СПИСОК ПРОВЕРОК
----------------------------------------------------------
local CHECKS = {}
local function addCheck(label, func)  -- func(swordName, checkIndex, appendLog) -> nil
    table.insert(CHECKS, {label = label, func = func})
end

----------------------------------------------------------
--  Проверка 1: getInventory, полный дамп полей
----------------------------------------------------------
addCheck("getInventory (дамп полей предмета)", function(swordName, idx, log)
    if not CommF then
        log(("Проверка #%d [%s], %s: CommF_ не найден"):format(idx, "getInventory", swordName))
        return
    end
    local ok, inv = pcall(function()
        return CommF:InvokeServer("getInventory")
    end)
    if not ok or not inv then
        log(("Проверка #%d [getInventory], %s: ошибка вызова: %s"):format(idx, swordName, tostring(inv)))
        return
    end

    local found = false
    for _, item in pairs(inv) do
        if item and item.Type == "Sword" and item.Name == swordName then
            found = true
            log(("Проверка #%d [getInventory], %s: найден предмет, поля:"):format(idx, swordName))
            for k, v in pairs(item) do
                log(("    %s = %s (%s)"):format(tostring(k), tostring(v), typeof(v)))
            end
        end
    end
    if not found then
        log(("Проверка #%d [getInventory], %s: меч в getInventory НЕ найден"):format(idx, swordName))
    end
end)

----------------------------------------------------------
--  Проверка 2: getInventory, ищем поля Level / Mastery / LVL
----------------------------------------------------------
addCheck("getInventory.Level / Mastery / lvl*", function(swordName, idx, log)
    if not CommF then
        log(("Проверка #%d [%s], %s: CommF_ не найден"):format(idx, "getInventory.Level", swordName))
        return
    end
    local ok, inv = pcall(function()
        return CommF:InvokeServer("getInventory")
    end)
    if not ok or not inv then
        log(("Проверка #%d [getInventory.Level], %s: ошибка вызова: %s"):format(idx, swordName, tostring(inv)))
        return
    end

    local keyNames = {"Level","level","Mastery","mastery","LVL","Lvl","lvl"}
    local function findLevelField(item)
        for _, key in ipairs(keyNames) do
            if item[key] ~= nil then
                return key, item[key]
            end
        end
        return nil, nil
    end

    local found = false
    for _, item in pairs(inv) do
        if item and item.Type == "Sword" and item.Name == swordName then
            local key, val = findLevelField(item)
            if key then
                found = true
                log(("Проверка #%d [getInventory.Level], %s level: %s (поле: %s)"):format(
                    idx, swordName, tostring(val), key
                ))
            end
        end
    end
    if not found then
        log(("Проверка #%d [getInventory.Level], %s level: не найдено"):format(idx, swordName))
    end
end)

----------------------------------------------------------
--  Проверка 3: Data.Sword[swordName].Level
----------------------------------------------------------
addCheck("Data.Sword[sword].Level", function(swordName, idx, log)
    local data = getData()
    if not data then
        log(("Проверка #%d [Data.Sword.Level], %s: Data отсутствует"):format(idx, swordName))
        return
    end
    local swordFolder = safeFind(data, "Sword")
    if not swordFolder then
        log(("Проверка #%d [Data.Sword.Level], %s: Data.Sword отсутствует"):format(idx, swordName))
        return
    end
    local entry = safeFind(swordFolder, swordName)
    if not entry then
        log(("Проверка #%d [Data.Sword.Level], %s: узел с именем меча отсутствует"):format(idx, swordName))
        return
    end
    local lvl = safeFind(entry, "Level")
    local val = numberOrNil(lvl)
    log(("Проверка #%d [Data.Sword.Level], %s level: %s"):format(idx, swordName, val and tostring(val) or "не найдено"))
end)

----------------------------------------------------------
--  Проверка 4: Data.Sword[swordName] как NumberValue
----------------------------------------------------------
addCheck("Data.Sword[sword] NumberValue", function(swordName, idx, log)
    local data = getData()
    if not data then
        log(("Проверка #%d [Data.Sword Num], %s: Data отсутствует"):format(idx, swordName))
        return
    end
    local swordFolder = safeFind(data, "Sword")
    if not swordFolder then
        log(("Проверка #%d [Data.Sword Num], %s: Data.Sword отсутствует"):format(idx, swordName))
        return
    end
    local val = safeFind(swordFolder, swordName)
    local num = numberOrNil(val)
    log(("Проверка #%d [Data.Sword Num], %s level: %s"):format(idx, swordName, num and tostring(num) or "не найдено"))
end)

----------------------------------------------------------
--  Проверка 5: Data[swordName].Level
----------------------------------------------------------
addCheck("Data[sword].Level", function(swordName, idx, log)
    local data = getData()
    if not data then
        log(("Проверка #%d [Data[sword].Level], %s: Data отсутствует"):format(idx, swordName))
        return
    end
    local node = safeFind(data, swordName)
    if not node then
        log(("Проверка #%d [Data[sword].Level], %s: Data[%s] отсутствует"):format(idx, swordName, swordName))
        return
    end
    local lvl = safeFind(node, "Level")
    local num = numberOrNil(lvl)
    log(("Проверка #%d [Data[sword].Level], %s level: %s"):format(idx, swordName, num and tostring(num) or "не найдено"))
end)

----------------------------------------------------------
--  Проверка 6: Data.Descendants, Parent.Name==sword, Name=="Level"
----------------------------------------------------------
addCheck("Data.Desc Parent==sword & Name==Level", function(swordName, idx, log)
    local data = getData()
    if not data then
        log(("Проверка #%d [Data.Desc Parent/Level], %s: Data отсутствует"):format(idx, swordName))
        return
    end
    local best
    for _, v in ipairs(safeDescendants(data)) do
        if v:IsA("NumberValue") and v.Name == "Level" and v.Parent and v.Parent.Name == swordName then
            best = v
            break
        end
    end
    local num = numberOrNil(best)
    log(("Проверка #%d [Data.Desc Parent/Level], %s level: %s"):format(idx, swordName, num and tostring(num) or "не найдено"))
end)

----------------------------------------------------------
--  Проверка 7: Data.Descendants, Name==swordName (сам NumberValue)
----------------------------------------------------------
addCheck("Data.Desc Name==sword", function(swordName, idx, log)
    local data = getData()
    if not data then
        log(("Проверка #%d [Data.Desc Name==sword], %s: Data отсутствует"):format(idx, swordName))
        return
    end
    local found
    for _, v in ipairs(safeDescendants(data)) do
        if v:IsA("NumberValue") and v.Name == swordName then
            found = v
            break
        end
    end
    local num = numberOrNil(found)
    log(("Проверка #%d [Data.Desc Name==sword], %s level: %s"):format(idx, swordName, num and tostring(num) or "не найдено"))
end)

----------------------------------------------------------
--  Проверка 8: Data.Descendants, Name содержит swordName
----------------------------------------------------------
addCheck("Data.Desc Name contains sword", function(swordName, idx, log)
    local data = getData()
    if not data then
        log(("Проверка #%d [Data.Desc contains sword], %s: Data отсутствует"):format(idx, swordName))
        return
    end
    local lname = string.lower(swordName)
    local best
    for _, v in ipairs(safeDescendants(data)) do
        if v:IsA("NumberValue") and string.find(string.lower(v.Name), lname, 1, true) then
            best = v
            break
        end
    end
    if best then
        log(("Проверка #%d [Data.Desc contains sword], %s level: %s (узел: %s)"):format(
            idx, swordName, tostring(numberOrNil(best)), best:GetFullName()
        ))
    else
        log(("Проверка #%d [Data.Desc contains sword], %s level: не найдено"):format(idx, swordName))
    end
end)

----------------------------------------------------------
--  Проверка 9: Stats[swordName].Level
----------------------------------------------------------
addCheck("Data.Stats[sword].Level", function(swordName, idx, log)
    local stats = getStats()
    if not stats then
        log(("Проверка #%d [Stats[sword].Level], %s: Stats отсутствует"):format(idx, swordName))
        return
    end
    local node = safeFind(stats, swordName)
    if not node then
        log(("Проверка #%d [Stats[sword].Level], %s: узел отсутствует"):format(idx, swordName))
        return
    end
    local lvl = safeFind(node, "Level")
    local num = numberOrNil(lvl)
    log(("Проверка #%d [Stats[sword].Level], %s level: %s"):format(idx, swordName, num and tostring(num) or "не найдено"))
end)

----------------------------------------------------------
--  Проверка 10: любой NumberValue в Tool (прямой ребёнок)
----------------------------------------------------------
addCheck("Tool.First NumberValue child", function(swordName, idx, log)
    local tool, where = getTool(swordName)
    if not tool then
        log(("Проверка #%d [Tool.FirstNum Child], %s: меч не найден в руках/рюкзаке"):format(idx, swordName))
        return
    end
    local found
    for _, v in ipairs(tool:GetChildren()) do
        if v:IsA("NumberValue") then
            found = v
            break
        end
    end
    if found then
        log(("Проверка #%d [Tool.FirstNum Child], %s level: %s (Name=%s, где: %s)"):format(
            idx, swordName, tostring(found.Value), found.Name, where
        ))
    else
        log(("Проверка #%d [Tool.FirstNum Child], %s: NumberValue не найдено (где: %s)"):format(idx, swordName, where))
    end
end)

----------------------------------------------------------
--  Проверка 11: любой NumberValue в Tool.Descendants
----------------------------------------------------------
addCheck("Tool.Desc First NumberValue", function(swordName, idx, log)
    local tool, where = getTool(swordName)
    if not tool then
        log(("Проверка #%d [Tool.DescNum], %s: меч не найден в руках/рюкзаке"):format(idx, swordName))
        return
    end
    local found
    for _, v in ipairs(tool:GetDescendants()) do
        if v:IsA("NumberValue") then
            found = v
            break
        end
    end
    if found then
        log(("Проверка #%d [Tool.DescNum], %s level: %s (Name=%s, путь=%s)"):format(
            idx, swordName, tostring(found.Value), found.Name, found:GetFullName()
        ))
    else
        log(("Проверка #%d [Tool.DescNum], %s: NumberValue не найдено"):format(idx, swordName))
    end
end)

----------------------------------------------------------
--  Проверка 12: Tool.Desc, Name содержит 'Level' / 'Master' / 'Mast'
----------------------------------------------------------
addCheck("Tool.Desc Name contains Level/Master", function(swordName, idx, log)
    local tool = select(1, getTool(swordName))
    if not tool then
        log(("Проверка #%d [Tool.Desc Level/Master], %s: меч не найден"):format(idx, swordName))
        return
    end
    local best
    for _, v in ipairs(tool:GetDescendants()) do
        if v:IsA("NumberValue") then
            local ln = string.lower(v.Name)
            if string.find(ln, "level", 1, true) or string.find(ln, "mast", 1, true) then
                best = v
                break
            end
        end
    end
    if best then
        log(("Проверка #%d [Tool.Desc Level/Master], %s level: %s (Name=%s, путь=%s)"):format(
            idx, swordName, tostring(best.Value), best.Name, best:GetFullName()
        ))
    else
        log(("Проверка #%d [Tool.Desc Level/Master], %s level: не найдено"):format(idx, swordName))
    end
end)

----------------------------------------------------------
--  Проверка 13: Поиск по всему LocalPlayer.NumberValue, где Name содержит swordName
----------------------------------------------------------
addCheck("LocalPlayer.Desc Name contains sword", function(swordName, idx, log)
    local lname = string.lower(swordName)
    local best
    for _, v in ipairs(safeDescendants(LocalPlayer)) do
        if v:IsA("NumberValue") and string.find(string.lower(v.Name), lname, 1, true) then
            best = v
            break
        end
    end
    if best then
        log(("Проверка #%d [Local.Name contains sword], %s level: %s (Name=%s, путь=%s)"):format(
            idx, swordName, tostring(best.Value), best.Name, best:GetFullName()
        ))
    else
        log(("Проверка #%d [Local.Name contains sword], %s level: не найдено"):format(idx, swordName))
    end
end)

----------------------------------------------------------
--  Проверка 14: Поиск NumberValue с Name == swordName.."Level"
----------------------------------------------------------
addCheck("LocalPlayer.Desc Name==sword..'Level'", function(swordName, idx, log)
    local targetNames = {
        swordName .. "Level",
        swordName .. "_Level",
        swordName .. "LVL",
        swordName .. "_LVL",
    }
    local best
    for _, v in ipairs(safeDescendants(LocalPlayer)) do
        if v:IsA("NumberValue") then
            for _, tn in ipairs(targetNames) do
                if v.Name == tn then
                    best = v
                    break
                end
            end
        end
        if best then break end
    end
    if best then
        log(("Проверка #%d [Local Name==swordLevel], %s level: %s (Name=%s, путь=%s)"):format(
            idx, swordName, tostring(best.Value), best.Name, best:GetFullName()
        ))
    else
        log(("Проверка #%d [Local Name==swordLevel], %s level: не найдено"):format(idx, swordName))
    end
end)

----------------------------------------------------------
--  Проверка 15: leaderstats (если вдруг автор туда кладёт уровни)
----------------------------------------------------------
addCheck("leaderstats[sword] / [swordLevel]", function(swordName, idx, log)
    local ls = safeFind(LocalPlayer, "leaderstats")
    if not ls then
        log(("Проверка #%d [leaderstats], %s: leaderstats отсутствует"):format(idx, swordName))
        return
    end
    local candNames = {
        swordName,
        swordName .. "Level",
        swordName .. "_Level",
        swordName .. " LVL",
    }
    local best
    for _, name in ipairs(candNames) do
        local v = safeFind(ls, name)
        if v then
            best = v
            break
        end
    end
    local num = numberOrNil(best)
    log(("Проверка #%d [leaderstats], %s level: %s (Name=%s)"):format(
        idx, swordName, num and tostring(num) or "не найдено", best and best.Name or "—"
    ))
end)

----------------------------------------------------------
--  Запуск всех проверок
----------------------------------------------------------
local running = false

local function runAllChecks()
    if running then return end
    running = true

    setLogText("")
    statusLabel.Text = "Выполняю проверки..."

    appendLog("=== START LEVEL DEBUG CHECKS ===")
    appendLog("Всего проверок (логически): " .. tostring(#CHECKS))
    appendLog("Оружия: Yama, Tushita")
    appendLog("")

    local checkIndex = 0

    for _, swordName in ipairs(SWORDS) do
        appendLog(("--- %s ---"):format(swordName))
        for _, chk in ipairs(CHECKS) do
            checkIndex = checkIndex + 1
            local label = chk.label
            local ok, err = pcall(function()
                chk.func(swordName, checkIndex, appendLog)
            end)
            if not ok then
                appendLog(("Проверка #%d [%s], %s: КРАШ функции (%s)"):format(
                    checkIndex, label, swordName, tostring(err)
                ))
            end
            appendLog("") -- пустая строка между проверками
            task.wait(0.01)
        end
        appendLog("")
    end

    appendLog("=== END LEVEL DEBUG CHECKS ===")
    statusLabel.Text = "Готово. Сфотай лог и скинь мне скрин."
    running = false
end

runButton.MouseButton1Click:Connect(runAllChecks)

print("[YTLevelDebug] Loaded. Нажми RUN в GUI.")
