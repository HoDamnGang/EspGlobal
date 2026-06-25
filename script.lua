--[[
    🌟 ONIKAMI MOBILE SCRIPT 🌟
    Funcionalidades:
    - Interface Mobile Otimizada
    - Auto Farm (com seleção de mobs)
    - Auto Farm Automático (conforme nível)
    - Kill Aura (para Katanas e Taijutsu)
    - Teleport para NPCs
    - Auto Pegar Respirações (Breaths)
    - Activate All Codes
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- ==================== CONFIGURAÇÕES ====================
local Settings = {
    AutoFarm = false,
    AutoFarmMob = "NPC",  -- Nome do mob
    AutoFarmAutomatic = false,
    KillAura = false,
    KillAuraMode = "Katana", -- "Katana" ou "Taijutsu"
    KillAuraRange = 25,
    TeleportNPCs = false,
    AutoBreath = false,
    AutoActivateCodes = false,
}

-- ==================== INTERFACE MOBILE ====================
local function CreateUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Parent = LocalPlayer.PlayerGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Botão Flutuante para abrir
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Parent = ScreenGui
    ToggleButton.Size = UDim2.new(0.12, 0, 0.07, 0)
    ToggleButton.Position = UDim2.new(0.01, 0, 0.01, 0)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    ToggleButton.Text = "⚡"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextScaled = true
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.BorderSizePixel = 0
    
    local MainVisible = false
    
    -- Menu Principal
    local MainFrame = Instance.new("Frame")
    MainFrame.Parent = ScreenGui
    MainFrame.Size = UDim2.new(0.92, 0, 0.85, 0)
    MainFrame.Position = UDim2.new(0.04, 0, 0.07, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    MainFrame.BackgroundTransparency = 0.1
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = false
    
    -- Título
    local Title = Instance.new("TextLabel")
    Title.Parent = MainFrame
    Title.Size = UDim2.new(1, 0, 0.07, 0)
    Title.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    Title.BorderSizePixel = 0
    Title.Text = "⚡ ONIKAMI MOBILE ⚡"
    Title.TextColor3 = Color3.fromRGB(255, 200, 50)
    Title.TextScaled = true
    Title.Font = Enum.Font.GothamBold
    
    -- Scroll
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Parent = MainFrame
    Scroll.Size = UDim2.new(1, 0, 0.9, 0)
    Scroll.Position = UDim2.new(0, 0, 0.08, 0)
    Scroll.BackgroundTransparency = 1
    Scroll.ScrollBarThickness = 4
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local UIList = Instance.new("UIListLayout")
    UIList.Parent = Scroll
    UIList.SortOrder = Enum.SortOrder.LayoutOrder
    UIList.Padding = UDim.new(0, 6)
    
    -- Função: Botão
    local function CreateButton(text, color, callback)
        local btn = Instance.new("TextButton")
        btn.Parent = Scroll
        btn.Size = UDim2.new(0.94, 0, 0.07, 0)
        btn.BackgroundColor3 = color or Color3.fromRGB(40, 40, 70)
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamBold
        btn.AutoButtonColor = false
        
        btn.MouseButton1Down:Connect(callback)
        return btn
    end
    
    -- Função: Toggle
    local function CreateToggle(text, setting, desc)
        local frame = Instance.new("Frame")
        frame.Parent = Scroll
        frame.Size = UDim2.new(0.94, 0, 0.07, 0)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        frame.BorderSizePixel = 0
        
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextScaled = true
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Padding = UDim.new(0, 10)
        
        local toggle = Instance.new("TextButton")
        toggle.Parent = frame
        toggle.Size = UDim2.new(0.2, 0, 0.8, 0)
        toggle.Position = UDim2.new(0.78, 0, 0.1, 0)
        toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
        toggle.BorderSizePixel = 0
        toggle.Text = "OFF"
        toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggle.TextScaled = true
        toggle.Font = Enum.Font.GothamBold
        
        toggle.MouseButton1Down:Connect(function()
            Settings[setting] = not Settings[setting]
            toggle.Text = Settings[setting] and "ON" or "OFF"
            toggle.BackgroundColor3 = Settings[setting] and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(60, 60, 100)
        end)
        
        return frame
    end
    
    -- ===== BOTÕES =====
    CreateToggle("🤖 Auto Farm", "AutoFarm")
    
    -- Selecionar Mob
    local mobBtn = CreateButton("🎯 Mob: " .. Settings.AutoFarmMob, Color3.fromRGB(30, 80, 30), function()
        local mobs = {"NPC", "Bandit", "Shinobi", "Samurai", "Dragon", "Demon", "Spirit", "Boss", "Akuma"}
        local current = table.find(mobs, Settings.AutoFarmMob) or 1
        Settings.AutoFarmMob = mobs[(current % #mobs) + 1]
        mobBtn.Text = "🎯 Mob: " .. Settings.AutoFarmMob
    end)
    
    CreateToggle("⚡ Auto Farm Automático", "AutoFarmAutomatic")
    CreateToggle("🗡️ Kill Aura", "KillAura")
    
    -- Modo Kill Aura
    local kaBtn = CreateButton("⚔️ Modo: " .. Settings.KillAuraMode, Color3.fromRGB(80, 30, 30), function()
        Settings.KillAuraMode = Settings.KillAuraMode == "Katana" and "Taijutsu" or "Katana"
        kaBtn.Text = "⚔️ Modo: " .. Settings.KillAuraMode
    end)
    
    CreateToggle("📡 Teleport NPCs", "TeleportNPCs")
    CreateToggle("💨 Auto Breath", "AutoBreath")
    
    -- Activate Codes
    CreateButton("🎁 Activar Todos os Códigos", Color3.fromRGB(200, 150, 0), function()
        Settings.AutoActivateCodes = true
        local codes = {"UPDATE", "RELEASE", "SUB2", "FREE", "BONUS", "RESET", "RANK", "SPINS", "RERIDE"}
        for _, code in ipairs(codes) do
            pcall(function()
                ReplicatedStorage.Remotes.Command:InvokeServer("redeem", code)
                wait(0.5)
            end)
        end
        Settings.AutoActivateCodes = false
    end)
    
    -- Fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = MainFrame
    closeBtn.Size = UDim2.new(0.08, 0, 0.06, 0)
    closeBtn.Position = UDim2.new(0.9, 0, 0.005, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.GothamBold
    
    closeBtn.MouseButton1Down:Connect(function()
        MainFrame.Visible = false
        ToggleButton.Visible = true
    end)
    
    -- Abrir/Fechar
    ToggleButton.MouseButton1Down:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
        ToggleButton.Visible = not MainFrame.Visible
    end)
end

-- ==================== FUNÇÕES ====================

-- Auto Farm
local function AutoFarm()
    if not Settings.AutoFarm then return end
    
    local target = nil
    local closestDist = math.huge
    
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") then
            local name = v.Name:lower()
            if string.find(name, Settings.AutoFarmMob:lower()) and v.Humanoid.Health > 0 then
                local dist = (RootPart.Position - v.HumanoidRootPart.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    target = v
                end
            end
        end
    end
    
    if target then
        TweenService:Create(RootPart, TweenInfo.new(0.5), {
            CFrame = CFrame.new(target.HumanoidRootPart.Position + Vector3.new(0, 0, 3))
        }):Play()
        wait(0.3)
        
        -- Atacar
        local combat = Character:FindFirstChildOfClass("Tool")
        if combat then
            combat:Activate()
            wait(0.1)
            combat:Deactivate()
        end
    end
end

-- Kill Aura
local function KillAura()
    if not Settings.KillAura then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                local dist = (RootPart.Position - char.HumanoidRootPart.Position).Magnitude
                if dist <= Settings.KillAuraRange then
                    -- Equipar
                    local weapon = nil
                    if Settings.KillAuraMode == "Katana" then
                        weapon = Character:FindFirstChild("Katana") or Character:FindFirstChild("Dual Katana") or Character:FindFirstChild("Blade")
                    else
                        weapon = Character:FindFirstChildOfClass("Tool")
                    end
                    
                    if weapon then
                        Humanoid:EquipTool(weapon)
                        wait(0.1)
                        weapon:Activate()
                        wait(0.2)
                        weapon:Deactivate()
                    end
                end
            end
        end
    end
end

-- Teleport NPCs
local function TeleportNPCs()
    if not Settings.TeleportNPCs then return end
    
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and string.find(v.Name:lower(), "npc") then
            RootPart.CFrame = CFrame.new(v.HumanoidRootPart.Position + Vector3.new(0, 2, 2))
            wait(0.5)
            break
        end
    end
end

-- Auto Breath
local function AutoBreath()
    if not Settings.AutoBreath then return end
    
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Handle") and string.find(v.Name:lower(), "breath") then
            local dist = (RootPart.Position - v.Handle.Position).Magnitude
            if dist < 15 then
                local click = v:FindFirstChildOfClass("ClickDetector")
                if click then
                    fireclickdetector(click)
                    wait(1)
                end
            end
        end
    end
end

-- Auto Farm Automático
local function AutoFarmAutomatic()
    if not Settings.AutoFarmAutomatic then return end
    
    local level = LocalPlayer.Data.Level.Value
    local mobs = {
        [0] = "NPC",
        [10] = "Bandit",
        [30] = "Shinobi",
        [60] = "Samurai",
        [100] = "Dragon",
        [200] = "Demon",
        [350] = "Spirit",
        [500] = "Boss"
    }
    
    local best = "NPC"
    for lvl, mob in pairs(mobs) do
        if level >= lvl then
            best = mob
        end
    end
    
    if best ~= Settings.AutoFarmMob then
        Settings.AutoFarmMob = best
    end
end

-- ==================== LOOP ====================
spawn(function()
    while wait(0.3) do
        pcall(function()
            Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            Humanoid = Character:FindFirstChildOfClass("Humanoid")
            RootPart = Character:FindFirstChild("HumanoidRootPart")
            
            if not (Humanoid and RootPart) then return end
            
            if Settings.AutoFarm then AutoFarm() end
            if Settings.KillAura then KillAura() end
            if Settings.TeleportNPCs then TeleportNPCs() end
            if Settings.AutoBreath then AutoBreath() end
            if Settings.AutoFarmAutomatic then AutoFarmAutomatic() end
        end)
    end
end)

-- ==================== INICIAR ====================
pcall(CreateUI)
print("✅ ONIKAMI MOBILE SCRIPT CARREGADO!")
print("🔥 Clique no ⚡ para abrir o menu!")