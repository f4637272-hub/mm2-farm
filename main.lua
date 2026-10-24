-- MM2 Candy Autofarm + Key System + GUI + Fly/NoClip + Fling
-- Исполнитель: Delta / Fluxus / Arceus X / Synapse / KRNL

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local LP          = Players.LocalPlayer

-- ================= НАСТРОЙКИ =================
local CONFIG = {
    checkURL   = "https://nbpanel-api.onrender.com/v1/licenses/verify",
    loopDelay  = 0.2,        
    touchWait  = 0.3,       
    itemFilter = {"Candy", "Treat", "Coin", "Gift"}, 
    flySpeed   = 50,         
    noClip     = true,
    
    -- НАСТРОЙКИ ФЛИНГА
    maxCandy   = 50,         -- Сколько конфет собрать до флинга (замени на свой лимит мешка)
    enableFling= true        -- Включить/выключить флинг
}
-- ==============================================

-- ===== KEY CHECK (FastAPI) =====
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
    if not ok or not response then return false, "Сервер недоступен (спит?)" end
    if response.StatusCode ~= 200 then return false, "Неверный ключ (Код: " .. tostring(response.StatusCode) .. ")" end
    return true, "OK"
end

-- ===== ОКНО КЛЮЧА =====
local function promptKey(callback)
    local gui = Instance.new("ScreenGui")
    gui.Name = "KeyGui"; gui.ResetOnSpawn = false; gui.Parent = LP:WaitForChild("PlayerGui")
    
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 320, 0, 180); f.Position = UDim2.new(0.5, -160, 0.5, -90)
    f.BackgroundColor3 = Color3.fromRGB(25, 25, 28); f.BorderSizePixel = 0; f.Parent = gui
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30); title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1; title.Text = "MM2 Candy Farm"
    title.TextColor3 = Color3.fromRGB(155, 225, 93); title.Font = Enum.Font.GothamBold; title.TextSize = 18; title.Parent = f

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 280, 0, 40); box.Position = UDim2.new(0, 20, 0, 50)
    box.PlaceholderText = "Введите ключ..."; box.Text = ""; box.ClearTextOnFocus = false
    box.TextSize = 16; box.BackgroundColor3 = Color3.fromRGB(40, 40, 45); box.TextColor3 = Color3.fromRGB(240, 240, 240)
    box.BorderSizePixel = 0; box.Parent = f
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 280, 0, 40); btn.Position = UDim2.new(0, 20, 0, 100)
    btn.Text = "Проверить"; btn.Font = Enum.Font.GothamBold; btn.TextSize = 16
    btn.BackgroundColor3 = Color3.fromRGB(155, 225, 93); btn.TextColor3 = Color3.fromRGB(20, 20, 20); btn.BorderSizePixel = 0; btn.Parent = f
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local st = Instance.new("TextLabel")
    st.Size = UDim2.new(0, 280, 0, 20); st.Position = UDim2.new(0, 20, 0, 148)
    st.BackgroundTransparency = 1; st.TextColor3 = Color3.fromRGB(255, 90, 90); st.TextSize = 13; st.Text = ""; st.Parent = f

    btn.MouseButton1Click:Connect(function()
        st.TextColor3 = Color3.fromRGB(200, 200, 200); st.Text = "Проверка..."
        local ok, msg = checkKey(box.Text)
        if ok then
            st.TextColor3 = Color3.fromRGB(80, 255, 80); st.Text = "Успешно!"
            task.wait(0.4); gui:Destroy(); callback()
        else
            st.TextColor3 = Color3.fromRGB(255, 90, 90); st.Text = "Ошибка: " .. tostring(msg)
        end
    end)
end

-- ===== ГЛАВНЫЙ GUI =====
local function createMainGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "MM2Farm_GUI"; gui.ResetOnSpawn = false; gui.Parent = LP:WaitForChild("PlayerGui")

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
    title.BackgroundTransparency = 1; title.Text = "MM2 Farm [v1.3]"
    title.TextColor3 = Color3.fromRGB(155, 225, 93); title.Font = Enum.Font.GothamBold; title.TextSize = 16; title.Parent = f

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

-- Ищем объекты. Теперь учитываем модели и проверяем Position с Handle.
local function getClosestItem()
    local h = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not h then return nil end
    local closest, shortestDist = nil, math.huge
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Tool") or obj:IsA("Model") then
            for _, name in ipairs(CONFIG.itemFilter) do
                if obj.Name:lower():find(name:lower()) then
                    -- Находим реальную 3D точку (если это модель, берем главную часть или хэндл)
                    local pos
                    if obj:IsA("Model") then
                        if obj.PrimaryPart then pos = obj.PrimaryPart.Position
                        elseif obj:FindFirstChild("Handle") then pos = obj.Handle.Position
                        else
                            local parts = obj:GetDescendants()
                            for _, p in ipairs(parts) do if p:IsA("BasePart") then pos = p.Position; break end end
                        end
                    elseif obj:IsA("BasePart") then pos = obj.Position
                    elseif obj:IsA("Tool") and obj:FindFirstChild("Handle") then pos = obj.Handle.Position end

                    if pos then
                        local dist = (h.Position - pos).Magnitude
                        if dist < shortestDist then 
                            shortestDist = dist
                            closest = obj 
                        end
                    end
                    break
                end
            end
        end
    end
    return closest
end

-- Получить позицию цели (универсально)
local function getTargetPos(target)
    if not target then return nil end
    if target:IsA("Model") then
        if target.PrimaryPart then return target.PrimaryPart.Position end
        if target:FindFirstChild("Handle") then return target.Handle.Position end
        for _, p in ipairs(target:GetDescendants()) do if p:IsA("BasePart") then return p.Position end end
    elseif target:IsA("Tool") and target:FindFirstChild("Handle") then
        return target.Handle.Position
    elseif target:IsA("BasePart") then
        return target.Position
    end
    return nil
end

-- ===== ФЛИНГ (РАЗБРАСЫВАНИЕ) =====
local function doFling()
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Ищем других игроков поблизости
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local targetHrp = player.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = player.Character:FindFirstChild("Humanoid")
            if targetHrp and targetHum and targetHum.Health > 0 then
                local dist = (hrp.Position - targetHrp.Position).Magnitude
                if dist < 30 then -- Если игрок в радиусе 30 стадов
                    -- Физический пинок
                    local bv = Instance.new("BodyAngularVelocity")
                    bv.AngularVelocity = Vector3.new(9999, 9999, 9999)
                    bv.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                    bv.Parent = targetHrp
                    
                    local bv2 = Instance.new("BodyVelocity")
                    bv2.Velocity = Vector3.new(0, 500, 0) -- Подкидываем вверх
                    bv2.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bv2.Parent = targetHrp
                    
                    task.delay(0.5, function()
                        if bv then bv:Destroy() end
                        if bv2 then bv2:Destroy() end
                    end)
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
    flyBV.Name = "MM2FarmFly"
    flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBV.Velocity = Vector3.zero
    flyBV.P = 0
    flyBV.Parent = hrp

    if flyConn then flyConn:Disconnect() end
    flyConn = RunService.Heartbeat:Connect(function()
        if not running or not flyBV or not flyBV.Parent then
            if flyBV then flyBV.Velocity = Vector3.zero end
            return
        end
        
        local pos = getTargetPos(currentTarget)
        local char2 = LP.Character
        local h = char2 and char2:FindFirstChild("HumanoidRootPart")
        
        if not h or not pos then
            flyBV.Velocity = Vector3.zero
            return
        end
        
        local diff = pos - h.Position
        local dist = diff.Magnitude
        
        -- Останавливаемся на расстоянии 2 стада, чтобы точно задеть хитбоксом
        if dist < 2 then
            flyBV.Velocity = Vector3.zero
        else
            local speed = math.min(CONFIG.flySpeed, dist * 5)
            flyBV.Velocity = diff.Unit * speed
        end
    end)
end

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    local char = LP.Character
    local h = char and char:FindFirstChild("HumanoidRootPart")
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
    if char then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = true end
        end
    end
end

-- ===== ОСНОВНОЙ ЦИКЛ =====
local function startFarm(counterLabel)
    if running then return end
    running = true
    local count = 0
    ensureFly()
    enableNoClip()

    task.spawn(function()
        while running do
            local target = getClosestItem()
            currentTarget = target
            
            if target then
                local t0 = tick()
                while running and target and target.Parent do
                    local h = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    local pos = getTargetPos(target)
                    if not h or not pos then break end
                    
                    -- Если подлетели ближе 2.5 стадов — хватит
                    if (h.Position - pos).Magnitude < 2.5 then break end
                    if tick() - t0 > 3 then break end
                    task.wait(0.05)
                end
                
                if running then
                    count = count + 1
                    if counterLabel then counterLabel.Text = "Собрано конфет: " .. count end
                    
                    -- === FLING ПРИ ЗАПОЛНЕНИИ МЕШКА ===
                    if CONFIG.enableFling and count >= CONFIG.maxCandy then
                        doFling() -- Вызываем флинг
                        count = 0  -- Сбрасываем счетчик (если конфеты сбрасываются)
                    end
                end
                task.wait(CONFIG.touchWait) 
            else
                task.wait(0.6)
            end
            task.wait(CONFIG.loopDelay)
        end
    end)
end

local function stopFarm()
    running = false
    currentTarget = nil
    stopFly()
    disableNoClip()
end

-- Анти-AFK
LP.Idled:Connect(function()
    VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new())
end)

-- ===== ЗАПУСК =====
promptKey(function()
    local frame, counter, btnStart, btnStop = createMainGUI()
    
    btnStart.MouseButton1Click:Connect(function()
        if not running then startFarm(counter) end
    end)
    
    btnStop.MouseButton1Click:Connect(function()
        stopFarm()
    end)
end)
