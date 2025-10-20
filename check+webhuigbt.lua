-- AccountInfo_Fixed (LocalScript)
-- Поместить в StarterPlayer > StarterPlayerScripts
-- Надёжная версия: собирает локальные данные игрока и показывает в GUI. Копирование в буфер (setclipboard) — опционально.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Безопасный поиск вложенных дочерних объектов по списку имён
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

-- Проход по ReplicatedStorage с простыми эвристиками (без вызова рему́тов)
local function scanReplicatedStorage()
	local found = {}
	local function add(v)
		if type(v) == "string" and v ~= "" then
			found[v] = true
		end
	end

	-- быстрые кандидаты по имени
	local candidates = {"Inventory", "PlayerInventory", "DevilFruits", "Fruits", "Backpack"}
	for _, name in ipairs(candidates) do
		local node = ReplicatedStorage:FindFirstChild(name)
		if node then
			for _, c in ipairs(node:GetChildren()) do
				if c:IsA("Tool") or c:IsA("Model") then
					add(c.Name)
				elseif c:IsA("StringValue") or c:IsA("ObjectValue") or c:IsA("ValueBase") then
					add(tostring(c.Value or c.Name))
				else
					add(c.Name)
				end
			end
		end
	end

	-- ограниченный обход дерева (глубина 2)
	local function walk(inst, depth)
		if depth > 2 then return end
		for _, child in ipairs(inst:GetChildren()) do
			local lname = child.Name:lower()
			if lname:find("fruit") or lname:find("devil") or lname:find("inventory") or lname:find("fruit") then
				for _, c2 in ipairs(child:GetChildren()) do
					if c2:IsA("Tool") or c2:IsA("
