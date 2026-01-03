-- LocalScript: Full Account Checker + Webhook + UI (fixed webhook)
local WEBHOOK_URL = "https://discord.com/api/webhooks/1455571104864141425/BEuHf_5yUFEQtyjPAebaFYGeNbh87gyVG_DwFgfeIKDkvVyK7EtSfxF9gc97trh9skIv"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local AUTO_REFRESH_INTERVAL = 0.1         -- как часто обновлять UI (сек)
local AUTO_SEND_WEBHOOK_ON_START = true  -- отправить вебхук автоматически один раз после первого сбора

local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

local FRUITS = {"Rocket-Rocket","Spin-Spin","Blade-Blade","Spring-Spring","Bomb-Bomb","Smoke-Smoke","Spike-Spike","Flame-Flame","Falcon-Falcon","Ice-Ice","Sand-Sand","Dark-Dark","Diamond-Diamond","Light-Light","Rubber-Rubber","Barrier-Barrier","Ghost-Ghost","Magma-Magma","Quake-Quake","Buddha-Buddha","Love-Love","Spider-Spider","Sound-Sound","Phoenix-Phoenix","Portal-Portal","Rumble-Rumble","Pain-Pain","Blizzard-Blizzard","Gravity-Gravity","Mammoth-Mammoth","T-Rex-T-Rex","Yeti-Yeti","Dough-Dough","Shadow-Shadow","Venom-Venom","Control-Control","Gas-Gas","Spirit-Spirit","Dragon-Dragon","Tiger-Tiger","Kitsune-Kitsune","Creation-Creation"}
local ACCESSORIES = {"Headband (Blue)","Headband (Green)","Headband (Orange)","Headband (Purple)","Headband (Red)","Headband (White)","Headband (Yellow)","Dojo Belt (Blue)","Dojo Belt (Green)","Dojo Belt (Orange)","Dojo Belt (Purple)","Dojo Belt (Red)","Dojo Belt (White)","Dojo Belt (Yellow)","Headband (Black)","Pink Coat","Bandanna (Black)","Bandanna (Green)","Bandanna (Red)","Black Spikey","Bear Ears","Black Cape","Coat","Blue Spikey Coat","Choppa","Dojo Belt (Black)","Golden Coat","Cool Shades","Elf Hat","Ghoul Mask","Sunhat","Hunter Cape (Black)","Hunter Cape (Green)","Hunter Cape (Red)","Jaw Shield","Lei","Marine Cap","Pretty","Red Spikey","Tooth","SwordsmanWarrior Helmet","T-Rex Skull","Tomoe Ring","Top Hat","Usoap's Hat","Helmet","Cupid's Coat","Dragon","D.S. Coat","Dino Hood","Mantle","Feathered Visage","Heart Shades","Holy Crown","Kitsune Mask","Kitsune Ribbon","Leviathan Crown","Musketeer Hat","Pale Scarf","Swan Glasses","Terror Jaw","Valkyrie Helm","Wyvern Helmet","Zebra Cap","50b Party Hat","Celestial Helmet","Leviathan","Dark Coat","Divine Cloak","Holiday Cloak","Shield","Oni Helmet","Party Hat","Sanguine Cloak","Uzoth's Cloak"}
local GUNS = {"Cutlass","Dual Katana","Katana","Iron Mace","Shark Saw","Triple Katana","Twin Hooks","Dragon Trident","Dual-Headed Blade","Flail","Gravity Blade","Longsword","Pipe","Soul Cane","Trident","Wardens Sword","Bisento","Buddy Sword","Canvander","Dark Dagger","Dragonheart","Fox Lamp","Koko","Midnight Blade","Oroshi","Pole (1st Form)","Pole (2nd Form)","Rengoku","Saber","Saishi","Spikey Trident","Shark Anchor","Shizu","Tushita","Yama","Cursed Dual Katana","Hallow Scythe","Dark Blade","Triple Dark Blade","True Triple Katana","Slingshot","Flintlock","Musket","Acidum Rifle","Bizarre Revolver","Cannon","Dual Flintlock","Magma Blaster","Refined Slingshot","Bazooka","Dragonstorm","Kabucha","Venom Bow","Skull Guitar"}
local COMBAT_STYLES = {"Combat","DarkStep","Electric","WaterKungFu","DragonBreath","Superhuman","DeathStep","SharkmanKarate","ElectricClaw","DragonTalon","Godhuman","SanguineArt"}

local function formatNumber(amount)
    local s = tostring(math.floor(amount or 0))
    local formatted = s:reverse():gsub("(%d%d%d)","%1."):reverse()
    if formatted:sub(1,1)=="." then formatted=formatted:sub(2) end
    return formatted.." $"
end

-- маленькая утилита для красивого вывода пустых списков
local function joinOrEmpty(t)
    if type(t) == "table" and #t > 0 then
        return table.concat(t, ", ")
    end
    return "(пусто)"
end

local function collectPlayerData()
    local data = {Name=player.Name,Race="Unknown",Beli=0,Level=0,Fragments=0,CombatStyle="None",BackpackFruits={},BackpackAccessories={},BackpackGuns={},InventoryFruits={},InventoryAccessories={},InventoryGuns={},TradeFruits={}}

    local statsFolder = player:FindFirstChild("Data")
    if statsFolder then
        local b = statsFolder:FindFirstChild("Beli")
        if b and typeof(b.Value)=="number" then data.Beli=b.Value end
        local l = statsFolder:FindFirstChild("Level")
        if l and typeof(l.Value)=="number" then data.Level=l.Value end
        local f = statsFolder:FindFirstChild("Fragments")
        if f and typeof(f.Value)=="number" then data.Fragments=f.Value end
        local r = statsFolder:FindFirstChild("Race")
        if r and typeof(r.Value)=="string" then data.Race=r.Value end
    end
    if player.GetAttribute then
        local attr = player:GetAttribute("Race")
        if attr then data.Race=attr end
    end

    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, it in ipairs(backpack:GetChildren()) do
            local name = it.Name
            if table.find(FRUITS,name) then table.insert(data.BackpackFruits,name)
            elseif table.find(ACCESSORIES,name) then table.insert(data.BackpackAccessories,name)
            elseif table.find(GUNS,name) then table.insert(data.BackpackGuns,name)
            elseif table.find(COMBAT_STYLES,name) then data.CombatStyle=name end
        end
    end

    local ok, invData = pcall(function() return remote:InvokeServer("getInventory") end)
    if ok and typeof(invData)=="table" then
        for _, item in ipairs(invData) do
            local name = item.Name or item.name or tostring(item)
            if table.find(FRUITS,name) then table.insert(data.InventoryFruits,name)
            elseif table.find(ACCESSORIES,name) then table.insert(data.InventoryAccessories,name)
            elseif table.find(GUNS,name) then table.insert(data.InventoryGuns,name)
            elseif table.find(COMBAT_STYLES,name) then data.CombatStyle=name end
        end
    end

    local ok2, tradeData = pcall(function() return remote:InvokeServer("getTradeInventory") end)
    if ok2 and typeof(tradeData)=="table" then
        for _, item in ipairs(tradeData) do
            local name = item.Name or item.name or tostring(item)
            if table.find(FRUITS,name) then table.insert(data.TradeFruits,name) end
        end
    end

    return data
end

-- =============== FIX: универсальная отправка JSON в Discord =================
local function httpPostJson(url, tbl)
    local json = HttpService:JSONEncode(tbl)
    local headers = {["Content-Type"] = "application/json"}

    -- поддержка executors (request/http_request/syn.request)
    local req = request or http_request or (syn and syn.request)

    if req then
        return pcall(function()
            req({Url = url, Method = "POST", Headers = headers, Body = json})
        end)
    else
        -- fallback: стандартный HttpService (работает из Server Script при включённом Http)
        return pcall(function()
            HttpService:PostAsync(url, json, Enum.HttpContentType.ApplicationJson)
        end)
    end
end

-- =============== FIX: переработанный SendWebhook ============================
local function SendWebhook(data)
    local embed = {
        ["title"] = "Account Report — " .. tostring(data.Name),
        ["description"] = "Собрано через CommF_",
        ["color"] = 3447003,
        ["fields"] = {
            {["name"]="Имя",                 ["value"]=data.Name,                 ["inline"]=true},
            {["name"]="Race",                ["value"]=data.Race,                 ["inline"]=true},
            {["name"]="Beli",                ["value"]=formatNumber(data.Beli),   ["inline"]=true},
            {["name"]="Level",               ["value"]=tostring(data.Level),      ["inline"]=true},
            {["name"]="Fragments",           ["value"]=tostring(data.Fragments),  ["inline"]=true},
            {["name"]="Combat Style",        ["value"]=data.CombatStyle,          ["inline"]=true},

            {["name"]="Фрукты (Backpack)",   ["value"]=joinOrEmpty(data.BackpackFruits),      ["inline"]=false},
            {["name"]="Аксессуары (Backpack)",["value"]=joinOrEmpty(data.BackpackAccessories), ["inline"]=false},
            {["name"]="Ганы (Backpack)",     ["value"]=joinOrEmpty(data.BackpackGuns),        ["inline"]=false},

            {["name"]="Фрукты (Inventory)",  ["value"]=joinOrEmpty(data.InventoryFruits),     ["inline"]=false},
            {["name"]="Аксессуары (Inventory)",["value"]=joinOrEmpty(data.InventoryAccessories),["inline"]=false},
            {["name"]="Ганы (Inventory)",    ["value"]=joinOrEmpty(data.InventoryGuns),       ["inline"]=false},

            {["name"]="Фрукты (Trade)",      ["value"]=joinOrEmpty(data.TradeFruits),         ["inline"]=false}
        },
        ["footer"] = {["text"] = os.date("%Y-%m-%d %H:%M:%S")}
    }

    local payload = {["embeds"] = {embed}}

    local ok, err = httpPostJson(WEBHOOK_URL, payload)
    if ok then
        print("✅ Отчёт успешно отправлен в Webhook!")
    else
        warn("❌ Ошибка при отправке Webhook: " .. tostring(err))
    end
    return ok
end
-- ===========================================================================

-- FULL UI
local function createUI()
    local gui = Instance.new("ScreenGui",playerGui)
    gui.Name="AccountCheckerUI"
    gui.ResetOnSpawn=false

    local frame = Instance.new("Frame",gui)
    frame.Size=UDim2.new(0,700,0,500)
    frame.Position=UDim2.new(0,10,0,10)
    frame.BackgroundColor3=Color3.fromRGB(30,30,30)

    local title = Instance.new("TextLabel",frame)
    title.Size=UDim2.new(1,0,0,30)
    title.Position=UDim2.new(0,0,0,0)
    title.Text="Account Checker UI"
    title.TextColor3=Color3.fromRGB(255,255,255)
    title.BackgroundTransparency=1
    title.Font=Enum.Font.SourceSansBold
    title.TextSize=22

    local scroll = Instance.new("ScrollingFrame",frame)
    scroll.Size=UDim2.new(1,-20,1,-70)
    scroll.Position=UDim2.new(0,10,0,40)
    scroll.CanvasSize=UDim2.new(0,0,5,0)
    scroll.BackgroundColor3=Color3.fromRGB(25,25,25)
    scroll.ScrollBarThickness=10

    local content = Instance.new("TextLabel",scroll)
    content.Size=UDim2.new(1,-20,0,10)
    content.Position=UDim2.new(0,10,0,10)
    content.BackgroundTransparency=1
    content.TextColor3=Color3.fromRGB(230,230,230)
    content.TextWrapped=true
    content.Font=Enum.Font.Code
    content.TextSize=14
    content.Text="Здесь будет отчёт..."

    local refreshBtn = Instance.new("TextButton",frame)
    refreshBtn.Size=UDim2.new(0,150,0,30)
    refreshBtn.Position=UDim2.new(0,10,1,-35)
    refreshBtn.Text="Обновить"
    refreshBtn.Font=Enum.Font.SourceSansBold
    refreshBtn.TextSize=16

    local sendBtn = Instance.new("TextButton",frame)
    sendBtn.Size=UDim2.new(0,200,0,30)
    sendBtn.Position=UDim2.new(0,170,1,-35)
    sendBtn.Text="Отправить в webhook"
    sendBtn.Font=Enum.Font.SourceSansBold
    sendBtn.TextSize=16

    local copyBtn = Instance.new("TextButton",frame)
    copyBtn.Size=UDim2.new(0,150,0,30)
    copyBtn.Position=UDim2.new(0,380,1,-35)
    copyBtn.Text="Скопировать"
    copyBtn.Font=Enum.Font.SourceSansBold
    copyBtn.TextSize=16

    local consoleBtn = Instance.new("TextButton",frame)
    consoleBtn.Size=UDim2.new(0,140,0,30)
    consoleBtn.Position=UDim2.new(0,540,1,-35)
    consoleBtn.Text="В Output"
    consoleBtn.Font=Enum.Font.SourceSansBold
    consoleBtn.TextSize=16

    local function refresh()
        local data = collectPlayerData()
        local lines = {}
        table.insert(lines,"=== Account: "..data.Name.." ===")
        table.insert(lines,"Race: "..data.Race)
        table.insert(lines,"Beli: "..formatNumber(data.Beli))
        table.insert(lines,"Level: "..data.Level)
        table.insert(lines,"Fragments: "..data.Fragments)
        table.insert(lines,"Combat Style: "..data.CombatStyle)
        table.insert(lines,"-- Backpack Fruits --\n"..joinOrEmpty(data.BackpackFruits))
        table.insert(lines,"-- Backpack Accessories --\n"..joinOrEmpty(data.BackpackAccessories))
        table.insert(lines,"-- Backpack Guns --\n"..joinOrEmpty(data.BackpackGuns))
        table.insert(lines,"-- Inventory Fruits --\n"..joinOrEmpty(data.InventoryFruits))
        table.insert(lines,"-- Inventory Accessories --\n"..joinOrEmpty(data.InventoryAccessories))
        table.insert(lines,"-- Inventory Guns --\n"..joinOrEmpty(data.InventoryGuns))
        table.insert(lines,"-- Trade Fruits --\n"..joinOrEmpty(data.TradeFruits))
        content.Text = table.concat(lines,"\n")
        content.Size = UDim2.new(1,-20,0,content.TextBounds.Y+20)
        scroll.CanvasSize = UDim2.new(0,0,0,content.TextBounds.Y+30)
    end

    refreshBtn.MouseButton1Click:Connect(refresh)
    copyBtn.MouseButton1Click:Connect(function()
        refresh()
        if setclipboard then
            pcall(function() setclipboard(content.Text) end)
        end
    end)
    consoleBtn.MouseButton1Click:Connect(function()
        refresh()
        print(content.Text)
    end)
    sendBtn.MouseButton1Click:Connect(function()
        sendBtn.Text="Отправка..."
        local data = collectPlayerData()
        local ok = SendWebhook(data)
        sendBtn.Text = ok and "✅ Отправлено" or "❌ Ошибка"
        task.delay(1.5,function() sendBtn.Text="Отправить в webhook" end)
    end)

    refresh()
end

-- маленькая утилита для красивого вывода пустых списков
local function joinOrEmpty(t)
    if type(t) == "table" and #t > 0 then
        return table.concat(t, ", ")
    end
    return "(пусто)"
end

-- (collectPlayerData / httpPostJson / SendWebhook остаются как в моем прошлом сообщении)

-- FULL UI
local function createUI()
    local gui = Instance.new("ScreenGui",playerGui)
    gui.Name="AccountCheckerUI"
    gui.ResetOnSpawn=false

    local frame = Instance.new("Frame",gui)
    frame.Size=UDim2.new(0,700,0,500)
    frame.Position=UDim2.new(0,10,0,10)
    frame.BackgroundColor3=Color3.fromRGB(30,30,30)

    local title = Instance.new("TextLabel",frame)
    title.Size=UDim2.new(1,0,0,30)
    title.Position=UDim2.new(0,0,0,0)
    title.Text="Account Checker UI"
    title.TextColor3=Color3.fromRGB(255,255,255)
    title.BackgroundTransparency=1
    title.Font=Enum.Font.SourceSansBold
    title.TextSize=22

    local scroll = Instance.new("ScrollingFrame",frame)
    scroll.Size=UDim2.new(1,-20,1,-70)
    scroll.Position=UDim2.new(0,10,0,40)
    scroll.CanvasSize=UDim2.new(0,0,5,0)
    scroll.BackgroundColor3=Color3.fromRGB(25,25,25)
    scroll.ScrollBarThickness=10

    local content = Instance.new("TextLabel",scroll)
    content.Size=UDim2.new(1,-20,0,10)
    content.Position=UDim2.new(0,10,0,10)
    content.BackgroundTransparency=1
    content.TextColor3=Color3.fromRGB(230,230,230)
    content.TextWrapped=true
    content.Font=Enum.Font.Code
    content.TextSize=14
    content.Text="Здесь будет отчёт..."

    local refreshBtn = Instance.new("TextButton",frame)
    refreshBtn.Size=UDim2.new(0,150,0,30)
    refreshBtn.Position=UDim2.new(0,10,1,-35)
    refreshBtn.Text="Обновить"
    refreshBtn.Font=Enum.Font.SourceSansBold
    refreshBtn.TextSize=16

    local sendBtn = Instance.new("TextButton",frame)
    sendBtn.Size=UDim2.new(0,200,0,30)
    sendBtn.Position=UDim2.new(0,170,1,-35)
    sendBtn.Text="Отправить в webhook"
    sendBtn.Font=Enum.Font.SourceSansBold
    sendBtn.TextSize=16

    local copyBtn = Instance.new("TextButton",frame)
    copyBtn.Size=UDim2.new(0,150,0,30)
    copyBtn.Position=UDim2.new(0,380,1,-35)
    copyBtn.Text="Скопировать"
    copyBtn.Font=Enum.Font.SourceSansBold
    copyBtn.TextSize=16

    local consoleBtn = Instance.new("TextButton",frame)
    consoleBtn.Size=UDim2.new(0,140,0,30)
    consoleBtn.Position=UDim2.new(0,540,1,-35)
    consoleBtn.Text="В Output"
    consoleBtn.Font=Enum.Font.SourceSansBold
    consoleBtn.TextSize=16

    -- === общая функция отрисовки текста + опционально вернуть data ===
    local function renderAndGet(returnData)
        local data = collectPlayerData()
        local lines = {}
        table.insert(lines,"=== Account: "..data.Name.." ===")
        table.insert(lines,"Race: "..data.Race)
        table.insert(lines,"Beli: "..formatNumber(data.Beli))
        table.insert(lines,"Level: "..data.Level)
        table.insert(lines,"Fragments: "..data.Fragments)
        table.insert(lines,"Combat Style: "..data.CombatStyle)
        table.insert(lines,"-- Backpack Fruits --\n"..joinOrEmpty(data.BackpackFruits))
        table.insert(lines,"-- Backpack Accessories --\n"..joinOrEmpty(data.BackpackAccessories))
        table.insert(lines,"-- Backpack Guns --\n"..joinOrEmpty(data.BackpackGuns))
        table.insert(lines,"-- Inventory Fruits --\n"..joinOrEmpty(data.InventoryFruits))
        table.insert(lines,"-- Inventory Accessories --\n"..joinOrEmpty(data.InventoryAccessories))
        table.insert(lines,"-- Inventory Guns --\n"..joinOrEmpty(data.InventoryGuns))
        table.insert(lines,"-- Trade Fruits --\n"..joinOrEmpty(data.TradeFruits))
        content.Text = table.concat(lines,"\n")
        content.Size = UDim2.new(1,-20,0,content.TextBounds.Y+20)
        scroll.CanvasSize = UDim2.new(0,0,0,content.TextBounds.Y+30)
        if returnData then return data end
    end

    -- кнопки как раньше
    refreshBtn.MouseButton1Click:Connect(function() renderAndGet(false) end)
    copyBtn.MouseButton1Click:Connect(function()
        renderAndGet(false)
        if setclipboard then pcall(function() setclipboard(content.Text) end) end
    end)
    consoleBtn.MouseButton1Click:Connect(function()
        renderAndGet(false)
        print(content.Text)
    end)
    sendBtn.MouseButton1Click:Connect(function()
        sendBtn.Text="Отправка..."
        local data = renderAndGet(true)
        local ok = SendWebhook(data)
        sendBtn.Text = ok and "✅ Отправлено" or "❌ Ошибка"
        task.delay(1.5,function() sendBtn.Text="Отправить в webhook" end)
    end)

    -- первичный рендер
    renderAndGet(false)

    -- ===== AUTO: автообновление + одноразовая автопосылка вебхука =====
    local webhookSent = false

    task.spawn(function()
        -- подождём немного, чтобы всё загрузилось (инвентарь/торговля)
        task.wait(3)
        if AUTO_SEND_WEBHOOK_ON_START and not webhookSent then
            local data = renderAndGet(true)
            local ok = SendWebhook(data)
            webhookSent = ok or true   -- даже если не ок — не спамим, можно поменять на `ok` если хочешь ретраи
        end

        while true do
            task.wait(AUTO_REFRESH_INTERVAL)
            renderAndGet(false)
        end
    end)
    -- ===== END AUTO =========================================================
end

pcall(createUI)
