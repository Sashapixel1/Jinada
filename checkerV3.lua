-- AccountChecker (LocalScript)
-- Поместить в StarterPlayer > StarterPlayerScripts
-- Собирает локальную информацию об аккаунте и показывает в GUI.
-- НЕ делает внешних HTTP-запросов.

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ---------- Вспомогательные функции ----------
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

-- ---------- Новый сканер GUI фруктов ----------
local function scanPlayerGUIFruits()
	local fruitsFound = {}
	local pathsToCheck = {
		"Inventory",
		"FruitInventory",
		"InventoryContainer",
	}

	local function addFruit(name)
		if type(name) == "string" and name:match("%w+%-%w+") then
			fruitsFound[name] = true
		end
	end

	for _, pathName in ipairs(pathsToCheck) do
		local folder = playerGui:FindFirstChild(pathName)
		if folder then
			for _, obj in ipairs(folder:GetDescendants()) do
				-- Проверяем текстовые поля
				if obj:IsA("TextLabel") or obj:IsA("TextButton") then
					local text = obj.Text or ""
					if text:match("%w+%-%w+") then
						addFruit(text)
					end
				end
				-- Иногда название хранится в атрибуте или свойстве Name
				if obj.Name and obj.Name:match("%w+%-%w+") then
					addFruit(obj.Name)
				end
				-- Иногда в ObjectValue / StringValue
				if obj:IsA("StringValue") and type(obj.Value) == "string" and obj.Value:match("%w+%-%w+") then
					addFruit(obj.Value)
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
	if rn and type(rn.
