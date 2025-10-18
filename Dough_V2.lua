-- AutoTradePress.lua
-- LocalScript: автоматически добавляет "Dough" в трейд и нажимает "Accept" каждые 2 секунды
-- Использовать ТОЛЬКО в своей копии игры в Roblox Studio

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CHECK_INTERVAL = 0.5       -- как часто сканируем наличие окна трейда (сек)
local ACTION_INTERVAL = 2        -- интервал между попытками добавить/подтвердить (сек)
local TRADE_TITLE_TEXT = "TREASURE TRADE" -- заголовок окна трейда (с твоего скрина)

-- Утилиты поиска GUI-элементов

-- Нестрогий поиск по тексту (игнорируем регистр)
local function strContains(a, b)
	if not a or not b then return false end
	a = tostring(a):lower()
	b = tostring(b):lower()
	return string.find(a, b, 1, true) ~= nil
end

-- Поиск окна трейда: ищем Frame/ScreenGui который содержит TextLabel с текстом TRADE TITLE
local function findTradeWindow()
	for _, gui in pairs(playerGui:GetDescendants()) do
		-- ищем контейнер, у которого есть дочерний TextLabel с нужным заголовком
		if gui:IsA("GuiObject") then
			-- проверяем детей этого контейнера
			for _, child in pairs(gui:GetChildren()) do
				if child:IsA("TextLabel") or child:IsA("TextButton") then
					if strContains(child.Text, TRADE_TITLE_TEXT) then
						-- считаем, что gui — контейнер окна трейда (поднимемся к Frame выше, если нужно)
						-- возвращаем ближайший Frame-родитель (или сам gui)
						local container = gui
						local parent = gui.Parent
						-- ищем Frame-родителя, чтобы вернуть весь блок окна (если gui — текст)
						local tries = 0
						while parent and tries < 5 do
							if parent:IsA("Frame") or parent:IsA("ScreenGui") then
								container = parent
								break
							end
							parent = parent.Parent
							tries = tries + 1
						end
						return container
					end
				end
			end
		end
	end
	return nil
end

-- Поиск кнопки Accept внутри окна трейда
local function findAcceptButton(tradeWindow)
	if not tradeWindow then return nil end
	for _, obj in pairs(tradeWindow:GetDescendants()) do
		if obj:IsA("TextButton") or obj:IsA("ImageButton") then
			-- проверим текст (для TextButton) и имя (fallback)
			local textOk = (obj:IsA("TextButton") and strContains(obj.Text, "Accept"))
			local nameOk = strContains(obj.Name, "Accept") or strContains(obj.Name, "accept")
			if textOk or nameOk then
				return obj
			end
		end
	end
	return nil
end

-- Поиск кнопки/иконки Dough в PlayerGui (инвентарь/панель)
-- Ищем по имени ("Dough") / тексту / Tooltip и т.п.
local function findDoughButton()
	for _, obj in pairs(playerGui:GetDescendants()) do
		if obj:IsA("TextButton") or obj:IsA("ImageButton") or obj:IsA("ImageLabel") then
			-- проверим текстовое поле (если есть) или имя
			local text = nil
			if obj:IsA("TextButton") then text = obj.Text end
			-- также может быть label рядом — проверим имя/атрибуты
			if (text and strContains(text, "Dough")) or strContains(obj.Name, "Dough") or strContains(obj:GetFullName(), "Dough") then
				return obj
			end
		end
	end
	-- Если не нашли в PlayerGui, попробуем проверить Inventory как отдельный ScreenGui
	return nil
end

-- Проверка: открыт ли трейд и существует ли Accept
local function isTradeActive(tradeWindow, acceptBtn)
	-- tradeWindow должен быть валидным и в дереве PlayerGui
	return tradeWindow and tradeWindow.Parent and tradeWindow:IsDescendantOf(playerGui) and acceptBtn and acceptBtn.Parent and acceptBtn:IsDescendantOf(tradeWindow)
end

-- Функция для "клика" по GUI-элементу: Activate для кнопок; если нет — пробуем :Fire("MouseButton1Click")
local function clickGuiButton(btn)
	if not btn then return false end
	-- безопасно: проверим, можно ли вызвать Activate (доступно для GuiButton в LocalScript)
	local success, err = pcall(function()
		if btn.Activate then
			btn:Activate()
		else
			-- Попытка эмулировать событие (в некоторых GUI :MouseButton1Click можно вызвать)
			if btn.MouseButton1Click then
				btn.MouseButton1Click:Fire()
			end
		end
	end)
	if not success then
		warn("Не удалось активировать кнопку:", err)
	end
	return success
end

-- Основной контроллер автоматизации
local autoRunning = false
local autoThread = nil

local function startAutoTradeLoop()
	if autoRunning then return end
	autoRunning = true

	autoThread = coroutine.create(function()
		while autoRunning do
			-- Найдём окно трейда
			local tradeWindow = findTradeWindow()
			if tradeWindow then
				local acceptBtn = findAcceptButton(tradeWindow)
				local doughBtn = findDoughButton()

				-- Если нашли кнопку Dough — кликнем по ней (попытка добавить в трейд)
				if doughBtn then
					pcall(function() clickGuiButton(doughBtn) end)
				else
					-- альтернативно: проверим бекенды (Backpack) — если в Backpack есть StringValue("Dough"), мы можем логировать
					-- но добавление предмета в трейд в большинстве реализаций делается через GUI-клик
					-- поэтому если не найдено — предупредим в Output
					-- warn("Dough button not found in PlayerGui")
				end

				-- Если нашли Accept — нажмём
				if acceptBtn then
					pcall(function() clickGuiButton(acceptBtn) end)
				else
					-- warn("Accept button not found in trade window")
				end

				-- Ждём пока окно трейда не закроется или интервал
				local t0 = tick()
				while tick() - t0 < ACTION_INTERVAL do
					wait(0.1)
					-- если окно закрылось — прервём
					if not findTradeWindow() then break end
				end
			else
				-- окно трейда не открыто — ожидаем
				wait(CHECK_INTERVAL)
			end
		end
	end)
	coroutine.resume(autoThread)
end

local function stopAutoTradeLoop()
	autoRunning = false
	autoThread = nil
end

-- Авто-старт: при нахождении окна трейда запускаем цикл; когда окно закрыто — останавливаем
-- Чтобы не запускать многократно, используем RunService.Heartbeat для частого сканирования
local scanning = false
local function startScanner()
	if scanning then return end
	scanning = true
	coroutine.wrap(function()
		while scanning do
			local tradeWindow = findTradeWindow()
			if tradeWindow and not autoRunning then
				print("[AutoTrade] Торговое окно найдено — запускаю автодействия")
				startAutoTradeLoop()
			elseif not tradeWindow and autoRunning then
				print("[AutoTrade] Торговое окно закрылось — останавливаю автодействия")
				stopAutoTradeLoop()
			end
			wait(CHECK_INTERVAL)
		end
	end)()
end

local function stopScanner()
	scanning = false
	stopAutoTradeLoop()
end

-- Стартуем сканер при загрузке скрипта
startScanner()

-- Простая привязка: по нажатию клавиши (например, T) можно включать/выключать автосканер (удобно при тестировании)
local UserInputService = game:GetService("UserInputService")
local toggleKey = Enum.KeyCode.T
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == toggleKey then
		if scanning then
			stopScanner()
			print("[AutoTrade] Сканер остановлен (T)")
		else
			startScanner()
			print("[AutoTrade] Сканер запущен (T)")
		end
	end
end)

print("AutoTradePress loaded.")
