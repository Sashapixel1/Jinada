-- TradeServer (ServerScriptService)
-- Менеджер торговых сессий — безопасная серверная логика

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local REQ_START = ReplicatedStorage:WaitForChild("Trade_RequestStart")
local REQ_ADD = ReplicatedStorage:WaitForChild("Trade_AddItem")
local REQ_CONFIRM = ReplicatedStorage:WaitForChild("Trade_Confirm")
local REQ_CANCEL = ReplicatedStorage:WaitForChild("Trade_Cancel")

-- Допустимые фрукты (можно расширить)
local allowedFruits = {
	["Dough"] = true,
	["Flame"] = true,
	["Light"] = true,
	["Ice"] = true,
}

-- Таблица сессий: key = sessionId (строка), value = {playerA = p1, playerB = p2, offers = {p1 = {...}, p2 = {...}}, confirmed = {p1=false,p2=false}}
local sessions = {}

-- Вспомогательная: создание sessionId
local function makeSessionId(p1, p2)
	return p1.UserId .. ":" .. p2.UserId
end

-- Вспомогательная: проверка наличия предмета у игрока (в рюкзаке / character)
local function playerHasFruit(player, fruitName)
	if not fruitName then return false end
	-- Предполагаем, что фрукт представлен как объект (StringValue) в Backpack или в Character
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		if backpack:FindFirstChild(fruitName) then
			return true
		end
	end
	-- Ищем в Character
	local char = player.Character
	if char and char:FindFirstChild(fruitName) then
		return true
	end
	return false
end

-- Удаление фрукта из игрока (перенос в nil)
local function removeFruitFromPlayer(player, fruitName)
	local backpack = player:FindFirstChild("Backpack")
	if backpack and backpack:FindFirstChild(fruitName) then
		backpack[fruitName]:Destroy()
		return true
	end
	local char = player.Character
	if char and char:FindFirstChild(fruitName) then
		char[fruitName]:Destroy()
		return true
	end
	return false
end

-- Добавление фрукта игроку
local function giveFruitToPlayer(player, fruitName)
	-- Создаём StringValue — в реальной игре замените на реальный объект фрукта
	local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack")
	local fruit = Instance.new("StringValue")
	fruit.Name = fruitName
	fruit.Parent = backpack
end

-- Создать новую сессию при наличии пары игроков
local function startSession(initiator, partner)
	if not initiator or not partner then return end
	local sid = makeSessionId(initiator, partner)
	local sidRev = makeSessionId(partner, initiator)
	if sessions[sid] or sessions[sidRev] then
		-- Уже есть
		return sessions[sid] or sessions[sidRev]
	end
	local sess = {
		playerA = initiator,
		playerB = partner,
		offers = {},
		offers[initiator] = {},
		offers[partner] = {},
		confirmed = {},
		confirmed[initiator] = false,
		confirmed[partner] = false,
		active = true,
	}
	sessions[sid] = sess
	return sess
end

-- Завершение сессии (отмена/комплит)
local function endSession(sess)
	if not sess then return end
	-- пометим неактивной и уберем из таблицы
	sess.active = false
	local sid = makeSessionId(sess.playerA, sess.playerB)
	sessions[sid] = nil
end

-- Попытка выполнить обмен: когда обе стороны подтвердили
local function tryExecuteTrade(sess)
	if not sess or not sess.active then return end
	local a = sess.playerA
	local b = sess.playerB
	if sess.confirmed[a] and sess.confirmed[b] then
		-- проверяем, что все предметы по-прежнему доступны
		for _,fruitName in ipairs(sess.offers[a]) do
			if not playerHasFruit(a, fruitName) then
				-- отмена, сообщаем
				endSession(sess)
				return
			end
		end
		for _,fruitName in ipairs(sess.offers[b]) do
			if not playerHasFruit(b, fruitName) then
				endSession(sess)
				return
			end
		end

		-- Выполняем обмен: временно сохраняем списки, удаляем у владельцев, даём новым
		local aItems = {}
		for _,n in ipairs(sess.offers[a]) do table.insert(aItems, n) end
		local bItems = {}
		for _,n in ipairs(sess.offers[b]) do table.insert(bItems, n) end

		-- Удаляем у а
		for _,n in ipairs(aItems) do
			removeFruitFromPlayer(a, n)
		end
		-- Удаляем у b
		for _,n in ipairs(bItems) do
			removeFruitFromPlayer(b, n)
		end

		-- Даём bItems игроку a
		for _,n in ipairs(bItems) do
			giveFruitToPlayer(a, n)
		end
		-- Даём aItems игроку b
		for _,n in ipairs(aItems) do
			giveFruitToPlayer(b, n)
		end

		-- Завершаем сессию
		endSession(sess)

		-- (опционально) можно отправить игрокам RemoteEvent/Notification о завершении
	end
end

-- Обработчики RemoteEvents

REQ_START.OnServerEvent:Connect(function(player, partnerUserId)
	-- partnerUserId должен быть число (UserId) или nil
	if type(partnerUserId) ~= "number" then return end
	local partner = Players:GetPlayerByUserId(partnerUserId)
	if not partner then return end
	local sess = startSession(player, partner)
	-- Можно уведомить игроков, что сессия создана — но клиенту достаточно знать, что старт успешен
end)

REQ_ADD.OnServerEvent:Connect(function(player, fruitName)
	-- Игрок просит добавить fruitName в своё предложение
	if type(fruitName) ~= "string" then return end
	if not allowedFruits[fruitName] then return end

	-- Найти сессию игрока (в которой он участвует)
	local playerSess = nil
	for _,sess in pairs(sessions) do
		if sess.playerA == player or sess.playerB == player then
			playerSess = sess
			break
		end
	end
	if not playerSess or not playerSess.active then return end

	-- проверяем, что игрок действительно владеет фруктом
	if not playerHasFruit(player, fruitName) then
		return
	end

	-- Добавляем в предложение (если ещё нет)
	local offers = playerSess.offers[player]
	if not offers then
		playerSess.offers[player] = {fruitName}
	else
		-- избегаем дублей
		for _,n in ipairs(offers) do
			if n == fruitName then
				return
			end
		end
		table.insert(offers, fruitName)
	end

	-- Сброс подтверждений при изменении предложения
	playerSess.confirmed[playerSess.playerA] = false
	playerSess.confirmed[playerSess.playerB] = false
end)

REQ_CONFIRM.OnServerEvent:Connect(function(player)
	-- Игрок подтверждает/подтверждает своё текущее предложение
	-- Найти сессию игрока
	local playerSess = nil
	for _,sess in pairs(sessions) do
		if sess.playerA == player or sess.playerB == player then
			playerSess = sess
			break
		end
	end
	if not playerSess or not playerSess.active then return end

	playerSess.confirmed[player] = true

	-- если обе подтверждены — выполняем
	tryExecuteTrade(playerSess)
end)

REQ_CANCEL.OnServerEvent:Connect(function(player)
	-- игрок отменил сессию
	local playerSess
	for _,sess in pairs(sessions) do
		if sess.playerA == player or sess.playerB == player then
			playerSess = sess
			break
		end
	end
	if not playerSess then return end
	endSession(playerSess)
end)

-- Удаление сессии при выходе игрока
Players.PlayerRemoving:Connect(function(player)
	for sid,sess in pairs(sessions) do
		if sess.playerA == player or sess.playerB == player then
			endSession(sess)
		end
	end
end)

print("TradeServer loaded.")
