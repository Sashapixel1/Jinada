--========================================================
-- CDKQuest: авто-старт Evil Trial
-- запускает Progress(Evil) -> StartTrial(Evil)
--========================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

-- простая лог-функция (можешь заменить на свой AddLog из GUI)
local function AddLog(msg)
    print("[CDKTrial] " .. tostring(msg))
end

local function StartEvilTrial()
    -- 1. Проверяем прогресс Evil-триала (как в логах)
    AddLog("Проверяю прогресс триала Evil...")
    local okProgress, progress = pcall(function()
        return CommF:InvokeServer("CDKQuest", "Progress", "Evil")
    end)

    if okProgress then
        AddLog("CDKQuest Progress (Evil) = " .. tostring(progress))
    else
        AddLog("Ошибка при запросе Progress(Evil): " .. tostring(progress))
    end

    -- небольшая пауза, как при ручном диалоге
    task.wait(0.3)

    -- 2. Стартуем триал
    AddLog("Пробую запустить StartTrial(Evil)...")
    local okStart, resStart = pcall(function()
        return CommF:InvokeServer("CDKQuest", "StartTrial", "Evil")
    end)

    if okStart then
        AddLog("✅ StartTrial(Evil) отправлен. Ответ: " .. tostring(resStart))
    else
        AddLog("❌ Ошибка при StartTrial(Evil): " .. tostring(resStart))
    end
end

-- автозапуск при инжекте
StartEvilTrial()
