-- MM2 Candy Autofarm + Key System + Auto-Search (PC + Mobile)
-- Исполнитель: Delta / Fluxus / Arceus X / Synapse / KRNL

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local LP          = Players.LocalPlayer

-- ================= НАСТРОЙКИ =================
local CONFIG = {
    -- Твой реальный URL с Render (FastAPI)
    checkURL   = "https://nbpanel-api.onrender.com/v1/licenses/verify",
    
    -- Настройки фарма
    loopDelay  = 0.5,       -- пауза между циклами поиска
    touchWait  = 0.15,      -- пауза после телепорта к конфете
    -- Имена конфет в ивенте (добавь нужные, если не находит)
    itemFilter = {"Candy", "Treat", "Coin", "Gift"}, 
    progressEvery = 20,     -- как часто присылать уведомление о сборе
}
-- ==============================================

local function notify(t)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",
            {Title = "MM2Farm", Text = tostring(t), Duration = 4})
    end)
end

-- ===== KEY CHECK (FastAPI /v1/licenses/verify) =====
local function checkKey(key)
    if not key or key == "" then return false, "Введите ключ" end

    local body = HttpService:JSONEncode({ key = key })

    local ok, response = pcall(function()
        local reqFunc = (syn and syn.request) or (http and http.request) or request
        if reqFunc then
            return reqFunc({
                Url = CONFIG.checkURL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = body
            })
        else
            -- Фоллбэк для старых исполнителей
            return { StatusCode = 200, Body = game:HttpPost(CONFIG.checkURL, body, "application/json") }
        end
    end)

    if not ok or not response then
        return false, "Сервер недоступен (спит?)"
    end

    -- Если сервер вернул ошибку валидации (422) или другую
    if response.StatusCode ~= 200 then
        return false, "Ключ неверный или истек (Код: " .. tostring(response.StatusCode) .. ")"
    end

    -- Успех. Парсим тело (FastAPI может вернуть строку или JSON)
    local okDecode, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
    if okDecode and type(data) == "table" then
        if data.status == "ok" or data.valid == true or data.success == true then
            return true, "OK"
        end
    elseif okDecode and type(data) == "string" then
        return true, data 
    end

    -- Если тело пустое, но статус 200 — ключ принят
    return true, "OK"
end

-- ===== ОКНО ВВОДА КЛЮЧА =====
local function promptKey(callback)
    local gui = Instance.new("ScreenGui")
    gui.Name = "KeyGui"; gui.ResetOnSpawn = false
    gui.Parent = LP:WaitForChild("PlayerGui")

    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 320, 0, 180); f.Position = UDim2.new(0.5, -160, 0.5, -90)
    f.BackgroundColor3 = Color3.fromRGB(25, 25, 28); f.BorderSizePixel = 0
    f.Parent = gui
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30); title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1; title.Text = "MM2 Candy Farm"
    title.TextColor3 = Color3.fromRGB(155, 225, 93)
    title.Font = Enum.Font.GothamBold; title.TextSize = 18; title.Parent = f

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 280, 0, 40); box.Position = UDim2.new(0, 20, 0, 50)
    box.PlaceholderText = "Введите ключ..."; box.Text = ""
    box.ClearTextOnFocus = false; box.TextSize = 16
    box.BackgroundColor3 = Color3.fromRGB(40, 40, 45); box.TextColor3 = Color3.fromRGB(240, 240, 240)
    box.BorderSizePixel = 0; box.Parent = f
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 280, 0, 40); btn.Position = UDim2.new(0, 20, 0, 100)
    btn.Text = "Проверить"; btn.Font = Enum.Font.GothamBold; btn.TextSize = 16
    btn.BackgroundColor3 = Color3.fromRGB(155, 225, 93); btn.TextColor3 = Color3.fromRGB(20, 20, 20)
    btn.BorderSizePixel = 0; btn.Parent = f
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local st = Instance.new("TextLabel")
    st.Size = UDim2.new(0, 280, 0, 20); st.Position = UDim2.new(0, 20, 0, 148)
    st.BackgroundTransparency = 1; st.TextColor3 = Color3.fromRGB(255, 90, 90)
    st.TextSize = 13; st.Text = ""; st.Parent = f

    btn.MouseButton1Click:Connect(function()
        st.TextColor3 = Color3.fromRGB(200, 200, 200)
        st.Text = "Проверка..."
        local ok, msg = checkKey(box.Text)
        if ok then
            st.TextColor3 = Color3.fromRGB(80, 255, 80)
            st.Text = "Ключ верный. Запуск..."
            task.wait(0.5)
            gui:Destroy()
            callback()
        else
            st.TextColor3 = Color3.fromRGB(255, 90, 90)
            st.Text = "Ошибка: " .. tostring(msg)
        end
    end)
end

-- ===== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ДЛЯ ФАРМА =====
local function hrp()
    local c = LP.Character or LP.CharacterAdded:Wait()
    return c:FindFirstChild("HumanoidRootPart")
end

-- Поиск ближайшей конфеты
local function getClosestItem()
    local h = hrp()
    if not h then return nil end
    
    local closest = nil
    local shortestDist = math.huge -- бесконечность

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Tool") then
            for _, name in ipairs(CONFIG.itemFilter) do
                if obj.Name:lower():find(name:lower()) then
                    local dist = (h.Position - obj.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = obj
                    end
                    break
                end
            end
        end
    end
    return closest
end

-- ===== ОСНОВНОЙ ЦИКЛ АВТО-ФАРМА =====
local running = false
local function farm()
    running = true
    local count = 0
    notify("Фарм запущен (Авто-поиск)")

    while running do
        local target = getClosestItem()

        if target then
            local h = hrp()
            if h then
                -- Телепорт к конфете и касание
                h.CFrame = CFrame.new(target.Position + Vector3.new(0, 2, 0))
                task.wait(CONFIG.touchWait)
            end
            
            count = count + 1
            if count % CONFIG.progressEvery == 0 then
                notify(("Собрано: %d"):format(count))
            end
        else
            -- Если конфет нет, ждем 1 секунду
            task.wait(1)
        end

        task.wait(CONFIG.loopDelay)
    end
end

-- ===== АНТИ-AFK =====
LP.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ===== УПРАВЛЕНИЕ В ЧАТЕ =====
LP.Chatted:Connect(function(m)
    m = m:lower()
    if m == "/stop" then 
        running = false
        notify("Фарм остановлен")
    elseif m == "/start" and not running then 
        task.spawn(farm)
    end
end)

-- ===== СТАРТ =====
promptKey(function()
    task.spawn(farm)
end)
