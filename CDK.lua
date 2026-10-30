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
--        AF >=6 -> алтарь CDK + Cursed Skeleton Boss; OFF после получения меча
--========================================================

print("[AutoCDK] safe-start v2: loading")

---------------------
-- НАСТРОЙКИ
---------------------
local WeaponName         = "Godhuman"       -- чем бить мобов
local SwordYamaName      = "Yama"
local SwordTushitaName   = "Tushita"
local SwordCDKName       = "Cursed Dual Katana"
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
    CFrame.new(-9533.2392578125, 7.254445552825928, -8372.69921875),
    CFrame.new(-6032.48486, 16.7328072, -2044.63171),
}

-- Tushita Q2
local TushitaQ2Center         = CFrame.new(-5539.3115, 313.8005, -2972.3723)
local TushitaQ2InZoneRadius   = 500
local TushitaQ2MaxMobDistance = 2000

-- Tushita Q3 (Cake Queen + HeavenlyDimension)
local CakeQueenIsland = CFrame.new(-709.3132934570312, 381.6005859375, -11011.396484375)
local CakeQueenOffset = CFrame.new(0, 20, -3)

-- Финальный этап CDK после шести фрагментов.
local CDKPrepPos = CFrame.new(-12389.3994, 603.632812, -6596.36475)
local CDKAltarPos = CFrame.new(-12361.7060546875, 603.3547973632812, -6550.5341796875)
local CDKAfterPos = CFrame.new(-12253.5419921875, 598.8999633789062, -6546.8388671875)

-- Avoid constructing a UI while the game is still loading its initial scene.
if not game:IsLoaded() then game.Loaded:Wait() end

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
local AutoCDKFinal   = false
local CDKFinalStarted = false

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
    if not LogsText or UI.Closed or UI.LogFlushPending then return end
    UI.LogFlushPending = true
    task.defer(function()
        UI.LogFlushPending = false
        if UI.Closed or not LogsText.Parent then return end
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
    -- Lazy, portable portrait. No native executor asset loader, disk IO or PNG decoding.
    -- Paint the bundled thumbnail with bounded native GUI primitives on first minimize.
    local function loadLauncherPortrait()
        if UI.PortraitStarted or UI.Closed then return end
        UI.PortraitStarted = true
        task.spawn(function()
            local pixels = "25151e14111a0c0e1c2c2d4c2d25421f24431f2443192041414c821f24431920411920411f24431f24431920411f24432f3f73414c822f3f734c436a2f3f734256925568bf3555c67a94f17583e10108530b153e151743152054080a2103092f27202e27202e130c171413234c436a8458682d25421920411f24431920411f2443262651262651262e6b262e6b2b335c262e6b2b335c1520543d3e682f3f734256925568bf5573dc5568bf5573dc26369e081d810b153e15174303092f0b153e3f385127202e25151e130c171f244364515f27202e2c2d4c2c2d4c2c2d4c262e6b090f3a0604090613530a195817216326369e262e6b1f24431520542f3f735e5ab42a45be5573dcd4abac806ea65573dc3555c60613530b153e1721631b23943f385127202e40232a40232a130c171f24431920412c2d4c3f38513f38510b153e010108130c1740232a40232a0c0e1c0a195826369e262e6b172163414c82806ea64256922a45be7583e15e5ab45568bf7a94f11b23941721632a45be1b23941617293d2d39aa6f6b653a3a27202e25151e1f24431920414c436a3d2d39130c174f343d7f524baa6f6bc38a89845868130c170a19582a45be262e6b2b335c4c436a4256924256922f3f735568bf5573dc495acc5573dc26369e3555c617216309080f3d2d39d4abac7f524b3d2d3927202e27202e1920412c2d4c27202e4f343d7f524baa6f6b653a3a7f524bc38a894f343d1617293555c62f3f732626511520541520541520541520541520545568bf2a45be495acc495acc1b23940a1958130c17130c176f46517f524baa6f6b6f465127202e1f24432c2d4c3d2d3940232a40232ac38a89653a3a653a3aaa6f6b8458680c0b1115339c3043941f24432626512626511f24432b335c2b335c26369e1b239415339c7a94f12a45be081d8125151e14111a0c0e1c64515fd4abacc38a8927202e1f24433f3851653a3a40232a653a3aaa6f6baa6f6bc38a89d4abacc38a8927202e3d42953043942c2d4c2626512c2d4c3d3e683d3e684256922a45be0412700412705573dc7583e12a45be40232a7f524b14111a1617298458686f46512c2d4c2b335c2626516f46517f524b653a3aaa6f6baa6f6bc38a89d4abacc38a897f524b806ea63043943f38513d3e685568bf5568bf3d3e685e5ab43d42951b2394081d810412707583e17583e17f524baa6f6b25151e3d2d393f38513d2d392c2d4c42569242569264515f7f524b653a3a7f524baa6f6bc38a89d4abacc38a89aa6f6b806ea62f3f732b335c414c827583e1425692262e6b5e5ab45573dc495acc2a45be04127015339c7a94f1c38a89c38a8940232a4f343d3d2d3964515f64515f414c824256924256927f524b6f4651aa6f6bc38a89c38a89d4abacc38a8964515f15339c414c822f3f733043944256922f3f733d3e688458687583e17a94f15573dc2a45be15339c2a45bed4abac7f524b3f38513d3e6827202e4f343d4f343d2626512f3f735e5ab48458687f524b7f524baa6f6baa6f6b845868c38a8964515f1b2394414c823555c64256923d3e68414c824c436a806ea65e5ab45568bf7583e17583e1414c823d4295c38a89653a3a3f38517583e1806ea68458683f38512626512f3f732f3f73414c824f343d40232a653a3a7f524baa6f6b845868172163151743090f3a2a45be5573dc3d42955568bf5e5ab4d4abac806ea63555c65e5ab47f524b7f524b806ea6aa6f6b3d2d392c2d4c806ea6d4abacaa6f6b64515f2f3f73414c82414c82414c824256926f4651845868c38a896f46514f343d1721630613530b153e2a45be7a94f1495acc3043945573dc7a94f15e5ab45573dc8458683f38513d4295130c174f343d2d2542262e6bd4abacd4abac5e5ab4414c82425692425692414c822b335c1f2443653a3a7f524b84586840232a40232a0b153e080a2103092f172163304394172163262e6b304394304394495acc7a94f18458684c436a15339c090f3a414c822626513d4295806ea6c38a89495acc3d42952f3f7326265114111a06040901010838171c6f46517f524b4f343d38171c03051f03051f03092f0c0e1c161729192041192041090f3a090f3a3555c6806ea67f524b7f524b1413230613533555c63043943d42954c436a4c436a3043943d429538171c09080f0c0b110c0b110101080c0b116f46516f465125151e38171c38171c15174309113c14132316172914132316172916172917216315339c64515f2c2d4c262e6b09080f14111a2a45be7a94f126369e414c82414c824256927583e164515f38171c0c0e1c130c170101080604094f343d27202e38171c40232a172163061353061353081d810a195815174314132314132306135315339c5e5ab464515f17216303092f0c0b11081d817583e1495acc806ea6806ea65e5ab47583e17a94f17f524b080a2109080f06040914111a0c0e1c38171c653a3a0412700a1958090f3a0a1958081d810a19580a19580a1958090f3a0a195815339c5e5ab46f46510c0b110b153e17216315339c495acc3555c6d4abacd4abac5573dc7583e17583e164515f09080f0604090c0b11130c1714132338171c4f343d04127009113c1617290a1958081d810a195809113c09113c0a19580613532a45be495acc3d429506135306040915174315339c5573dc5573dc7a94f17a94f17583e130439415174325151e09080f0c0b1114111a27202e14132338171c262e6b0613531617294c436a0b153e04127017216319204103092f080a2109113c081d815568bf26265116172938171c09113c1721632a45be495acc262e6b3d4295262e6b15205414132325151e0c0b1114132314111a14111a14111a3d2d391721630613531413234c436a3d3e683d3e683d3e683d3e6803092f03051f090f3a090f3a3d429527202e130c1738171c06135326369e2a45be262e6b1517431517431520542b335c2626510c0b110c0b110c0b110c0b11130c170c0e1c17216326265140232a1617293f385164515f4c436a3d3e68414c8203092f080a2103092f0b153e0412703555c65e5ab40c0e1c0c0e1c2a45be30439426265119204103092f0b153e09113c2b335c1f24430b153e0c0b1114111a1617290c0b11041270262651653a3a1413234c436a4c436a3f385127202e3d3e680b153e01010803092f0a1958081d815573dc7a94f1041270090f3a2a45be262651090f3a16172903092f192041080a211617294256921b23940b153e2d254227202e06040915205406135327202e3d2d392c2d4c4c436a414c823f38512626511f244306040903092f03092f495acc7a94f115339c080a212d25425568bf2c2d4c6f46518458686f465127202e2f3f735e5ab442569230439415339c1413230604090101081517431721634f343d1f24433f385164515f3d2d393d3e683d3e68262651080a2103051f0108535573dc5573dc04127009080f40232a262e6b14111a40232a38171c40232a080a212b335c5568bf262e6b15205415339c01010806040909080f161729172163653a3a2d2542090f3a4c436a4f343d2c2d4c262651262e6b090f3a03051f0613535573dc2a45be081d8103051f0c0e1c141323080a2103051f40232a6f46513d2d3925151e262651192041304394304394010108130c170c0b11080a211721634f343d090f3a0b153e1617292c2d4c3d3e683d3e68172163090f3a01085315339c5573dc3555c62a45be17216303092f1920410b153e0c0e1c25151e653a3a6f465138171c1f244314111a262e6b04127001010814111a09080f0c0b110a195815205440232a0b153e09113c080a212b335c414c821b23940412702a45be7a94f17a94f17a94f17a94f12a45be03092f0a1958141323090f3a080a21653a3a6f465138171c1f24431413230a195803051f06040914111a09080f09080f1520540a195815174340232a15174303092f1f2443152054081d81495acc7a94f15573dc2a45be2a45be5573dc081d810613530613531617290c0e1c0c0b1140232a4f343d25151e0c0e1c0a195803051f0101080c0e1c0c0e1c09080f09080f0b153e0a19580613531517434f343d0b153e09113c010853495acc7a94f12a45be15339c1b23942a45be2a45be010853081d8109113c38171c0b153e090f3a653a3a27202e0c0b110b153e080a2101010809080f14111a0c0b1114111a130c17090f3a0613530a19580613532626512626510108530412705573dc5573dc30439430439426369e5573dc1b239403092f26369e"
            local width = 32
            local function inside(x, y)
                local cx = math.clamp(x + 0.5, 7, 25)
                local cy = math.clamp(y + 0.5, 7, 25)
                return (x + 0.5 - cx)^2 + (y + 0.5 - cy)^2 <= 49
            end
            local function colorAt(x, y)
                local offset = (y * width + x) * 6 + 1
                return pixels:sub(offset, offset + 5)
            end
            for y = 0, width - 1 do
                if UI.Closed or not launcher.Parent then return end
                local x = 0
                while x < width do
                    if not inside(x,y) then
                        x = x + 1
                    else
                        local color = colorAt(x,y)
                        local finish = x + 1
                        while finish < width and inside(finish,y) and colorAt(finish,y) == color do finish = finish + 1 end
                        make("Frame", {Name = "PortraitPixel", BorderSizePixel = 0, Active = false,
                            Position = UDim2.fromScale(x / width, y / width),
                            Size = UDim2.fromScale((finish - x) / width, 1 / width),
                            BackgroundColor3 = Color3.fromRGB(tonumber(color:sub(1,2),16),
                                tonumber(color:sub(3,4),16), tonumber(color:sub(5,6),16)), ZIndex = 1}, launcher)
                        x = finish
                    end
                end
                if y % 4 == 3 then task.wait() end
            end
            UI.PortraitLoaded = true
        end)
    end
    badge.ZIndex = 3

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
        if value then loadLauncherPortrait() end
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
        AutoCDKFinal = false
        CurrentStage = -1
        UI.RestoreCollision()
    end
    UI.Close = function(destroyGui)
        if UI.Closed then return end
        stopAutomation()
        UI.Closed = true
        GuiAlive = false
        for _, connection in ipairs(UI.Connections) do connection:Disconnect() end
        UI.Connections = {}
        if sessionEnv.__AutoCDKSession == UI then sessionEnv.__AutoCDKSession = nil end
        if destroyGui ~= false and ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
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
    TrackConnection(ScreenGui.Destroying:Connect(function() UI.Close(false) end))
    fitViewport()
    RefreshLogs()
    AddLog("ME Terminal готов. Перетаскивай заголовок, меняй размер за правый нижний угол.")
end

print("[AutoCDK] safe-start v2: creating interface")
CreateMainGui()
print("[AutoCDK] safe-start v2: interface ready")

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
local InventoryItemIds = {}
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
                    if type(index) == "table" and type(index.StorageKey) == "string" and tonumber(index.ItemId) then
                        local key = NormalizeMaterialName(index.StorageKey)
                        InventoryItemIds[key] = tonumber(index.ItemId)
                        if index.IdType == "Material" then MaterialIds[key] = tonumber(index.ItemId) end
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

local function HasLocalTool(name)
    for _, container in pairs({LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack")}) do
        if container then
            local tool = container:FindFirstChild(name)
            if tool and tool:IsA("Tool") then return true end
        end
    end
    return false
end

local function HasOwnedWeapon(name)
    if HasLocalTool(name) then return true end
    -- The same verified snapshot contains sword quantities as well as materials.
    if GetCountMaterials("Alucard Fragment") == nil then return nil end
    local id = InventoryItemIds[NormalizeMaterialName(name)]
    if not id or not MaterialQuantities or tick() - MaterialSuccessTime > 5 then return nil end
    return (MaterialQuantities[id] or 0) > 0
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
-- TUSHITA QUEST 1 (BoatQuest через Boat Dealer)
---------------------
local Tushita1Index = 1

local function FindNearestBoatDealer(maxDist)
    maxDist = maxDist or 200
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local best, nearest = maxDist, nil
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Boat Dealer" then
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

    local npc = FindNearestBoatDealer(150)
    if not npc then
        AddLog("Tushita1: Boat Dealer не найден у точки "..idx)
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
        CDKFinalStarted = true
        AutoCDKFinal = true
        UpdateStatus("6 фрагментов получены. Перехожу к алтарю и боссу CDK.")
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
    AutoCDKFinal = false
end

---------------------
-- ФИНАЛ CDK: АЛТАРЬ / БОСС / ПОДТВЕРЖДЕНИЕ ПОЛУЧЕНИЯ
---------------------
local CDKFinalState = {NextAltar = -math.huge, NextSwordLoad = -math.huge, RewardUntil = 0, PrepDone = false}

local function CDKFinalActive()
    return AutoCDK and AutoCDKFinal and GuiAlive and not StopTween and not UI.Closed
end

local function CDKFinalCharacter()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if char and root and hum and hum.Health > 0 then return char, root, hum end
end

local function FindCDKFinalTarget(bossOnly)
    local _, root = CDKFinalCharacter()
    local enemies = Workspace:FindFirstChild("Enemies")
    if not root or not enemies then return nil end
    local boss, bossDist, mob, mobDist = nil, math.huge, nil, math.huge
    for _, candidate in ipairs(enemies:GetChildren()) do
        if candidate:IsA("Model") then
            local hum = candidate:FindFirstChildOfClass("Humanoid")
            local targetRoot = candidate:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and targetRoot then
                local distance = (targetRoot.Position - root.Position).Magnitude
                if candidate.Name:find("Cursed Skeleton Boss", 1, true) then
                    if distance < bossDist then boss, bossDist = candidate, distance end
                elseif not bossOnly and candidate.Name:find("Cursed Skeleton", 1, true)
                    and (targetRoot.Position - CDKAfterPos.Position).Magnitude <= 600 then
                    if distance < mobDist then mob, mobDist = candidate, distance end
                end
            end
        end
    end
    return boss or (not bossOnly and mob or nil)
end

local function EquipCDKFinalSword()
    for _, name in ipairs({SwordYamaName, SwordTushitaName}) do
        if IsToolEquipped(name) then return true end
    end
    for _, name in ipairs({SwordYamaName, SwordTushitaName}) do
        if HasLocalTool(name) then
            EquipToolByName(name)
            return IsToolEquipped(name)
        end
    end
    if tick() >= CDKFinalState.NextSwordLoad then
        CDKFinalState.NextSwordLoad = tick() + 3
        local ok, err = pcall(function() remote:InvokeServer("LoadItem", SwordYamaName) end)
        if not ok then AddLog("Финал CDK: не удалось загрузить Yama: "..tostring(err)) end
    end
    UpdateStatus("Финал CDK: загружаю Yama для боя.")
    return false
end

local function FinishCDK()
    AutoCDK = false
    StopTween = true
    NoclipEnabled = false
    DisableAllQuests()
    UI.RestoreCollision()
    if UI.RenderRunning then UI.RenderRunning() end
    UpdateStatus("Cursed Dual Katana получен!")
    AddLog("CDK! Поздравляю")
end

local function FightCDKFinalTarget(target)
    local char, root = CDKFinalCharacter()
    local hum = target and target:FindFirstChildOfClass("Humanoid")
    local targetRoot = target and target:FindFirstChild("HumanoidRootPart")
    if not CDKFinalActive() or not (char and hum and targetRoot) or hum.Health <= 0 then return end
    if not EquipCDKFinalSword() then return end
    local isBoss = target.Name:find("Cursed Skeleton Boss", 1, true) ~= nil
    local function interrupted()
        return not CDKFinalActive() or LocalPlayer.Character ~= char or not target.Parent
            or hum.Health <= 0 or (not isBoss and FindCDKFinalTarget(true) ~= nil)
    end
    UpdateStatus("Финал CDK: "..target.Name)
    if (targetRoot.Position - root.Position).Magnitude > 50 then
        if not SimpleTeleport(targetRoot.CFrame * FarmOffset, "финал CDK: "..target.Name, interrupted) then return end
    end
    local deadline, lastAttack = tick() + (isBoss and 180 or 60), -math.huge
    while not interrupted() and tick() < deadline do
        local current, currentRoot = CDKFinalCharacter()
        hum = target:FindFirstChildOfClass("Humanoid")
        targetRoot = target:FindFirstChild("HumanoidRootPart")
        if current ~= char or not currentRoot or not hum or not targetRoot then break end
        if (targetRoot.Position - currentRoot.Position).Magnitude > 50 then
            if not SimpleTeleport(targetRoot.CFrame * FarmOffset, "финал CDK: сближение", interrupted) then break end
        else
            currentRoot.CFrame = targetRoot.CFrame * FarmOffset
            currentRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
            currentRoot.AssemblyAngularVelocity = Vector3.new(0,0,0)
        end
        if interrupted() then break end
        AutoHaki()
        if CDKFinalActive() and EquipCDKFinalSword() and tick() - lastAttack >= 0.15 then
            AttackModule:AttackEnemyModel(target)
            lastAttack = tick()
        end
        RunService.Heartbeat:Wait()
    end
    -- A vanished model may have despawned. Only a known death starts the reward wait.
    if isBoss and hum and hum.Health <= 0 and CDKFinalActive() then
        CDKFinalState.RewardUntil = tick() + 20
        AddLog("Cursed Skeleton Boss побеждён. Проверяю получение Cursed Dual Katana.")
    end
end

local function CDKFinalWait(seconds, char)
    local deadline = tick() + seconds
    while tick() < deadline do
        if not CDKFinalActive() or LocalPlayer.Character ~= char
            or not CDKFinalCharacter() or FindCDKFinalTarget(true) then return false end
        task.wait(0.05)
    end
    return CDKFinalActive() and LocalPlayer.Character == char and CDKFinalCharacter() ~= nil
        and FindCDKFinalTarget(true) == nil
end

local function HoldCDKAltarE(char, seconds)
    if not CDKFinalActive() or LocalPlayer.Character ~= char or not CDKFinalCharacter()
        or FindCDKFinalTarget(true) then return false end
    local pressed, err = pcall(function() VirtualInput:SendKeyEvent(true, "E", false, game) end)
    if not pressed then AddLog("Алтарь CDK: ошибка E: "..tostring(err)); return false end
    local ok, held = pcall(CDKFinalWait, seconds or 2, char)
    -- Always release E, including cancellation, death, errors and a newly spawned boss.
    pcall(function() VirtualInput:SendKeyEvent(false, "E", false, game) end)
    if not ok then error(held) end
    return held
end

local function CDKFinalTick()
    if not CDKFinalActive() then return end
    local owned = HasOwnedWeapon(SwordCDKName)
    if not CDKFinalActive() then return end
    if owned == true then FinishCDK(); return end
    local char, root = CDKFinalCharacter()
    if not char then return end
    -- A living boss always takes priority over altar interactions and other skeletons.
    local target = FindCDKFinalTarget(false)
    if target then FightCDKFinalTarget(target); return end
    if tick() < CDKFinalState.RewardUntil then
        UpdateStatus("Босс побеждён. Жду выдачи Cursed Dual Katana.")
        return
    end
    if owned == nil then
        UpdateStatus("Финал CDK: жду подтверждения данных инвентаря.")
        return
    end
    local fragments = GetCountMaterials("Alucard Fragment")
    if not CDKFinalStarted and (fragments == nil or fragments < 6) then return end
    if tick() < CDKFinalState.NextAltar then
        UpdateStatus("Финал CDK: жду появления босса у алтаря.")
        return
    end
    if not CDKFinalState.PrepDone then
        UpdateStatus("Финал CDK: подготовительный пьедестал, E на 5 секунд.")
        if (root.Position - CDKPrepPos.Position).Magnitude > 8 then
            if not SimpleTeleport(CDKPrepPos, "подготовительный пьедестал CDK", function()
                return not CDKFinalActive() or LocalPlayer.Character ~= char or FindCDKFinalTarget(true) ~= nil
            end) then return end
        end
        local current, prepRoot = CDKFinalCharacter()
        if current ~= char or not prepRoot or (prepRoot.Position - CDKPrepPos.Position).Magnitude > 12 then return end
        if not HoldCDKAltarE(char, 5) then return end
        CDKFinalState.PrepDone = true
        AddLog("Подготовительный пьедестал CDK активирован. Перехожу к следующему.")
    end
    if (root.Position - CDKAltarPos.Position).Magnitude > 8 then
        UpdateStatus("Финал CDK: лечу к алтарю.")
        if not SimpleTeleport(CDKAltarPos, "алтарь CDK", function()
            return not CDKFinalActive() or LocalPlayer.Character ~= char or FindCDKFinalTarget(true) ~= nil
        end) then return end
    end
    if not CDKFinalActive() or LocalPlayer.Character ~= char or FindCDKFinalTarget(true) then return end
    local _, arrivedRoot = CDKFinalCharacter()
    if not arrivedRoot or (arrivedRoot.Position - CDKAltarPos.Position).Magnitude > 12 then return end
    CDKFinalState.NextAltar = tick() + 12
    UpdateStatus("Финал CDK: взаимодействую с алтарём.")
    for _, side in ipairs({"Good", "Evil"}) do
        if not CDKFinalActive() or FindCDKFinalTarget(true) then return end
        local ok, err = pcall(function() remote:InvokeServer("CDKQuest", "Progress", side) end)
        if not ok then AddLog("Алтарь CDK: "..tostring(err)); return end
        if not CDKFinalWait(1, char) then return end
    end
    if not HoldCDKAltarE(char) then return end
    if not CDKFinalWait(1, char) then return end
    if SimpleTeleport(CDKAfterPos, "позиция после алтаря CDK", function()
        return not CDKFinalActive() or LocalPlayer.Character ~= char or FindCDKFinalTarget(true) ~= nil
    end) then
        AddLog("Алтарь CDK активирован. Жду Cursed Skeleton Boss и выдачи меча.")
    end
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
                local stage = CDKFinalStarted and 6 or (af ~= nil and GetStageFromAF(af) or nil)
                if stage ~= nil and stage ~= CurrentStage then
                    CurrentStage = stage
                    AddLog("CDK: AF="..tostring(af).." -> стадия "..stage)
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
                        CDKFinalStarted = true
                        AutoCDKFinal = true
                        UpdateStatus("Финал CDK: алтарь и Cursed Skeleton Boss.")
                        AddLog("6 фрагментов есть. Продолжаю до получения Cursed Dual Katana.")
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
                if AutoCDKFinal then RunTick("CDKFinalTick", CDKFinalTick) end
            end
        end
    end
end)

AddLog("AutoCDK загружен. Включай кнопку в 3-м море (Haunted Castle / Castle on the Sea / Cake Queen).")
