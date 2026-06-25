--[[
    KATANA HUB v2.0 - Script Reescrito
    Funcionalidades: ESP de NPCs + Kill Aura (Melee)
    
    COMO TESTAR:
    1. Execute o script
    2. A interface vai abrir
    3. Ative o ESP para ver se os NPCs são marcados
    4. Se não aparecer nada, olhe o F9 (console) para ver os logs
    5. Ative o Kill Aura e veja se ele ataca
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- ============================================
-- CONFIGURAÇÕES
-- ============================================
local config = {
    espEnabled = false,
    killAuraEnabled = false,
    range = 20,
    attackSpeed = 0.3,
    espColor = Color3.fromRGB(255, 50, 50),
}

-- ============================================
-- SISTEMA DE LOG (para debug no F9)
-- ============================================
local function log(msg, ...)
    print("[KatanaHub] " .. string.format(msg, ...))
end

log("Script iniciado! Aguardando character...")

-- ============================================
-- DETECÇÃO DE NPCs (MELHORADA)
-- ============================================
local function isNPC(model)
    if not model or not model:IsA("Model") then return false end
    -- Ignora o próprio jogador
    if model == character then return false end
    -- Ignora se for um jogador
    if Players:GetPlayerFromCharacter(model) then return false end
    -- Verifica se tem Humanoid e HumanoidRootPart
    local hum = model:FindFirstChild("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    -- Verifica se o Humanoid está vivo
    if hum.Health <= 0 then return false end
    return true
end

local function getEntitiesInRange(origin, range)
    local entities = {}
    local count = 0
    for _, v in ipairs(Workspace:GetChildren()) do
        if isNPC(v) then
            local root = v:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (root.Position - origin).Magnitude
                if dist <= range then
                    count = count + 1
                    table.insert(entities, {
                        model = v,
                        root = root,
                        distance = dist,
                        humanoid = v:FindFirstChild("Humanoid")
                    })
                end
            end
        end
    end
    log("NPCs encontrados no range: %d", count)
    table.sort(entities, function(a, b) return a.distance < b.distance end)
    return entities
end

-- ============================================
-- SISTEMA DE ESP (COM BILLBOARD GUI)
-- ============================================
local espObjects = {}

local function createEspLabel(model)
    if espObjects[model] then return end
    
    local root = model:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local humanoid = model:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- BillboardGui
    local label = Instance.new("BillboardGui")
    label.Name = "ESPLabel"
    label.Size = UDim2.new(0, 200, 0, 50)
    label.AlwaysOnTop = true
    label.StudsOffset = Vector3.new(0, 3, 0)
    label.Parent = root
    
    -- Frame principal
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Parent = label
    
    -- Nome
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = config.espColor
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = model.Name or "NPC"
    nameLabel.Parent = frame
    
    -- Distância
    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distLabel.TextStrokeTransparency = 0.3
    distLabel.TextSize = 12
    distLabel.Font = Enum.Font.Gotham
    distLabel.Text = "0m"
    distLabel.Parent = frame
    
    -- Box (borda)
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, 0, 1, 0)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 2
    box.BorderColor3 = config.espColor
    box.Parent = label
    
    espObjects[model] = {
        label = label,
        nameLabel = nameLabel,
        distLabel = distLabel,
        box = box,
        model = model,
        root = root,
        humanoid = humanoid
    }
    
    log("ESP criado para: %s", model.Name)
end

local function removeEsp(model)
    local data = espObjects[model]
    if data then
        if data.label then data.label:Destroy() end
        espObjects[model] = nil
    end
end

local function updateEsp()
    if not config.espEnabled then
        for model, _ in pairs(espObjects) do
            removeEsp(model)
        end
        return
    end
    
    local origin = humanoidRootPart.Position
    
    -- Verifica todos os modelos no Workspace
    for _, v in ipairs(Workspace:GetChildren()) do
        if isNPC(v) then
            if not espObjects[v] then
                createEspLabel(v)
            end
            -- Atualiza distância
            local root = v:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (root.Position - origin).Magnitude
                local data = espObjects[v]
                if data then
                    data.distLabel.Text = string.format("%.1fm", dist)
                    -- Cor baseada na vida
                    local health = data.humanoid and data.humanoid.Health or 100
                    local maxHealth = data.humanoid and data.humanoid.MaxHealth or 100
                    local healthPercent = math.clamp(health / maxHealth, 0, 1)
                    local color = Color3.fromRGB(
                        255 * (1 - healthPercent),
                        255 * healthPercent,
                        50
                    )
                    data.nameLabel.TextColor3 = color
                    data.box.BorderColor3 = color
                end
            end
        else
            if espObjects[v] then
                removeEsp(v)
            end
        end
    end
    
    -- Limpa objetos que não existem mais
    for model, _ in pairs(espObjects) do
        if not model or not model.Parent then
            removeEsp(model)
        end
    end
end

-- ============================================
-- SISTEMA DE KILL AURA (COM MÚLTIPLOS MÉTODOS)
-- ============================================
local currentTarget = nil
local attackCooldown = 0

local function findWeapon()
    -- Procura no inventário (Backpack)
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, v in ipairs(backpack:GetChildren()) do
            if v:IsA("Tool") then
                return v
            end
        end
    end
    -- Verifica se está segurando alguma arma
    if character then
        for _, v in ipairs(character:GetChildren()) do
            if v:IsA("Tool") then
                return v
            end
        end
    end
    return nil
end

local function attackTarget(target)
    local weapon = findWeapon()
    if not weapon then
        log("Nenhuma arma encontrada!")
        return false
    end
    
    log("Atacando: %s com arma: %s", target.Name, weapon.Name)
    
    -- Tenta equipar a arma se estiver no Backpack
    if weapon.Parent == player:FindFirstChild("Backpack") then
        weapon.Parent = character
        task.wait(0.1)
    end
    
    -- Verifica se a arma está equipada
    if weapon.Parent ~= character then
        log("Falha ao equipar arma!")
        return false
    end
    
    -- MÉTODO 1: Ativar a ferramenta diretamente
    pcall(function()
        weapon:Activate()
    end)
    
    -- MÉTODO 2: Disparar eventos remotos comuns
    for _, v in ipairs(weapon:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            pcall(function()
                v:FireServer()
            end)
        elseif v:IsA("RemoteFunction") then
            pcall(function()
                v:InvokeServer()
            end)
        end
    end
    
    -- MÉTODO 3: Simular clique do mouse
    pcall(function()
        local mouse = player:GetMouse()
        if mouse then
            mouse.Button1Down:Fire()
            task.wait(0.05)
            mouse.Button1Up:Fire()
        end
    end)
    
    -- MÉTODO 4: Usar VirtualUser (para simuladores de clique)
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new())
    end)
    
    -- MÉTODO 5: Ativar via Humanoid (se existir)
    if humanoid and humanoid:FindFirstChild("Attack") then
        pcall(function()
            humanoid.Attack:FireServer()
        end)
    end
    
    return true
end

local function performKillAura()
    if not config.killAuraEnabled then
        currentTarget = nil
        return
    end
    
    local origin = humanoidRootPart.Position
    local range = config.range
    
    -- Busca entidades no range
    local entities = getEntitiesInRange(origin, range)
    
    if #entities == 0 then
        currentTarget = nil
        return
    end
    
    -- Escolhe o alvo mais próximo
    local target = entities[1]
    if not target then return end
    
    currentTarget = target.model
    
    -- Cooldown
    if attackCooldown > 0 then
        attackCooldown = attackCooldown - 0.1
        return
    end
    
    -- Verifica se o alvo ainda está vivo
    if not target.humanoid or target.humanoid.Health <= 0 then
        currentTarget = nil
        return
    end
    
    -- Tenta atacar
    local success = attackTarget(target.model)
    if success then
        attackCooldown = config.attackSpeed
    end
end

-- ============================================
-- INTERFACE GRÁFICA (SIMPLIFICADA E FUNCIONAL)
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KatanaHubGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

-- Estilo
local theme = {
    bg = Color3.fromRGB(20, 20, 28),
    bgAlt = Color3.fromRGB(30, 30, 42),
    primary = Color3.fromRGB(200, 60, 60),
    secondary = Color3.fromRGB(60, 200, 120),
    text = Color3.fromRGB(255, 255, 255),
    textDim = Color3.fromRGB(180, 180, 200),
}

local function createFrame(parent, size, pos, color)
    local f = Instance.new("Frame")
    f.Size = size
    f.Position = pos
    f.BackgroundColor3 = color or theme.bg
    f.BorderSizePixel = 0
    f.ClipsDescendants = true
    f.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 12)
    c.Parent = f
    return f
end

-- Frame principal
local mainFrame = createFrame(screenGui, UDim2.new(0, 340, 0, 420), UDim2.new(0.5, -170, 0.5, -210))

-- Título
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚔ KATANA HUB v2"
title.TextColor3 = Color3.fromRGB(255, 80, 80)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- Fechar
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -38, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = mainFrame
local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(0, 8)
cc.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

-- Conteúdo
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -50)
content.Position = UDim2.new(0, 10, 0, 45)
content.BackgroundTransparency = 1
content.Parent = mainFrame

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 10)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = content

-- Função para criar toggle
local function createToggle(parent, labelText, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 35)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = theme.text
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.Parent = container
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 26)
    btn.Position = UDim2.new(1, -55, 0.5, -13)
    btn.BackgroundColor3 = default and theme.secondary or Color3.fromRGB(80, 80, 100)
    btn.BorderSizePixel = 0
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = theme.text
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Parent = container
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 13)
    c.Parent = btn
    
    local state = default
    local function toggle()
        state = not state
        btn.BackgroundColor3 = state and theme.secondary or Color3.fromRGB(80, 80, 100)
        btn.Text = state and "ON" or "OFF"
        if callback then callback(state) end
    end
    btn.MouseButton1Click:Connect(toggle)
    return { toggle = btn, get = function() return state end }
end

-- Função para criar slider
local function createSlider(parent, labelText, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 45)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6, 0, 0.5, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = theme.text
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.Gotham
    lbl.Parent = container
    
    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0.4, 0, 0.5, 0)
    valLbl.Position = UDim2.new(0.6, 0, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = Color3.fromRGB(255, 200, 50)
    valLbl.TextSize = 13
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Font = Enum.Font.Gotham
    valLbl.Parent = container
    
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 4)
    track.Position = UDim2.new(0, 0, 1, -6)
    track.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    track.BorderSizePixel = 0
    track.Parent = container
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = theme.primary
    fill.BorderSizePixel = 0
    fill.Parent = track
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new((default - min) / (max - min), -7, -0.5, -7)
    knob.BackgroundColor3 = theme.text
    knob.BorderSizePixel = 0
    knob.Parent = track
    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(0, 7)
    kc.Parent = knob
    
    local value = default
    local function update(x)
        local trackSize = track.AbsoluteSize.X
        if trackSize == 0 then return end
        local rel = math.clamp((x - track.AbsolutePosition.X) / trackSize, 0, 1)
        value = min + (max - min) * rel
        value = math.round(value * 10) / 10
        value = math.clamp(value, min, max)
        fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        knob.Position = UDim2.new((value - min) / (max - min), -7, -0.5, -7)
        valLbl.Text = tostring(value)
        if callback then callback(value) end
    end
    
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            update(input.Position.X)
        end
    end)
    track.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            update(input.Position.X)
        end
    end)
    return { get = function() return value end }
end

-- ============================================
-- ADICIONANDO OS CONTROLES NA INTERFACE
-- ============================================

-- ESP
local espToggle = createToggle(content, "👁 ESP de NPCs", false, function(state)
    config.espEnabled = state
    log("ESP %s", state and "ATIVADO" or "DESATIVADO")
    if not state then
        for model, _ in pairs(espObjects) do removeEsp(model) end
    end
end)

-- Kill Aura
local kaToggle = createToggle(content, "🗡 Kill Aura", false, function(state)
    config.killAuraEnabled = state
    log("Kill Aura %s", state and "ATIVADO" or "DESATIVADO")
end)

-- Range
local rangeSlider = createSlider(content, "Alcance", 5, 50, 20, function(v)
    config.range = v
end)

-- Velocidade
local speedSlider = createSlider(content, "Velocidade (s)", 0.1, 1.5, 0.3, function(v)
    config.attackSpeed = v
end)

-- Info
local infoFrame = Instance.new("Frame")
infoFrame.Size = UDim2.new(1, 0, 0, 30)
infoFrame.BackgroundTransparency = 1
infoFrame.Parent = content

local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(1, 0, 1, 0)
infoText.BackgroundTransparency = 1
infoText.Text = "📊 Alvo: Nenhum"
infoText.TextColor3 = theme.textDim
infoText.TextSize = 12
infoText.Font = Enum.Font.Gotham
infoText.Parent = infoFrame

-- ============================================
-- LOOP PRINCIPAL
-- ============================================
log("Interface carregada! Aguardando ações...")

-- Loop de ESP
RunService.RenderStepped:Connect(function()
    updateEsp()
end)

-- Loop de Kill Aura
game:GetService("Heartbeat"):Connect(function(dt)
    if config.killAuraEnabled then
        performKillAura()
        if currentTarget then
            local dist = (currentTarget:FindFirstChild("HumanoidRootPart") and currentTarget.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude or 0
            infoText.Text = string.format("🎯 Alvo: %s | %.1fm", currentTarget.Name or "NPC", dist)
        else
            infoText.Text = "📊 Alvo: Nenhum"
        end
    else
        infoText.Text = "📊 Kill Aura desativada"
    end
end)

-- Atualiza character se ressuscitar
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    log("Character recarregado!")
end)

log("✅ Katana Hub v2 carregado! Use F9 para ver os logs de debug.")