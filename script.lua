--[[
    ONIKAMI MOBILE SCRIPT - VERSÃO CORRIGIDA
    Correções aplicadas:
    - Removido label.Padding inválido (substituído por UIPadding)
    - CanvasSize do ScrollingFrame atualiza automaticamente
    - AutoFarmAutomatic protegido com pcall
    - mobBtn e kaBtn declarados antes do callback
    - Todas as referências a instâncias protegidas
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- Configurações
local Settings = {
    AutoFarm = false,
    AutoFarmMob = "NPC",
    AutoFarmAutomatic = false,
    KillAura = false,
    KillAuraMode = "Katana",
    KillAuraRange = 25,
    TeleportNPCs = false,
    AutoBreath = false,
    AutoActivateCodes = false,
}

-- ==================== INTERFACE ====================
local function CreateUI()
    -- Remove GUI antiga se existir
    local oldGui = LocalPlayer.PlayerGui:FindFirstChild("OnigamiGui")
    if oldGui then oldGui:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "OnigamiGui"
    ScreenGui.Parent = LocalPlayer.PlayerGui
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Botão flutuante para abrir/fechar
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
    ToggleButton.Visible = true
    ToggleButton.ZIndex = 10

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = ToggleButton

    -- Frame principal (menu)
    local MainFrame = Instance.new("Frame")
    MainFrame.Parent = ScreenGui
    MainFrame.Size = UDim2.new(0.92, 0, 0.85, 0)
    MainFrame.Position = UDim2.new(0.04, 0, 0.07, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    MainFrame.BackgroundTransparency = 0.1
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = false

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = MainFrame

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
    Scroll.Size = UDim2.new(1, 0, 0.88, 0)
    Scroll.Position = UDim2.new(0, 0, 0.09, 0)
    Scroll.BackgroundTransparency = 1
    Scroll.ScrollBarThickness = 4
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y -- CORREÇÃO: canvas automático

    local UIList = Instance.new("UIListLayout")
    UIList.Parent = Scroll
    UIList.SortOrder = Enum.SortOrder.LayoutOrder
    UIList.Padding = UDim.new(0, 6)
    UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local UIPad = Instance.new("UIPadding")
    UIPad.Parent = Scroll
    UIPad.PaddingTop = UDim.new(0, 6)
    UIPad.PaddingBottom = UDim.new(0, 6)

    -- Função para criar botão normal
    local function CreateButton(text, color, callback)
        local btn = Instance.new("TextButton")
        btn.Parent = Scroll
        btn.Size = UDim2.new(0.94, 0, 0, 44)
        btn.BackgroundColor3 = color or Color3.fromRGB(40, 40, 70)
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamBold
        btn.AutoButtonColor = false

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn

        btn.MouseButton1Down:Connect(callback)
        return btn
    end

    -- Função para criar toggle (CORRIGIDA: sem label.Padding inválido)
    local function CreateToggle(text, setting)
        local frame = Instance.new("Frame")
        frame.Parent = Scroll
        frame.Size = UDim2.new(0.94, 0, 0, 44)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        frame.BorderSizePixel = 0

        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 8)
        frameCorner.Parent = frame

        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(0.72, 0, 1, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextScaled = true
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left

        -- CORREÇÃO: UIPadding em vez de label.Padding
        local labelPad = Instance.new("UIPadding")
        labelPad.PaddingLeft = UDim.new(0, 10)
        labelPad.Parent = label

        local toggle = Instance.new("TextButton")
        toggle.Parent = frame
        toggle.Size = UDim2.new(0.2, 0, 0.7, 0)
        toggle.Position = UDim2.new(0.78, 0, 0.15, 0)
        toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
        toggle.BorderSizePixel = 0
        toggle.Text = "OFF"
        toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggle.TextScaled = true
        toggle.Font = Enum.Font.GothamBold

        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 6)
        toggleCorner.Parent = toggle

        toggle.MouseButton1Down:Connect(function()
            Settings[setting] = not Settings[setting]
            toggle.Text = Settings[setting] and "ON" or "OFF"
            toggle.BackgroundColor3 = Settings[setting]
                and Color3.fromRGB(0, 180, 0)
                or Color3.fromRGB(60, 60, 100)
        end)

        return frame
    end

    -- ===== BOTÕES DO MENU =====
    CreateToggle("🤖 Auto Farm", "AutoFarm")

    -- CORREÇÃO: variável declarada antes, atribuída depois
    local mobBtn
    mobBtn = CreateButton("🎯 Mob: " .. Settings.AutoFarmMob, Color3.fromRGB(30, 80, 30), function()
        local mobs = {"NPC", "Bandit", "Shinobi", "Samurai", "Dragon", "Demon", "Spirit", "Boss", "Akuma"}
        local current = table.find(mobs, Settings.AutoFarmMob) or 1
        Settings.AutoFarmMob = mobs[(current % #mobs) + 1]
        mobBtn.Text = "🎯 Mob: " .. Settings.AutoFarmMob
    end)

    CreateToggle("⚡ Auto Farm Automático", "AutoFarmAutomatic")
    CreateToggle("🗡️ Kill Aura", "KillAura")

    -- CORREÇÃO: mesmo padrão para kaBtn
    local kaBtn
    kaBtn = CreateButton("⚔️ Modo: " .. Settings.KillAuraMode, Color3.fromRGB(80, 30, 30), function()
        Settings.KillAuraMode = Settings.KillAuraMode == "Katana" and "Taijutsu" or "Katana"
        kaBtn.Text = "⚔️ Modo: " .. Settings.KillAuraMode
    end)

    CreateToggle("📡 Teleport NPCs", "TeleportNPCs")
    CreateToggle("💨 Auto Breath", "AutoBreath")

    CreateButton("🎁 Activar Todos os Códigos", Color3.fromRGB(200, 150, 0), function()
        if Settings.AutoActivateCodes then return end
        Settings.AutoActivateCodes = true
        local codes = {"UPDATE", "RELEASE", "SUB2", "FREE", "BONUS", "RESET", "RANK", "SPINS", "RERIDE"}
        for _, code in ipairs(codes) do
            pcall(function()
                ReplicatedStorage.Remotes.Command:InvokeServer("redeem", code)
            end)
            task.wait(0.5)
        end
        Settings.AutoActivateCodes = false
    end)

    -- Botão fechar (X)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = MainFrame
    closeBtn.Size = UDim2.new(0.1, 0, 0.065, 0)
    closeBtn.Position = UDim2.new(0.88, 0, 0.005, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 5

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Down:Connect(function()
        MainFrame.Visible = false
        ToggleButton.Visible = true
    end)

    -- ===== LÓGICA DO BOTÃO FLUTUANTE =====
    ToggleButton.MouseButton1Down:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
        ToggleButton.Visible = not MainFrame.Visible
    end)
end

-- ==================== FUNÇÕES ====================

local function AutoFarm()
    if not Settings.AutoFarm then return end
    local target = nil
    local closestDist = math.huge
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") then
            if v.Humanoid.Health > 0 and string.find(v.Name:lower(), Settings.AutoFarmMob:lower()) then
                local dist = (RootPart.Position - v.HumanoidRootPart.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    target = v
                end
            end
        end
    end
    if target and target:FindFirstChild("HumanoidRootPart") then
        local tween = TweenService:Create(RootPart, TweenInfo.new(0.5), {
            CFrame = CFrame.new(target.HumanoidRootPart.Position + Vector3.new(0, 0, 3))
        })
        tween:Play()
        task.wait(0.3)
        local combat = Character:FindFirstChildOfClass("Tool")
        if combat then
            combat:Activate()
            task.wait(0.1)
            combat:Deactivate()
        end
    end
end

local function KillAura()
    if not Settings.KillAura then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                if char.Humanoid.Health > 0 then
                    local dist = (RootPart.Position - char.HumanoidRootPart.Position).Magnitude
                    if dist <= Settings.KillAuraRange then
                        local weapon = nil
                        if Settings.KillAuraMode == "Katana" then
                            weapon = Character:FindFirstChild("Katana")
                                or Character:FindFirstChild("Dual Katana")
                                or Character:FindFirstChild("Blade")
                        else
                            weapon = Character:FindFirstChildOfClass("Tool")
                        end
                        if weapon then
                            Humanoid:EquipTool(weapon)
                            task.wait(0.1)
                            weapon:Activate()
                            task.wait(0.2)
                            weapon:Deactivate()
                        end
                    end
                end
            end
        end
    end
end

local function TeleportNPCs()
    if not Settings.TeleportNPCs then return end
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and string.find(v.Name:lower(), "npc") then
            RootPart.CFrame = CFrame.new(v.HumanoidRootPart.Position + Vector3.new(0, 2, 2))
            task.wait(0.5)
            break
        end
    end
end

local function AutoBreath()
    if not Settings.AutoBreath then return end
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Handle") and string.find(v.Name:lower(), "breath") then
            local dist = (RootPart.Position - v.Handle.Position).Magnitude
            if dist < 15 then
                local click = v:FindFirstChildOfClass("ClickDetector")
                if click then
                    fireclickdetector(click)
                    task.wait(1)
                end
            end
        end
    end
end

-- CORREÇÃO: protegido com pcall para evitar crash se Data não existir
local function AutoFarmAutomatic()
    if not Settings.AutoFarmAutomatic then return end
    local ok, level = pcall(function()
        return LocalPlayer.Data.Level.Value
    end)
    if not ok or not level then return end

    local mobs = {
        {lvl = 500, mob = "Boss"},
        {lvl = 350, mob = "Spirit"},
        {lvl = 200, mob = "Demon"},
        {lvl = 100, mob = "Dragon"},
        {lvl = 60,  mob = "Samurai"},
        {lvl = 30,  mob = "Shinobi"},
        {lvl = 10,  mob = "Bandit"},
        {lvl = 0,   mob = "NPC"},
    }

    local best = "NPC"
    for _, entry in ipairs(mobs) do
        if level >= entry.lvl then
            best = entry.mob
            break
        end
    end

    if best ~= Settings.AutoFarmMob then
        Settings.AutoFarmMob = best
    end
end

-- ==================== LOOP PRINCIPAL ====================
task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            Humanoid = Character:FindFirstChildOfClass("Humanoid")
            RootPart = Character:FindFirstChild("HumanoidRootPart")
            if not (Humanoid and RootPart) then return end

            if Settings.AutoFarm          then AutoFarm() end
            if Settings.KillAura          then KillAura() end
            if Settings.TeleportNPCs      then TeleportNPCs() end
            if Settings.AutoBreath        then AutoBreath() end
            if Settings.AutoFarmAutomatic then AutoFarmAutomatic() end
        end)
    end
end)

-- ==================== INICIAR ====================
pcall(CreateUI)
print("✅ ONIKAMI MOBILE SCRIPT CARREGADO!")
print("🔥 Clique no ⚡ para abrir o menu!")
