-- Race Checker (GUI Inventory Scan)
-- Ищет расу ТОЛЬКО через GUI инвентаря (Items / Items > Build)

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------
-- НАСТРОЙКИ
--------------------------------------------------
local SCAN_ATTEMPTS = 5        -- сколько попыток сканирования
local SCAN_DELAY = 1          -- задержка между попытками (сек)
local RACE_KEYWORD = "Human"  -- ключевое слово для поиска

--------------------------------------------------
-- UI: ЛОГ-ПАНЕЛЬ
--------------------------------------------------
local gui = Instance.new("ScreenGui", playerGui)
gui.Name = "RaceCheckerUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 500, 0, 350)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "Race Checker — GUI Scan"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1

local logFrame = Instance.new("ScrollingFrame", frame)
logFrame.Position = UDim2.new(0, 10, 0, 40)
logFrame.Size = UDim2.new(1, -20, 1, -50)
logFrame.CanvasSize = UDim2.new(0,0,0,0)
logFrame.ScrollBarThickness = 8
logFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)

local logLabel = Instance.new("TextLabel", logFrame)
logLabel.Size = UDim2.new(1, -10, 0, 10)
logLabel.Position = UDim2.new(0, 5, 0, 5)
logLabel.TextWrapped = true
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 14
logLabel.TextColor3 = Color3.fromRGB(230,230,230)
logLabel.BackgroundTransparency = 1
logLabel.Text = ""

--------------------------------------------------
-- ЛОГ-ФУНКЦИЯ
--------------------------------------------------
local function log(text)
    logLabel.Text ..= text .. "\n"
    task.wait()
    logLabel.Size = UDim2.new(1, -10, 0, logLabel.TextBounds.Y + 10)
    logFrame.CanvasSize = UDim2.new(0,0,0, logLabel.TextBounds.Y + 20)
    logFrame.CanvasPosition = Vector2.new(0, math.max(0, logFrame.CanvasSize.Y.Offset - logFrame.AbsoluteWindowSize.Y))
end

--------------------------------------------------
-- ПОИСК RACE В GUI
--------------------------------------------------
local function scanGuiForRace(root, path)
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            if typeof(obj.Text) == "string" and obj.Text:find(RACE_KEYWORD) then
                log("✅ НАЙДЕНО: '" .. obj.Text .. "'")
                log("📍 Путь: " .. path)
                return obj.Text
            end
        end
    end
    return nil
end

--------------------------------------------------
-- ОСНОВНАЯ ЛОГИКА СКАНИРОВАНИЯ
--------------------------------------------------
task.spawn(function()
    log("▶ Старт поиска расы...")
    log("🔎 Ключевое слово: " .. RACE_KEYWORD)
    log("🔁 Попыток: " .. SCAN_ATTEMPTS)
    log("--------------------------------")

    for attempt = 1, SCAN_ATTEMPTS do
        log("🔄 Попытка #" .. attempt)

        local inventoryGui = playerGui:FindFirstChild("Inventory") 
            or playerGui:FindFirstChild("InventoryGUI")

        if not inventoryGui then
            log("❌ Inventory GUI не найдено")
        else
            log("✔ Inventory GUI найдено")

            -- Items
            local items = inventoryGui:FindFirstChild("Items", true)
            if items then
                log("🔍 Сканирую: Items")
                local found = scanGuiForRace(items, "Inventory > Items")
                if found then
                    log("🎯 ИТОГОВАЯ РАСА: " .. found)
                    return
                end

                -- Items > Build
                local build = items:FindFirstChild("Build", true)
                if build then
                    log("🔍 Сканирую: Items > Build")
                    local foundBuild = scanGuiForRace(build, "Inventory > Items > Build")
                    if foundBuild then
                        log("🎯 ИТОГОВАЯ РАСА: " .. foundBuild)
                        return
                    end
                else
                    log("⚠ Build не найден в Items")
                end
            else
                log("❌ Items не найдено в Inventory")
            end
        end

        log("⏳ Ожидание перед следующей попыткой...\n")
        task.wait(SCAN_DELAY)
    end

    log("❌ Раса не найдена после всех попыток")
end)
