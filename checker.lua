-- AccountInfoUI (LocalScript)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("Players").LocalPlayer.PlayerGui.Backpack.Inventory 
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local sendEvent = ReplicatedStorage:WaitForChild("SendWebhookEvent")

-- Сбор данных: используем несколько мест, которые ты указал
local function collectPlayerData()
    local data = {}
    data.Name = player.Name

    -- Beli: пробуем leaderstats, потом Data.Beli
    local beliVal
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local b = leaderstats:FindFirstChild("Beli")
        if b and b.Value then beliVal = b.Value end
    end
    if not beliVal then
        local bnode = getNested(player, {"Data", "stats", "Beli"})
        if bnode and bnode.Value ~= nil then beliVal = bnode.Value end
    end
    data.Beli = beliVal or 0

    -- Race (возможно атрибут или Data.Race)
    local race = player:GetAttribute and player:GetAttribute("Race")
    if not race then
        local rn = getNested(player, {"Data", "stats", "Race"})
        if rn then
            race = rn.Value or tostring(rn)
        end
    end
    data.Race = race or "Unknown"

    -- DevilFruits: попробуем Data.DevilFruits (Folder/String/Value) или Backpack инструменты с названиями фруктов
    local fruits = {}

    -- 1) Проверка Data.DevilFruits
    local df = getNested(player, {"Data", "stats", "DevilFruits"})
    if df then
        -- если это Folder — перечислим имена дочерних объектов
        if df:IsA("Folder") then
            for _, child in ipairs(df:GetChildren()) do
                table.insert(fruits, child.Name)
            end
        else
            -- может быть StringValue или Value
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

    -- 2) Проверка Backpack инструментов (инструменты в рюкзаке)
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") or item:IsA("HopperBin") then
                table.insert(fruits, item.Name)
            end
        end
    end

    -- Убираем дубликаты
    local unique = {}
    for _, v in ipairs(fruits) do unique[v] = true end
    local fruitList = {}
    for k, _ in pairs(unique) do table.insert(fruitList, k) end
    data.DevilFruits = fruitList

    -- Соберём Stats: путь "Data -> Stats -> <statName> -> Exp, Level"
    data.Stats = {}
    local statsRoot = getNested(player, {"Data", "Stats"}) or getNested(player, {"Stats"})
    if statsRoot then
        for _, stat in ipairs(statsRoot:GetChildren()) do
            if stat:IsA("Folder") or stat:IsA("Instance") then
                local statName = stat.Name
                local exp = nil
                local lvl = nil
                local eObj = stat:FindFirstChild("Exp") or stat:FindFirstChild("Experience")
                if eObj and eObj.Value ~= nil then exp = eObj.Value end
                local lObj = stat:FindFirstChild("Level")
                if lObj and lObj.Value ~= nil then lvl = lObj.Value end
                data.Stats[statName] = { Exp = exp or 0, Level = lvl or 0 }
            end
        end
    else
        -- Если нет Stats, попробуем найти некоторые по именам, которые ты указал
        local names = {"Demon Fruits", "Gun", "Melee", "Sword"}
        for _, name in ipairs(names) do
            local node = getNested(player, {"Data", "Stats", name}) or getNested(player, {"Data", name})
            if node then
                local exp = (node:FindFirstChild("Exp") and node.Exp.Value) or 0
                local lvl = (node:FindFirstChild("Level") and node.Level.Value) or 0
                data.Stats[name] = { Exp = exp, Level = lvl }
            end
        end
    end

    return data
end

-- UI: простой интерфейс с полем для Webhook и кнопками
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AccountInfoUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 420, 0, 320)
frame.Position = UDim2.new(0, 18, 0, 18)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -12, 0, 34)
title.Position = UDim2.new(0, 6, 0, 6)
title.BackgroundTransparency = 1
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.Text = "Account Info & Discord Webhook"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local function makeLabel(yOffset)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 20)
    lbl.Position = UDim2.new(0, 6, 0, yOffset)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 16
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    return lbl
end

local infoStartY = 46
local nameLabel = makeLabel(infoStartY + 0)
local beliLabel = makeLabel(infoStartY + 24)
local raceLabel = makeLabel(infoStartY + 48)
local fruitsLabel = makeLabel(infoStartY + 72)
local statsLabel = makeLabel(infoStartY + 96)
statsLabel.TextWrapped = true

-- Webhook input
local webhookBox = Instance.new("TextBox")
webhookBox.Size = UDim2.new(1, -12, 0, 26)
webhookBox.Position = UDim2.new(0, 6, 0, 200)
webhookBox.BackgroundTransparency = 0.1
webhookBox.ClearTextOnFocus = false
webhookBox.PlaceholderText = "Вставьте Discord Webhook URL сюда"
webhookBox.Text = ""
webhookBox.Font = Enum.Font.SourceSans
webhookBox.TextSize = 14
webhookBox.Parent = frame

local sendBtn = Instance.new("TextButton")
sendBtn.Size = UDim2.new(0, 120, 0, 30)
sendBtn.Position = UDim2.new(0, 6, 0, 236)
sendBtn.Text = "Отправить на Webhook"
sendBtn.Font = Enum.Font.SourceSansBold
sendBtn.TextSize = 14
sendBtn.Parent = frame

local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(0, 120, 0, 30)
refreshBtn.Position = UDim2.new(0, 132, 0, 236)
refreshBtn.Text = "Обновить инфо"
refreshBtn.Font = Enum.Font.SourceSans
refreshBtn.TextSize = 14
refreshBtn.Parent = frame

local statusLabel = makeLabel(280)
statusLabel.Text = ""

-- Обновление UI
local function updateUI()
    local d = collectPlayerData()
    nameLabel.Text = "Игрок: " .. tostring(d.Name or "—")
    beliLabel.Text = "Beli: " .. tostring(d.Beli or 0)
    raceLabel.Text = "Race: " .. tostring(d.Race or "—")
    fruitsLabel.Text = "Devil Fruits: " .. ( (#d.DevilFruits>0) and table.concat(d.DevilFruits, ", ") or "Нет" )

    local statsText = "Stats:\n"
    for k, v in pairs(d.Stats or {}) do
        statsText = statsText .. string.format("  %s — Exp: %s  Level: %s\n", tostring(k), tostring(v.Exp or 0), tostring(v.Level or 0))
    end
    statsLabel.Text = statsText
end

-- отправка серверу
local function sendToWebhook(webhookUrl, payload)
    if not webhookUrl or webhookUrl == "" then
        statusLabel.Text = "Введите URL Webhook"
        return
    end
    statusLabel.Text = "Отправка..."
    -- Отправляем: аргументы: player не нужно передавать — сервер получит авто. Но RemoteEvent требует: FireServer(arg1, arg2)
    sendEvent:FireServer(webhookUrl, payload)
end

-- Ответ от сервера (результат отправки)
sendEvent.OnClientEvent:Connect(function(success, message)
    if success then
        statusLabel.Text = "Отправлено успешно"
    else
        statusLabel.Text = "Ошибка: " .. tostring(message)
    end
end)

-- Кнопки
refreshBtn.MouseButton1Click:Connect(function()
    updateUI()
    statusLabel.Text = "Обновлено"
end)

sendBtn.MouseButton1Click:Connect(function()
    local d = collectPlayerData()
    sendToWebhook(webhookBox.Text, d)
end)

-- Начальное обновление
updateUI()

-- Дополнительно: обновлять UI каждые 5 секунд (чтобы видеть динамику)
spawn(function()
    while true do
        wait(5)
        updateUI()
    end
end)
