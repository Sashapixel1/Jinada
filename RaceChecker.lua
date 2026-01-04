-- ✅ Race Checker — FINAL STABLE VERSION
-- GUI лог + защита от тихих ошибок

local Players = game:GetService("Players")
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
-- ЛОГ ФУНКЦИЯ (БЕЗ ОПАСНЫХ YIELD)
--------------------------------------------------
local function log(text)
    logLabel.Text = logLabel.Text .. text .. "\n"
    task.wait()
    logLabel.Size = UDim2.new(1,-10,0,logLabel.TextBounds.Y + 10)
    scroll.CanvasSize = UDim2.new(0,0,0,logLabel.TextBounds.Y + 20)
    scroll.CanvasPosition = Vector2.new(
        0,
        math.max(0, scroll.CanvasSize.Y.Offset - scroll.AbsoluteWindowSize.Y)
    )
end

--------------------------------------------------
-- ОСНОВНОЙ КОД (ЗАЩИЩЁННЫЙ)
--------------------------------------------------
task.spawn(function()
    local ok, err = pcall(function()

        log("▶ Старт поиска расы")
        log("🔎 Ключ: " .. RACE_KEYWORD)
        log("🔁 Попыток: " .. SCAN_ATTEMPTS)
        log("--------------------------------")

        for attempt = 1, SCAN_ATTEMPTS do
            log("🔄 Попытка #" .. attempt)

            local data = player:FindFirstChild("Data")
            if data then
                log("✔ Data найдено")

                local raceValue = data:FindFirstChild("Race")
                if raceValue then
                    local race = tostring(raceValue.Value)
                    log("✔ Найдено Data.Race: " .. race)

                    if race:find(RACE_KEYWORD) then
                        log("✅ РАСА НАЙДЕНА!")
                        log("🎯 Race: " .. race)
                        log("📍 Source: Data.Race")
                        return
                    end
                else
                    log("✖ Data.Race отсутствует")
                end
            else
                log("✖ Data отсутствует")
            end

            local attrRace = player:GetAttribute("Race")
            if attrRace then
                log("✔ Attribute Race: " .. tostring(attrRace))
                if tostring(attrRace):find(RACE_KEYWORD) then
                    log("✅ РАСА НАЙДЕНА!")
                    log("🎯 Race: " .. tostring(attrRace))
                    log("📍 Source: Attribute")
                    return
                end
            else
                log("✖ Attribute Race отсутствует")
            end

            log("⏳ Ожидание " .. SCAN_DELAY .. " сек...\n")
            task.wait(SCAN_DELAY)
        end

        log("❌ Раса не найдена после всех попыток")
    end)

    if not ok then
        log("💥 ОШИБКА СКРИПТА:")
        log(tostring(err))
    end
end)
