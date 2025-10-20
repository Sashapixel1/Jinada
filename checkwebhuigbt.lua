-- AccountInfo GUI — безопасная версия
-- Показывает данные о персонаже и копирует их в буфер обмена

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Вспомогательная функция
local function getNested(root, parts)
	if not root then return nil end
	local cur = root
	for _, name in ipairs(parts) do
		cur = cur:FindFirstChild(name)
		if not cur then return nil end
	end
	return cur
end

-- Сбор информации об игроке
local function collectPlayerData()
	local data = {}
	data.Name = player.Name
	data.Beli = 0
	data.Race = "Unknown"
	data.Stats = {}
	data.BackpackFruits = {}
	data.GUIInventory = {}
	data.ReplicatedInventory = {}

	-- Beli
	local beliNode = getNested(player, {"Data", "Beli"})
	if beliNode and beliNode.Value then data.Beli = beliNode.Value end

	-- Race
	local raceNode = getNested(player, {"Data", "Race"})
	if raceNode and raceNode.Value then data.Race = raceNode.Value end

	-- Backpack
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") or item:IsA("Model") then
				table.insert(data.BackpackFruits, item.Name)
			end
		end
	end

	-- GUI Inventory
	local guiBackpack = playerGui:FindFirstChild("Backpack")
	if guiBackpack then
		local inv = guiBackpack:FindFirstChild("Inventory")
		if inv then
			for _, child in ipairs(inv:GetChildren()) do
				table.insert(data.GUIInventory, child.Name)
			end
		end
	end

local function scanReplicatedStorage()
    local RS = ReplicatedStorage
    local found = {}
    local function add(name)
        if type(name) == "string" and name ~= "" and #name < 50 then
            found[name] = true
        end
    end

    local directCandidates = {"Inventory", "PlayerInventory", "DevilFruits", "Fruits", "Backpack", "Items"}
    for _, cname in ipairs(directCandidates) do
        local node = RS:FindFirstChild(cname)
        if node then
            for _, child in ipairs(node:GetChildren()) do
                if child:IsA("Tool") or child:IsA("Model") then
                    add(child.Name)
                elseif child:IsA("StringValue") then
                    add(child.Value)
                elseif child:IsA("ObjectValue") and child.Value then
                    add(child.Value.Name)
                end
            end
        end
    end

    local MAX_CHECK = 1500
    local checked = 0
    for _, inst in ipairs(RS:GetDescendants()) do
        checked += 1
        if checked > MAX_CHECK then break end

        if inst:IsA("Tool") or inst:IsA("Model") then
            add(inst.Name)
        elseif inst:IsA("StringValue") then
            add(inst.Value)
        elseif inst:IsA("ObjectValue") and inst.Value then
            add(inst.Value.Name)
        elseif inst.Name:lower():find("fruit") or inst.Name:find("devil") then
            add(inst.Name)
        end
    end

    local out = {}
    for k,_ in pairs(found) do table.insert(out, k) end
    table.sort(out)
    return out
end

	-- Stats
	local stats = getNested(player, {"Data", "Stats"})
	if stats then
		for _, s in ipairs(stats:GetChildren()) do
			local exp = s:FindFirstChild("Exp")
			local lvl = s:FindFirstChild("Level")
			data.Stats[s.Name] = {
				Exp = exp and exp.Value or 0,
				Level = lvl and lvl.Value or 0
			}
		end
	end

	return data
end

-- Конвертация таблицы в текст
local function formatData(data)
	local text = {}
	table.insert(text, "=== Account Info ===")
	table.insert(text, "Player: " .. data.Name)
	table.insert(text, "Beli: " .. tostring(data.Beli))
	table.insert(text, "Race: " .. tostring(data.Race))
	table.insert(text, "\n-- Backpack Fruits --")
	table.insert(text, table.concat(data.BackpackFruits, ", "))
	table.insert(text, "\n-- GUI Inventory --")
	table.insert(text, table.concat(data.GUIInventory, ", "))
	table.insert(text, "\n-- ReplicatedStorage Fruits --")
	table.insert(text, table.concat(data.ReplicatedInventory, ", "))
	table.insert(text, "\n-- Stats --")
	for name, st in pairs(data.Stats) do
		table.insert(text, string.format("%s: Exp %s, Level %s", name, st.Exp, st.Level))
	end
	return table.concat(text, "\n")
end

-- ---------- UI ----------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AccountInfoUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 500, 0, 420)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundTransparency = 1
title.Text = "Account Info"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 22
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = frame

-- Поле для Webhook
local webhookBox = Instance.new("TextBox")
webhookBox.PlaceholderText = "Webhook URL (необязательно)"
webhookBox.Size = UDim2.new(1, -20, 0, 28)
webhookBox.Position = UDim2.new(0, 10, 0, 46)
webhookBox.ClearTextOnFocus = false
webhookBox.Text = ""
webhookBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
webhookBox.TextColor3 = Color3.fromRGB(255, 255, 255)
webhookBox.Parent = frame

-- Кнопка копирования
local copyButton = Instance.new("TextButton")
copyButton.Text = "Скопировать отчёт"
copyButton.Size = UDim2.new(0, 180, 0, 32)
copyButton.Position = UDim2.new(0, 10, 0, 84)
copyButton.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
copyButton.TextColor3 = Color3.new(1, 1, 1)
copyButton.Font = Enum.Font.SourceSansBold
copyButton.TextSize = 18
copyButton.Parent = frame

-- Кнопка "Отправить"
local sendButton = Instance.new("TextButton")
sendButton.Text = "Отправить отчёт (в консоль)"
sendButton.Size = UDim2.new(0, 220, 0, 32)
sendButton.Position = UDim2.new(0, 200, 0, 84)
sendButton.BackgroundColor3 = Color3.fromRGB(80, 255, 120)
sendButton.TextColor3 = Color3.new(0, 0, 0)
sendButton.Font = Enum.Font.SourceSansBold
sendButton.TextSize = 18
sendButton.Parent = frame

-- Поле с отчётом
local reportBox = Instance.new("TextBox")
reportBox.MultiLine = true
reportBox.TextWrapped = false
reportBox.ClearTextOnFocus = false
reportBox.Size = UDim2.new(1, -20, 1, -130)
reportBox.Position = UDim2.new(0, 10, 0, 126)
reportBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
reportBox.TextColor3 = Color3.new(1, 1, 1)
reportBox.Font = Enum.Font.Code
reportBox.TextSize = 14
reportBox.Text = ""
reportBox.TextYAlignment = Enum.TextYAlignment.Top
reportBox.Parent = frame

-- Обновление данных
local function updateReport()
	local data = collectPlayerData()
	local formatted = formatData(data)
	reportBox.Text = formatted
	return formatted
end

updateReport()

copyButton.MouseButton1Click:Connect(function()
	local text = updateReport()
	if setclipboard then
		setclipboard(text)
		copyButton.Text = "✅ Скопировано!"
	else
		copyButton.Text = "Clipboard недоступен"
	end
	task.wait(2)
	copyButton.Text = "Скопировать отчёт"
end)

sendButton.MouseButton1Click:Connect(function()
	local text = updateReport()
	local webhook = webhookBox.Text
	print("[DEBUG] Webhook (не используется):", webhook)
	print("[DEBUG] Отчёт:\n" .. text)
	sendButton.Text = "✅ Напечатано в консоли!"
	task.wait(2)
	sendButton.Text = "Отправить отчёт (в консоль)"
end)

-- Автообновление каждые 5 сек
task.spawn(function()
	while true do
		task.wait(5)
		updateReport()
	end
end)
