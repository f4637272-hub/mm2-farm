-- MM2 Candy Autofarm + WindUI + Fling + Auto-Search
-- Автор: TGK @BaysentaScript
-- Исполнитель: Delta / Fluxus / Arceus X / Synapse / KRNL

local Players      = game:GetService("Players")
local HttpService  = game:GetService("HttpService")
local VirtualUser  = game:GetService("VirtualUser")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP           = Players.LocalPlayer

-- ================= НАСТРОЙКИ (УСКОРЕНО) =================
local CONFIG = {
    checkURL   = "https://nbpanel-api.onrender.com/v1/licenses/verify",
    loopDelay  = 0.05,       
    touchWait  = 0.1,        
    itemFilter = {"Candy", "Treat", "Coin", "Gift"}, 
    flySpeed   = 75,         -- Базовая скорость (меняется слайдером)
    noClip     = true,
    maxCandy   = 50,         
    enableFling= true        
}
-- =========================================================

-- ===== КРАСИВЫЙ WINDUI СТИЛЬ =====
local WindUI = {
    BgColor     = Color3.fromRGB(18, 18, 20),
    BgTrans     = 0.05,
    StrokeColor = Color3.fromRGB(45, 45, 50),
    TextColor   = Color3.fromRGB(240, 240, 240),
    Accent      = Color3.fromRGB(155, 225, 93), -- Твой неоновый лайм
    Danger      = Color3.fromRGB(255, 80, 80),
    Font        = Enum.Font.GothamMedium,
    FontBold    = Enum.Font.GothamBold,
    
    CreateWindow = function(titleText)
        local gui = Instance.new("ScreenGui")
        gui.Name = "MM2_WindUI"; gui.ResetOnSpawn = false
        gui.Parent = LP:WaitForChild("PlayerGui")
        
        local main = Instance.new("Frame")
        main.Size = UDim2.new(0, 280, 0, 240); main.Position = UDim2.new(0, 20, 0, 20)
        main.BackgroundColor3 = WindUI.BgColor; main.BackgroundTransparency = WindUI.BgTrans
        main.BorderSizePixel = 0; main.Active = true; main.Parent = gui
        Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = WindUI.StrokeColor; stroke.Thickness = 1.5; stroke.Parent = main

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -40, 0, 25); title.Position = UDim2.new(0, 20, 0, 10)
        title.BackgroundTransparency = 1; title.Text = titleText
        title.TextColor3 = WindUI.TextColor; title.Font = WindUI.FontBold; title.TextSize = 16
        title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = main
        
        -- ТВОЙ ТЕЛЕГРАМ ТЕГ
        local tgTag = Instance.new("TextLabel")
        tgTag.Size = UDim2.new(1, -40, 0, 15); tgTag.Position = UDim2.new(0, 20, 0, 32)
        tgTag.BackgroundTransparency = 1; tgTag.Text = "TGK: @BaysentaScript"
        tgTag.TextColor3 = Color3.fromRGB(120, 180, 255); -- Голубой цвет для ссылки
        tgTag.Font = WindUI.Font; tgTag.TextSize = 12
        tgTag.TextXAlignment = Enum.TextXAlignment.Left; tgTag.Parent = main
        
        local sep = Instance.new("Frame")
        sep.Size = UDim2.new(1, -40, 0, 1); sep.Position = UDim2.new(0, 20, 0, 55)
        sep.BackgroundColor3 = WindUI.StrokeColor; sep.BorderSizePixel = 0; sep.Parent = main

        -- Перетаскивание
        local dragging, dragInput, dragStart, startPos
        main.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = input.Position; startPos = main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        main.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        
        return main
    end,
    
    CreateButton = function(parent, text, isDanger)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.5, -10, 0, 35); btn.BackgroundColor3 = isDanger and WindUI.Danger or WindUI.Accent
        btn.TextColor3 = isDanger and WindUI.TextColor or Color3.fromRGB(20, 20, 20)
        btn.Font = WindUI.FontBold; btn.TextSize = 14; btn.Text = text; btn.BorderSizePixel = 0
        btn.AutoButtonColor = false; btn.Parent = parent
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = isDanger and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(180, 245, 120)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = isDanger and WindUI.Danger or WindUI.Accent}):Play()
        end)
        return btn
    end,
    
    CreateSlider = function(parent, text, min, max, default, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -40, 0, 45); frame.BackgroundTransparency = 1; frame.Parent = parent
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20); label.BackgroundTransparency = 1
        label.Text = text .. ": " .. default; label.TextColor3 = WindUI.TextColor
        label.Font = WindUI.Font; label.TextSize = 13; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = frame
        
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, 0, 0, 6); bar.Position = UDim2.new(0, 0, 0, 28)
        bar.BackgroundColor3 = WindUI.StrokeColor; bar.BorderSizePixel = 0; bar.Parent = frame
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = WindUI.Accent; fill.BorderSizePixel = 0; fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1; btn.Text = ""; btn.Parent = bar
        
        local dragging = false
        local function update(input)
            local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * pos)
            fill.Size = UDim2.new(pos, 0, 1, 0)
            label.Text = text .. ": " .. value
            callback(value)
        end
        
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; update(input)
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update(input)
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        
        return frame
    end
}

-- ===== KEY CHECK =====
local function checkKey(key)
    if not key or key == "" then return false, "Введите ключ" end
    local body = HttpService:JSONEncode({ key = key })
    local ok, response = pcall(function()
        local reqFunc = (syn and syn.request) or (http and http.request) or request
        if reqFunc then
            return reqFunc({ Url = CONFIG.checkURL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
        else
            return { StatusCode = 200, Body = game:HttpPost(CONFIG.checkURL, body, "application/json") }
        end
    end)
    if not ok or not response then return false, "Сервер недоступен" end
    if response.StatusCode ~= 200 then return false, "Неверный ключ" end
    return true, "OK"
end

-- ===== ОКНО КЛЮЧА =====
local function promptKey(callback)
    local gui = Instance.new("ScreenGui")
    gui.Name = "KeyGui"; gui.ResetOnSpawn = false; gui.Parent = LP:WaitForChild("PlayerGui")
    
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 300, 0, 180); f.Position = UDim2.new(0.5, -150, 0.5, -90)
    f.BackgroundColor3 = WindUI.BgColor; f.BorderSizePixel = 0; f.Parent = gui
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke"); stroke.Color = WindUI.StrokeColor; stroke.Parent = f

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 25); title.Position = UDim2.new(0, 0, 0, 15)
    title.BackgroundTransparency = 1; title.Text = "АВТОРИЗАЦИЯ"
    title.TextColor3 = WindUI.Accent; title.Font = WindUI.FontBold; title.TextSize = 16; title.Parent = f

    local tgTag = Instance.new("TextLabel")
    tgTag.Size = UDim2.new(1, 0, 0, 15); tgTag.Position = UDim2.new(0, 0, 0, 35)
    tgTag.BackgroundTransparency = 1; tgTag.Text = "TGK: @BaysentaScript"
    tgTag.TextColor3 = Color3.fromRGB(120, 180, 255); tgTag.Font = WindUI.Font; tgTag.TextSize = 12; tgTag.Parent = f

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 260, 0, 35); box.Position = UDim2.new(0, 20, 0, 60)
    box.PlaceholderText = "Введите ключ..."; box.Text = ""; box.ClearTextOnFocus = false
    box.TextSize = 14; box.BackgroundColor3 = Color3.fromRGB(30, 30, 35); box.TextColor3 = WindUI.TextColor
    box.Font = WindUI.Font; box.BorderSizePixel = 0; box.Parent = f
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

    local btn = WindUI.CreateButton(f, "Проверить", false)
    btn.Size = UDim2.new(0, 260, 0, 35); btn.Position = UDim2.new(0, 20, 0, 110)

    local st = Instance.new("TextLabel")
    st.Size = UDim2.new(0, 260, 0, 20); st.Position = UDim2.new(0, 20, 0, 150)
    st.BackgroundTransparency = 1; st.TextColor3 = WindUI.Danger; st.TextSize = 12; st.Font = WindUI.Font; st.Text = ""; st.Parent = f

    btn.MouseButton1Click:Connect(function()
        st.TextColor3 = Color3.fromRGB(200, 200, 200); st.Text = "Проверка..."
        local ok, msg = checkKey(box.Text)
        if ok then
            st.TextColor3 = WindUI.Accent; st.Text = "Успешно!"
            task.wait(0.4); gui:Destroy(); callback()
        else
            st.TextColor3 = WindUI.Danger; st.Text = "Ошибка: " .. tostring(msg)
        end
    end)
end

-- ===== ГЛАВНОЕ ОКНО =====
local function createMainGUI()
    local main = WindUI.CreateWindow("MM2 FARM | WindUI")
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -40, 0, 20); status.Position = UDim2.new(0, 20, 0, 65)
    status.BackgroundTransparency = 1; status.Text = "Статус: Ожидание"
    status.TextColor3 = WindUI.TextColor; status.Font = WindUI.Font; status.TextSize = 13
    status.TextXAlignment = Enum.TextXAlignment.Left; status.Parent = main

    local counter = Instance.new("TextLabel")
    counter.Size = UDim2.new(1, -40, 0, 20); counter.Position = UDim2.new(0, 20, 0, 85)
    counter.BackgroundTransparency = 1; counter.Text = "Собрано: 0"
    counter.TextColor3 = WindUI.Accent; counter.Font = WindUI.FontBold; counter.TextSize = 14
    counter.TextXAlignment = Enum.TextXAlignment.Left; counter.Parent = main

    local slider = WindUI.CreateSlider(main, "Скорость полета", 30, 120, CONFIG.flySpeed, function(val)
        CONFIG.flySpeed = val
    end)
    slider.Position = UDim2.new(0, 20, 0, 110)

    local btnStart = WindUI.CreateButton(main, "Старт", false)
    btnStart.Position = UDim2.new(0, 20, 0, 180)
    
    local btnStop = WindUI.CreateButton(main, "Стоп", true)
    btnStop.Position = UDim2.new(0, 150, 0, 180)

    return main, counter, status, btnStart, btnStop
end

-- ===== ФИЗИКА И ПОИСК =====
local running = false
local currentTarget = nil
local flyBV, flyConn, noclipConn = nil, nil, nil

local function getClosestItem()
    local h = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not h then return nil end
    local closest, shortestDist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Tool") or obj:IsA("Model") then
            for _, name in ipairs(CONFIG.itemFilter) do
                if obj.Name:lower():find(name:lower()) then
                    local pos
                    if obj:IsA("Model") then
                        if obj.PrimaryPart then pos = obj.PrimaryPart.Position
                        elseif obj:FindFirstChild("Handle") then pos = obj.Handle.Position
                        else
                            for _, p in ipairs(obj:GetDescendants()) do if p:IsA("BasePart") then pos = p.Position; break end end
                        end
                    elseif obj:IsA("BasePart") then pos = obj.Position
                    elseif obj:IsA("Tool") and obj:FindFirstChild("Handle") then pos = obj.Handle.Position end

                    if pos then
                        local dist = (h.Position - pos).Magnitude
                        if dist < shortestDist then shortestDist = dist; closest = obj end
                    end
                    break
                end
            end
        end
    end
    return closest
end

local function getTargetPos(target)
    if not target then return nil end
    if target:IsA("Model") then
        if target.PrimaryPart then return target.PrimaryPart.Position end
        if target:FindFirstChild("Handle") then return target.Handle.Position end
        for _, p in ipairs(target:GetDescendants()) do if p:IsA("BasePart") then return p.Position end end
    elseif target:IsA("Tool") and target:FindFirstChild("Handle") then return target.Handle.Position
    elseif target:IsA("BasePart") then return target.Position end
    return nil
end

-- ===== ФЛИНГ =====
local function doFling()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local targetHrp = player.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = player.Character:FindFirstChild("Humanoid")
            if targetHrp and targetHum and targetHum.Health > 0 then
                if (hrp.Position - targetHrp.Position).Magnitude < 30 then
                    local bv = Instance.new("BodyAngularVelocity")
                    bv.AngularVelocity = Vector3.new(9999, 9999, 9999)
                    bv.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                    bv.Parent = targetHrp
                    
                    local bv2 = Instance.new("BodyVelocity")
                    bv2.Velocity = Vector3.new(0, 500, 0)
                    bv2.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bv2.Parent = targetHrp
                    
                    task.delay(0.5, function() if bv then bv:Destroy() end; if bv2 then bv2:Destroy() end end)
                end
            end
        end
    end
end

local function ensureFly()
    if flyBV and flyBV.Parent then return end
    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    flyBV = Instance.new("BodyVelocity")
    flyBV.Name = "MM2FarmFly"; flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBV.Velocity = Vector3.zero; flyBV.P = 0; flyBV.Parent = hrp

    if flyConn then flyConn:Disconnect() end
    flyConn = RunService.Heartbeat:Connect(function()
        if not running or not flyBV or not flyBV.Parent then
            if flyBV then flyBV.Velocity = Vector3.zero end
            return
        end
        local pos = getTargetPos(currentTarget)
        local h = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not h or not pos then flyBV.Velocity = Vector3.zero; return end
        local diff = pos - h.Position
        local dist = diff.Magnitude
        if dist < 2 then flyBV.Velocity = Vector3.zero
        else flyBV.Velocity = diff.Unit * math.min(CONFIG.flySpeed, dist * 5) end
    end)
end

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    local h = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if h then h.AssemblyLinearVelocity = Vector3.zero end
end

local function enableNoClip()
    if not CONFIG.noClip or noclipConn then return end
    noclipConn = RunService.Stepped:Connect(function()
        local char = LP.Character
        if char then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
            end
        end
    end)
end

local function disableNoClip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    local char = LP.Character
    if char then for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = true end end end
end

-- ===== ЦИКЛ ФАРМА =====
local function startFarm(counterLabel, statusLabel)
    if running then return end
    running = true
    statusLabel.Text = "Статус: Работает"
    statusLabel.TextColor3 = WindUI.Accent
    local count = 0
    ensureFly(); enableNoClip()

    task.spawn(function()
        while running do
            local target = getClosestItem()
            currentTarget = target
            if target then
                local t0 = tick()
                while running and target and target.Parent do
                    local h = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    local pos = getTargetPos(target)
                    if not h or not pos or (h.Position - pos).Magnitude < 2.5 or tick() - t0 > 3 then break end
                    task.wait(0.01)
                end
                if running then
                    count = count + 1
                    counterLabel.Text = "Собрано: " .. count
                    if CONFIG.enableFling and count >= CONFIG.maxCandy then doFling(); count = 0 end
                end
                task.wait(CONFIG.touchWait) 
            else
                task.wait(0.3)
            end
            task.wait(CONFIG.loopDelay)
        end
    end)
end

local function stopFarm(statusLabel)
    running = false; currentTarget = nil; stopFly(); disableNoClip()
    statusLabel.Text = "Статус: Остановлен"
    statusLabel.TextColor3 = WindUI.Danger
end

-- Анти-AFK
LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)

-- ===== ЗАПУСК =====
promptKey(function()
    local main, counter, status, btnStart, btnStop = createMainGUI()
    btnStart.MouseButton1Click:Connect(function() if not running then startFarm(counter, status) end end)
    btnStop.MouseButton1Click:Connect(function() stopFarm(status) end)
end)
