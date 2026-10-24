-- =============================================
-- ПОЛНЫЙ СКРИПТ MM2 CANDY FARM + FAST TP
-- Автор: @BaysentaScript
-- =============================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- ================= НАСТРОЙКИ =================
local CONFIG = {
    checkURL = "https://nbpanel-api.onrender.com/v1/licenses/verify"
}

getgenv().AutoFarm = false
getgenv().AntiAFK = false
getgenv().FarmSpeed = 0 -- 0 = максимальная скорость (без задержек)

-- =============================================
-- СИСТЕМА ПРОВЕРКИ КЛЮЧА (KEY SYSTEM)
-- =============================================
local function checkKey(key)
    key = tostring(key or ""):gsub("^%s*(.-)%s*$", "%1")
    if key == "" then return false, "Введите ключ" end

    local success, isValid, errorMsg = pcall(function()
        local response = HttpService:RequestAsync({
            Url = CONFIG.checkURL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({ key = key })
        })

        if not response.Success then
            return false, "HTTP " .. tostring(response.StatusCode)
        end

        local data = HttpService:JSONDecode(response.Body)
        if type(data) ~= "table" then return false, "Ошибка сервера" end

        if data.valid == true and data.status == "active" then
            return true, "OK"
        end

        if data.status == "expired" then return false, "Срок действия ключа истёк"
        elseif data.status == "revoked" then return false, "Ключ отозван"
        elseif data.status == "invalid" then return false, "Неверный ключ" end

        return false, "Не удалось подтвердить ключ"
    end)

    if not success then
        return false, "Ошибка соединения"
    end

    return isValid, errorMsg
end

-- =============================================
-- ГЛАВНЫЙ ЗАПУСК (СНАЧАЛА КЛЮЧ, ПОТОМ GUI)
-- =============================================
local function startScript()
    
    -- СОЗДАНИЕ GUI
    local ScreenGui = Instance.new("ScreenGui")
    local MainFrame = Instance.new("Frame")
    local AutoFarmBtn = Instance.new("TextButton")
    local AntiAFKBtn = Instance.new("TextButton")
    local Title = Instance.new("TextLabel")
    local TgTag = Instance.new("TextLabel")
    local Status = Instance.new("TextLabel")

    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 20

    -- Основной фрейм
    MainFrame.Parent = ScreenGui
    MainFrame.Size = UDim2.new(0, 220, 0, 200)
    MainFrame.Position = UDim2.new(0, 10, 0, 10)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

    -- Заголовок
    Title.Parent = MainFrame
    Title.Size = UDim2.new(1, 0, 0, 25)
    Title.Position = UDim2.new(0, 0, 0, 5)
    Title.BackgroundTransparency = 1
    Title.Text = "🎮 MM2 Fast TP Farm"
    Title.Font = Enum.Font.GothamBold
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16

    -- ТЕЛЕГРАМ ТЕГ
    TgTag.Parent = MainFrame
    TgTag.Size = UDim2.new(1, 0, 0, 15)
    TgTag.Position = UDim2.new(0, 0, 0, 28)
    TgTag.BackgroundTransparency = 1
    TgTag.Text = "TGK: @BaysentaScript"
    TgTag.Font = Enum.Font.Gotham
    TgTag.TextColor3 = Color3.fromRGB(120, 180, 255)
    TgTag.TextSize = 12

    -- Статус
    Status.Parent = MainFrame
    Status.Size = UDim2.new(1, 0, 0, 20)
    Status.Position = UDim2.new(0, 0, 0.85, 0)
    Status.BackgroundTransparency = 1
    Status.Text = "Готов к работе!"
    Status.TextColor3 = Color3.fromRGB(200, 200, 200)
    Status.TextSize = 12

    -- Кнопка авто-фарма
    AutoFarmBtn.Parent = MainFrame
    AutoFarmBtn.Size = UDim2.new(0.8, 0, 0, 45)
    AutoFarmBtn.Position = UDim2.new(0.1, 0, 0.25, 0)
    AutoFarmBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    AutoFarmBtn.Text = "🚜 ТП-Фарм: ВЫКЛ"
    AutoFarmBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    AutoFarmBtn.Font = Enum.Font.GothamBold
    AutoFarmBtn.TextSize = 14
    Instance.new("UICorner", AutoFarmBtn).CornerRadius = UDim.new(0, 6)

    -- Кнопка анти-АФК
    AntiAFKBtn.Parent = MainFrame
    AntiAFKBtn.Size = UDim2.new(0.8, 0, 0, 45)
    AntiAFKBtn.Position = UDim2.new(0.1, 0, 0.55, 0)
    AntiAFKBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    AntiAFKBtn.Text = "⏰ Анти-АФК: ВЫКЛ"
    AntiAFKBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    AntiAFKBtn.Font = Enum.Font.GothamBold
    AntiAFKBtn.TextSize = 14
    Instance.new("UICorner", AntiAFKBtn).CornerRadius = UDim.new(0, 6)

    -- ФУНКЦИИ GUI
    AutoFarmBtn.MouseButton1Click:Connect(function()
        getgenv().AutoFarm = not getgenv().AutoFarm
        if getgenv().AutoFarm then
            AutoFarmBtn.Text = "🚜 ТП-Фарм: ВКЛ"
            AutoFarmBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
            Status.Text = "Быстрый ТП-фарм запущен!"
            startFastFarm()
        else
            AutoFarmBtn.Text = "🚜 ТП-Фарм: ВЫКЛ"
            AutoFarmBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
            Status.Text = "ТП-фарм остановлен"
        end
    end)

    AntiAFKBtn.MouseButton1Click:Connect(function()
        getgenv().AntiAFK = not getgenv().AntiAFK
        if getgenv().AntiAFK then
            AntiAFKBtn.Text = "⏰ Анти-АФК: ВКЛ"
            AntiAFKBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
            Status.Text = "Анти-АФК активирован!"
            startAntiAFK()
        else
            AntiAFKBtn.Text = "⏰ Анти-АФК: ВЫКЛ"
            AntiAFKBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
            Status.Text = "Анти-АФК выключен"
        end
    end)

    -- СЛУЖЕБНЫЕ ФУНКЦИИ
    function notify(msg)
        Status.Text = msg
        task.wait(3)
        if getgenv().AutoFarm then
            Status.Text = "Сканируем и собираем..."
        else
            Status.Text = "Готов к работе"
        end
    end

    function isAlive()
        return LocalPlayer.Character and 
               LocalPlayer.Character:FindFirstChild("Humanoid") and 
               LocalPlayer.Character.Humanoid.Health > 0 and
               LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    end

    -- =============================================
    -- БЫСТРЫЙ ТП-ФАРМ
    -- =============================================
    function startFastFarm()
        task.spawn(function()
            while getgenv().AutoFarm do
                if not isAlive() then
                    LocalPlayer.CharacterAdded:Wait()
                    task.wait(1)
                end
                
                local candiesFound = 0
                
                -- Сканируем ВСЁ пространство мгновенно
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if not getgenv().AutoFarm then break end
                    
                    -- Ищем конфеты (Part или Model)
                    if (obj:IsA("BasePart") or obj:IsA("Model")) and (obj.Name:lower():find("candy") or obj.Name:lower():find("halloween")) then
                        
                        local targetPos
                        if obj:IsA("Model") then
                            if obj.PrimaryPart then targetPos = obj.PrimaryPart.Position
                            elseif obj:FindFirstChild("Handle") then targetPos = obj.Handle.Position
                            else
                                for _, p in pairs(obj:GetDescendants()) do
                                    if p:IsA("BasePart") then targetPos = p.Position break end
                                end
                            end
                        elseif obj:IsA("BasePart") then
                            targetPos = obj.Position
                        end

                        if targetPos then
                            -- Мгновенный телепорт к конфете
                            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 2, 0))
                            
                            -- Мгновенное касание (сбор)
                            pcall(function()
                                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 0)
                                task.wait(0.01) -- микро-задержка для сервера
                                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, obj, 1)
                            end)
                            
                            candiesFound = candiesFound + 1
                            
                            -- Если конфет много, делаем крошечную паузу, чтобы не крашнуло игру
                            if candiesFound % 10 == 0 then
                                task.wait(0.05)
                            end
                        end
                    end
                end
                
                if candiesFound > 0 then
                    Status.Text = "Собрано за проход: " .. candiesFound
                else
                    Status.Text = "Ищем конфеты..."
                    task.wait(0.5) -- Ждем спавна новых
                end
                
                task.wait(0.1) -- Пауза перед следующим сканированием
            end
        end)
    end

    -- ФУНКЦИЯ АНТИ-АФК
    function startAntiAFK()
        task.spawn(function()
            while getgenv().AntiAFK do
                if isAlive() then
                    VirtualInputManager:SendKeyEvent(true, "W", false, game)
                    task.wait(0.5)
                    VirtualInputManager:SendKeyEvent(false, "W", false, game)
                    task.wait(0.5)
                    VirtualInputManager:SendKeyEvent(true, "S", false, game)
                    task.wait(0.5)
                    VirtualInputManager:SendKeyEvent(false, "S", false, game)
                    
                    local cam = workspace.CurrentCamera
                    if cam then
                        cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(45), 0)
                    end
                end
                task.wait(25)
            end
        end)
    end

    -- АВТО-РЕСПАВН
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(3)
        if getgenv().AutoFarm then
            notify("Респавн. Продолжаем фарм!")
        end
    end)

    notify("Скрипт загружен! 🎮")
end

-- =============================================
-- ОКНО АВТОРИЗАЦИИ
-- =============================================
local function promptKey(callback)
    local gui = Instance.new("ScreenGui")
    gui.Name = "KeyGui"; gui.ResetOnSpawn = false; gui.DisplayOrder = 10
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
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

    local st = Instance.new("TextLabel")
    st.Size = UDim2.new(0, 260, 0, 20); st.Position = UDim2.new(0, 20, 0, 150)
    st.BackgroundTransparency = 1; st.TextColor3 = Color3.fromRGB(255, 90, 90); st.TextSize = 12; st.Font = Enum.Font.Gotham; st.Text = ""; st.Parent = f

    btn.MouseButton1Click:Connect(function()
        st.TextColor3 = Color3.fromRGB(200, 200, 200); st.Text = "Проверка..."
        local ok, msg = checkKey(box.Text)
        if ok then
            st.TextColor3 = Color3.fromRGB(155, 225, 93); st.Text = "Успешно!"
            task.wait(0.3)
            
            callback()
            task.wait(0.1)
            
            gui.Enabled = false
        else
            st.TextColor3 = Color3.fromRGB(255, 90, 90); st.Text = "Ошибка: " .. tostring(msg)
        end
    end)
end

-- ===== СТАРТ ПРОВЕРКИ КЛЮЧА =====
promptKey(function()
    startScript()
end)
