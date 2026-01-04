-- ✅ Race Checker with GUI Log (STABLE VERSION)
-- НЕ зависает, НЕ требует открытия инвентаря

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------
-- НАСТРОЙКИ
--------------------------------------------------
local SCAN_ATTEMPTS = 5
local SCAN_DELAY = 1
local RACE_KEYWORD = "Human"

--------------------------------------------------
-- GUI: ЛОГ ПАНЕЛЬ
--------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "RaceCheckerUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0, 520, 0, 340)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0

local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1,0,0,30)
title.Text = "Race Checker — LOG"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1

local scroll = Instance.new("ScrollingFrame")
scroll.Parent = frame
scroll.Position = UDim2.new(0,10,0,40)
scroll.Size = UDim2.new(1,-20,1,-50)
scroll.ScrollBarThickness = 8
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.BackgroundColor3 = Color3.fromRGB(20,20,20)
scroll.BorderSizePixel = 0

local logLabel = Instance.new("TextLabel")
logLabel.Parent = scroll
logLabel.Position = UDim2.new(0,5,0,5)
logLabel.Size = UDim2.new(1,-10,0,10)
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 14
logLabel.TextWrapped = true
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.TextColor3 = Color3.fromRGB(230,230,230)
logLabel.BackgroundTransparency = 1
logLabel.Text = ""

--------------------------------------------------
-- ЛОГ ФУНКЦИЯ (ГАРАНТИРОВАННАЯ)
--------------------------------------------------
local function log(text)
    logLabel.Text ..= text .. "\n"
    RunService.Heartbeat:Wait()
    logLabel.Size = UDim2.new(1,-10,0,logLabel.TextBounds.Y + 10)
    scroll.CanvasSize = UDim2.new(0,0,0,logLabel.TextBounds.Y + 20)
    scroll.CanvasPosition = Vector2.new(
        0,
        math.max(0, scroll.CanvasSize.Y.Offset - scroll.AbsoluteWindowSize.Y)
    )
end

--------------------------------------------------
-- ПОИСК РАСЫ
--------------------------------------------------
local function checkRace()
    -- 1️⃣ Data.Race
    local data = player:FindFirstChild("Data")
    if data and data:FindFirstChild("Race") then
        local race = tostring(data.Race.Value)
        log("✔ Найдено в Data.Race: " .. race)
        if race:find(RACE_KEYWORD) then
            return race, "Data.Race"
        end
    else
        log("✖ Data.Race не найден")
    end

    -- 2️⃣ Attribute
    local attr = player:GetAttribute("Race")
    if attr then
        local race = tostring(attr)
        log("✔ Найдено в Attribute Race: " .. race)
        if race:find(RACE_KEYWORD) then
            return race, "Attribute"
        end
    else
        log("✖ Attribute Race отсутствует")
    end

    return nil
end

--------------------------------------------------
-- ОСНОВНОЙ ЦИКЛ
--------------------------------------------------
task.spawn(function()
    log("▶ Старт поиска расы")
    log("🔎 Ключ: " .. RACE_KEYWORD)
    log("🔁 Попыток: " .. SCAN_ATTEMPTS)
    log("--------------------------------")

    for attempt = 1, SCAN_ATTEMPTS do
        log("🔄 Попытка #" .. attempt)

        local race, source = checkRace()
        if race then
            log("✅ РАСА НАЙДЕНА!")
            log("🎯 Race: " .. race)
            log("📍 Source: " .. source)
            return
        end

        log("⏳ Ожидание " .. SCAN_DELAY .. " сек...\n")
        task.wait(SCAN_DELAY)
    end

    log("❌ Раса не найдена")
end)
