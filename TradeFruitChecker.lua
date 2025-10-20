-- 🔧 Сервисы
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- 📦 Папка трейда
local tradeFramePath = PlayerGui:WaitForChild("Main")
	:WaitForChild("Trade")
	:WaitForChild("Container")
	:WaitForChild("1")
	:WaitForChild("FrameAdd")
	:WaitForChild("Frame")

-- 🍎 Список всех фруктов
local fruitList = {
	"Rocket-Rocket", "Spin-Spin", "Blade-Blade", "Spring-Spring", "Bomb-Bomb",
	"Smoke-Smoke", "Spike-Spike", "Flame-Flame", "Falcon-Falcon", "Ice-Ice",
	"Sand-Sand", "Dark-Dark", "Diamond-Diamond", "Light-Light", "Rubber-Rubber",
	"Barrier-Barrier", "Ghost-Ghost", "Magma-Magma", "Quake-Quake", "Buddha-Buddha",
	"Love-Love", "Spider-Spider", "Sound-Sound", "Phoenix-Phoenix", "Portal-Portal",
	"Rumble-Rumble", "Pain-Pain", "Blizzard-Blizzard", "Gravity-Gravity", "Mammoth-Mammoth",
	"T-Rex-T-Rex", "Yeti-Yeti", "Dough-Dough", "Shadow-Shadow", "Venom-Venom",
	"Control-Control", "Gas-Gas", "Spirit-Spirit", "Dragon-Dragon", "Leopard-Leopard",
	"Kitsune-Kitsune", "Creation-Creation"
}

-- 🧱 GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FruitChecker"
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 600, 0, 450)
frame.Position = UDim2.new(0.5, -300, 0.5, -225)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 2
frame.Parent = screenGui

-- Заголовок
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 22
title.Text = "🍏 Фрукты, доступные для трейда"
title.Parent = frame

-- 🔄 Кнопка обновления
local refreshButton = Instance.new("TextButton")
refreshButton.Size = UDim2.new(0, 120, 0, 30)
refreshButton.Position = UDim2.new(1, -130, 0, 40)
refreshButton.BackgroundColor3 = Color3.fromRGB(80, 130, 80)
refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshButton.Text = "🔄 Обновить"
refreshButton.Font = Enum.Font.SourceSansBold
refreshButton.TextSize = 18
refreshButton.Parent = frame

-- 🔍 Поиск
local searchFrame = Instance.new("Frame")
searchFrame.Size = UDim2.new(1, -160, 0, 35)
searchFrame.Position = UDim2.new(0, 10, 0, 40)
searchFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
searchFrame.Parent = frame

local searchIcon = Instance.new("TextLabel")
searchIcon.Size = UDim2.new(0, 30, 1, 0)
searchIcon.Position = UDim2.new(0, 5, 0, 0)
searchIcon.BackgroundTransparency = 1
searchIcon.Text = "🔍"
searchIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
searchIcon.Font = Enum.Font.SourceSansBold
searchIcon.TextSize = 20
searchIcon.Parent = searchFrame

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -40, 1, -6)
searchBox.Position = UDim2.new(0, 35, 0, 3)
searchBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.PlaceholderText = "Введите название фрукта..."
searchBox.Font = Enum.Font.SourceSans
searchBox.TextSize = 18
searchBox.ClearTextOnFocus = false
searchBox.Parent = searchFrame

-- 📜 Скроллинг
local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Size = UDim2.new(1, -20, 1, -95)
scrollingFrame.Position = UDim2.new(0, 10, 0, 85)
scrollingFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
scrollingFrame.BorderSizePixel = 1
scrollingFrame.ScrollBarThickness = 10
scrollingFrame.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = scrollingFrame
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 3)

local itemButtons = {}

-- 🧭 Проверка фруктов
local function scanFruits()
	for _, old in ipairs(scrollingFrame:GetChildren()) do
		if old:IsA("TextButton") or old:IsA("TextLabel") then
			old:Destroy()
		end
	end
	itemButtons = {}

	for _, fruitName in ipairs(fruitList) do
		local found = tradeFramePath:FindFirstChild(fruitName)
		if found then
			local button = Instance.new("TextButton")
			button.Size = UDim2.new(1, -10, 0, 25)
			button.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
			button.Text = "✅ " .. fruitName
			button.Font = Enum.Font.SourceSans
			button.TextSize = 16
			button.Parent = scrollingFrame
			table.insert(itemButtons, {Instance = button, Text = fruitName})

			button.MouseButton1Click:Connect(function()
				print("Имя:", found.Name)
				print("Путь:", found:GetFullName())
			end)
		end
	end

	if #itemButtons == 0 then
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -10, 0, 25)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(200, 200, 200)
		label.Text = "❌ В трейде не найдено ни одного фрукта."
		label.TextSize = 16
		label.Parent = scrollingFrame
	end
end

-- 🧠 Фильтрация
local function filterList(text)
	text = string.lower(text)
	for _, entry in ipairs(itemButtons) do
		if string.find(string.lower(entry.Text), text, 1, true) then
			entry.Instance.Visible = true
		else
			entry.Instance.Visible = false
		end
	end
end

-- 🔎 Поиск
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	filterList(searchBox.Text)
end)

-- 🔄 Кнопка обновления
refreshButton.MouseButton1Click:Connect(function()
	scanFruits()
end)

-- 🌀 Автообновление CanvasSize
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end)

-- 🚀 Запуск
scanFruits()
