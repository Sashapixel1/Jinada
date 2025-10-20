-- AccountInfoLocal (LocalScript)
-- Поместить в StarterPlayer > StarterPlayerScripts
-- Показывает локальную информацию о твоём персонаже. Никаких вебхуков, ничего серверного.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Безопасный поиск вложенных дочерних объектов по списку имён
local function getNested(root, parts)
    if not root then return nil end
    local cur = root
    for _, name in ipairs(parts) do
        if not cur then return nil end
        cur = cur:FindFirstChild(name)
    end
    return cur
end

-- Собирает данные игрока гибко, пытаясь прочесть обычно используемые места
local function collectPlayerData()
    local data = {}
    data.Name = player.Name

    -- Beli
    local beliVal = nil
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local b = leaderstats:FindFirstChild("Beli") or leaderstats:FindFirstChild("beli")
        if b and b.Value ~= nil then beliVal = b.Value end
    end
    if not beliVal then
        local bnode = getNested(player, {"Data", "Beli"}) or getNested(player, {"Data", "beli"})
        if bnode and bnode.Value ~= nil then beliVal = bnode.Value end
    end
    data.Beli = beliVal or 0

    -- Race: атрибут или Data.Race
    local race = nil
    if player.GetAttribute then
        race = player:GetAttribute("Race") or player:GetAttribute("race")
    end
    if not race then
        local rn = getNested(player, {"Data", "Race"}) or getNested(player, {"Data", "race"})
        if rn and rn.Value ~= nil then race = rn.Value end
    end
    data.Race = race or "Unknown"

    -- DevilFruits: из Data.DevilFruits (Folder/StringValue) и из Backpack (инструменты)
    local fruits = {}

    local df = getNested(player, {"Data", "DevilFruits"}) or getNested(player, {"Data", "Devilfruit"}) or getNested(player, {"Data", "Devil Fruit"})
    if df then
        if df:IsA("Folder") or df:IsA("Instance") then
            for _, c in ipairs(df:GetChildren()) do
                table.insert(fruits, c.Name)
            end
        else
            -- строковое или value
            if df.Value then
                if type(df.Value) == "table" then
                    for _, v in ipairs(df.Value) do table.insert(fruits, tostring(v)) end
                else
                    table.insert(fruits, tostring(df.Value))
                end
            else
                table.insert(fruits, tostring(df))
            end
        end
    end

    -- Проверка Backpack (обычное место для инструментов)
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") or item:IsA("HopperBin") then
                table.insert(fruits, item.Name)
            end
        end
    end

    -- Проверка пути, который ты упомянул: PlayerGui.Backpack.Inventory (иногда разработчики кладут GUI-репрезентацию)
    local guiBackpack = playerGui:FindFirstChild("Backpack")
    if guiBackpack then
        local inventory = guiBackpack:FindFirstChild("Inventory")
        if inventory then
            for _, child in ipairs(inventory:GetChildren()) do
                if child:IsA("TextLabel") or child:IsA("ImageLabel") or child:IsA("Frame") then
                    -- попытаемся взять имя
                    if child.Name and child.Name ~= "" then table.insert(fruits, child.Name) end
                    -- или Text
                    if child:IsA("TextLabel") and child.Text and child.Text ~= "" then table.insert(fruits, child.Text) end
                end
            end
        end
    end

    -- Удаляем дубликаты
    local uniq = {}
    local fruitList = {}
    for _, v in ipairs(fruits) do
        if v and v ~= "" and not uniq[v] then
            uniq[v] = true
            table.insert(fruitList, v)
        end
    end
    data.DevilFruits = fruitList

    -- Stats: Data.Stats -> дочерние объекты с Exp и Level
    data.Stats = {}
    local statsRoot = getNested(player, {"Data", "Stats"}) or getNested(player, {"Stats"}) or getNested(player, {"Data"})
    if statsRoot then
        -- если нашли именно Folder Stats, пройдём её детей, иначе попробуем конкретные имена
        if statsRoot:FindFirstChild("Stats") then statsRoot = statsRoot:FindFirstChild("Stats") end
        for _, stat in ipairs(statsRoot:GetChildren()) do
            -- пропускаем привычные value-поля (например Beli), обращаем внимание на структуры с Exp/Level
            if stat:IsA("Folder") or #stat:GetChildren() > 0 then
                local statName = stat.Name
                local exp = 0
                local lvl = 0
                local eObj = stat:FindFirstChild("Exp") or stat:FindFirstChild("Experience") or stat:FindFirstChild("exp")
                if eObj and eObj.Value ~= nil then exp = eObj.Value end
                local lObj = stat:FindFirstChild("Level") or stat:FindFirstChild("level")
                if lObj and lObj.Value ~= nil then lvl = lObj.Value end
                data.Stats[statName] = { Exp = exp, Level = lvl }
            end
        end
    end

    -- Если не нашлось Stats, попробуем найти конкретные имена (как в твоём запросе)
    local expectedNames = {"Demon Fruits", "Gun", "Melee", "Sword", "DemonFruits", "Demon"}
    for _, name in ipairs(expectedNames) do
        if not data.Stats[name] then
            local node = getNested(player, {"Data", "Stats", name}) or getNested(player, {"Data", name})
            if node then
                local exp = 0
                local lvl = 0
                local eObj = node:FindFirstChild("Exp") or node:FindFirstChild("exp")
                if eObj and eObj.Value ~= nil then exp = eObj.Value end
                local lObj = node:FindFirstChild("Level") or node:FindFirstChild("level")
                if lObj and lObj.Value ~= nil then lvl = lObj.Value end
                data.Stats[name] = { Exp = exp, Level = lvl }
            end
        end
    end

    return data
end

-- UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AccountInfoUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 460, 0, 360)
frame.Position = UDim2.new(0, 16, 0, 16)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -12, 0, 36)
title.Position = UDim2.new(0, 6, 0, 6)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.Text = "Account Info (локально)"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local function makeLabel(name, y)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 20)
    lbl.Position = UDim2.new(0, 6, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 16
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = name
    lbl.Parent = frame
    return lbl
end

local nameLabel = makeLabel("Игрок: —", 48)
local beliLabel = makeLabel("Beli: —", 72)
local raceLabel = makeLabel("Race: —", 96)
local fruitsLabel = makeLabel("Devil Fruits: —", 120)

local statsTitle = Instance.new("TextLabel")
statsTitle.Size = UDim2.new(1, -12, 0, 20)
statsTitle.Position = UDim2.new(0, 6, 0, 150)
statsTitle.BackgroundTransparency = 1
statsTitle.Font = Enum.Font.SourceSansBold
statsTitle.TextSize = 16
statsTitle.Text = "Stats:"
statsTitle.TextXAlignment = Enum.TextXAlignment.Left
statsTitle.Parent = frame

local statsBox = Instance.new("TextLabel")
statsBox.Size = UDim2.new(1, -12, 0, 160)
statsBox.Position = UDim2.new(0, 6, 0, 174)
statsBox.BackgroundTransparency = 1
statsBox.Font = Enum.Font.Code
statsBox.TextSize = 14
statsBox.TextXAlignment = Enum.TextXAlignment.Left
statsBox.TextYAlignment = Enum.TextYAlignment.Top
statsBox.TextWrapped = true
statsBox.Text = ""
statsBox.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -12, 0, 18)
statusLabel.Position = UDim2.new(0, 6, 0, 338)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.SourceSansItalic
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Text = "Последнее обновление: —"
statusLabel.Parent = frame

-- Обновление UI на основе собранных данных
local function updateUI()
    local ok, data = pcall(collectPlayerData)
    if not ok then
        statusLabel.Text = "Ошибка при сборе данных: " .. tostring(data)
        return
    end

    nameLabel.Text = "Игрок: " .. tostring(data.Name or "—")
    beliLabel.Text = "Beli: " .. tostring(data.Beli or 0)
    raceLabel.Text = "Race: " .. tostring(data.Race or "—")
    fruitsLabel.Text = "Devil Fruits: " .. ((#(data.DevilFruits or {}) > 0) and table.concat(data.DevilFruits, ", ") or "Нет")

    local statsTextLines = {}
    for statName, statTable in pairs(data.Stats or {}) do
        local line = string.format("%s — Exp: %s  Level: %s", tostring(statName), tostring(statTable.Exp or 0), tostring(statTable.Level or 0))
        table.insert(statsTextLines, line)
    end
    if #statsTextLines == 0 then
        statsBox.Text = "  (Stats не найдены)"
    else
        statsBox.Text = table.concat(statsTextLines, "\n")
    end

    statusLabel.Text = "Последнее обновление: " .. os.date("%Y-%m-%d %H:%M:%S")
end

-- Первичный апдейт
updateUI()

-- Обновлять каждые 3 секунды
task.spawn(function()
    while true do
        task.wait(3)
        -- Если игрок отсоединился — прерываем цикл
        if not player or not player.Parent then break end
        updateUI()
    end
end)
