-- Race Checker (через getInventory, БЕЗ открытия GUI)
-- Основано на твоём коде скана фруктов / ганов

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

--------------------------------------------------
-- НАСТРОЙКИ
--------------------------------------------------
local SCAN_ATTEMPTS = 6
local SCAN_DELAY = 1
local RACE_KEYWORD = "Human"

--------------------------------------------------
-- UI: ЛОГ ПАНЕЛЬ
--------------------------------------------------
local gui = Instance.new("ScreenGui", playerGui)
gui.Name = "RaceCheckerUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 520, 0, 360)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.Text = "Race Checker — getInventory scan"
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
-- ЛОГ
--------------------------------------------------
local function log(text)
    logLabel.Text ..= text .. "\n"
    task.wait()
    logLabel.Size = UDim2.new(1,-10,0,logLabel.TextBounds.Y + 10)
    scroll.CanvasSize = UDim2.new(0,0,0,logLabel.TextBounds.Y + 20)
    scroll.CanvasPosition = Vector2.new(
        0,
        math.max(0, scroll.CanvasSize.Y.Offset - scroll.AbsoluteWindowSize.Y)
    )
end

--------------------------------------------------
-- СКАН getInventory
--------------------------------------------------
local function scanRaceFromInventory(invTable)
    for i, item in ipairs(invTable) do
        local name = item.Name or item.name or ""
        local itemType = item.Type or item.type or "unknown"

        log("   • Item #" .. i .. ": " .. tostring(name) .. " | type=" .. tostring(itemType))

        if typeof(name) == "string" and name:find(RACE_KEYWORD) then
            return name, itemType
        end
    end
    return nil
end

--------------------------------------------------
-- ОСНОВНАЯ ЛОГИКА
--------------------------------------------------
task.spawn(function()
    log("▶ Старт поиска расы")
    log("🔎 Ключевое слово: " .. RACE_KEYWORD)
    log("🔁 Попыток: " .. SCAN_ATTEMPTS)
    log("--------------------------------")

    for attempt = 1, SCAN_ATTEMPTS do
        log("🔄 Попытка #" .. attempt)

        local ok, invData = pcall(function()
            return remote:InvokeServer("getInventory")
        end)

        if not ok then
            log("❌ Ошибка InvokeServer(getInventory)")
        elseif typeof(invData) ~= "table" then
            log("❌ getInventory вернул не таблицу")
        else
            log("✔ getInventory получен, items: " .. #invData)

            local raceName, sourceType = scanRaceFromInventory(invData)
            if raceName then
                log("✅ РАСА НАЙДЕНА!")
                log("🎯 Race: " .. raceName)
                log("📦 Source type: " .. tostring(sourceType))
                return
            end

            log("❌ Human не найден в этом инвентаре")
        end

        log("⏳ Ожидание " .. SCAN_DELAY .. " сек...\n")
        task.wait(SCAN_DELAY)
    end

    log("❌ Раса не найдена после всех попыток")
end)
