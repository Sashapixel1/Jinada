-- ✅ Race Checker (FIXED)
-- Ищет расу через GUI инвентаря (Items / Items > Build)
-- Делает несколько попыток и логирует каждый шаг

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------
-- НАСТРОЙКИ
--------------------------------------------------
local SCAN_ATTEMPTS = 6
local SCAN_DELAY = 1
local RACE_KEYWORD = "Human"

--------------------------------------------------
-- UI: ЛОГ ПАНЕЛЬ
--------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "RaceCheckerUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 520, 0, 360)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.Text = "Race Checker — GUI Scan"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1

local scroll = Instance.new("ScrollingFrame", frame)
scroll.Position = UDim2.new(0,10,0,40)
scroll.Size = UDim2.new(1,-20,1,-50)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.ScrollBarThickness = 8
scroll.BackgroundColor3 = Color3.fromRGB(20,20,20)

local logLabel = Instance.new("TextLabel", scroll)
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
-- ЛОГ ФУНКЦИЯ
--------------------------------------------------
local function log(txt)
    logLabel.Text ..= txt .. "\n"
    task.wait()
    logLabel.Size = UDim2.new(1,-10,0,logLabel.TextBounds.Y + 10)
    scroll.CanvasSize = UDim2.new(0,0,0,logLabel.TextBounds.Y + 20)
    scroll.CanvasPosition = Vector2.new(0, math.max(0, scroll.CanvasSize.Y.Offset - scroll.AbsoluteWindowSize.Y))
end

--------------------------------------------------
-- СКАН GUI НА RACE
--------------------------------------------------
local function scanForRace(root)
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            if typeof(obj.Text) == "string" and obj.Text:find(RACE_KEYWORD) then
                return obj, obj.Text
            end
        end
    end
    return nil
end

--------------------------------------------------
-- ОСНОВНОЙ СКАН
--------------------------------------------------
task.spawn(function()
    log("▶ Старт поиска расы")
    log("🔎 Ищем слово: " .. RACE_KEYWORD)
    log("🔁 Попыток: " .. SCAN_ATTEMPTS)
    log("--------------------------------")

    for attempt = 1, SCAN_ATTEMPTS do
        log("🔄 Попытка #" .. attempt)

        local foundAnyGui = false

        for _, guiObj in ipairs(playerGui:GetChildren()) do
            if guiObj:IsA("ScreenGui") then
                foundAnyGui = true
                log("📦 Проверка GUI: " .. guiObj.Name)

                local obj, text = scanForRace(guiObj)
                if obj then
                    log("✅ НАЙДЕНО: " .. text)
                    log("📍 GUI: " .. guiObj.Name)
                    log("🎯 ИТОГОВАЯ РАСА: " .. text)
                    return
                end
            end
        end

        if not foundAnyGui then
            log("⚠ PlayerGui пока пуст")
        else
            log("❌ Race не найдена в этой попытке")
        end

        log("⏳ Ожидание " .. SCAN_DELAY .. " сек...\n")
        task.wait(SCAN_DELAY)
    end

    log("❌ Раса не найдена после всех попыток")
end)
