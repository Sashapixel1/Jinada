-- Dialog / CommF_ Deep Logger
-- Цель: узнать точный Instance, который летит в CommF_:InvokeServer("CDKQuest","BoatQuest", ...)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local CommF
pcall(function()
    CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
end)

----------------------------------------------------------------
-- GUI (широкий)
----------------------------------------------------------------
local StatusLogs = {}
local MaxLogs = 400

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DialogDeepLoggerGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 800, 0, 340)
MainFrame.Position = UDim2.new(0, 10, 0, 130)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 24)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.Text = "Dialog / CommF_ Deep Logger"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20
Title.Parent = MainFrame

local LogsFrame = Instance.new("Frame")
LogsFrame.Size = UDim2.new(1, -20, 0, 300)
LogsFrame.Position = UDim2.new(0, 10, 0, 30)
LogsFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
LogsFrame.BorderSizePixel = 0
LogsFrame.Parent = MainFrame

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -4, 1, -4)
Scroll.Position = UDim2.new(0, 2, 0, 2)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.CanvasSize = UDim2.new(0, 0, 5, 0)
Scroll.ScrollBarThickness = 6
Scroll.Parent = LogsFrame

local LogsText = Instance.new("TextLabel")
LogsText.Size = UDim2.new(1, -4, 0, 20)
LogsText.Position = UDim2.new(0, 0, 0, 0)
LogsText.BackgroundTransparency = 1
LogsText.TextColor3 = Color3.new(1,1,1)
LogsText.Font = Enum.Font.Code
LogsText.TextSize = 14
LogsText.TextXAlignment = Enum.TextXAlignment.Left
LogsText.TextYAlignment = Enum.TextYAlignment.Top
LogsText.TextWrapped = false
LogsText.Text = ""
LogsText.Parent = Scroll

local function AddLog(msg)
    local ts = os.date("%H:%M:%S")
    local line = "[" .. ts .. "] " .. tostring(msg)
    table.insert(StatusLogs, 1, line)
    if #StatusLogs > MaxLogs then
        table.remove(StatusLogs, #StatusLogs)
    end
    LogsText.Text = table.concat(StatusLogs, "\n")
end

AddLog("Deep logger загружен. Открой диалог с Luxury Boat Dealer и клацай Next / Pardon me.")

----------------------------------------------------------------
-- Ловим клики по TextButton (чисто для инфы)
----------------------------------------------------------------
local function HookButton(btn)
    if btn:GetAttribute("DeepLoggerHooked") then return end
    btn:SetAttribute("DeepLoggerHooked", true)

    local fullName = btn:GetFullName()

    local function onClick()
        AddLog("Button click: '" .. (btn.Text or "") .. "' [" .. fullName .. "]")
    end

    btn.Activated:Connect(onClick)
    if btn.MouseButton1Click then
        btn.MouseButton1Click:Connect(onClick)
    end
end

for _, inst in ipairs(PlayerGui:GetDescendants()) do
    if inst:IsA("TextButton") then
        HookButton(inst)
    end
end

PlayerGui.DescendantAdded:Connect(function(inst)
    if inst:IsA("TextButton") then
        HookButton(inst)
    end
end)

----------------------------------------------------------------
-- Хук на CommF_:InvokeServer (с детальным выводом BoatQuest)
----------------------------------------------------------------
local function formatArgShort(v)
    local t = typeof(v)
    if t == "string" or t == "number" or t == "boolean" then
        return tostring(v)
    elseif t == "Instance" then
        return string.format("%s[%s]", v.Name, v.ClassName)
    else
        return "[" .. t .. "]"
    end
end

pcall(function()
    if not (hookmetamethod and getnamecallmethod and typeof(CommF) == "Instance") then
        AddLog("⚠️ hookmetamethod недоступен, вижу только клики по кнопкам.")
        return
    end

    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if self == CommF and method == "InvokeServer" then
            -- короткая сводка
            local parts = {}
            for i, v in ipairs(args) do
                parts[i] = formatArgShort(v)
            end
            AddLog("CommF_:InvokeServer(" .. table.concat(parts, ", ") .. ")")

            -- детальный разбор, если это CDKQuest / BoatQuest
            if args[1] == "CDKQuest" and args[2] == "BoatQuest" then
                AddLog("  *** Детальный разбор CDKQuest / BoatQuest ***")
                for i = 1, #args do
                    local v = args[i]
                    local t = typeof(v)
                    if t == "Instance" then
                        local okFullName, full = pcall(function()
                            return v:GetFullName()
                        end)
                        AddLog(string.format(
                            "  Arg #%d: Instance name='%s', class='%s', full='%s'",
                            i,
                            v.Name,
                            v.ClassName,
                            okFullName and full or "GetFullName error"
                        ))
                    else
                        AddLog(string.format(
                            "  Arg #%d: value=%s, type=%s",
                            i,
                            tostring(v),
                            t
                        ))
                    end
                end
                AddLog("  *** Конец детального разбора ***")
            end
        end

        return old(self, ...)
    end)

    AddLog("Хук на CommF_:InvokeServer установлен.")
end)
