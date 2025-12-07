-- Dialog / Remote Logger
-- Ловит клики по кнопкам диалога и вызовы CommF_:InvokeServer
-- Инжектить отдельно, без авто-квеста

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local CommF
pcall(function()
    CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
end)

----------------------------------------------------------------
-- GUI логи
----------------------------------------------------------------
local StatusLogs = {}
local MaxLogs = 200

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DialogLoggerGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 480, 0, 260)
MainFrame.Position = UDim2.new(0, 20, 0, 200)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 24)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.Text = "Dialog / CommF_ Logger"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18
Title.Parent = MainFrame

local LogsFrame = Instance.new("Frame")
LogsFrame.Size = UDim2.new(1, -20, 0, 220)
LogsFrame.Position = UDim2.new(0, 10, 0, 30)
LogsFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
LogsFrame.BorderSizePixel = 0
LogsFrame.Parent = MainFrame

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -4, 1, -4)
Scroll.Position = UDim2.new(0, 2, 0, 2)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.CanvasSize = UDim2.new(0,0,5,0)
Scroll.ScrollBarThickness = 4
Scroll.Parent = LogsFrame

local LogsText = Instance.new("TextLabel")
LogsText.Size = UDim2.new(1, -4, 0, 20)
LogsText.Position = UDim2.new(0, 0, 0, 0)
LogsText.BackgroundTransparency = 1
LogsText.TextColor3 = Color3.new(1,1,1)
LogsText.Font = Enum.Font.Code
LogsText.TextSize = 12
LogsText.TextXAlignment = Enum.TextXAlignment.Left
LogsText.TextYAlignment = Enum.TextYAlignment.Top
LogsText.TextWrapped = false
LogsText.Text = ""
LogsText.Parent = Scroll

local function AddLog(msg)
    local ts = os.date("%H:%M:%S")
    local line = "["..ts.."] "..tostring(msg)
    table.insert(StatusLogs, 1, line)
    if #StatusLogs > MaxLogs then
        table.remove(StatusLogs, #StatusLogs)
    end
    LogsText.Text = table.concat(StatusLogs, "\n")
end

AddLog("Dialog logger загружен. Открой диалог и кликай кнопки.")

----------------------------------------------------------------
-- Хук на TextButton’ы
----------------------------------------------------------------
local function HookButton(btn)
    if btn:GetAttribute("DialogLoggerHooked") then return end
    btn:SetAttribute("DialogLoggerHooked", true)

    local fullName = btn:GetFullName()

    local function onClick()
        AddLog("Button click: '"..(btn.Text or "").."' ["..fullName.."]")
    end

    btn.Activated:Connect(onClick)
    if btn:IsA("TextButton") and btn.MouseButton1Click then
        btn.MouseButton1Click:Connect(onClick)
    end
end

-- уже существующие кнопки
for _, inst in ipairs(PlayerGui:GetDescendants()) do
    if inst:IsA("TextButton") then
        HookButton(inst)
    end
end

-- новые кнопки (когда появляется диалог)
PlayerGui.DescendantAdded:Connect(function(inst)
    if inst:IsA("TextButton") then
        HookButton(inst)
    end
end)

----------------------------------------------------------------
-- Хук на CommF_:InvokeServer
----------------------------------------------------------------
pcall(function()
    if not (hookmetamethod and getnamecallmethod and typeof(CommF) == "Instance") then
        AddLog("⚠️ hookmetamethod недоступен, лог только по кнопкам GUI.")
        return
    end

    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if self == CommF and method == "InvokeServer" then
            -- собираем аргументы в строку
            local parts = {}
            for i, v in ipairs(args) do
                local t = typeof(v)
                if t == "string" or t == "number" or t == "boolean" then
                    parts[i] = tostring(v)
                else
                    parts[i] = "["..t.."]"
                end
            end
            AddLog("CommF_:InvokeServer("..table.concat(parts, ", ")..")")
        end

        return old(self, ...)
    end)

    AddLog("Хук на CommF_:InvokeServer установлен.")
end)
