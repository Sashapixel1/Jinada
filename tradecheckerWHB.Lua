-- Combined AccountChecker + Webhook sender (LocalScript)
-- Поместить в StarterPlayer > StarterPlayerScripts
-- Собирает локальную информацию об аккаунте, показывает GUI и умеет отправлять отчёт на discord webhook.
-- ВНИМАНИЕ: Замените WEBHOOK_URL на ваш вебхук.

local WEBHOOK_URL = "https://discordapp.com/api/webhooks/ВАШ_WEBHOOK_ID/ВАШ_TOKEN" -- <- поставь сюда URL

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------------------------
-- 💰 ФОРМАТИРОВАНИЕ BELI
--------------------------------------------------------------------
local function formatBeli(amount)
	if type(amount) ~= "number" then return tostring(amount or 0) end
	local s = tostring(math.floor(amount))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
	if formatted:sub(1,1) == "." then formatted = formatted:sub(2) end
	return formatted .. "$"
end

--------------------------------------------------------------------
-- 🍏 МОДУЛЬ ПРОВЕРКИ ФРУКТОВ ЧЕРЕЗ ТРЕЙД
--------------------------------------------------------------------
local function scanFruitsFromTrade()
	local fruitsFound = {}
	local fruitList = {
		"Rocket-Rocket","Spin-Spin","Blade-Blade","Spring-Spring","Bomb-Bomb",
		"Smoke-Smoke","Spike-Spike","Flame-Flame","Falcon-Falcon","Ice-Ice",
		"Sand-Sand","Dark-Dark","Diamond-Diamond","Light-Light","Rubber-Rubber",
		"Barrier-Barrier","Ghost-Ghost","Magma-Magma","Quake-Quake","Buddha-Buddha",
		"Love-Love","Spider-Spider","Sound-Sound","Phoenix-Phoenix","Portal-Portal",
		"Rumble-Rumble","Pain-Pain","Blizzard-Blizzard","Gravity-Gravity","Mammoth-Mammoth",
		"T-Rex-T-Rex","Yeti-Yeti","Dough-Dough","Shadow-Shadow","Venom-Venom",
		"Control-Control","Gas-Gas","Spirit-Spirit","Dragon-Dragon","Leopard-Leopard",
		"Kitsune-Kitsune","Creation-Creation"
	}

	local tradePath = { "Main", "Trade", "Container", "1", "FrameAdd", "Frame" }
	local tradeFrame = playerGui
	for _, part in ipairs(tradePath) do
		tradeFrame = tradeFrame:FindFirstChild(part)
		if not tradeFrame then return {} end
	end

	for _, fruitName in ipairs(fruitList) do
		if tradeFrame:FindFirstChild(fruitName) then
			table.insert(fruitsFound, fruitName)
		end
	end

	return fruitsFound
end

--------------------------------------------------------------------
-- 🔍 УТИЛИТА ДЛЯ ДОСТУПА К ВЛОЖЕННЫМ ОБЪЕКТАМ
--------------------------------------------------------------------
local function getNested(root, parts)
	if not root then return nil end
	local cur = root
	for _, name in ipairs(parts) do
		cur = cur:FindFirstChild(name)
		if not cur then return nil end
	end
	return cur
end

--------------------------------------------------------------------
-- 📦 СБОР ДАННЫХ
--------------------------------------------------------------------
local function collectPlayerData()
	local data = {}
	data.Name = player.Name or "Unknown"
	data.Beli = 0
	data.Race = "Unknown"
	data.BackpackFruits = {}
	data.TradeFruits = {}
	data.Stats = {}

	-- Beli
	local leader = player:FindFirstChild("leaderstats")
	if leader then
		local b = leader:FindFirstChild("Beli") or leader:FindFirstChild("beli")
		if b and typeof(b.Value) == "number" then
			data.Beli = b.Value
		end
	end
	local bnode = getNested(player, {"Data", "Beli"}) or getNested(player, {"Data", "beli"})
	if bnode and typeof(bnode.Value) == "number" then
		data.Beli = bnode.Value
	end

	-- Race
	if player.GetAttribute then
		local r = player:GetAttribute("Race") or player:GetAttribute("race")
		if r then data.Race = r end
	end
	local rn = getNested(player, {"Data", "Race"}) or getNested(player, {"Data", "race"})
	if rn and typeof(rn.Value) == "string" then
		data.Race = rn.Value
	end

	-- Backpack (инвентарь)
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, it in ipairs(backpack:GetChildren()) do
			if it:IsA("Tool") or it:IsA("Model") then
				if it.Name:match("%w+%-%w+") then
					table.insert(data.BackpackFruits, it.Name)
				end
			end
		end
	end

	-- Фрукты через трейд
	local ok, fruits = pcall(scanFruitsFromTrade)
	if ok and fruits then
		data.TradeFruits = fruits
	else
		data.TradeFruits = {}
	end

	-- Stats
	local statsRoot = getNested(player, {"Data", "Stats"}) or getNested(player, {"Stats"}) or getNested(player, {"Data"})
	if statsRoot then
		if statsRoot:FindFirstChild("Stats") then
			statsRoot = statsRoot:FindFirstChild("Stats")
		end
		for _, s in ipairs(statsRoot:GetChildren()) do
			local expVal, lvlVal = 0, 0
			local eObj = s:FindFirstChild("Exp") or s:FindFirstChild("Experience") or s:FindFirstChild("exp")
			local lObj = s:FindFirstChild("Level") or s:FindFirstChild("level")
			if eObj and typeof(eObj.Value) == "number" then expVal = eObj.Value end
			if lObj and typeof(lObj.Value) == "number" then lvlVal = lObj.Value end
			if expVal ~= 0 or lvlVal ~= 0 then
				data.Stats[s.Name] = { Exp = expVal, Level = lvlVal }
			end
		end
	end

	return data
end

--------------------------------------------------------------------
-- 🧾 ФОРМАТИРОВАНИЕ ОТЧЁТА
--------------------------------------------------------------------
local function formatData(data)
	local lines = {}
	table.insert(lines, ("=== Account Info — %s ==="):format(tostring(data.Name or "Unknown")))
	table.insert(lines, ("Beli: %s"):format(formatBeli(data.Beli or 0)))
	table.insert(lines, ("Race: %s"):format(tostring(data.Race or "Unknown")))
	table.insert(lines, "")

	table.insert(lines, "-- Backpack (фрукты) --")
	if #data.BackpackFruits > 0 then
		table.insert(lines, table.concat(data.BackpackFruits, ", "))
	else
		table.insert(lines, "(пусто)")
	end
	table.insert(lines, "")

	table.insert(lines, "-- Trade Inventory (фрукты) --")
	if #data.TradeFruits > 0 then
		for _, v in ipairs(data.TradeFruits) do
			table.insert(lines, "- " .. v)
		end
	else
		table.insert(lines, "(фрукты в трейде не найдены)")
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

--------------------------------------------------------------------
-- 🔗 HTTP: функции отправки
--------------------------------------------------------------------
local function safeRequest(reqTable)
	local success, res = pcall(function() return request(reqTable) end)
	if not success then
		-- если request недоступен в окружении, попробуем HttpService:PostAsync (работает только если разрешено)
		if HttpService and HttpService.HttpEnabled then
			local ok2, err2 = pcall(function()
				HttpService:PostAsync(reqTable.Url, reqTable.Body, Enum.HttpContentType.ApplicationJson, false, reqTable.Headers)
			end)
			if not ok2 then
				return false, tostring(err2)
			end
			return true, "Posted via HttpService"
		end
		return false, tostring(res)
	end
	return true, res
end

local function SendMessage(url, message)
	local headers = {
		["Content-Type"] = "application/json"
	}
	local data = {
		["content"] = message
	}
	local body = HttpService:JSONEncode(data)
	local ok, res = safeRequest({
		Url = url,
		Method = "POST",
		Headers = headers,
		Body = body
	})
	if ok then
		print("Webhook: sent message")
		return true, res
	else
		warn("Webhook send failed:", res)
		return false, res
	end
end

local function SendMessageEMBED(url, embed)
	local headers = {
		["Content-Type"] = "application/json"
	}
	-- embed.fields должен быть массив полей вида { name=..., value=..., inline=true/false }
	local data = {
		["embeds"] = {
			{
				["title"] = embed.title,
				["description"] = embed.description,
				["color"] = embed.color or 65280,
				["fields"] = embed.fields or {},
				["footer"] = embed.footer and { ["text"] = embed.footer.text } or nil,
				["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
			}
		}
	}
	local body = HttpService:JSONEncode(data)
	local ok, res = safeRequest({
		Url = url,
		Method = "POST",
		Headers = headers,
		Body = body
	})
	if ok then
		print("Webhook: sent embed")
		return true, res
	else
		warn("Webhook embed send failed:", res)
		return false, res
	end
end

--------------------------------------------------------------------
-- 🖥️ GUI + интеграция отправки
--------------------------------------------------------------------
local function createUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AccountCheckerUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 50
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 640, 0, 520)
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
	title.Text = "Account Checker (локально) — отправка в webhook"
	title.Parent = frame

	local refreshBtn = Instance.new("TextButton")
	refreshBtn.Size = UDim2.new(0, 120, 0, 34)
	refreshBtn.Position = UDim2.new(0, 12, 0, 52)
	refreshBtn.Text = "Обновить"
	refreshBtn.Font = Enum.Font.SourceSansBold
	refreshBtn.TextSize = 16
	refreshBtn.Parent = frame

	local sendBtn = Instance.new("TextButton")
	sendBtn.Size = UDim2.new(0, 170, 0, 34)
	sendBtn.Position = UDim2.new(0, 148, 0, 52)
	sendBtn.Text = "Отправить в webhook"
	sendBtn.Font = Enum.Font.SourceSansBold
	sendBtn.TextSize = 16
	sendBtn.Parent = frame

	local copyBtn = Instance.new("TextButton")
	copyBtn.Size = UDim2.new(0, 150, 0, 34)
	copyBtn.Position = UDim2.new(0, 330, 0, 52)
	copyBtn.Text = "Скопировать отчёт"
	copyBtn.Font = Enum.Font.SourceSansBold
	copyBtn.TextSize = 16
	copyBtn.Parent = frame

	local consoleBtn = Instance.new("TextButton")
	consoleBtn.Size = UDim2.new(0, 210, 0, 34)
	consoleBtn.Position = UDim2.new(0, 494, 0, 52)
	consoleBtn.Text = "Показать в Output"
	consoleBtn.Font = Enum.Font.SourceSans
	consoleBtn.TextSize = 16
	consoleBtn.Parent = frame

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -24, 1, -120)
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
			return nil
		end
		local txt = formatData(data)
		content.Text = txt

		local textBounds = content.TextBounds
		local height = math.max(textBounds.Y + 24, 20)
		content.Size = UDim2.new(1, -20, 0, height)
		scroll.CanvasSize = UDim2.new(0, 0, 0, height + 32)
		status.Text = "Последнее обновление: " .. os.date("%Y-%m-%d %H:%M:%S")
		return data
	end

	refreshBtn.MouseButton1Click:Connect(function()
		refresh()
	end)

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

	-- Формируем embed и поля для отправки
	local function buildEmbedFromData(data)
		local fields = {}

		-- Короткие поля
		table.insert(fields, { name = "Имя", value = tostring(data.Name or "Unknown"), inline = true })
		table.insert(fields, { name = "Race", value = tostring(data.Race or "Unknown"), inline = true })
		table.insert(fields, { name = "Beli", value = formatBeli(data.Beli or 0), inline = true })

		-- Кол-во фруктов
		table.insert(fields, { name = "Фрукты в рюкзаке", value = tostring(#(data.BackpackFruits or {})) .. " шт.", inline = true })
		table.insert(fields, { name = "Фрукты в трейде", value = tostring(#(data.TradeFruits or {})) .. " шт.", inline = true })

		-- Если есть несколько фруктов — добавим краткий список (если длинный — усечём)
		if #data.BackpackFruits > 0 then
			local v = table.concat(data.BackpackFruits, ", ")
			if #v > 1000 then v = v:sub(1, 980) .. "..." end
			table.insert(fields, { name = "Backpack list", value = v, inline = false })
		end
		if #data.TradeFruits > 0 then
			local v = table.concat(data.TradeFruits, ", ")
			if #v > 1000 then v = v:sub(1, 980) .. "..." end
			table.insert(fields, { name = "Trade list", value = v, inline = false })
		end

		-- Stats: добавим каждую способность как поле (если их слишком много — усечём до 10)
		local count = 0
		for k, v in pairs(data.Stats or {}) do
			if count >= 10 then break end
			local s = ("Exp: %s | Lvl: %s"):format(tostring(v.Exp or 0), tostring(v.Level or 0))
			table.insert(fields, { name = tostring(k), value = s, inline = true })
			count = count + 1
		end
		if (data.Stats and next(data.Stats) and count == 0) then
			-- если есть stats но не попали в цикл (маловероятно), добавим заметку
			table.insert(fields, { name = "Stats", value = "(есть данные, но не были добавлены)", inline = false })
		end

		local embed = {
			title = ("Account: %s"):format(tostring(data.Name or "Unknown")),
			description = "Локальный отчёт, отправлен с клиента",
			color = 3447003, -- синий
			fields = fields,
			footer = { text = ("Sent at %s"):format(os.date("%Y-%m-%d %H:%M:%S")) }
		}
		return embed
	end

	sendBtn.MouseButton1Click:Connect(function()
		sendBtn.Text = "Отправка..."
		local data = refresh()
		if not data then
			sendBtn.Text = "Ошибка"
			task.delay(1.5, function() if sendBtn then sendBtn.Text = "Отправить в webhook" end end)
			return
		end

		-- Попробуем отправить как embed (и текстом как fallback)
		local embed = buildEmbedFromData(data)
		local ok, res = SendMessageEMBED(WEBHOOK_URL, embed)
		if not ok then
			-- Fallback: отправим plain text (если embed не прошёл)
			local txt = formatData(data)
			local ok2, res2 = SendMessage(WEBHOOK_URL, "```" .. txt:sub(1, 1900) .. "```")
			if ok2 then
				sendBtn.Text = "✅ Отправлено (fallback)"
			else
				sendBtn.Text = "❌ Ошибка"
			end
		else
			sendBtn.Text = "✅ Отправлено"
		end

		task.delay(1.5, function() if sendBtn then sendBtn.Text = "Отправить в webhook" end end)
	end)

	-- initial
	refresh()
end

local ok, err = pcall(createUI)
if not ok then
	warn("Не удалось создать AccountChecker UI: ", err)
end
