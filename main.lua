-- MM2 Candy Autofarm + Key System + GUI + Fly/NoClip
-- Исполнитель: Delta / Fluxus / Arceus X / Synapse / KRNL

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local LP          = Players.LocalPlayer
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")

-- ================= НАСТРОЙКИ =================
local CONFIG = {
    checkURL   = "https://nbpanel-api.onrender.com/v1/licenses/verify",
    loopDelay  = 0.4,
    touchWait  = 0.15,
    itemFilter = {"Candy", "Treat", "Coin", "Gift"}, 
    progressEvery = 20,
    flySpeed   = 45,  -- Скорость полета (оптимально 40-60)
    noClip     = true -- Выключать коллизию со стенами
}
-- ==============================================

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

-- ===== ГЛАВНЫЙ GUI (Появляется после ключа) =====
local function createMainGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "MM2Farm_GUI"; gui.ResetOnSpawn = false
    gui.Parent = LP:WaitForChild("PlayerGui")

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

    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30); title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1; title.Text = "MM2 Farm [v1.1]"
    title.TextColor3 = Color3.fromRGB(155, 225, 93); title.Font = Enum.Font.GothamBold; title.TextSize = 16; title.Parent = f

    -- Счётчик
    local counter = Instance.new("TextLabel")
    counter.Size = UDim2.new(1, 0, 0, 30); counter.Position = UDim2.new(0, 0, 0, 40)
    counter.BackgroundTransparency = 1; counter.Text = "Собрано конфет: 0"
    counter.TextColor3 = Color3.fromRGB(240, 240, 240); counter.Font = Enum.Font.Gotham; counter.TextSize = 15; counter.Parent = f

    -- Кнопка Start
    local btnStart = Instance.new("TextButton")
    btnStart.Size = UDim2.new(0, 110, 0, 30); btnStart.Position = UDim2.new(0, 20, 0, 100)
    btnStart.Text = "Старт"; btnStart.Font = Enum.Font.GothamBold; btnStart.TextSize = 14
    btnStart.BackgroundColor3 = Color3.fromRGB(155, 225, 93); btnStart.TextColor3 = Color3.fromRGB(20, 20, 20); btnStart.Parent = f
    Instance.new("UICorner", btnStart).CornerRadius = UDim.new(0, 4)

    -- Кнопка Stop
    local btnStop = Instance.new("TextButton")
    btnStop.Size = UDim2.new(0, 110, 0, 30); btnStop.Position = UDim2.new(0, 130, 0, 100)
    btnStop.Text = "Стоп"; btnStop.Font = Enum.Font.GothamBold; btnStop.TextSize = 14
    btnStop.BackgroundColor3 = Color3.fromRGB(255, 90, 90); btnStop.TextColor3 = Color3.fromRGB(20, 20, 20); btnStop.Parent = f
    Instance.new("UICorner", btnStop).CornerRadius = UDim.new(0, 4)

    return f, counter, btnStart, btnStop
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

-- ===== ФИЗИКА И ФАРМ =====
local running = false
local flyConnection = nil
local noclipConnection = nil

local function getClosestItem()
    local h = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not h then return nil end
    local closest, shortestDist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Tool") then
            for _, name in ipairs(CONFIG.itemFilter) do
                if obj.Name:lower():find(name:lower()) then
                    local dist = (h.Position - obj.Position).Magnitude
                    if dist < shortestDist then shortestDist = dist; closest = obj end
                    break
                end
            end
        end
    end
    return closest
end

local function startFly(targetPart)
    local char = LP.Character or LP.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    
    if flyConnection then flyConnection:Disconnect() end
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    
    flyConnection = RunService.Heartbeat:Connect(function()
        if not running or not targetPart or not targetPart.Parent then
            bv.Velocity = Vector3.zero
            return
        end
        local direction = (targetPart.Position - hrp.Position).Unit
        bv.Velocity = direction * CONFIG.flySpeed
    end)
    
    return function() -- StopFly
        if flyConnection then flyConnection:Disconnect() end
        if bv then bv:Destroy() end
    end
end

local function startFarm(counterLabel)
    if running then return end
    running = true
    local count = 0
    local char = LP.Character or LP.CharacterAdded:Wait()
    
    -- NoClip
    if CONFIG.noClip then
        noclipConnection = RunService.Stepped:Connect(function()
            if char then
                for _, v in pairs(char:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
                end
            end
        end)
    end

    task.spawn(function()
        while running do
            local target = getClosestItem()
            if target then
                local stopFly = startFly(target)
                task.wait(CONFIG.touchWait)
                stopFly()
                count = count + 1
                counterLabel.Text = "Собрано конфет: " .. count
            else
                task.wait(1)
            end
            task.wait(CONFIG.loopDelay)
        end
    end)
end

local function stopFarm()
    running = false
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        for _, v in pairs(LP.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = true end
        end
    end
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
