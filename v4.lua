-- AccountChecker (LocalScript)
-- Поместить в StarterPlayer > StarterPlayerScripts
-- Собирает локальную информацию об аккаунте и показывает в GUI.
-- НЕ делает внешних HTTP-запросов.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ---------- Вспомогательные функции ----------
local function safeFind(parent, name)
	if not parent then return nil end
	return parent:FindFirstChild(name)
end

local function getNested(root, parts)
	if not root then return nil end
	local cur = root
	for _, name in ipairs(parts) do
		if not cur then return nil end
		cur = cur:FindFirstChild(name)
		if not cur then return nil end
	end
	return cur
end

-- ---------- Новый вариант scanReplicatedStorage ----------
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

-- ---------- Остальной код без изменений ----------

local function collectPlayerData()
	local data = {}
	data.Name = player.Name or "Unknown"
	data.Beli = 0
	data.Race = "Unknown"
	data.BackpackFruits = {}
	data.GUIInventory = {}
	data.ReplicatedInventory = {}
	data.Stats = {}

	local leader = player:FindFirstChild("leaderstats")
	if leader then
		local b = leader:FindFirstChild("Beli") or leader:FindFirstChild("beli")
		if b and type(b.Value) ~= "nil" then data.Beli = b.Value end
	end
	local bnode = getNested(player, {"Data", "Beli"}) or getNested(player, {"Data", "beli"})
	if bnode and type(bnode.Value) ~= "nil" then data.Beli = bnode.Value end

	if player.GetAttribute then
		local r = player:GetAttribute("Race") or player:GetAttribute("race")
		if r then data.Race = r end
	end
	local rn = getNested(player, {"Data", "Race"}) or getNested(player, {"Data", "race"})
	if rn and type(rn.Value) ~= "nil" then data.Race = rn.Value end

	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, it in ipairs(backpack:GetChildren()) do
			if it:IsA("Tool") or it:IsA("Model") or it:IsA("HopperBin") then
				table.insert(data.BackpackFruits, it.Name)
			end
		end
	end

	local guiBack = playerGui:FindFirstChild("Backpack")
	if guiBack then
		local inv = guiBack:FindFirstChild("Inventory")
		if inv then
			for _, ch in ipairs(inv:GetChildren()) do
				if ch:IsA("TextLabel") and ch.Text and ch.Text ~= "" then
					table.insert(data.GUIInventory, ch.Text)
				elseif ch.Name and ch.Name ~= "" then
					table.insert(data.GUIInventory, ch.Name)
				end
			end
		end
	end

	local ok, repList = pcall(scanReplicatedStorage)
	if ok and type(repList) == "table" then
		data.ReplicatedInventory = repList
	else
		data.ReplicatedInventory = {}
	end

	local statsRoot = getNested(player, {"Data", "Stats"}) or getNested(player, {"Stats"}) or getNested(player, {"Data"})
	if statsRoot then
		if statsRoot:FindFirstChild("Stats") then statsRoot = statsRoot:FindFirstChild("Stats") end
		for _, s in ipairs(statsRoot:GetChildren()) do
			local expVal, lvlVal = 0, 0
			local eObj = s:FindFirstChild("Exp") or s:FindFirstChild("Experience") or s:FindFirstChild("exp")
			local lObj = s:FindFirstChild("Level") or s:FindFirstChild("level")
			if eObj and type(eObj.Value) ~= "nil" then expVal = eObj.Value end
			if lObj and type(lObj.Value) ~= "nil" then lvlVal = lObj.Value end
			if expVal ~= 0 or lvlVal ~= 0 or #s:GetChildren() > 0 then
				data.Stats[s.Name] = { Exp = expVal, Level = lvlVal }
			end
		end
	end

	return data
end

local function formatData(data)
	local lines = {}
	table.insert(lines, ("=== Account Info — %s ==="):format(tostring(data.Name or "Unknown")))
	table.insert(lines, ("Beli: %s"):format(tostring(data.Beli or 0)))
	table.insert(lines, ("Race: %s"):format(tostring(data.Race or "Unknown")))
	table.insert(lines, "")

	table.insert(lines, "-- Backpack (tools) --")
	if #data.BackpackFruits > 0 then
		table.insert(lines, table.concat(data.BackpackFruits, ", "))
	else
		table.insert(lines, "(пусто)")
	end
	table.insert(lines, "")

	table.insert(lines, "-- GUI Inventory --")
	if #data.GUIInventory > 0 then
		table.insert(lines, table.concat(data.GUIInventory, ", "))
	else
		table.insert(lines, "(не найдено)")
	end
	table.insert(lines, "")

	table.insert(lines, "-- ReplicatedStorage (scan) --")
	if #data.ReplicatedInventory > 0 then
		for _, v in ipairs(data.ReplicatedInventory) do table.insert(lines, "- "..v) end
	else
		table.insert(lines, "(не найдено)")
	end
	table.insert(lines, "")

	table.insert(lines, "-- Stats --")
	local anyStats = false
	for k,v in pairs(data.Stats or {}) do
		anyStats = true
		table.insert(lines, string.format("%s — Exp: %s  Level: %s", tostring(k), tostring(v.Exp or 0), tostring(v.Level or 0)))
	end
	if not anyStats then table.insert(lines, "(Stats не найдены)") end

	return table.concat(lines, "\n")
end

-- ---------- UI ----------
local function createUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AccountCheckerUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 50
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 640, 0, 480)
	frame.Position = UDim2.new(0, 12, 0, 12)
	frame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 0, 36)
	title.Position = UDim2.new(0, 12, 0, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 20
	title.TextColor3 = Color3.fromRGB(240,240,240)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Account Checker (локально)"
	title.Parent = frame

	local webhookBox = Instance.new("TextBox")
	webhookBox.Size = UDim2.new(1, -24, 0, 28)
	webhookBox.Position = UDim2.new(0, 12, 0, 52)
	webhookBox.BackgroundColor3 = Color3.fromRGB(45,45,45)
	webhookBox.TextColor3 = Color3.fromRGB(235,235,235)
	webhookBox.PlaceholderText = "Webhook URL (необязательно; не используется автоматически)"
	webhookBox.ClearTextOnFocus = false
	webhookBox.Parent = frame

	local refreshBtn = Instance.new("TextButton")
	refreshBtn.Size = UDim2.new(0, 140, 0, 34)
	refreshBtn.Position = UDim2.new(0, 12, 0, 92)
	refreshBtn.Text = "Обновить"
	refreshBtn.Font = Enum.Font.SourceSansBold
	refreshBtn.TextSize = 16
	refreshBtn.Parent = frame

	local copyBtn = Instance.new("TextButton")
	copyBtn.Size = UDim2.new(0, 190, 0, 34)
	copyBtn.Position = UDim2.new(0, 164, 0, 92)
	copyBtn.Text = "Скопировать отчёт"
	copyBtn.Font = Enum.Font.SourceSansBold
	copyBtn.TextSize = 16
	copyBtn.Parent = frame

	local consoleBtn = Instance.new("TextButton")
	consoleBtn.Size = UDim2.new(0, 210, 0, 34)
	consoleBtn.Position = UDim2.new(0, 366, 0, 92)
	consoleBtn.Text = "Показать в Output"
	consoleBtn.Font = Enum.Font.SourceSans
	consoleBtn.TextSize = 16
	consoleBtn.Parent = frame

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -24, 1, -150)
	scroll.Position = UDim2.new(0, 12, 0, 138)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.ScrollBarThickness = 8
	scroll.BackgroundColor3 = Color3.fromRGB(20,20,20)
	scroll.Parent = frame

	local uiList = Instance.new("UIListLayout")
	uiList.Padding = UDim.new(0, 6)
	uiList.Parent = scroll

	local content = Instance.new("TextLabel")
	content.Size = UDim2.new(1, -20, 0, 10)
	content.Position = UDim2.new(0, 10, 0, 8)
	content.BackgroundTransparency = 1
	content.Font = Enum.Font.Code
	content.TextSize = 14
	content.TextColor3 = Color3.fromRGB(225,225,225)
	content.TextWrapped = true
	content.TextYAlignment = Enum.TextYAlignment.Top
	content.Text = ""
	content.Parent = scroll

	local status = Instance.new("TextLabel")
	status.Size = UDim2.new(1, -24, 0, 20)
	status.Position = UDim2.new(0, 12, 1, -34)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.SourceSansItalic
	status.TextSize = 12
	status.TextColor3 = Color3.fromRGB(180,180,180)
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Text = "Последнее обновление: —"
	status.Parent = frame

	local function refresh()
		local ok, data = pcall(collectPlayerData)
		if not ok or not data then
			content.Text = "Ошибка при сборе данных: "..tostring(data)
			status.Text = "Ошибка: "..tostring(data)
			return
		end
		local txt = formatData(data)
		content.Text = txt

		local textBounds = content.TextBounds
		local height = math.max(textBounds.Y + 24, 20)
		content.Size = UDim2.new(1, -20, 0, height)
		scroll.CanvasSize = UDim2.new(0, 0, 0, height + 32)

		status.Text = "Последнее обновление: "..os.date("%Y-%m-%d %H:%M:%S")
	end

	refreshBtn.MouseButton1Click:Connect(function()
		refresh()
		refreshBtn.Text = "Обновлено"
		task.delay(1.2, function() if refreshBtn then refreshBtn.Text = "Обновить" end end)
	end)

	copyBtn.MouseButton1Click:Connect(function()
		refresh()
		local txt = content.Text or ""
		if type(setclipboard) == "function" then
			local suc, err = pcall(function() setclipboard(txt) end)
			if suc then
				copyBtn.Text = "✅ Скопировано"
			else
				copyBtn.Text = "Ошибка"
				warn("setclipboard error:", err)
			end
		else
			copyBtn.Text = "Clipboard недоступен"
		end
		task.delay(1.6, function() if copyBtn then copyBtn.Text = "Скопировать отчёт" end end)
	end)

	consoleBtn.MouseButton1Click:Connect(function()
		refresh()
		print("=== Account Info (client) ===")
		print(content.Text)
		consoleBtn.Text = "✅ Напечатано"
		task.delay(1.4, function() if consoleBtn then consoleBtn.Text = "Показать в Output" end end)
	end)

	refresh()
	task.spawn(function()
		while player and player.Parent do
			task.wait(5)
			pcall(refresh)
		end
	end)
end

local ok, err = pcall(createUI)
if not ok then
	warn("Не удалось создать AccountChecker UI: ", err)
end
