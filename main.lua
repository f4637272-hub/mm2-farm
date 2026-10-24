-- MM2 Candy Autofarm + Simple GUI + Fling + Auto-Search
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
    flySpeed   = 75,         
    noClip     = true,
    maxCandy   = 50,         
    enableFling= true        
}
-- =========================================================

-- ===== KEY CHECK =====
local function checkKey(key)
    key = tostring(key or ""):gsub("^%s*(.-)%s*$", "%1")

    if key == "" then
        return false, "Введите ключ"
    end

    local success, isValid, errorMsg = pcall(function()
        local response = HttpService:RequestAsync({
            Url = CONFIG.checkURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                key = key
            })
        })

        if not response.Success then
            return false, "HTTP " .. tostring(response.StatusCode)
        end

        local data = HttpService:JSONDecode(response.Body)

        if type(data) ~= "table" then
            return false, "Некорректный ответ сервера"
        end

        if data.valid == true and data.status == "active" then
            return true, "OK"
        end

        if data.status == "expired" then
            return false, "Срок действия ключа истёк"
        elseif data.status == "revoked" then
            return false, "Ключ отозван"
        elseif data.status == "invalid" then
            return false, "Неверный ключ"
        end

        return false, "Не удалось подтвердить ключ"
    end)

    if not success then
        warn("Ошибка проверки лицензии:", isValid)
        return false, "Ошибка соединения или ответа сервера"
    end

    return isValid, errorMsg
end

-- ===== ОКНО КЛЮЧА =====
local function promptKey(callback)
    local gui = Instance.new("ScreenGui")
    gui.Name = "KeyGui"; gui.ResetOnSpawn = false; gui.DisplayOrder = 10
    gui.Parent = LP:WaitForChild("PlayerGui")
    
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 300, 0, 180); f.Position = UDim2.new(0.5, -150, 0.5, -90)
    f.BackgroundColor3 = Color3.fromRGB(25, 25, 28); f.BorderSizePixel = 0; f.Parent = gui
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(45, 45, 50); stroke.Parent = f

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 25); title.Position = UDim2.new(0, 0, 0, 15)
    title.BackgroundTransparency = 1; title.Text = "АВТОРИЗАЦИЯ"
    title.TextColor3 = Color3.fromRGB(155, 225, 93); title.Font = Enum.Font.GothamBold; title.TextSize = 16; title.Parent = f

    local tgTag = Instance.new("TextLabel")
    tgTag.Size = UDim2.new(1, 0, 0, 15); tgTag.Position = UDim2.new(0, 0, 0, 35)
    tgTag.BackgroundTransparency = 1; tgTag.Text = "TGK: @BaysentaScript"
    tgTag.TextColor3 = Color3.fromRGB(120, 180, 255); tgTag.Font = Enum.Font.Gotham; tgTag.TextSize = 12; tgTag.Parent = f

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 260, 0, 35); box.Position = UDim2.new(0, 20, 0, 60)
    box.PlaceholderText = "Введите ключ..."; box.Text = ""; box.ClearTextOnFocus = false
    box.TextSize = 14; box.BackgroundColor3 = Color3.fromRGB(40, 40, 45); box.TextColor3 = Color3.fromRGB(240, 240, 240)
    box.Font = Enum.Font.Gotham; box.BorderSizePixel = 0; box.Parent = f
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 260, 0, 35) 
    btn.Position = UDim2.new(0, 20, 0, 110)
    btn.BackgroundColor3 = Color3.fromRGB(155, 225, 93)
    btn.TextColor3 = Color3.fromRGB(20, 20, 20)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; btn.Text = "Проверить"
    btn.BorderSizePixel = 0; btn.AutoButtonColor = false; btn.Parent = f
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(180, 245, 120)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(155, 225, 93)}):Play()
    end)

    local st = Instance.new("TextLabel")
    st.Size = UDim2.new(0, 260, 0, 20); st.Position = UDim2.new(0, 20, 0, 150)
    st.BackgroundTransparency = 1; st.TextColor3 = Color3.fromRGB(255, 90, 90); st.TextSize = 12; st.Font = Enum.Font.Gotham; st.Text = ""; st.Parent = f

    btn.MouseButton1Click:Connect(function()
        st.TextColor3 = Color3.fromRGB(200, 200, 200); st.Text = "Проверка..."
        local ok, msg = checkKey(box.Text)
        if ok then
            st.TextColor3 = Color3.fromRGB(155, 225, 93); st.Text = "Успешно!"
            task.wait(0.3)
            
            callback() -- Создаем главное окно
            task.wait(0.1)
            
            gui.Enabled = false -- Скрываем окно ключа
        else
            st.TextColor3 = Color3.fromRGB(255, 90, 90); st.Text = "Ошибка: " .. tostring(msg)
        end
    end)
end

-- ===== ГЛАВНОЕ ОКНО (ПРОСТАЯ GUI) =====
local function createMainGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "MM2Farm_GUI"; gui.ResetOnSpawn = false; gui.Parent = LP:WaitForChild("PlayerGui")
    gui.DisplayOrder = 20

    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 260, 0, 160); f.Position = UDim2.new(0, 20, 0, 20)
    f.BackgroundColor3 = Color3.fromRGB(25, 25, 28); f.BorderSizePixel = 0
    f.Active = true; f.Parent = gui
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

    -- Перетаскивание
    local dragging, dragInput, dragStart, startPos
    f.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = f.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    f.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            f.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30); title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1; title.Text = "MM2 Farm | @BaysentaScript"
    title.TextColor3 = Color3.fromRGB(155, 225, 93); title.Font = Enum.Font.GothamBold; title.TextSize = 15; title.Parent = f

    local counter = Instance.new("TextLabel")
    counter.Size = UDim2.new(1, 0, 0, 30); counter.Position = UDim2.new(0, 0, 0, 40)
    counter.BackgroundTransparency = 1; counter.Text = "Собрано конфет: 0"
    counter.TextColor3 = Color3.fromRGB(240, 240, 240); counter.Font = Enum.Font.Gotham; counter.TextSize = 15; counter.Parent = f

    local btnStart = Instance.new("TextButton")
    btnStart.Size = UDim2.new(0, 110, 0, 30); btnStart.Position = UDim2.new(0, 20, 0, 100)
    btnStart.Text = "Старт"; btnStart.Font = Enum.Font.GothamBold; btnStart.TextSize = 14
    btnStart.BackgroundColor3 = Color3.fromRGB(155, 225, 93); btnStart.TextColor3 = Color3.fromRGB(20, 20, 20); btnStart.Parent = f
    Instance.new("UICorner", btnStart).CornerRadius = UDim.new(0, 4)

    local btnStop = Instance.new("TextButton")
    btnStop.Size = UDim2.new(0, 110, 0, 30); btnStop.Position = UDim2.new(0, 130, 0, 100)
    btnStop.Text = "Стоп"; btnStop.Font = Enum.Font.GothamBold; btnStop.TextSize = 14
    btnStop.BackgroundColor3 = Color3.fromRGB(255, 90, 90); btnStop.TextColor3 = Color3.fromRGB(20, 20, 20); btnStop.Parent = f
    Instance.new("UICorner", btnStop).CornerRadius = UDim.new(0, 4)

    return f, counter, btnStart, btnStop
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

-- ===== ПОЛЕТ И NOCLIP =====
local function ensureFly()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if flyBV and flyBV.Parent == hrp then return end

    if flyConn then flyConn:Disconnect() end
    if flyBV then flyBV:Destroy() end

    flyBV = Instance.new("BodyVelocity")
    flyBV.Name = "MM2FarmFly"; flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBV.Velocity = Vector3.zero; flyBV.P = 0; flyBV.Parent = hrp

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
local function startFarm(counterLabel)
    if running then return end
    running = true
    local count = 0
    enableNoClip()

    task.spawn(function()
        while running do
            if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then
                task.wait(1)
            else
                ensureFly()
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
                        counterLabel.Text = "Собрано конфет: " .. count
                        if CONFIG.enableFling and count >= CONFIG.maxCandy then doFling(); count = 0 end
                    end
                    task.wait(CONFIG.touchWait) 
                else
                    task.wait(0.3)
                end
            end
            task.wait(CONFIG.loopDelay)
        end
    end)
end

local function stopFarm()
    running = false; currentTarget = nil; stopFly(); disableNoClip()
end

-- Анти-AFK
LP.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)

-- ===== КОМАНДА ДЛЯ СМЕНЫ КЛЮЧА =====
LP.Chatted:Connect(function(msg)
    if msg:lower() == "/key" then
        local keyGui = LP.PlayerGui:FindFirstChild("KeyGui")
        if keyGui then
            keyGui.Enabled = not keyGui.Enabled 
        end
    end
end)

-- ===== ЗАПУСК =====
promptKey(function()
    local main, counter, btnStart, btnStop = createMainGUI()
    btnStart.MouseButton1Click:Connect(function() if not running then startFarm(counter) end end)
    btnStop.MouseButton1Click:Connect(function() stopFarm() end)
end)
