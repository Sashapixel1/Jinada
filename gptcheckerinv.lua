-- AccountInfo_WithReplicatedStorage (LocalScript)
-- Показывает локальную информацию + фрукты из ReplicatedStorage (без вызова чужих RemoteFunctions)
-- Помести в StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Вспомогательная функция: безопасный поиск вложенных объектов
local function getNested(root, parts)
    if not root then return nil end
    local cur = root
    for _, name in ipairs(parts) do
        if not cur then return nil end
        cur = cur:FindFirstChild(name)
    end
    return cur
end

-- Сканирование ReplicatedStorage на предмет инвентарей/фруктов, доступных клиенту
local function collectFromReplicatedStorage()
    local found = {}

    local function addIfValid(name)
        if name and name ~= "" and not found[name] then
            found[name] = true
        end
    end

    -- Ищем явно именованные узлы
    local candidateNames = {"Inventory", "PlayerInventory", "DevilFruits", "Devil Fruit", "Fruits", "Backpack"}
    for _, cname in ipairs(candidateNames) do
        local node = ReplicatedStorage:FindFirstChild(cname)
        if node then
            -- Если это папка — перечисляем её детей
            if node:IsA("Folder") or node:IsA("Instance") then
                for _, child in ipairs(node:GetChildren()) do
                    -- Если дочерний — инструмент/модель/значение/строка — добавляем его имя/значение
                    if child:IsA("Tool") or child:IsA("Model") then
                        addIfValid(child.Name)
                    elseif child:IsA("StringValue") or child:IsA("ObjectValue") or child:IsA("ValueBase") then
                        addIfValid(tostring(child.Value or child.Name))
                    else
                        addIfValid(child.Name)
                    end
                end
            end
        end
    end

    -- Общий обход: иногда фрукты лежат глубже (например ReplicatedStorage.SomeFolder.Inventory.Player123)
    -- Мы ограничим глубину и типы, чтобы не собирать всё подряд.
    local maxDepth = 3
    local function walk(instance, depth)
        if depth > maxDepth then return end
        for _, child in ipairs(instance:GetChildren()) do
            -- маленькая эвристика по имени
            local lname = child.Name:lower()
            if lname:find("fruit") or lname:find("devil") or lname:find("inventory") or lname:find("backpack") then
                -- перечисляем содержимое
                for _, c2 in ipairs(child:GetChildren()) do
                    if c2:IsA("Tool") or c2:IsA("Model") then
                        addIfValid(c2.Name)
                    elseif c2:IsA("StringValue") or c2:IsA("ValueBase") then
                        addIfValid(tostring(c2.Value or c2.Name))
                    else
                        addIfValid(c2.Name)
                    end
                end
            end
            -- рекурсивно, ограничивая глубину
            walk(child, depth + 1)
        end
    end

    -- Запускаем обход корня ReplicatedStorage
    walk(ReplicatedStorage, 1)

    -- Собираем результат в массив
    local list = {}
    for k, _ in pairs(found) do table.insert(list, k) end
    return list
end

-- Сбор данных игрока (Backpack + GUI + ReplicatedStorage)
local function collectPlayerData()
    local data = {}
    data.Name = player.Name

    -- Beli
    local beliVal
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

    -- Race
    local race
    if player.GetAttribute then race = player:GetAttribute("Race") or player:GetAttribute("race") end
    if not race then
        local rn = getNested(player, {"Data", "Race"}) or getNested(player, {"Data", "race"})
        if rn and rn.Value ~= nil then race = rn.Value end
    end
    data.Race = race or "Unknown"

    -- DevilFruits из Backpack
    local fruits = {}
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") or item:IsA("Model") or item:IsA("HopperBin") then
                table.insert(fruits, item.Name)
            end
        end
    end
    data.BackpackFruits = fruits

    -- GUI-инвентарь (PlayerGui.Backpack.Inventory)
    local guiList = {}
    local guiBackpack = playerGui:FindFirstChild("Backpack")
    if guiBackpack then
        local inventory = guiBackpack:FindFirstChild("Inventory")
        if inventory then
            for _, child in ipairs(inventory:GetChildren()) do
                -- попытаемся взять текстовые значения и имена
                if child:IsA("TextLabel") and child.Text and child.Text ~= "" then
                    table.insert(guiList, child.Text)
                elseif child.Name and child.Name ~= "" then
                    table.insert(guiList, child.Name)
                end
            end
        end
    end
    data.GUIInventory = guiList

    -- ReplicatedStorage inventory (без вызова RemoteFunction)
    data.ReplicatedInventory = collectFromReplicatedStorage()

    -- Stats (как раньше)
    data.Stats = {}
    local statsRoot = getNested(player, {"Data", "Stats"}) or getNested(player, {"Stats"}) or getNested(player, {"Data"})
    if statsRoot then
        if statsRoot:FindFirstChild("Stats") then statsRoot = statsRoot:FindFirstChild("Stats") end
        for _, stat in ipairs(statsRoot:GetChildren()) do
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

    return data
end

-- ---------- UI ----------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AccountInfoUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 520, 0, 420)
frame.Position = UDim2.new(0, 12, 0, 12)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -12, 0, 36)
title.Position = UDim2.new(0, 6, 0, 6)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.Text = "Account Info (локально) — показывает фрукты из ReplicatedStorage"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local function makeLabel(y)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 20)
    lbl.Position = UDim2.new(0, 6, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 16
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    return lbl
end

local nameLabel = makeLabel(52)
local beliLabel = makeLabel(76)
local raceLabel = makeLabel(100)
local backpackLabel = makeLabel(124)
local guiInvLabel = makeLabel(148)
local repInvTitle = makeLabel(176)
repInvTitle.Font = Enum.Font.SourceSansBold

local repInvBox = Instance.new("TextLabel")
repInvBox.Size = UDim2.new(1, -12, 0, 120)
repInvBox.Position = UDim2.new(0, 6, 0, 200)
repInvBox.BackgroundTransparency = 1
repInvBox.Font = Enum.Font.Code
repInvBox.TextSize = 14
repInvBox.TextXAlignment = Enum.TextXAlignment.Left
repInvBox.TextYAlignment = Enum.TextYAlignment.Top
repInvBox.TextWrapped = true
repInvBox.Parent = frame

local statsTitle = makeLabel(328)
statsTitle.Font = Enum.Font.SourceSansBold
statsTitle.Text = "Stats:"

local statsBox = Instance.new("TextLabel")
statsBox.Size = UDim2.new(1, -12, 0, 60)
statsBox.Position = UDim2.new(0, 6, 0, 352)
statsBox.BackgroundTransparency = 1
statsBox.Font = Enum.Font.Code
statsBox.TextSize = 14
statsBox.TextXAlignment = Enum.TextXAlignment.Left
statsBox.TextYAlignment = Enum.TextYAlignment.Top
statsBox.TextWrapped = true
statsBox.Parent = frame

local statusLabel = makeLabel(420)
statusLabel.Position = UDim2.new(0, 6, 0, 416)
statusLabel.Font = Enum.Font.SourceSansItalic
statusLabel.TextSize = 12
statusLabel.Text = "Последнее обновление: —"

-- Обновление UI
local function updateUI()
    local ok, data = pcall(collectPlayerData)
    if not ok then
        statusLabel.Text = "Ошибка при сборе данных: " .. tostring(data)
        return
    end

    nameLabel.Text = "Игрок: " .. tostring(data.Name or "—")
    beliLabel.Text = "Beli: " .. tostring(data.Beli or 0)
    raceLabel.Text = "Race: " .. tostring(data.Race or "—")
    backpackLabel.Text = "Backpack (инструменты): " .. ( (#(data.BackpackFruits or {})>0) and table.concat(data.BackpackFruits, ", ") or "Нет" )
    guiInvLabel.Text = "GUI Inventory: " .. ( (#(data.GUIInventory or {})>0) and table.concat(data.GUIInventory, ", ") or "Нет" )

    repInvBox.Text = "ReplicatedStorage (найдено):\n" .. ( (#(data.ReplicatedInventory or {})>0) and ("  "..table.concat(data.ReplicatedInventory, "\n  ")) or "  (не найдено)")

    local statsLines = {}
    for k, v in pairs(data.Stats or {}) do
        table.insert(statsLines, string.format("%s — Exp: %s  Lvl: %s", tostring(k), tostring(v.Exp or 0), tostring(v.Level or 0)))
    end
    statsBox.Text = (#statsLines>0) and table.concat(statsLines, "\n") or "  (Stats не найдены)"

    statusLabel.Text = "Последнее обновление: " .. os.date("%Y-%m-%d %H:%M:%S")
end

updateUI()

-- Автообновление
task.spawn(function()
    while true do
        task.wait(3)
        if not player or not player.Parent then break end
        updateUI()
    end
end)
