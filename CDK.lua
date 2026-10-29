--========================================================
--  AutoCDK
--  1) Сначала качает Yama и Tushita до 350 мастери на Reborn Skeleton
--     в Haunted Castle, затем делает CommF_("CDKQuest","OpenDoor")
--  2) После открытия двери запускает связку:
--        AF 0 -> Yama1
--        AF 1 -> Yama2
--        AF 2 -> Yama3 (полный скрипт Bones+Hallow+HellDimension)
--        AF 3 -> Tushita1 (Trial Evil + Trial Good + BoatQuest)
--        AF 4 -> Tushita2 (Trial Good)
--        AF 5 -> Tushita3 (Trial Good + Cake Queen + HeavenlyDimension)
--        AF >=6 -> всё готово, AutoCDK выключается
--========================================================

---------------------
-- НАСТРОЙКИ
---------------------
local WeaponName         = "Godhuman"       -- чем бить мобов
local SwordYamaName      = "Yama"
local SwordTushitaName   = "Tushita"
local MasteryTarget      = 350

local TeleportSpeed      = 150             -- скорость полёта, stud/сек
local FarmOffset         = CFrame.new(0, 10, -3)

-- Castle on the Sea (Elite Hunter) для Yama1
local CastleOnSeaCFrame  = CFrame.new(-5494.08154, 313.794739, -2874.36621)

-- Haunted Castle / Death King (для мастери и Yama3)
local HauntedFallback    = CFrame.new(-9515.129, 142.233, 6200.441)

-- Soul Reaper spawn (Yama3)
local SoulReaperSpawnCF  = CFrame.new(-9570.033203125, 315.9346923828125, 6726.89306640625)

-- Максимум роллов костей в Yama3 (как в AutoBones)
local MaxRollsPerWindow  = 10
local RollWindowDuration = 2*60*60 + 5*60
local MinBonesToRoll     = 500

local Yama2PatrolPoints = {

    -- === СТАРЫЕ (валидные, не в воде) ===
    CFrame.new(-2293.2937, 38.3638916, -10241.7725),
    CFrame.new(5249.16113, 17.3900623, 400.869446),
    CFrame.new(-187.3301544189453, 86.23987579345703, 6013.513671875),
    CFrame.new(2286.0078125, 73.13391876220703, -7159.80908203125),
    CFrame.new(-12361.7060546875, 603.3547973632812, -6550.5341796875),
    CFrame.new(-13451.46484375, 543.712890625, -6961.0029296875),
    CFrame.new(-13274.478515625, 332.3781433105469, -7769.58056640625),
    CFrame.new(-13680.607421875, 501.08154296875, -6991.189453125),
    CFrame.new(-13457.904296875, 391.545654296875, -9859.177734375),
    CFrame.new(-12256.16015625, 331.73828125, -10485.8369140625),
    CFrame.new(-1887.8099365234375, 77.6185073852539, -12998.3505859375),
    CFrame.new(-21.55328369140625, 80.57499694824219, -12352.3876953125),
    CFrame.new(582.590576171875, 77.18809509277344, -12463.162109375),
    CFrame.new(-16641.6796875, 235.7825469970703, 1031.282958984375),
    CFrame.new(-16587.896484375, 154.21299743652344, 1533.40966796875),
    CFrame.new(-16885.203125, 114.12911224365234, 1627.949951171875),

    -- === CASTLE ON THE SEA (суша) ===
    CFrame.new(-5472.1201171875, 313.3, -2931.77),
    CFrame.new(-4890.1103515625, 320.0, -2980.21),
    CFrame.new(-5180.330078125, 316.7, -3400.88),

    -- === HAUNTED CASTLE — все точки сухие ===
    CFrame.new(-9515.129, 142.233, 6200.441),
    CFrame.new(-9450.55, 144.0, 6025.11),
    CFrame.new(-9605.98, 144.5, 6350.27),
    CFrame.new(-9705.44, 146.2, 6150.88),

    -- === CAKE QUEEN ISLAND (суша) ===
    CFrame.new(-709.31, 381.6, -11011.39),
    CFrame.new(-580.55, 380.9, -10840.22),
    CFrame.new(-840.77, 382.2, -11180.55),

    -- === SEA OF TREATS (суша) ===
    CFrame.new(2356.44, 72.8, -12890.6),
    CFrame.new(1331.7, 72.8, -13550.2),
    CFrame.new(920.77, 78.5, -12880.33),
    CFrame.new(555.44, 77.2, -11980.22),

    -- === MANSION / HYDRA PASS AREA ===
    CFrame.new(-12240.55, 332.0, -9850.77),
    CFrame.new(-11980.33, 332.0, -9450.88),
    CFrame.new(-11800.77, 332.0, -10120.55),

    -- === HYDRA ISLAND (новые ТОЛЬКО суша!) ===
    CFrame.new(-17100.55, 210.3, 1380.88),     -- центр возле мобов Forest Pirates
    CFrame.new(-16760.77, 230.1, 1820.44),     -- верхняя платформа Hydra
    CFrame.new(-16910.33, 198.0, 1050.22),     -- возле Gunman / Archer кемпа

    -- === FLOATING TURTLE (новые ТОЛЬКО суша!) ===
    CFrame.new(-10943.77, 333.4, -9128.55),    -- вход в деревню
    CFrame.new(-11320.22, 379.3, -10010.33),   -- кемп Forest Pirates
    CFrame.new(-11600.11, 450.2, -10340.44),   -- верхняя площадка с NPC / мобами
    CFrame.new(-11220.88, 390.8, -9600.77),    -- центр острова
}


-- Tushita Q1 (BoatQuest)
local TushitaQ1Points = {
    CFrame.new(-9546.990234375, 21.139892578125, 4686.1142578125),
    CFrame.new(-6120.0576171875, 16.455780029296875, -2250.697265625),
    CFrame.new(-9533.2392578125, 7.254445552825928, -8372.69921875),
}

-- Tushita Q2
local TushitaQ2Center         = CFrame.new(-5539.3115, 313.8005, -2972.3723)
local TushitaQ2InZoneRadius   = 500
local TushitaQ2MaxMobDistance = 2000

-- Tushita Q3 (Cake Queen + HeavenlyDimension)
local CakeQueenIsland = CFrame.new(-709.3132934570312, 381.6005859375, -11011.396484375)
local CakeQueenOffset = CFrame.new(0, 20, -3)

---------------------
-- СЕРВИСЫ
---------------------
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local VirtualUser       = game:GetService("VirtualUser")
local VirtualInput      = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local remote      = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

---------------------
-- СОСТОЯНИЯ
---------------------
local AutoCDK        = false
local CurrentStage   = -1           -- стадия по Alucard Fragment (0..6)
local NeedMastery    = true         -- пока не прокачали 350/350
local DoorOpened     = false

local IsTeleporting  = false
local StopTween      = false
local NoclipEnabled  = false

-- флаги квестов
local AutoYama1      = false
local AutoYama2      = false
local AutoYama3      = false
local AutoTushita1   = false
local AutoTushita2   = false
local AutoTushita3   = false

-- мастери
local LastMasteryCheck = 0

-- Yama2
local Yama2PatrolIndex   = 1
local Yama2PatrolHold    = 0
local Yama2LastPatrolHop = 0
local Yama2IsFighting    = false

-- Yama3 (Bones/Hallow)
local BonesCount      = 0
local RollsUsed       = 0
local HasHallow       = false
local RollWindowStart = os.time()
local IsFightingBones = false
local lastRollAttempt = 0

-- HeavenlyDimension (Tushita3)
local T3_HeavenlyStage = 0

---------------------
-- ME TERMINAL / GUI
---------------------
local UI = {Connections = {}, FollowLogs = true, Closed = false, CollisionState = {}}
local GuiAlive = true
local StatusLogs = {}
local MaxLogs = 250
local ScreenGui, MainFrame, BtnCDK
local StatusLabel, AFLabel, LogsText, MasteryLabel

local function TrackConnection(connection)
    table.insert(UI.Connections, connection)
    return connection
end

function UI.RestoreCollision()
    for part, canCollide in pairs(UI.CollisionState) do
        if part.Parent then pcall(function() part.CanCollide = canCollide end) end
    end
    UI.CollisionState = {}
end

local function RefreshLogs()
    if not LogsText or UI.Closed then return end
    local scroll = UI.LogScroll
    local previousY = scroll.CanvasPosition.Y
    local previousHeight = LogsText.AbsoluteSize.Y
    LogsText.Text = table.concat(StatusLogs, "\n")
    if UI.LogCount then UI.LogCount.Text = tostring(#StatusLogs).." / "..MaxLogs end
    task.defer(function()
        if UI.Closed or not scroll.Parent then return end
        UI.AdjustingLogScroll = true
        local maxY = math.max(0, scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteWindowSize.Y)
        local y = UI.FollowLogs and 0 or math.clamp(previousY + math.max(0, LogsText.AbsoluteSize.Y - previousHeight), 0, maxY)
        scroll.CanvasPosition = Vector2.new(0, y)
        UI.AdjustingLogScroll = false
    end)
end

local function AddLog(msg)
    if not GuiAlive then return end
    local line = "["..os.date("%H:%M:%S").."] "..tostring(msg)
    table.insert(StatusLogs, 1, line)
    if #StatusLogs > MaxLogs then table.remove(StatusLogs) end
    RefreshLogs()
    print(line)
end

local function UpdateStatus(text)
    if UI.Closed then return end
    if StatusLabel then StatusLabel.Text = tostring(text) end
    -- Repeated polling statuses do not drown out useful events.
    if UI.LastStatus ~= text then
        UI.LastStatus = text
        AddLog("Статус: "..tostring(text))
    end
end

local function UpdateAFLabel(count)
    if UI.Closed then return end
    if AFLabel then AFLabel.Text = (count ~= nil and tostring(count) or "?").." / 6" end
    if UI.FragmentFill then UI.FragmentFill.Size = UDim2.fromScale(math.clamp((count or 0) / 6, 0, 1), 1) end
end

local function UpdateMasteryLabel(yamaM, tushM)
    if UI.Closed then return end
    if MasteryLabel then MasteryLabel.Text = "Цель: "..MasteryTarget.." mastery" end
    for _, item in ipairs({{UI.YamaValue, UI.YamaFill, yamaM}, {UI.TushitaValue, UI.TushitaFill, tushM}}) do
        if item[1] then item[1].Text = item[3] ~= nil and tostring(item[3]) or "?" end
        if item[2] then item[2].Size = UDim2.fromScale(math.clamp((item[3] or 0) / MasteryTarget, 0, 1), 1) end
    end
end

local function CreateMainGui()
    local UIS = game:GetService("UserInputService")
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local sessionEnv = type(getgenv) == "function" and getgenv() or _G
    local previous = sessionEnv.__AutoCDKSession
    if type(previous) == "table" and type(previous.Close) == "function" then pcall(previous.Close) end
    local previousGui = pg:FindFirstChild("AutoCDKGui")
    if previousGui then previousGui:Destroy() end

    local theme = {
        Background = Color3.fromRGB(20,18,28), Sidebar = Color3.fromRGB(33,30,43),
        Surface = Color3.fromRGB(43,39,56), Field = Color3.fromRGB(16,14,24),
        Accent = Color3.fromRGB(191,153,255), Text = Color3.fromRGB(240,235,255),
        Muted = Color3.fromRGB(166,155,191), Border = Color3.fromRGB(91,75,116),
    }
    local function make(class, properties, parent)
        local obj = Instance.new(class)
        for key, value in pairs(properties) do obj[key] = value end
        obj.Parent = parent
        return obj
    end
    local function corner(obj, radius) make("UICorner", {CornerRadius = UDim.new(0, radius)}, obj) end
    local function stroke(obj, color, transparency)
        return make("UIStroke", {Color = color or theme.Border, Thickness = 1, Transparency = transparency or 0}, obj)
    end
    local function label(parent, text, size, position, textSize, color, font)
        return make("TextLabel", {BackgroundTransparency = 1, BorderSizePixel = 0,
            Size = size, Position = position, Text = text, TextSize = textSize or 13,
            TextColor3 = color or theme.Text, Font = font or Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
            TextTruncate = Enum.TextTruncate.None}, parent)
    end
    local function button(parent, name, text, size, position)
        local obj = make("TextButton", {Name = name, Size = size, Position = position,
            BackgroundColor3 = theme.Surface, BorderSizePixel = 0, Text = text,
            TextColor3 = theme.Text, Font = Enum.Font.GothamMedium, TextSize = 12,
            AutoButtonColor = false}, parent)
        corner(obj, 8)
        TrackConnection(obj.MouseEnter:Connect(function()
            if not UI.Closed then TweenService:Create(obj, TweenInfo.new(0.12), {BackgroundColor3 = theme.Border}):Play() end
        end))
        TrackConnection(obj.MouseLeave:Connect(function()
            if not UI.Closed then
                if obj == BtnCDK and UI.RenderRunning then UI.RenderRunning()
                else TweenService:Create(obj, TweenInfo.new(0.12), {BackgroundColor3 = theme.Surface}):Play() end
            end
        end))
        return obj
    end

    ScreenGui = make("ScreenGui", {Name = "AutoCDKGui", ResetOnSpawn = false,
        IgnoreGuiInset = true, DisplayOrder = 90, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, pg)
    MainFrame = make("Frame", {Name = "Window", BackgroundColor3 = theme.Background,
        BorderSizePixel = 0, Size = UDim2.fromOffset(610, 550), Position = UDim2.fromOffset(36, 100),
        Active = true, ClipsDescendants = true}, ScreenGui)
    corner(MainFrame, 16)
    stroke(MainFrame, theme.Accent, 0.35)
    local header = make("Frame", {Name = "Header", Size = UDim2.new(1,0,0,76),
        BackgroundColor3 = theme.Sidebar, BorderSizePixel = 0, Active = true}, MainFrame)
    local monogram = label(header, "CDK", UDim2.fromOffset(44,44), UDim2.fromOffset(18,16), 14, theme.Accent, Enum.Font.GothamBold)
    monogram.TextXAlignment = Enum.TextXAlignment.Center
    monogram.BackgroundColor3 = theme.Field
    monogram.BackgroundTransparency = 0
    corner(monogram, 12)
    stroke(monogram, theme.Border, 0.2)
    local title = label(header, "AUTO CDK", UDim2.new(1,-198,0,25), UDim2.fromOffset(76,14), 19, theme.Text, Enum.Font.GothamBold)
    title.TextTruncate = Enum.TextTruncate.AtEnd
    local subtitle = label(header, "ME TERMINAL  /  QUEST AUTOMATION", UDim2.new(1,-192,0,20), UDim2.fromOffset(76,40), 10, theme.Muted)
    subtitle.TextTruncate = Enum.TextTruncate.AtEnd
    make("Frame", {Size = UDim2.new(1,-36,0,1), Position = UDim2.new(0,18,1,-1),
        BackgroundColor3 = theme.Border, BackgroundTransparency = 0.45, BorderSizePixel = 0}, header)
    local minimize = button(header, "Minimize", "−", UDim2.fromOffset(30,30), UDim2.new(1,-88,0,20))
    minimize.TextSize = 23
    local close = button(header, "Close", "×", UDim2.fromOffset(30,30), UDim2.new(1,-48,0,20))
    close.TextSize = 23

    local body = make("ScrollingFrame", {Name = "BodyScroll", Size = UDim2.new(1,-28,1,-116),
        Position = UDim2.fromOffset(16,88), BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 4,
        ScrollBarImageColor3 = theme.Accent, ClipsDescendants = true,
        VerticalScrollBarInset = Enum.ScrollBarInset.Always}, MainFrame)
    local content = make("Frame", {Name = "Content", Size = UDim2.new(1,-10,0,0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, body)
    make("UIListLayout", {Padding = UDim.new(0,12), SortOrder = Enum.SortOrder.LayoutOrder}, content)

    local overview = make("Frame", {Name = "Progress", Size = UDim2.new(1,0,0,164),
        BackgroundColor3 = theme.Sidebar, BorderSizePixel = 0, LayoutOrder = 1}, content)
    corner(overview, 12)
    stroke(overview, theme.Border, 0.5)
    label(overview, "ALUCARD FRAGMENTS", UDim2.new(1,-160,0,20), UDim2.fromOffset(16,10), 10, theme.Muted, Enum.Font.GothamMedium)
    AFLabel = label(overview, "? / 6", UDim2.fromOffset(112,25), UDim2.new(1,-128,0,8), 20, theme.Accent, Enum.Font.GothamBold)
    AFLabel.Name = "FragmentValue"
    AFLabel.TextXAlignment = Enum.TextXAlignment.Right
    local fragmentTrack = make("Frame", {Size = UDim2.new(1,-32,0,3), Position = UDim2.fromOffset(16,39),
        BackgroundColor3 = theme.Surface, BorderSizePixel = 0, ClipsDescendants = true}, overview)
    corner(fragmentTrack, 2)
    UI.FragmentFill = make("Frame", {Name = "Fill", Size = UDim2.fromScale(0,1), BackgroundColor3 = theme.Accent, BorderSizePixel = 0}, fragmentTrack)
    StatusLabel = label(overview, "Остановлен", UDim2.new(1,-32,0,32), UDim2.fromOffset(16,48), 12, theme.Text)
    StatusLabel.Name = "Status"
    StatusLabel.TextWrapped = true
    MasteryLabel = label(overview, "Цель: "..MasteryTarget.." mastery", UDim2.new(1,-32,0,18), UDim2.fromOffset(16,84), 10, theme.Muted)
    local function masteryRow(name, x)
        local cell = make("Frame", {Size = UDim2.new(0.5,-24,0,46), Position = UDim2.new(x,16,0,108), BackgroundTransparency = 1}, overview)
        label(cell, name, UDim2.new(1,-55,0,20), UDim2.fromOffset(0,0), 12, theme.Text, Enum.Font.GothamMedium)
        local value = label(cell, "?", UDim2.fromOffset(55,20), UDim2.new(1,-55,0,0), 13, theme.Accent, Enum.Font.Code)
        value.TextXAlignment = Enum.TextXAlignment.Right
        value.Name = name.."Value"
        local track = make("Frame", {Size = UDim2.new(1,0,0,4), Position = UDim2.fromOffset(0,29), BackgroundColor3 = theme.Surface, BorderSizePixel = 0, ClipsDescendants = true}, cell)
        corner(track, 2)
        local fill = make("Frame", {Size = UDim2.fromScale(0,1), BackgroundColor3 = theme.Accent, BorderSizePixel = 0}, track)
        corner(fill, 2)
        return value, fill
    end
    UI.YamaValue, UI.YamaFill = masteryRow("YAMA", 0)
    UI.TushitaValue, UI.TushitaFill = masteryRow("TUSHITA", 0.5)

    BtnCDK = button(content, "ToggleAutoCDK", "ЗАПУСТИТЬ AUTO CDK", UDim2.new(1,0,0,44), UDim2.fromOffset(0,0))
    BtnCDK.LayoutOrder = 2
    BtnCDK.Font = Enum.Font.GothamBold
    BtnCDK.TextSize = 13
    UI.RenderRunning = function()
        if UI.Closed then return end
        BtnCDK.Text = AutoCDK and "ПРИОСТАНОВИТЬ AUTO CDK" or "ЗАПУСТИТЬ AUTO CDK"
        BtnCDK.BackgroundColor3 = AutoCDK and theme.Surface or theme.Accent
        BtnCDK.TextColor3 = AutoCDK and theme.Accent or theme.Field
        if UI.RunningIndicator then UI.RunningIndicator.Text = AutoCDK and "●  РАБОТАЕТ" or "○  ОЖИДАНИЕ" end
    end
    UI.RenderRunning()

    local logsCard = make("Frame", {Name = "LogsCard", Size = UDim2.new(1,0,0,200),
        LayoutOrder = 3, BackgroundColor3 = theme.Field, BorderSizePixel = 0, ClipsDescendants = true}, content)
    corner(logsCard, 12)
    stroke(logsCard, theme.Border, 0.5)
    label(logsCard, "ЖУРНАЛ", UDim2.fromOffset(80,22), UDim2.fromOffset(14,9), 10, theme.Muted, Enum.Font.GothamMedium)
    UI.LogCount = label(logsCard, "0 / "..MaxLogs, UDim2.fromOffset(70,20), UDim2.fromOffset(14,31), 10, theme.Muted, Enum.Font.Code)
    local follow = button(logsCard, "FollowLogs", "Авто: вкл", UDim2.fromOffset(88,26), UDim2.new(1,-192,0,13))
    local clear = button(logsCard, "ClearLogs", "Очистить", UDim2.fromOffset(82,26), UDim2.new(1,-96,0,13))
    UI.UpdateFollow = function() follow.Text = UI.FollowLogs and "Авто: вкл" or "Авто: выкл" end
    UI.LogScroll = make("ScrollingFrame", {Name = "LogScroll", Size = UDim2.new(1,-20,1,-66),
        Position = UDim2.fromOffset(12,57), BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 4,
        ScrollBarImageColor3 = theme.Accent, ClipsDescendants = true,
        VerticalScrollBarInset = Enum.ScrollBarInset.Always}, logsCard)
    LogsText = label(UI.LogScroll, "", UDim2.new(1,-12,0,0), UDim2.fromOffset(0,0), 12, theme.Muted, Enum.Font.Code)
    LogsText.Name = "LogText"
    LogsText.AutomaticSize = Enum.AutomaticSize.Y
    LogsText.TextWrapped = true
    LogsText.TextYAlignment = Enum.TextYAlignment.Top
    LogsText.RichText = false
    LogsText.LineHeight = 1.2
    TrackConnection(follow.Activated:Connect(function()
        UI.FollowLogs = not UI.FollowLogs
        UI.UpdateFollow()
        if UI.FollowLogs then UI.LogScroll.CanvasPosition = Vector2.new(0,0) end
    end))
    TrackConnection(clear.Activated:Connect(function()
        StatusLogs = {}
        RefreshLogs()
    end))
    TrackConnection(UI.LogScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if not UI.AdjustingLogScroll and UI.LogScroll.CanvasPosition.Y > 8 and UI.FollowLogs then
            UI.FollowLogs = false
            UI.UpdateFollow()
        end
    end))

    UI.RunningIndicator = label(MainFrame, "○  ОЖИДАНИЕ", UDim2.fromOffset(135,20), UDim2.new(0,18,1,-24), 10, theme.Accent, Enum.Font.GothamMedium)
    label(MainFrame, "Новые события сверху", UDim2.fromOffset(170,20), UDim2.new(1,-198,1,-24), 10, theme.Muted)
    local resize = make("TextButton", {Name = "ResizeHandle", Size = UDim2.fromOffset(24,24),
        Position = UDim2.new(1,-25,1,-25), Text = "◢", TextSize = 18, TextColor3 = theme.Accent,
        BackgroundTransparency = 1, AutoButtonColor = false, ZIndex = 5}, MainFrame)

    local launcher = make("ImageButton", {Name = "Launcher", Size = UDim2.fromOffset(64,64),
        Position = UDim2.fromOffset(24,180), BackgroundColor3 = theme.Sidebar,
        BorderSizePixel = 0, AutoButtonColor = false, Visible = false, ScaleType = Enum.ScaleType.Crop}, ScreenGui)
    corner(launcher, 16)
    stroke(launcher, theme.Accent, 0)
    local badge = label(launcher, "CDK", UDim2.fromOffset(32,16), UDim2.new(1,-35,1,-20), 9, theme.Accent, Enum.Font.GothamBold)
    badge.BackgroundColor3 = theme.Field
    badge.BackgroundTransparency = 0.15
    badge.TextXAlignment = Enum.TextXAlignment.Center
    corner(badge, 5)
    UI.Launcher = launcher
    -- The supplied portrait is bundled. No URL or Roblox upload is needed.
    local function loadLauncherImage()
        local asset = getcustomasset or getsynasset
        if type(writefile) ~= "function" or type(asset) ~= "function" then return end
        local encoded = "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"
        local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local codes = {}
        for index = 1, #alphabet do codes[alphabet:sub(index,index)] = index - 1 end
        local bytes, buffer, bits = {}, 0, 0
        for index = 1, #encoded do
            local value = codes[encoded:sub(index,index)]
            if value then
                buffer = buffer * 64 + value
                bits = bits + 6
                if bits >= 8 then
                    bits = bits - 8
                    local divisor = 2 ^ bits
                    bytes[#bytes+1] = string.char(math.floor(buffer / divisor) % 256)
                    buffer = buffer % divisor
                end
            end
        end
        local filename = "AutoCDK_launcher.png"
        writefile(filename, table.concat(bytes))
        launcher.Image = asset(filename)
    end
    local loaded, imageError = pcall(loadLauncherImage)
    if not loaded then AddLog("Картинка кнопки: "..tostring(imageError)) end

    local function viewport()
        return Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
    end
    local function fitWindow(width, height, x, y)
        local view = viewport()
        local maxWidth, maxHeight = math.max(1, view.X - 16), math.max(1, view.Y - 16)
        width = math.clamp(width, math.min(360,maxWidth), maxWidth)
        height = math.clamp(height, math.min(300,maxHeight), maxHeight)
        MainFrame.Size = UDim2.fromOffset(width,height)
        MainFrame.Position = UDim2.fromOffset(math.clamp(x,8,math.max(8,view.X-width-8)), math.clamp(y,8,math.max(8,view.Y-height-8)))
        logsCard.Size = UDim2.new(1,0,0,math.max(180,height-362))
    end
    UI.FitWindow = fitWindow
    UI.SetMinimized = function(value)
        if UI.Closed then return end
        MainFrame.Visible = not value
        launcher.Visible = value
        UI.Minimized = value
        if not value then
            fitWindow(MainFrame.Size.X.Offset,MainFrame.Size.Y.Offset,MainFrame.Position.X.Offset,MainFrame.Position.Y.Offset)
        end
    end
    local function stopAutomation()
        AutoCDK = false
        NoclipEnabled = false
        StopTween = true
        AutoYama1, AutoYama2, AutoYama3 = false, false, false
        AutoTushita1, AutoTushita2, AutoTushita3 = false, false, false
        UI.RestoreCollision()
    end
    UI.Close = function()
        if UI.Closed then return end
        stopAutomation()
        UI.Closed = true
        GuiAlive = false
        for _, connection in ipairs(UI.Connections) do connection:Disconnect() end
        UI.Connections = {}
        if sessionEnv.__AutoCDKSession == UI then sessionEnv.__AutoCDKSession = nil end
        if ScreenGui then ScreenGui:Destroy() end
    end
    sessionEnv.__AutoCDKSession = UI
    TrackConnection(close.Activated:Connect(UI.Close))
    TrackConnection(minimize.Activated:Connect(function() UI.SetMinimized(true) end))
    TrackConnection(launcher.Activated:Connect(function()
        if not UI.LauncherMoved then UI.SetMinimized(false) end
    end))
    TrackConnection(BtnCDK.Activated:Connect(function()
        AutoCDK = not AutoCDK
        if AutoCDK then
            NoclipEnabled = true
            StopTween = false
            UpdateStatus("Auto CDK включен. Сначала мастери, потом квесты.")
        else
            stopAutomation()
            UpdateStatus("Остановлен")
        end
        UI.RenderRunning()
    end))

    local gesture
    local function begin(input, target, mode)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        gesture = {Input = input, Target = target, Mode = mode, Start = Vector2.new(input.Position.X,input.Position.Y),
            Position = target.Position, Size = target.Size}
        if target == launcher then UI.LauncherMoved = false end
    end
    TrackConnection(header.InputBegan:Connect(function(input)
        if input.Position.X < header.AbsolutePosition.X + header.AbsoluteSize.X - 104 then begin(input,MainFrame,"drag") end
    end))
    TrackConnection(resize.InputBegan:Connect(function(input) begin(input,MainFrame,"resize") end))
    TrackConnection(launcher.InputBegan:Connect(function(input) begin(input,launcher,"drag") end))
    TrackConnection(UIS.InputChanged:Connect(function(input)
        if not gesture then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input ~= gesture.Input then return end
        local delta = Vector2.new(input.Position.X,input.Position.Y) - gesture.Start
        local start, size = gesture.Position, gesture.Size
        if gesture.Target == launcher then
            if delta.Magnitude > 5 then UI.LauncherMoved = true end
            local view = viewport()
            launcher.Position = UDim2.fromOffset(math.clamp(start.X.Offset+delta.X,8,math.max(8,view.X-72)), math.clamp(start.Y.Offset+delta.Y,8,math.max(8,view.Y-72)))
        elseif gesture.Mode == "resize" then
            local view = viewport()
            fitWindow(math.min(size.X.Offset+delta.X,view.X-start.X.Offset-8), math.min(size.Y.Offset+delta.Y,view.Y-start.Y.Offset-8), start.X.Offset,start.Y.Offset)
        else
            fitWindow(size.X.Offset,size.Y.Offset,start.X.Offset+delta.X,start.Y.Offset+delta.Y)
        end
    end))
    TrackConnection(UIS.InputEnded:Connect(function(input)
        if gesture and input == gesture.Input then gesture = nil end
    end))
    local function fitViewport()
        if UI.Closed then return end
        fitWindow(MainFrame.Size.X.Offset,MainFrame.Size.Y.Offset,MainFrame.Position.X.Offset,MainFrame.Position.Y.Offset)
        local view = viewport()
        launcher.Position = UDim2.fromOffset(math.clamp(launcher.Position.X.Offset,8,math.max(8,view.X-72)),math.clamp(launcher.Position.Y.Offset,8,math.max(8,view.Y-72)))
    end
    if Workspace.CurrentCamera then TrackConnection(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitViewport)) end
    TrackConnection(ScreenGui.Destroying:Connect(function() if not UI.Closed then UI.Close() end end))
    fitViewport()
    RefreshLogs()
    AddLog("ME Terminal готов. Перетаскивай заголовок, меняй размер за правый нижний угол.")
end

CreateMainGui()

---------------------
-- ANTI-AFK
---------------------
spawn(function()
    while task.wait(60) and GuiAlive do
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

---------------------
-- NOCLIP
---------------------
spawn(function()
    while task.wait(0.1) and GuiAlive do
        if NoclipEnabled then
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if UI.CollisionState[part] == nil then UI.CollisionState[part] = part.CanCollide end
                        part.CanCollide = false
                    end
                end
            end
        elseif next(UI.CollisionState) then
            UI.RestoreCollision()
        end
    end
end)

---------------------
-- NET / FAST ATTACK
---------------------
-- Resolve events without blocking the entire script when Net is unavailable.
local AttackModule = { LastAttack = 0, LastError = 0 }

function AttackModule:AttackEnemyModel(enemyModel)
    if not AutoCDK or StopTween or not enemyModel or not enemyModel.Parent then return false end
    local char = LocalPlayer.Character
    local playerHum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hrp = enemyModel:FindFirstChild("HumanoidRootPart")
    local hum = enemyModel:FindFirstChildOfClass("Humanoid")
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not (root and playerHum and playerHum.Health > 0 and hrp and hum and hum.Health > 0 and tool) then
        return false
    end
    if (root.Position - hrp.Position).Magnitude > 60 then return false end
    if tick() - self.LastAttack < 0.15 then return false end
    self.LastAttack = tick()

    local modules = ReplicatedStorage:FindFirstChild("Modules")
    local net = modules and modules:FindFirstChild("Net")
    local registerAttack = net and net:FindFirstChild("RE/RegisterAttack")
    local registerHit = net and net:FindFirstChild("RE/RegisterHit")
    local ok, err = pcall(function()
        if registerAttack and registerAttack:IsA("RemoteEvent")
            and registerHit and registerHit:IsA("RemoteEvent") then
            registerAttack:FireServer(0)
            registerHit:FireServer(hrp, { {enemyModel, hrp} })
        else
            tool:Activate()
        end
    end)
    if not ok and tick() - self.LastError > 3 then
        self.LastError = tick()
        AddLog("Ошибка атаки: "..tostring(err))
    end
    return ok
end

---------------------
-- ЭКИП / ХАКИ
---------------------
local function AutoHaki()
    local char = LocalPlayer.Character
    if not char then return end
    if not char:FindFirstChild("HasBuso") then
        pcall(function()
            remote:InvokeServer("Buso")
        end)
    end
end

local lastEquipFailLog = 0

local function IsToolEquipped(name)
    local char = LocalPlayer.Character
    if not char then return false end
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") and string.lower(obj.Name) == string.lower(name) then
            return true
        end
    end
    return false
end

local function EquipToolByName(name)
    if IsToolEquipped(name) then return end

    local p   = LocalPlayer
    if not p then return end

    local char = p.Character or p.CharacterAdded:Wait()
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local nameLower = string.lower(name)
    local toolFound

    local function findToolIn(container)
        if not container then return nil end
        for _, obj in ipairs(container:GetChildren()) do
            if obj:IsA("Tool") and string.lower(obj.Name) == nameLower then
                return obj
            end
        end
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("Tool") and string.lower(obj.Name) == nameLower then
                return obj
            end
        end
        return nil
    end

    local backpack = p:FindFirstChild("Backpack")
    if backpack then
        toolFound = findToolIn(backpack)
    end
    if not toolFound and char then
        toolFound = findToolIn(char)
    end

    if toolFound then
        hum:UnequipTools()
        hum:EquipTool(toolFound)
        AddLog("⚔️ Экипирован: "..toolFound.Name)
    else
        if tick() - lastEquipFailLog > 3 then
            AddLog("⚠️ Не удалось найти оружие: "..name)
            lastEquipFailLog = tick()
        end
    end
end

---------------------
-- ПОЛЁТ (без коррекции откидываний и повторных запусков)
---------------------
local function SimpleTeleport(targetCFrame, label, shouldInterrupt)
    if not AutoCDK or StopTween or IsTeleporting then return false end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return false end

    IsTeleporting = true
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    -- No upper time limit: long routes must retain the configured speed.
    local travelTime = math.max(distance / math.max(TeleportSpeed, 1), 0.1)
    AddLog(string.format("Полёт к %s (%.0f stud, %.0f stud/сек, t=%.1f)",
        label or "цели", distance, TeleportSpeed, travelTime))

    local tween
    local ok, result = pcall(function()
        tween = TweenService:Create(hrp,
            TweenInfo.new(travelTime, Enum.EasingStyle.Linear),
            {CFrame = targetCFrame})
        tween:Play()
        while tween.PlaybackState == Enum.PlaybackState.Playing do
            if StopTween or not AutoCDK or LocalPlayer.Character ~= char
                or not hrp.Parent or hum.Health <= 0
                or (shouldInterrupt and shouldInterrupt()) then
                AddLog("Полёт прерван.")
                return false
            end
            task.wait(0.05)
        end
        return tween.PlaybackState == Enum.PlaybackState.Completed
    end)

    if tween and tween.PlaybackState ~= Enum.PlaybackState.Completed then
        tween:Cancel()
    end
    IsTeleporting = false
    if not ok then
        AddLog("Ошибка полёта: "..tostring(result))
        return false
    end
    -- The tween finishes naturally; do not snap CFrame to the destination.
    return result
end

TrackConnection(LocalPlayer.CharacterAdded:Connect(function(char)
    IsTeleporting = false
    StopTween     = not AutoCDK
    AddLog("Персонаж возрождён, HRP обновлён.")
    char:WaitForChild("HumanoidRootPart", 10)
end))

---------------------
-- ИНВЕНТАРЬ / МАТЕРИАЛЫ / МАСТЕРИ
---------------------
local function GetInventory()
    local ok, inv = pcall(function()
        return remote:InvokeServer("getInventory")
    end)
    if ok and type(inv) == "string" then
        local decoded, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(inv)
        end)
        if decoded then inv = data end
    end
    if ok and type(inv) == "table" then
        return inv, true
    end
    return {}, false, ok and ("тип ответа: "..type(inv)) or tostring(inv)
end

-- Current inventory protocol, verified in the running client:
-- RF/GetAllItemValues -> { { ItemId = 578, Key = "Quantity", Value = 2 }, ... }
-- Names/IDs come from Generated.Configs[*].Index.StorageKey / Index.ItemId.
local MaterialIds = {}
local MaterialIdLoadTime = -math.huge
local MaterialQuantities = nil
local MaterialScanTime = -math.huge
local MaterialSuccessTime = -math.huge
local MaterialScanBusy = false
local LastMaterialWarning = -math.huge
local MaterialSourceLogged = false

local function NormalizeMaterialName(name)
    local normalized = string.lower(tostring(name)):gsub("[^%w]", "")
    if normalized == "alucardfragments" then return "alucardfragment" end
    return normalized
end

local function GetMaterialId(materialName)
    local wanted = NormalizeMaterialName(materialName)
    if MaterialIds[wanted] then return MaterialIds[wanted] end
    if tick() - MaterialIdLoadTime >= 10 then
        MaterialIdLoadTime = tick()
        local itemConfig = ReplicatedStorage:FindFirstChild("ItemConfig")
        local generated = itemConfig and itemConfig:FindFirstChild("Generated")
        local module = generated and generated:FindFirstChild("Configs")
        if module then
            local ok, data = pcall(require, module)
            if ok and type(data) == "table" and type(data.Configs) == "table" then
                for _, config in pairs(data.Configs) do
                    local index = type(config) == "table" and config.Index
                    if type(index) == "table" and index.IdType == "Material"
                        and type(index.StorageKey) == "string" and tonumber(index.ItemId) then
                        MaterialIds[NormalizeMaterialName(index.StorageKey)] = tonumber(index.ItemId)
                    end
                end
            end
        end
    end
    return MaterialIds[wanted]
end

local function ParseItemQuantities(rows)
    if type(rows) ~= "table" then return nil, "ответ не является таблицей" end
    local items, validRecords = {}, false
    for _, row in pairs(rows) do
        if type(row) == "table" and tonumber(row.ItemId) and type(row.Key) == "string" then
            validRecords = true
            -- IsOwned/Mastery/Upgrade are independent properties, never quantities.
            if row.Key == "Quantity" then
                local value = tonumber(row.Value)
                if not value or value ~= value or value < 0 or value >= math.huge or value % 1 ~= 0 then
                    return nil, "неверное Quantity у ItemId="..tostring(row.ItemId)
                end
                local id = tonumber(row.ItemId)
                local uid = row.NetworkedUID or "aggregate"
                items[id] = items[id] or {}
                items[id][uid] = value
            end
        end
    end
    if not validRecords then return nil, "пустой или неизвестный формат GetAllItemValues" end
    local counts = {}
    for id, instances in pairs(items) do
        local total = 0
        for _, quantity in pairs(instances) do total = total + quantity end
        counts[id] = total
    end
    return counts
end

local function GetCountMaterials(materialName)
    local id = GetMaterialId(materialName)
    if not id then
        if tick() - LastMaterialWarning >= 10 then
            LastMaterialWarning = tick()
            AddLog("Материалы: нет ItemId для "..materialName.." в ItemConfig.Generated.Configs")
        end
        return nil
    end
    if not MaterialScanBusy and tick() - MaterialScanTime >= 1 then
        MaterialScanBusy = true
        MaterialScanTime = tick()
        local ok, counts, err = pcall(function()
            local modules = ReplicatedStorage:FindFirstChild("Modules")
            local net = modules and modules:FindFirstChild("Net")
            local getValues = net and net:FindFirstChild("RF/GetAllItemValues")
            if not getValues then return nil, "RF/GetAllItemValues не найден" end
            return ParseItemQuantities(getValues:InvokeServer())
        end)
        MaterialScanBusy = false
        if ok and counts then
            MaterialQuantities = counts
            MaterialSuccessTime = tick()
            if not MaterialSourceLogged then
                MaterialSourceLogged = true
                AddLog("Материалы: RF/GetAllItemValues, количество из Quantity по ItemId")
            end
        elseif tick() - LastMaterialWarning >= 10 then
            LastMaterialWarning = tick()
            AddLog("Материалы: "..tostring(ok and err or counts))
        end
    end
    -- A failed request must not reset the quest to stage zero.
    if not MaterialQuantities or tick() - MaterialSuccessTime > 5 then return nil end
    return MaterialQuantities[id] or 0
end

local MasteryCache = {}
local LastMasteryLoad = -math.huge

local function ReadToolMastery(tool)
    for _, key in ipairs({"Level", "Mastery", "MasteryLevel"}) do
        local value = tool:FindFirstChild(key)
        local number = value and value:IsA("ValueBase") and tonumber(value.Value)
        if number and number >= 0 then return number end
        local attribute = tool:GetAttribute(key)
        number = tonumber(attribute)
        if number and number >= 0 then return number end
    end
    return nil
end

local function GetWeaponMastery(name)
    local best = MasteryCache[name]
    local function remember(value)
        local number = tonumber(value)
        if number and number >= 0 then
            best = math.max(best or 0, number)
        end
    end
    -- Equipped weapons live in Character; unequipped weapons live in Backpack.
    for _, containerName in ipairs({"Character", "Backpack"}) do
        local container = containerName == "Character" and LocalPlayer.Character
            or LocalPlayer:FindFirstChild("Backpack")
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and string.lower(tool.Name) == string.lower(name) then
                    remember(ReadToolMastery(tool))
                end
            end
        end
    end
    -- Inventory responses may omit mastery entirely. Missing data is not level 0.
    if best == nil then
        for _, item in pairs(GetInventory()) do
            if type(item) == "table" and item.Name == name then
                remember(item.Mastery)
                remember(item.Level)
                remember(item.MasteryLevel)
            end
        end
    end
    MasteryCache[name] = best
    return best
end

local function LoadSwordForMastery(name)
    if tick() - LastMasteryLoad < 3 then return end
    LastMasteryLoad = tick()
    UpdateStatus("Читаю мастери: "..name)
    local ok, err = pcall(function()
        remote:InvokeServer("LoadItem", name)
    end)
    if not ok then AddLog("Не удалось загрузить "..name..": "..tostring(err)) end
end

---------------------
-- CDKTrialModule (StartTrial Evil / Good с Option1)
---------------------
local function ClickDialogueOption1(tag)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    local main = pg:FindFirstChild("Main")
    if not main then return end
    local dialogue = main:FindFirstChild("Dialogue")
    if not dialogue then return end
    local opt1 = dialogue:FindFirstChild("Option1")
    if opt1 and opt1:IsA("TextButton") then
        AddLog((tag or "").." Нажимаю Dialogue.Option1 два раза.")
        if typeof(firesignal) == "function" then
            pcall(firesignal, opt1.MouseButton1Click)
            pcall(firesignal, opt1.MouseButton1Click)
        else
            -- fallback: имитация клика через VirtualInput по центру кнопки
            local absPos = opt1.AbsolutePosition
            local absSize = opt1.AbsoluteSize
            local cx = absPos.X + absSize.X/2
            local cy = absPos.Y + absSize.Y/2
            VirtualInput:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
            VirtualInput:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
            VirtualInput:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
            VirtualInput:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
        end
    else
        AddLog((tag or "").." Dialogue.Option1 не найден.")
    end
end

local CDKTrialModule = {}

function CDKTrialModule.StartGoodTrial()
    AddLog("[Trial Good] Progress...")
    local okP, resP = pcall(function()
        return remote:InvokeServer("CDKQuest", "Progress", "Good")
    end)
    AddLog("[Trial Good] Progress => "..tostring(resP))

    task.wait(0.2)

    AddLog("[Trial Good] StartTrial...")
    local okS, resS = pcall(function()
        return remote:InvokeServer("CDKQuest", "StartTrial", "Good")
    end)
    AddLog("[Trial Good] StartTrial => "..tostring(resS))

    task.wait(0.1)
    ClickDialogueOption1("[Trial Good]")
end

function CDKTrialModule.StartEvilTrial()
    AddLog("[Trial Evil] Progress...")
    local okP, resP = pcall(function()
        return remote:InvokeServer("CDKQuest", "Progress", "Evil")
    end)
    AddLog("[Trial Evil] Progress => "..tostring(resP))

    task.wait(0.2)

    AddLog("[Trial Evil] StartTrial...")
    local okS, resS = pcall(function()
        return remote:InvokeServer("CDKQuest", "StartTrial", "Evil")
    end)
    AddLog("[Trial Evil] StartTrial => "..tostring(resS))

    task.wait(0.1)
    ClickDialogueOption1("[Trial Evil]")
end

---------------------
-- HAUNTED / SKELETON HELPERS (общие)
---------------------
local function FindDeathKingModel()
    local candidate
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Death King" then
            if obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") then
                candidate = obj
                break
            end
        end
    end
    return candidate
end

local function GetHauntedCenterCFrame()
    local dk = FindDeathKingModel()
    if dk then
        local hrp = dk:FindFirstChild("HumanoidRootPart") or dk:FindFirstChild("Head")
        if hrp then
            return hrp.CFrame
        end
    end
    return HauntedFallback
end

local function IsSkeletonMob(mob)
    local n = tostring(mob.Name)
    if string.find(n, "Reborn Skeleton") then return true end
    if string.find(n, "Skeleton") then return true end
    if string.find(n, "Living Skeleton") then return true end
    return false
end

local function GetNearestSkeleton(maxDistance)
    maxDistance = maxDistance or 9999
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local center = GetHauntedCenterCFrame()
    local best, nearest = maxDistance, nil

    for _, v in ipairs(enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            if IsSkeletonMob(v) then
                local distFromCenter = (v.HumanoidRootPart.Position - center.Position).Magnitude
                if distFromCenter < 800 then
                    local d = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < best then
                        best    = d
                        nearest = v
                    end
                end
            end
        end
    end
    return nearest
end

local function EnsureOnHauntedIsland()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hrp) then return false end

    local center = GetHauntedCenterCFrame()
    local dist   = (hrp.Position - center.Position).Magnitude
    if dist > 600 then
        UpdateStatus("Лечу к Haunted Castle.")
        SimpleTeleport(center * CFrame.new(0,4,3), "Haunted Castle")
        task.wait(1)
        return false
    end
    return true
end

---------------------
-- МАСТЕРИ-ФАРМ (Reborn Skeleton)
---------------------
local function FightMobForWeapon(target, weaponName, label)
    if not target then return end
    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        local hum  = target:FindFirstChild("Humanoid")
        if not (char and hrp and tHRP and hum) then return end

        UpdateStatus(label or ("Фарм мастери: "..weaponName.." по "..target.Name))
        SimpleTeleport(tHRP.CFrame * FarmOffset, label or "мастери моб")

        local deadline      = tick() + 60
        local lastPosAdjust = 0
        local lastAttack    = 0

        while AutoCDK and NeedMastery and target.Parent and hum.Health > 0 and tick() < deadline do
            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            hum  = target:FindFirstChild("Humanoid")
            if not (char and hrp and tHRP and hum) then break end

            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 2000 then
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий моб мастери")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * FarmOffset
                    hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide = false
                    lastPosAdjust = tick()
                end
            end

            AutoHaki()
            EquipToolByName(weaponName)

            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end
    end)

    if not ok then
        AddLog("Ошибка FightMobForWeapon: "..tostring(err))
    end
end

local function MasteryTick()
    if not AutoCDK or not NeedMastery then return end

    local yamaM  = GetWeaponMastery(SwordYamaName)
    local tushM  = GetWeaponMastery(SwordTushitaName)
    UpdateMasteryLabel(yamaM, tushM)

    if yamaM == nil then LoadSwordForMastery(SwordYamaName); return end
    if tushM == nil then LoadSwordForMastery(SwordTushitaName); return end

    if yamaM >= MasteryTarget and tushM >= MasteryTarget then
        if not DoorOpened then
            UpdateStatus("Мастери достигнуты, открываю дверь CDK.")
            local ok, res = pcall(function()
                return remote:InvokeServer("CDKQuest","OpenDoor")
            end)
            AddLog("OpenDoor => "..tostring(res))
            DoorOpened = true
        end
        NeedMastery = false
        UpdateStatus("Мастери готовы, перехожу к Yama/Tushita квестам.")
        return
    end

    if not EnsureOnHauntedIsland() then return end

    local sword = yamaM < MasteryTarget and SwordYamaName or SwordTushitaName
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not ((char and char:FindFirstChild(sword)) or (backpack and backpack:FindFirstChild(sword))) then
        LoadSwordForMastery(sword)
        return
    end

    local target = GetNearestSkeleton(9999)
    if not target then
        UpdateStatus("Mastery: скелеты не найдены, жду спавна.")
        return
    end

    if yamaM < MasteryTarget then
        FightMobForWeapon(target, SwordYamaName, "Mastery: Yama")
    elseif tushM < MasteryTarget then
        FightMobForWeapon(target, SwordTushitaName, "Mastery: Tushita")
    end
end

---------------------
-- YAMA QUEST 1
---------------------
local function YamaQuest1Tick()
    if not AutoYama1 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af == nil then return end
    if af >= 1 then
        AutoYama1 = false
        UpdateStatus("Yama1: фрагмент получен, перехожу к Yama2.")
        return
    end

    EquipToolByName("Yama")

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not (char and hrp and hum) then return end

    if hum.Health <= 0 then return end

    local dist = (hrp.Position - CastleOnSeaCFrame.Position).Magnitude
    if dist > 150 then
        UpdateStatus("Yama1: лечу к Elite Hunter (Castle on the Sea), жду смерти.")
        SimpleTeleport(CastleOnSeaCFrame, "Elite Hunter (Castle on the Sea)")
    else
        UpdateStatus("Yama1: стою у Elite Hunter, жду смерти.")
    end
end

---------------------
-- YAMA QUEST 2 (HazeESP)
---------------------
local function GetNearestHazeEnemy(maxDistance)
    maxDistance = maxDistance or 9999
    local enemies = Workspace:FindFirstChild("Enemies")
    local char    = LocalPlayer.Character
    local hrp     = char and char:FindFirstChild("HumanoidRootPart")
    if not enemies or not hrp then return nil end

    local best, nearest = maxDistance, nil
    for _, v in ipairs(enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            if v:FindFirstChild("HazeESP", true) then
                local d = (v.HumanoidRootPart.Position - hrp.Position).Magnitude
                if d < best then
                    best    = d
                    nearest = v
                end
            end
        end
    end
    return nearest
end

local function Yama2PatrolStep()
    if not AutoYama2 or not AutoCDK then return end
    if IsTeleporting then return end
    if tick() < Yama2PatrolHold then return end
    if tick() - Yama2LastPatrolHop < 2 then return end

    local idx = Yama2PatrolIndex
    Yama2PatrolIndex = Yama2PatrolIndex + 1
    if Yama2PatrolIndex > #Yama2PatrolPoints then
        Yama2PatrolIndex = 1
    end

    Yama2LastPatrolHop = tick()
    local targetCF = Yama2PatrolPoints[idx] * FarmOffset
    AddLog("Yama2: патруль к точке "..idx)
    SimpleTeleport(targetCF, "Yama2 патруль "..idx, function()
        return not AutoYama2 or GetNearestHazeEnemy(1200) ~= nil
    end)
    Yama2PatrolHold = tick() + 5
end

local function YamaQuest2Tick()
    if not AutoYama2 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af == nil then return end
    if af >= 2 then
        AutoYama2 = false
        UpdateStatus("Yama2: второй фрагмент получен, перехожу к Yama3.")
        return
    end

    if Yama2IsFighting then return end

    local target = GetNearestHazeEnemy(math.huge)
    if not target then
        UpdateStatus("Yama2: Haze-мобы не найдены, патрулирую.")
        Yama2PatrolStep()
        return
    end

    Yama2IsFighting = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        local hum  = target:FindFirstChild("Humanoid")
        if not (char and hrp and tHRP and hum) then return end

        local fightCharacter = char
        UpdateStatus("Yama2: фарм "..target.Name)
        SimpleTeleport(tHRP.CFrame * FarmOffset, "Yama2 моб", function()
            return not AutoYama2 or not target.Parent or hum.Health <= 0
                or not target:FindFirstChild("HazeESP", true)
        end)

        local deadline      = tick() + 40
        local lastPosAdjust = 0
        local lastAttack    = 0

        while AutoYama2 and AutoCDK and not StopTween and target.Parent
            and target:FindFirstChild("HazeESP", true)
            and hum and hum.Health > 0 and tick() < deadline do
            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            hum  = target:FindFirstChild("Humanoid")
            if not (char and hrp and tHRP and hum) then break end

            local playerHum = char:FindFirstChildOfClass("Humanoid")
            if char ~= fightCharacter or not playerHum or playerHum.Health <= 0 then break end
            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 60 then
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий Haze-моб", function()
                    return not AutoYama2 or not target.Parent or hum.Health <= 0
                        or not target:FindFirstChild("HazeESP", true)
                end)
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * FarmOffset
                    hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide = false
                    lastPosAdjust = tick()
                end
            end

            AutoHaki()
            EquipToolByName("Yama")

            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end
    end)

    if not ok then
        AddLog("Ошибка YamaQuest2Tick: "..tostring(err))
    end

    Yama2IsFighting = false
end

---------------------
-- YAMA QUEST 3  (ПОЛНЫЙ, как AutoBones, но под AutoYama3/AutoCDK)
---------------------
local function HasItemInInventory(itemName)
    local p = LocalPlayer
    if not p then return false end

    local backpack = p:FindFirstChild("Backpack")
    if backpack and backpack:FindFirstChild(itemName) then
        return true
    end

    local char = p.Character
    if char and char:FindFirstChild(itemName) then
        return true
    end

    local invData = GetInventory()
    for _, item in ipairs(invData) do
        local name = item.Name or item.name or tostring(item)
        if name == itemName then
            return true
        end
    end
    return false
end

local function UpdateHallowStatus()
    HasHallow = HasItemInInventory("Hallow Essence")
end

local function RefreshBonesCount()
    local c = GetCountMaterials("Bones")
    BonesCount = c or 0
end

local function RefreshRollWindow()
    local now = os.time()
    if now - RollWindowStart > RollWindowDuration then
        RollWindowStart = now
        RollsUsed = 0
        AddLog("Yama3: окно роллов обновлено, RollsUsed = 0.")
    end
end

local function DoDeathKingRolls()
    UpdateHallowStatus()
    if HasHallow then
        AddLog("Yama3: Hallow Essence уже есть, роллы не нужны.")
        return
    end

    RefreshBonesCount()
    if BonesCount < MinBonesToRoll then
        AddLog("Yama3: костей меньше "..MinBonesToRoll..", ролл откладывается.")
        return
    end

    RefreshRollWindow()
    if RollsUsed >= MaxRollsPerWindow then
        AddLog("Yama3: лимит роллов ("..MaxRollsPerWindow..") достигнут.")
        return
    end

    if tick() - lastRollAttempt < 5 then
        return
    end
    lastRollAttempt = tick()

    UpdateStatus("Yama3: роллы у Death King.")
    local center = GetHauntedCenterCFrame()
    SimpleTeleport(center * CFrame.new(0,4,3), "Death King")
    task.wait(1.2)

    local rollsToDo = MaxRollsPerWindow - RollsUsed
    for i = 1, rollsToDo do
        RefreshBonesCount()
        if BonesCount < 50 then
            AddLog("Yama3: костей <50, остановка роллов.")
            break
        end

        RefreshRollWindow()
        if RollsUsed >= MaxRollsPerWindow then
            AddLog("Yama3: достигнут лимит роллов.")
            break
        end

        local ok, res = pcall(function()
            return remote:InvokeServer("Bones", "Buy", 1, 1)
        end)
        RollsUsed = RollsUsed + 1
        AddLog("Yama3: ролл #"..RollsUsed.." => "..tostring(res))

        UpdateHallowStatus()
        if HasHallow then
            AddLog("Yama3: Hallow Essence получена, останавливаю роллы.")
            break
        end

        task.wait(1.5)
    end
end

local function FarmBonesOnceYama3()
    if IsFightingBones then return end
    IsFightingBones = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hrp then return end

        local target = GetNearestSkeleton(9999)
        if not target then
            UpdateStatus("Yama3: скелеты не найдены.")
            return
        end

        UpdateStatus("Yama3: фарм костей по "..target.Name)
        AddLog("Yama3: нашёл скелета "..target.Name)

        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if tHRP then
            SimpleTeleport(tHRP.CFrame * FarmOffset, "Yama3 скелет")
        end

        local fightDeadline = tick() + 40
        local lastPosAdjust = 0
        local lastAttack    = 0
        local engaged       = false

        while AutoYama3
            and AutoCDK
            and target.Parent
            and target:FindFirstChild("Humanoid")
            and target.Humanoid.Health > 0
            and tick() < fightDeadline do

            engaged = true

            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            if not (char and hrp and tHRP) then break end

            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 2000 then
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий скелет")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * FarmOffset
                    hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide = false
                    lastPosAdjust = tick()
                end
            end

            pcall(function()
                tHRP.CanCollide = false
                target.Humanoid.WalkSpeed = 0
                target.Humanoid.JumpPower = 0
                if not tHRP:FindFirstChild("BodyVelocity") then
                    local bv = Instance.new("BodyVelocity", tHRP)
                    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bv.Velocity = Vector3.new(0,0,0)
                end
            end)

            AutoHaki()
            EquipToolByName(WeaponName)

            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end

        if engaged then
            local hum = target:FindFirstChild("Humanoid")
            local dead = hum and hum.Health <= 0
            if dead or not target.Parent then
                AddLog("Yama3: скелет убит, кости начислены.")
                RefreshBonesCount()
            else
                AddLog("Yama3: бой со скелетом прерван.")
            end
        end
    end)

    if not ok then
        AddLog("Ошибка Yama3 FarmBonesOnce: "..tostring(err))
    end

    IsFightingBones = false
end

---------------------
-- HELL DIMENSION (Yama3): удержание E = 2 сек + мобы
---------------------
local function HoldEFor(seconds)
    AddLog("Зажимаю E на "..tostring(seconds).." сек.")
    VirtualInput:SendKeyEvent(true, "E", false, game)
    task.wait(seconds)
    VirtualInput:SendKeyEvent(false, "E", false, game)
end

local function IsHellMob(v)
    local n = tostring(v.Name)
    if string.find(n, "Cursed Skeleton") then return true end
    if string.find(n, "Hell's Messenger") then return true end
    return false
end

local function FarmHellMobsOnce()
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return end

    for _, v in ipairs(enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            if v.Humanoid.Health > 0 and IsHellMob(v) then
                local hum  = v.Humanoid
                local tHRP = v.HumanoidRootPart
                local deadline = tick() + 45
                AddLog("HellDimension: атакую моба "..tostring(v.Name))

                while AutoYama3
                    and AutoCDK
                    and hum.Health > 0
                    and v.Parent
                    and tick() < deadline do

                    local char = LocalPlayer.Character
                    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                    if not (char and hrp and tHRP) then break end

                    local dist = (tHRP.Position - hrp.Position).Magnitude
                    if dist > 2000 then
                        SimpleTeleport(tHRP.CFrame * FarmOffset, "Hell mob (далеко)")
                    else
                        hrp.CFrame = tHRP.CFrame * FarmOffset
                        hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                        hrp.CanCollide = false
                    end

                    pcall(function()
                        tHRP.CanCollide = false
                        hum.WalkSpeed   = 0
                        hum.JumpPower   = 0
                    end)

                    AutoHaki()
                    EquipToolByName(WeaponName)
                    AttackModule:AttackEnemyModel(v)

                    RunService.Heartbeat:Wait()
                end
            end
        end
    end
end

local function HandleHellDimensionYama3()
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    local hd = map:FindFirstChild("HellDimension")
    if not hd then return end

    UpdateStatus("Yama3: HellDimension активен.")
    AddLog("Yama3: HellDimension обнаружен, выполняю факела и мобов.")

    local Torch1 = hd:FindFirstChild("Torch1")
    local Torch2 = hd:FindFirstChild("Torch2")
    local Torch3 = hd:FindFirstChild("Torch3")
    local Exit   = hd:FindFirstChild("Exit")

    if Torch1 then
        AddLog("Yama3 Hell: Torch1 -> E на 2 сек, затем мобы.")
        SimpleTeleport(Torch1.CFrame, "Hell Torch1")
        task.wait(0.3)
        HoldEFor(2)
        task.wait(0.3)
        FarmHellMobsOnce()
    end

    if Torch2 then
        AddLog("Yama3 Hell: Torch2 -> E на 2 сек, затем мобы.")
        SimpleTeleport(Torch2.CFrame, "Hell Torch2")
        task.wait(0.3)
        HoldEFor(2)
        task.wait(0.3)
        FarmHellMobsOnce()
    end

    if Torch3 then
        AddLog("Yama3 Hell: Torch3 -> E на 2 сек, затем мобы.")
        SimpleTeleport(Torch3.CFrame, "Hell Torch3")
        task.wait(0.3)
        HoldEFor(2)
        task.wait(0.3)
        FarmHellMobsOnce()
    end

    AddLog("Yama3 Hell: добиваю мобов/босса.")
    FarmHellMobsOnce()

    if Exit then
        AddLog("Yama3 Hell: телепорт к Exit.")
        SimpleTeleport(Exit.CFrame, "Hell Exit")
    else
        AddLog("Yama3 Hell: Exit не найден.")
    end
end

---------------------
-- SOUL REAPER -> HellDimension (Yama3): ждать 10 сек
---------------------
local function FindSoulReaper()
    local enemies = Workspace:FindFirstChild("Enemies")
    if enemies then
        for _, v in ipairs(enemies:GetChildren()) do
            if tostring(v.Name) == "Soul Reaper" then
                local hum = v:FindFirstChild("Humanoid")
                local hrp = v:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and hrp then
                    return v, hum, hrp
                end
            end
        end
    end
    return nil
end

local function HandleSoulReaperPhaseYama3()
    local map = Workspace:FindFirstChild("Map")
    local hd  = map and map:FindFirstChild("HellDimension")
    if hd then
        return
    end

    local soul, sh, sHRP = FindSoulReaper()
    if not soul then
        AddLog("Yama3: Soul Reaper не найден, лечу к спавну.")
        SimpleTeleport(SoulReaperSpawnCF, "Soul Reaper spawn")
        return
    end

    UpdateStatus("Yama3: Soul Reaper найден, подлетаю и жду урона.")
    AddLog("Yama3: подлетаю к Soul Reaper, не атакую, жду HP <= 500, затем ещё 10 сек стою.")

    local prevNoclip = NoclipEnabled
    NoclipEnabled = false

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    sHRP       = soul:FindFirstChild("HumanoidRootPart")
    sh         = soul:FindFirstChild("Humanoid")

    if hrp and sHRP then
        hrp.CFrame = sHRP.CFrame * CFrame.new(0,0,-6)
    end

    local waitDeadline = tick() + 120

    while AutoYama3
        and AutoCDK
        and soul.Parent
        and sh
        and sh.Health > 0
        and tick() < waitDeadline do

        char = LocalPlayer.Character
        hrp  = char and char:FindFirstChild("HumanoidRootPart")
        sHRP = soul:FindFirstChild("HumanoidRootPart")
        sh   = soul:FindFirstChild("Humanoid")

        if not (char and hrp and sHRP and sh) then
            break
        end

        local mapNow = Workspace:FindFirstChild("Map")
        local hDimNow = mapNow and mapNow:FindFirstChild("HellDimension")
        if hDimNow then
            AddLog("Yama3: HellDimension уже появился, жду авто-переноса.")
            NoclipEnabled = prevNoclip
            return
        end

        local dist = (hrp.Position - sHRP.Position).Magnitude
        if dist > 120 then
            AddLog("Yama3: меня откинуло от Soul Reaper, подлетаю обратно.")
            hrp.CFrame = sHRP.CFrame * CFrame.new(0,0,-6)
        end

        local phum = char:FindFirstChild("Humanoid")
        if phum and phum.Health <= 500 then
            AddLog("Yama3: HP <= 500, стою 10 секунд и жду HellDimension.")
            UpdateStatus("Yama3: жду 10 секунд перед HellDimension.")

            local t0 = tick()
            local hellDetected = false

            while AutoYama3 and AutoCDK and tick() - t0 < 10 do
                local m  = Workspace:FindFirstChild("Map")
                local hD = m and m:FindFirstChild("HellDimension")
                if hD and not hellDetected then
                    hellDetected = true
                    AddLog("Yama3: HellDimension появился, но тп будет после полного таймера 10 сек.")
                end
                task.wait(0.1)
            end

            local m2  = Workspace:FindFirstChild("Map")
            local hDim2 = m2 and m2:FindFirstChild("HellDimension")
            if hDim2 then
                local torch1 = hDim2:FindFirstChild("Torch1")
                local exit   = hDim2:FindFirstChild("Exit")
                local fallbackCf
                if torch1 and torch1.CFrame then
                    fallbackCf = torch1.CFrame
                elseif exit and exit.CFrame then
                    fallbackCf = exit.CFrame
                elseif hDim2:IsA("Model") and hDim2.PrimaryPart then
                    fallbackCf = hDim2.PrimaryPart.CFrame
                end

                if fallbackCf then
                    AddLog("Yama3: 10 секунд прошли, HellDimension есть — телепорт внутрь.")
                    SimpleTeleport(fallbackCf, "HellDimension")
                else
                    AddLog("Yama3: HellDimension есть, но нет Torch1/Exit для тп.")
                end
            else
                AddLog("Yama3: 10 секунд прошло, HellDimension не появился.")
            end

            NoclipEnabled = prevNoclip
            return
        end

        RunService.Heartbeat:Wait()
    end

    NoclipEnabled = prevNoclip
end

local function HandleSummonerIfHasHallow()
    if not HasHallow then return end
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    local hc = map:FindFirstChild("Haunted Castle")
    if not hc then return end
    local summonerModel = hc:FindFirstChild("Summoner")
    if not summonerModel then return end
    local detection = summonerModel:FindFirstChild("Detection")
    if not detection then return end

    UpdateStatus("Yama3: есть Hallow Essence, лечу к Summoner.")
    SimpleTeleport(detection.CFrame, "Summoner Detection")
    task.wait(1.0)
end

local function YamaQuest3Tick()
    if not AutoYama3 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af == nil then return end
    if af >= 3 then
        AutoYama3 = false
        UpdateStatus("Yama3: третий фрагмент получен, перехожу к Tushita.")
        return
    end

    local map = Workspace:FindFirstChild("Map")
    local hellDim = map and map:FindFirstChild("HellDimension")
    if hellDim then
        HandleHellDimensionYama3()
        return
    end

    if not EnsureOnHauntedIsland() then return end
    RefreshBonesCount()
    UpdateHallowStatus()
    RefreshRollWindow()

    local alucardCount = GetCountMaterials("Alucard Fragment") or 0
    if alucardCount >= 3 then
        UpdateStatus("Yama3: 3 фрагмента уже есть, просто фармлю кости.")
        FarmBonesOnceYama3()
        return
    end

    if HasHallow then
        HandleSummonerIfHasHallow()
        HandleSoulReaperPhaseYama3()
        return
    end

    local soul = FindSoulReaper()
    if soul then
        HandleSoulReaperPhaseYama3()
        return
    end

    if BonesCount >= MinBonesToRoll and RollsUsed < MaxRollsPerWindow then
        DoDeathKingRolls()
        return
    end

    UpdateStatus("Yama3: фарм скелетов для костей.")
    FarmBonesOnceYama3()
end

---------------------
-- TUSHITA QUEST 1 (BoatQuest через Lux Boat Dealer)
---------------------
local Tushita1Index = 1

local function FindNearestLuxuryBoatDealer(maxDist)
    maxDist = maxDist or 200
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local best, nearest = maxDist, nil
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Luxury Boat Dealer" then
            local head = obj:FindFirstChild("HumanoidRootPart")
                or obj:FindFirstChild("Head")
                or obj:FindFirstChildWhichIsA("BasePart")
            if head then
                local d = (head.Position - hrp.Position).Magnitude
                if d < best then
                    best    = d
                    nearest = obj
                end
            end
        end
    end
    return nearest
end

local function TushitaQuest1Tick()
    if not AutoTushita1 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af == nil then return end
    if af >= 4 then
        AutoTushita1 = false
        UpdateStatus("Tushita1: фрагмент получен, перехожу к Tushita2.")
        return
    end

    local idx = Tushita1Index
    Tushita1Index = Tushita1Index + 1
    if Tushita1Index > #TushitaQ1Points then
        Tushita1Index = 1
    end

    UpdateStatus("Tushita1: точка "..idx)
    SimpleTeleport(TushitaQ1Points[idx], "Tushita Q1 точка "..idx)

    local npc = FindNearestLuxuryBoatDealer(150)
    if not npc then
        AddLog("Tushita1: Luxury Boat Dealer не найден у точки "..idx)
        return
    end

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")
    local head = npc:FindFirstChild("HumanoidRootPart")
        or npc:FindFirstChild("Head")
        or npc:FindFirstChildWhichIsA("BasePart")

    if head then
        hrp.CFrame = head.CFrame * CFrame.new(0,0,-3)
    end

    local ok1, res1 = pcall(function()
        return remote:InvokeServer("GetUnlockables","BoatDealer")
    end)
    AddLog("Tushita1: GetUnlockables/BoatDealer => "..tostring(res1))

    task.wait(0.3)

    local ok2, res2 = pcall(function()
        return remote:InvokeServer("CDKQuest","BoatQuest", npc)
    end)
    AddLog("Tushita1: BoatQuest => "..tostring(res2))
end

---------------------
-- TUSHITA QUEST 2
---------------------
local Tushita2IsFighting = false

local function IsInTushita2Zone()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, 99999 end
    local dist = (hrp.Position - TushitaQ2Center.Position).Magnitude
    return dist <= TushitaQ2InZoneRadius, dist
end

local function GetNearestMobInTushita2Zone()
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local best, nearest = TushitaQ2MaxMobDistance, nil
    for _, v in ipairs(enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
            local tHRP = v.HumanoidRootPart
            local distToPlayer = (tHRP.Position - hrp.Position).Magnitude
            local distToCenter = (tHRP.Position - TushitaQ2Center.Position).Magnitude
            if distToPlayer <= TushitaQ2MaxMobDistance and distToCenter <= TushitaQ2InZoneRadius + 200 then
                if distToPlayer < best then
                    best    = distToPlayer
                    nearest = v
                end
            end
        end
    end
    return nearest
end

local function TushitaQuest2Tick()
    if not AutoTushita2 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af == nil then return end
    if af >= 5 then
        AutoTushita2 = false
        UpdateStatus("Tushita2: фрагмент получен, перехожу к Tushita3.")
        return
    end

    if Tushita2IsFighting then return end

    local inZone, dist = IsInTushita2Zone()
    if not inZone then
        UpdateStatus(string.format("Tushita2: лечу в зону (%.0f stud)", dist or 9999))
        SimpleTeleport(TushitaQ2Center * CFrame.new(0,5,0), "центр Tushita Q2")
        return
    end

    local target = GetNearestMobInTushita2Zone()
    if not target then
        UpdateStatus("Tushita2: враги не найдены, жду...")
        return
    end

    Tushita2IsFighting = true

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        local hum  = target:FindFirstChild("Humanoid")
        if not (char and hrp and tHRP and hum) then return end

        UpdateStatus("Tushita2: фарм "..target.Name)
        SimpleTeleport(tHRP.CFrame * FarmOffset, "моб Tushita Q2")

        local deadline      = tick() + 45
        local lastPosAdjust = 0
        local lastAttack    = 0

        while AutoTushita2 and AutoCDK and target.Parent and hum.Health > 0 and tick() < deadline do
            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            hum  = target:FindFirstChild("Humanoid")
            if not (char and hrp and tHRP and hum) then break end

            local distToMob = (tHRP.Position - hrp.Position).Magnitude
            if distToMob > 2000 then
                SimpleTeleport(tHRP.CFrame * FarmOffset, "далёкий моб Tushita Q2")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * FarmOffset
                    hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide = false
                    lastPosAdjust = tick()
                end
            end

            AutoHaki()
            EquipToolByName(WeaponName)

            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end
    end)

    if not ok then
        AddLog("Ошибка TushitaQuest2Tick: "..tostring(err))
    end

    Tushita2IsFighting = false
end

---------------------
-- TUSHITA QUEST 3 (Cake Queen + HeavenlyDimension)
---------------------
local function HeavenlyDimensionFolder()
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil end
    return map:FindFirstChild("HeavenlyDimension")
end

local function FindCakeQueen()
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil end
    for _, v in ipairs(enemies:GetChildren()) do
        if v.Name == "Cake Queen"
            and v:FindFirstChild("Humanoid")
            and v:FindFirstChild("HumanoidRootPart")
            and v.Humanoid.Health > 0 then
            return v
        end
    end
    return nil
end

local function FightMobSimple(target, label, offsetCF)
    offsetCF = offsetCF or FarmOffset
    if not target then return end

    local ok, err = pcall(function()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = target:FindFirstChild("Humanoid")
        local tHRP = target:FindFirstChild("HumanoidRootPart")
        if not (char and hrp and hum and tHRP) then return end

        UpdateStatus(label or ("Бой: "..target.Name))
        SimpleTeleport(tHRP.CFrame * offsetCF, label or "цель")

        local deadline      = tick() + 90
        local lastPosAdjust = 0
        local lastAttack    = 0

        while AutoTushita3 and AutoCDK and target.Parent and hum.Health > 0 and tick() < deadline do
            char = LocalPlayer.Character
            hrp  = char and char:FindFirstChild("HumanoidRootPart")
            tHRP = target:FindFirstChild("HumanoidRootPart")
            hum  = target:FindFirstChild("Humanoid")
            if not (char and hrp and hum and tHRP) then break end

            local dist = (tHRP.Position - hrp.Position).Magnitude
            if dist > 2000 then
                SimpleTeleport(tHRP.CFrame * offsetCF, "далёкий моб")
            else
                if tick() - lastPosAdjust > 0.05 then
                    hrp.CFrame = tHRP.CFrame * offsetCF
                    hrp.AssemblyLinearVelocity  = Vector3.new(0,0,0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    hrp.CanCollide = false
                    lastPosAdjust = tick()
                end
            end

            AutoHaki()
            EquipToolByName(WeaponName)
            if tick() - lastAttack > 0.15 then
                AttackModule:AttackEnemyModel(target)
                lastAttack = tick()
            end

            RunService.Heartbeat:Wait()
        end
    end)

    if not ok then
        AddLog("Ошибка FightMobSimple: "..tostring(err))
    end
end

local function TushitaQuest3Tick()
    if not AutoTushita3 or not AutoCDK then return end

    local af = GetCountMaterials("Alucard Fragment")
    if af == nil then return end
    if af >= 6 then
        AutoTushita3 = false
        UpdateStatus("Tushita3: 6-й фрагмент получен. Готово.")
        AutoCDK = false
        NoclipEnabled = false
        StopTween = true
        if UI.RenderRunning then UI.RenderRunning() end
        AddLog("Готово: 6 Alucard Fragment. Все квесты завершены.")
        return
    end

    local dim = HeavenlyDimensionFolder()
    if not dim then
        local boss = FindCakeQueen()
        if boss then
            -- после убийства Cake Queen просто ждём 5 сек, игра сама переносит в HeavenlyDimension
            FightMobSimple(boss, "Tushita3: Cake Queen", CakeQueenOffset)
            AddLog("Tushita3: жду 5 сек авто-переноса в HeavenlyDimension.")
            task.wait(5)
        else
            UpdateStatus("Tushita3: Cake Queen не найдена, лечу на остров.")
            SimpleTeleport(CakeQueenIsland, "остров Cake Queen")
        end
        return
    end

    local torch1 = dim:FindFirstChild("Torch1")
    local torch2 = dim:FindFirstChild("Torch2")
    local torch3 = dim:FindFirstChild("Torch3")
    local exit   = dim:FindFirstChild("Exit")

    -- Каждый факел: E на 2 сек, потом мобы, потом следующий
    if T3_HeavenlyStage == 0 and torch1 then
        UpdateStatus("Tushita3: Torch1.")
        SimpleTeleport(torch1.CFrame * CFrame.new(0,5,0), "Torch1")
        HoldEFor(2)
        local enemies = Workspace:FindFirstChild("Enemies")
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if enemies and root then
            for _, mob in ipairs(enemies:GetChildren()) do
                local mobRoot = mob:FindFirstChild("HumanoidRootPart")
                if mobRoot and (mobRoot.Position - root.Position).Magnitude <= 500 then
                    FightMobSimple(mob, "Tushita3: бой у факела")
                end
            end
        end
        T3_HeavenlyStage = 1
        return
    end

    if T3_HeavenlyStage == 1 and torch2 then
        UpdateStatus("Tushita3: Torch2.")
        SimpleTeleport(torch2.CFrame * CFrame.new(0,5,0), "Torch2")
        HoldEFor(2)
        local enemies = Workspace:FindFirstChild("Enemies")
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if enemies and root then
            for _, mob in ipairs(enemies:GetChildren()) do
                local mobRoot = mob:FindFirstChild("HumanoidRootPart")
                if mobRoot and (mobRoot.Position - root.Position).Magnitude <= 500 then
                    FightMobSimple(mob, "Tushita3: бой у факела")
                end
            end
        end
        T3_HeavenlyStage = 2
        return
    end

    if T3_HeavenlyStage == 2 and torch3 then
        UpdateStatus("Tushita3: Torch3.")
        SimpleTeleport(torch3.CFrame * CFrame.new(0,5,0), "Torch3")
        HoldEFor(2)
        local enemies = Workspace:FindFirstChild("Enemies")
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if enemies and root then
            for _, mob in ipairs(enemies:GetChildren()) do
                local mobRoot = mob:FindFirstChild("HumanoidRootPart")
                if mobRoot and (mobRoot.Position - root.Position).Magnitude <= 500 then
                    FightMobSimple(mob, "Tushita3: бой у факела")
                end
            end
        end
        T3_HeavenlyStage = 3
        return
    end

    if T3_HeavenlyStage == 3 then
        local enemies = Workspace:FindFirstChild("Enemies")
        if enemies then
            for _, v in ipairs(enemies:GetChildren()) do
                if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                    FightMobSimple(v, "Tushita3: бой в HeavenlyDimension")
                end
            end
        end
        if exit then
            UpdateStatus("Tushita3: лечу к Exit.")
            SimpleTeleport(exit.CFrame * CFrame.new(0,5,0), "Exit")
            T3_HeavenlyStage = 4
        end
        return
    end

    if T3_HeavenlyStage >= 4 then
        UpdateStatus("Tushita3: жду завершения HeavenlyDimension.")
    end
end

---------------------
-- ПОМОЩЬ: стадия по AF
---------------------
local function GetStageFromAF(count)
    if count <= 0 then
        return 0
    elseif count == 1 then
        return 1
    elseif count == 2 then
        return 2
    elseif count == 3 then
        return 3
    elseif count == 4 then
        return 4
    elseif count == 5 then
        return 5
    else
        return 6
    end
end

local function DisableAllQuests()
    AutoYama1,AutoYama2,AutoYama3 = false,false,false
    AutoTushita1,AutoTushita2,AutoTushita3 = false,false,false
end

---------------------
-- ГЛАВНЫЙ ЦИКЛ AutoCDK (мастери -> квесты)
---------------------
spawn(function()
    while task.wait(1) and GuiAlive do
        local scannedAF = GetCountMaterials("Alucard Fragment")
        UpdateAFLabel(scannedAF)
        if not AutoCDK then
            CurrentStage = -1
        else
            if NeedMastery then
                -- просто обновляем мастери, стадий квестов не трогаем
                local yM = GetWeaponMastery(SwordYamaName)
                local tM = GetWeaponMastery(SwordTushitaName)
                UpdateMasteryLabel(yM, tM)
            else
                local af = scannedAF
                local stage = af ~= nil and GetStageFromAF(af) or nil
                if stage ~= nil and stage ~= CurrentStage then
                    CurrentStage = stage
                    AddLog("CDK: AF="..af.." -> стадия "..stage)
                    DisableAllQuests()
                    StopTween = true
                    task.wait(0.2)
                    StopTween = false

                    if stage == 0 then
                        UpdateStatus("Yama Quest 1")
                        AutoYama1 = true
                        AddLog("Перед Yama1: запускаю Trial Evil.")
                        CDKTrialModule.StartEvilTrial()

                    elseif stage == 1 then
                        UpdateStatus("Yama Quest 2")
                        AutoYama2 = true
                        AddLog("Перед Yama2: запускаю Trial Evil.")
                        CDKTrialModule.StartEvilTrial()

                    elseif stage == 2 then
                        UpdateStatus("Yama Quest 3")
                        AutoYama3 = true
                        AddLog("Перед Yama3: запускаю Trial Evil.")
                        CDKTrialModule.StartEvilTrial()

                    elseif stage == 3 then
                        UpdateStatus("Tushita Quest 1 (BoatQuest)")
                        AutoTushita1 = true
                        AddLog("Перед Tushita1: Trial Evil + Trial Good.")
                        CDKTrialModule.StartEvilTrial()
                        task.wait(0.3)
                        CDKTrialModule.StartGoodTrial()

                    elseif stage == 4 then
                        UpdateStatus("Tushita Quest 2")
                        AutoTushita2 = true
                        AddLog("Перед Tushita2: Trial Good.")
                        CDKTrialModule.StartGoodTrial()

                    elseif stage == 5 then
                        UpdateStatus("Tushita Quest 3")
                        AutoTushita3 = true
                        T3_HeavenlyStage = 0
                        AddLog("Перед Tushita3: Trial Good.")
                        CDKTrialModule.StartGoodTrial()

                    elseif stage == 6 then
                        UpdateStatus("Готово (6+ Alucard Fragment)")
                        AddLog("Все 6 фрагментов уже есть, выключаю AutoCDK.")
                        AutoCDK = false
                        NoclipEnabled = false
                        StopTween = true
                        if UI.RenderRunning then UI.RenderRunning() end
                    end
                end
            end
        end
    end
end)

---------------------
-- ТИКИ КВЕСТОВ / МАСТЕРИ
---------------------
local lastTickError = {}
local function RunTick(name, callback)
    local ok, err = pcall(callback)
    if not ok and tick() - (lastTickError[name] or 0) > 3 then
        lastTickError[name] = tick()
        AddLog(name..": "..tostring(err))
    end
end

spawn(function()
    while task.wait(0.4) and GuiAlive do
        if AutoCDK then
            if NeedMastery then
                RunTick("MasteryTick", MasteryTick)
            else
                if AutoYama1    then RunTick("YamaQuest1Tick", YamaQuest1Tick)    end
                if AutoYama2    then RunTick("YamaQuest2Tick", YamaQuest2Tick)    end
                if AutoYama3    then RunTick("YamaQuest3Tick", YamaQuest3Tick)    end
                if AutoTushita1 then RunTick("TushitaQuest1Tick", TushitaQuest1Tick) end
                if AutoTushita2 then RunTick("TushitaQuest2Tick", TushitaQuest2Tick) end
                if AutoTushita3 then RunTick("TushitaQuest3Tick", TushitaQuest3Tick) end
            end
        end
    end
end)

AddLog("AutoCDK загружен. Включай кнопку в 3-м море (Haunted Castle / Castle on the Sea / Cake Queen).")
