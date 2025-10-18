--[[ 
✅ Скрипт интерфейса и выдачи фрукта "Dough"
⚠️ Работает только в твоей игре (не в Blox Fruits!)
--]]

-- Сервисы
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Создаём RemoteEvent, если его нет
local event = ReplicatedStorage:FindFirstChild("GiveFruitEvent")
if not event then
	event = Instance.new("RemoteEvent")
	event.Name = "GiveFruitEvent"
	event.Parent = ReplicatedStorage
end

-- GUI
local player = Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FruitGiverGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Основное окно
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 150)
frame.Position = UDim2.new(0.5, -125, 0.5, -75)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.BackgroundTransparency = 0.1
frame.Parent = screenGui

-- Заголовок
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Text = "Fruit Control Panel"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.Parent = frame

-- Индикатор статуса
local indicator = Instance.new("Frame")
indicator.Size = UDim2.new(0, 20, 0, 20)
indicator.Position = UDim2.new(0, 10, 0, 40)
indicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
indicator.Parent = frame

local indicatorText = Instance.new("TextLabel")
indicatorText.Position = UDim2.new(0, 40, 0, 40)
indicatorText.Size = UDim2.new(1, -50, 0, 20)
indicatorText.Text = "Скрипт не активен"
indicatorText.TextColor3 = Color3.fromRGB(255, 255, 255)
indicatorText.Font = Enum.Font.SourceSans
indicatorText.TextSize = 16
indicatorText.BackgroundTransparency = 1
indicatorText.Parent = frame

-- Кнопка "Xalepa"
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 100, 0, 40)
button.Position = UDim2.new(0.5, -50, 1, -50)
button.Text = "Xalepa"
button.Font = Enum.Font.SourceSansBold
button.TextSize = 20
button.BackgroundColor3 = Color3.fromRGB(70, 70, 255)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Parent = frame

-- Состояние скрипта
local isActive = false

-- Обработчик кнопки
button.MouseButton1Click:Connect(function()
	isActive = not isActive
	if isActive then
		indicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		indicatorText.Text = "Скрипт активен"
		
		-- Выдаем фрукт "Dough"
		event:FireServer("Dough")
	else
		indicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		indicatorText.Text = "Скрипт не активен"
	end
end)

-- Серверная часть (если её нет, добавь в ServerScriptService):
--[[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local event = ReplicatedStorage:WaitForChild("GiveFruitEvent")

event.OnServerEvent:Connect(function(player, fruitName)
	local allowed = {"Dough", "Flame", "Light", "Ice"}
	if table.find(allowed, fruitName) then
		local fruit = Instance.new("StringValue")
		fruit.Name = fruitName
		fruit.Parent = player:WaitForChild("Backpack")
		print(player.Name .. " получил фрукт " .. fruitName)
	end
end)
]]
