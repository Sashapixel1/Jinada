-- AccountChecker (LocalScript)
-- Поместить в StarterPlayer > StarterPlayerScripts
-- Собирает локальную информацию об аккаунте и показывает в GUI.
-- НЕ делает внешних HTTP-запросов.

local Players = game:GetService("Players")
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

-- ---------- Новый сканер инвентаря (по PlayerGui) ----------
local function scanPlayerGUIFruits()
	local fruitsFound = {}
	local pathsToCheck = {
		"Inventory",
		"FruitInventory",
		"InventoryContainer",
	}

	local function addFruit(name)
		if type(name) == "string" and name:match("^%w+%-%w+$") then
			fruitsFound[name] = true
		end
	end

	for _, pathName in ipairs(pathsToCheck) do
		local folder = playerGui:FindFirstChild(pathName)
		if folder then
			for _, obj in ipairs(folder:GetDescendants()) do
				-- Проверяем текст или имя
				if obj:IsA("TextLabel") or obj:IsA("TextButton") then
					if obj.Text and obj.Text:match("^%w+%-%w+$") then
						addFruit(obj.Text)
					end
				elseif obj.Name and obj.Name:match("^%w+%-%w+$") then
					addFruit(obj.Name)
				end
			end
		end
	end

	local fruits = {}
	for name in pairs(fruitsFound) do
		table.insert(fruits, name)
	end
	table.sort(fruits)
	return fruits
end

-- ---------- Сбор данных ----------
local function collectPlayerData()
	local data = {}
	data.Name = player.Name or "Unknown"
	data.Beli = 0
	data.Race = "Unknown"
	data.BackpackFruits = {}
	data.GUIFruits = {}
	data.Stats = {}

	-- Beli
	local leader = player:FindFirstChild("leaderstats")
	if leader then
		local b = leader:FindFirstChild("Beli") or leader:FindFirstChild("beli")
		if b and type(b.Value) ~= "nil" then data.Beli = b.Value end
	end
	local bnode = getNested(player, {"Data", "Beli"}) or getNested(player, {"Data", "beli"})
	if bnode and type(bnode.Value) ~= "nil" then data.Beli = bnode.Value end

	-- Race
	if player.GetAttribute then
		local r = player:GetAttribute("Race") or player:GetAttribute("race")
		if r then data.Race = r end
	end
	local rn = getNested(player, {"Data", "Race"}) or getNested(player, {"Data", "race"})
	if rn and type(rn.Value) ~= "nil" then data.Race = rn.Value end

	-- Backpack (инвентарь инструментов)
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, it in ipairs(backpack:GetChildren()) do
			if it:IsA("Tool") or it:IsA("Model") then
				if it.Name:match("^%w+%-%w+$") then
					table.insert(data.BackpackFruits, it.Name)
				end
			end
		end
	end

	-- GUI (реальные фрукты из интерфейса)
	local ok, fruits = pcall(scanPlayerGUIFruits)
	if ok and fruits then
		data.GUIFruits = fruits
	else
		data.GUIFruits = {}
	end

	-- Stats
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

-- ---------- Формат отчёта ----------
local function formatData(data)
	local lines = {}
	table.insert(lines, ("=== Account Info — %s ==="):format(tostring(data.Name or "Unknown")))
	table.insert(lines, ("Beli: %s"):format(tostring(data.Beli or 0)))
	table.insert(lines, ("Race: %s"):format(tostring(data.Race or "Unknown")))
	table.insert(lines, "")

	table.insert(lines, "-- Backpack (фрукты) --")
	if #data.BackpackFruits > 0 then
		table.insert(lines, table.concat(data.BackpackFruits, ", "))
	else
		table.insert(lines, "(пусто)")
	end
	table.insert(lines, "")

	table.insert(lines, "-- GUI Inventory (реальные фрукты) --")
	if #data.GUIFruits > 0 then
		for _, v in ipairs(data.GUIFruits) do
			table.insert(lines, "- " .. v)
		end
	else
		table.insert(lines, "(фрукты не найдены в интерфейсе)")
	end
	table.insert(lines, "")

	table.insert(lines, "-- Stats --")
	local anyStats = false
	for k, v in pairs(data.Stats or {}) do
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

	local refreshBtn = Instance.new("TextButton")
	refreshBtn.Size = UDim2.new(0, 140, 0, 34)
	refreshBtn.Position = UDim2.new(0, 12, 0, 52)
	refreshBtn.Text = "Обновить"
	refreshBtn.Font = Enum.Font.SourceSansBold
	refreshBtn.TextSize = 16
	refreshBtn.Parent = frame

	local copyBtn = Instance.new("TextButton")
	copyBtn.Size = UDim2.new(0, 190, 0, 34)
	copyBtn.Position = UDim2.new(0, 164, 0, 52)
	copyBtn.Text = "Скопировать отчёт"
	copyBtn.Font = Enum.Font.SourceSansBold
	copyBtn.TextSize = 16
	copyBtn.Parent = frame

	local consoleBtn = Instance.new("TextButton")
	consoleBtn.Size = UDim2.new(0, 210, 0, 34)
	consoleBtn.Position = UDim2.new(0, 366, 0, 52)
	consoleBtn.Text = "Показать в Output"
	consoleBtn.Font = Enum.Font.SourceSans
	consoleBtn.TextSize = 16
	consoleBtn.Parent = frame

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -24, 1, -100)
	scroll.Position = UDim2.new(0, 12, 0, 100)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.ScrollBarThickness = 8
	scroll.BackgroundColor3 = Color3.fromRGB(20,20,20)
	scroll.Parent = frame

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
	status.Position = UDim2.new(0, 12, 1, -24)
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
			content.Text = "Ошибка при сборе данных: " .. tostring(data)
			status.Text = "Ошибка: " .. tostring(data)
			return
		end
		local txt = formatData(data)
		content.Text = txt

		local textBounds = content.TextBounds
		local height = math.max(textBounds.Y + 24, 20)
		content.Size = UDim2.new(1, -20, 0, height)
		scroll.CanvasSize = UDim2.new(0, 0, 0, height + 32)
		status.Text = "Последнее обновление: " .. os.date("%Y-%m-%d %H:%M:%S")
	end

	refreshBtn.MouseButton1Click:Connect(refresh)
	copyBtn.MouseButton1Click:Connect(function()
		refresh()
		if type(setclipboard) == "function" then
			pcall(function() setclipboard(content.Text) end)
			copyBtn.Text = "✅ Скопировано"
			task.delay(1.2, function() if copyBtn then copyBtn.Text = "Скопировать отчёт" end end)
		end
	end)
	consoleBtn.MouseButton1Click:Connect(function()
		refresh()
		print("=== Account Info (client) ===")
		print(content.Text)
		consoleBtn.Text = "✅ Напечатано"
		task.delay(1.2, function() if consoleBtn then consoleBtn.Text = "Показать в Output" end end)
	end)

	refresh()
end

local ok, err = pcall(createUI)
if not ok then
	warn("Не удалось создать AccountChecker UI: ", err)
end
