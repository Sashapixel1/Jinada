-- ✅ Race Checker (ANTI-FREEZE VERSION)
-- НЕ зависит от GUI
-- НЕ зависает на InvokeServer
-- ВСЕГДА пишет логи

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

--------------------------------------------------
-- НАСТРОЙКИ
--------------------------------------------------
local SCAN_ATTEMPTS = 5
local SCAN_DELAY = 1
local RACE_KEYWORD = "Human"
local INVOKE_TIMEOUT = 2 -- секунд

--------------------------------------------------
-- UI: ЛОГ
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
title.Text = "Race Checker — SAFE MODE"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1

local scroll = Instance.new("ScrollingFrame", frame)
scroll.Position = UDim2.new(0,10,0,40)
scroll.Size = UDim2.new(1,-20,1,-50)
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

local function log(text)
    logLabel.Text ..= text .. "\n"
    RunService.Heartbeat:Wait()
    logLabel.Size = UDim2.new(1,-10,0,logLabel.TextBounds.Y + 10)
    scroll.CanvasSize = UDim2.new(0,0,0,logLabel.TextBounds.Y + 20)
end

--------------------------------------------------
-- SAFE InvokeServer (НЕ ВИСНЕТ)
--------------------------------------------------
local function safeInvoke(...)
    local finished = false
    local result

    task.spawn(function()
        local ok, res = pcall(function()
            return remote:InvokeServer(...)
        end)
        if ok then result = res end
        finished = true
    end)

    local start = tick()
    while not finished do
        if tick() - start > INVOKE_TIMEOUT then
            return nil, "timeout"
        end
        RunService.Heartbeat:Wait()
    end

    return result
end

--------------------------------------------------
-- ПОИСК РАСЫ В ТАБЛИЦЕ
--------------------------------------------------
local function findRaceInTable(t)
    for i, v in ipairs(t) do
        local name = v.Name or v.name
        if typeof(name) == "string" and name:find(RACE_KEYWORD) then
            return name
        end
    end
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
        log("📡 Запрос getInventory...")

        local inv, err = safeInvoke("getInventory")

        if err == "timeout" then
            log("⚠ getInventory: таймаут (сервер не ответил)")
        elseif typeof(inv) == "table" then
            log("✔ Инвентарь получен, items: " .. #inv)
            local race = findRaceInTable(inv)
            if race then
                log("✅ РАСА НАЙДЕНА: " .. race)
                return
            else
                log("❌ Human не найден")
            end
        else
            log("❌ getInventory вернул пусто")
        end

        -- 🔁 FALLBACK: Data / Attributes
        local data = player:FindFirstChild("Data")
        if data and data:FindFirstChild("Race") then
            log("📦 Fallback Race(Data): " .. tostring(data.Race.Value))
            return
        end

        local attr = player:GetAttribute("Race")
        if attr then
            log("📦 Fallback Race(Attribute): " .. tostring(attr))
            return
        end

        task.wait(SCAN_DELAY)
    end

    log("❌ Раса не найдена")
end)
