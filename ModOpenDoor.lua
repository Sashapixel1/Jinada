--========================================================
-- GUI
--========================================================
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Frame = Instance.new("Frame", ScreenGui)
local ToggleBtn = Instance.new("TextButton", Frame)
local StatusLight = Instance.new("Frame", Frame)
local LogBox = Instance.new("TextBox", Frame)

ScreenGui.Name = "OpenDoorTrialGUI"

Frame.Size = UDim2.new(0, 260, 0, 200)
Frame.Position = UDim2.new(0, 20, 0, 200)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 0

ToggleBtn.Size = UDim2.new(0, 120, 0, 35)
ToggleBtn.Position = UDim2.new(0, 10, 0, 10)
ToggleBtn.Text = "OFF"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ToggleBtn.TextColor3 = Color3.new(1,1,1)
ToggleBtn.BorderSizePixel = 0

StatusLight.Size = UDim2.new(0, 25, 0, 25)
StatusLight.Position = UDim2.new(0, 140, 0, 15)
StatusLight.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
StatusLight.BorderSizePixel = 0

LogBox.Size = UDim2.new(0, 240, 0, 130)
LogBox.Position = UDim2.new(0, 10, 0, 55)
LogBox.Text = ""
LogBox.TextColor3 = Color3.new(1,1,1)
LogBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
LogBox.ClearTextOnFocus = false
LogBox.TextXAlignment = Enum.TextXAlignment.Left
LogBox.TextYAlignment = Enum.TextYAlignment.Top
LogBox.TextWrapped = false
LogBox.MultiLine = true
LogBox.BorderSizePixel = 0

--========================================================
-- ЛОГ
--========================================================
local function AddLog(msg)
    LogBox.Text = LogBox.Text .. "\n" .. tostring(msg)
    LogBox.CursorPosition = #LogBox.Text + 1
end

--========================================================
--   OpenDoorTrial.Run()  — перенесённый модуль
--========================================================
local function OpenDoorTrial_Run(addLog)
    local log = typeof(addLog) == "function" and addLog or function(msg)
        print("[OpenDoorTrial] " .. tostring(msg))
    end

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

    log("Пробую открыть дверь: шаг 1 (OpenDoor).")
    local ok1, res1 = pcall(function()
        return CommF:InvokeServer("CDKQuest", "OpenDoor")
    end)

    if not ok1 then
        log("Ошибка на шаге 1: " .. tostring(res1))
        return false, res1
    end

    task.wait(0.3)

    log("Пробую открыть дверь: шаг 2 (OpenDoor, true).")
    local ok2, res2 = pcall(function()
        return CommF:InvokeServer("CDKQuest", "OpenDoor", true)
    end)

    if not ok2 then
        log("Ошибка на шаге 2: " .. tostring(res2))
        return false, res2
    end

    log("✅ Дверь триала должна быть открыта.")
    return true, res2
end

--========================================================
--  ЛОГИКА ВКЛ/ВЫКЛ
--========================================================
local Enabled = false
local Loop

local function UpdateLight()
    StatusLight.BackgroundColor3 = Enabled
        and Color3.fromRGB(0, 200, 0)
        or  Color3.fromRGB(180, 0, 0)

    ToggleBtn.Text = Enabled and "ON" or "OFF"
end

ToggleBtn.MouseButton1Click:Connect(function()
    Enabled = not Enabled
    UpdateLight()

    if Enabled then
        AddLog("=== Авто-OpenDoorTrial: ВКЛЮЧЕНО ===")

        Loop = task.spawn(function()
            while Enabled do
                local ok, err = OpenDoorTrial_Run(AddLog)

                if ok then
                    AddLog("Готово! Можно идти дальше.")
                else
                    AddLog("Ошибка: "..tostring(err))
                end

                task.wait(2)
            end
        end)

    else
        AddLog("=== Авто-OpenDoorTrial: ВЫКЛЮЧЕНО ===")
        if Loop then task.cancel(Loop) end
    end
end)

UpdateLight()
