--[[
    Script: Katana Hub v1.0
    Funcionalidades: ESP de NPCs + Kill Aura (melee)
    Modo de uso: Execute no executor (Synapse, Krnl, etc.)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- ============================================
-- CONFIGURAÇÕES PADRÃO
-- ============================================
local config = {
    espEnabled = false,
    killAuraEnabled = false,
    range = 20,
    attackSpeed = 0.3,
    espColor = Color3.fromRGB(255, 50, 50),
    showDistance = true,
    showName = true,
    targetFilter = "NPC", -- "NPC", "Players", "All"
}

-- ============================================
-- UTILITÁRIOS
-- ============================================
local function isNPC(model)
    if not model or not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    return model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart")
end

local function isPlayer(model)
    if not model or not model:IsA("Model") then return false end
    return Players:GetPlayerFromCharacter(model) ~= nil
end

local function getCharacterParts(model)
    local parts = {}
    for _, v in ipairs(model:GetDescendants()) do
        if v:IsA("BasePart") and v ~= humanoidRootPart then
            table.insert(parts, v)
        end
    end
    return parts
end

local function getNearestNPC(origin, range)
    local nearest = nil
    local minDist = range or math.huge
    
    for _, v in ipairs(Workspace:GetChildren()) do
        if isNPC(v) then
            local root = v:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (root.Position - origin).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = v
                end
            end
        end
    end
    return nearest, minDist
end

local function getEntitiesInRange(origin, range)
    local entities = {}
    for _, v in ipairs(Workspace:GetChildren()) do
        if isNPC(v) then
            local root = v:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (root.Position - origin).Magnitude
                if dist <= range then
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
    -- Ordenar por distância (mais próximo primeiro)
    table.sort(entities, function(a, b) return a.distance < b.distance end)
    return entities
end

-- ============================================
-- SISTEMA DE ESP
-- ============================================
local espObjects = {}
local espConnections = {}

local function createEspLabel(model)
    if espObjects[model] then return end
    
    local root = model:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local humanoid = model:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local label = Instance.new("BillboardGui")
    label.Name = "ESPLabel"
    label.Size = UDim2.new(0, 200, 0, 50)
    label.AlwaysOnTop = true
    label.StudsOffset = Vector3.new(0, 3, 0)
    label.Parent = root
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Parent = label
    
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
    
    -- Box outline (opcional)
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
    
    for _, v in ipairs(Workspace:GetChildren()) do
        if isNPC(v) then
            local root = v:FindFirstChild("HumanoidRootPart")
            if root then
                if not espObjects[v] then
                    createEspLabel(v)
                end
                -- Atualizar distância
                local dist = (root.Position - origin).Magnitude
                local data = espObjects[v]
                if data then
                    data.distLabel.Text = string.format("%.1fm", dist)
                    -- Cor baseada na distância (verde perto, vermelho longe)
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
    
    -- Limpar objetos que não existem mais
    for model, _ in pairs(espObjects) do
        if not model or not model.Parent then
            removeEsp(model)
        end
    end
end

-- ============================================
-- SISTEMA DE KILL AURA
-- ============================================
local killAuraRunning = false
local currentTarget = nil
local attackCooldown = 0

local function findWeapon()
    -- Procura por uma ferramenta melee no inventário do jogador
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, v in ipairs(backpack:GetChildren()) do
            if v:IsA("Tool") and (v:FindFirstChild("Handle") or v:FindFirstChild("Part")) then
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
    if not weapon then return false end
    
    -- Tenta ativar a ferramenta (equipar se necessário)
    if weapon.Parent == player:FindFirstChild("Backpack") then
        weapon.Parent = character
        wait(0.1)
    end
    
    -- Verifica se a arma está equipada
    if weapon.Parent ~= character then return false end
    
    -- Tenta ativar/atacar
    local toolService = game:GetService("ToolService") or game:GetService("Selection") or game:GetService("StarterGui")
    
    -- Método 1: Ativar a ferramenta
    if weapon:FindFirstChild("Activate") then
        weapon.Activate:FireServer()
    end
    
    -- Método 2: Chamar função de ataque comum
    if weapon:FindFirstChild("Attack") then
        weapon.Attack:FireServer()
    end
    
    -- Método 3: Ativar o Handle (simulação de clique)
    local handle = weapon:FindFirstChild("Handle")
    if handle then
        -- Simula um clique com a ferramenta
        local mouse = player:GetMouse()
        if mouse then
            mouse.Button1Down:Fire()
            wait(0.05)
            mouse.Button1Up:Fire()
        end
    end
    
    -- Método 4: Através do Humanoid (ataque corpo a corpo)
    if humanoid and humanoid:FindFirstChild("Attack") then
        humanoid.Attack:FireServer()
    end
    
    -- Método 5: Através de evento remoto genérico
    for _, v in ipairs(weapon:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local success, err = pcall(function()
                v:FireServer()
            end)
            if not success then
                pcall(function()
                    v:InvokeServer()
                end)
            end
        end
    end
    
    return true
end

local function performKillAura()
    if not config.killAuraEnabled then
        killAuraRunning = false
        currentTarget = nil
        return
    end
    
    local origin = humanoidRootPart.Position
    local range = config.range
    
    -- Buscar entidades na faixa
    local entities = getEntitiesInRange(origin, range)
    
    if #entities == 0 then
        currentTarget = nil
        return
    end
    
    -- Escolher alvo (o mais próximo)
    local target = entities[1]
    if not target then return end
    
    currentTarget = target.model
    
    -- Verificar cooldown do ataque
    if attackCooldown > 0 then
        attackCooldown = attackCooldown - 0.1
        return
    end
    
    -- Verificar se o alvo ainda está vivo
    if not target.humanoid or target.humanoid.Health <= 0 then
        currentTarget = nil
        return
    end
    
    -- Verificar se o alvo está dentro do campo de visão (opcional)
    local cameraPos = Camera.CFrame.Position
    local targetPos = target.root.Position
    local lookVector = Camera.CFrame.LookVector
    local toTarget = (targetPos - cameraPos).Unit
    local dot = lookVector:Dot(toTarget)
    
    -- Se o alvo estiver atrás (ângulo > 90 graus), ignorar (opcional)
    -- if dot < -0.1 then return end
    
    -- Atacar o alvo
    local success = attackTarget(target.model)
    
    if success then
        attackCooldown = config.attackSpeed
    end
end

-- ============================================
-- INTERFACE GRÁFICA
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KatanaHubGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

-- Estilo visual
local theme = {
    background = Color3.fromRGB(20, 20, 28),
    backgroundAlt = Color3.fromRGB(30, 30, 42),
    primary = Color3.fromRGB(200, 60, 60),
    primaryHover = Color3.fromRGB(230, 80, 80),
    secondary = Color3.fromRGB(60, 200, 120),
    text = Color3.fromRGB(255, 255, 255),
    textDim = Color3.fromRGB(180, 180, 200),
    accent = Color3.fromRGB(255, 200, 50),
}

local function createRoundedFrame(parent, size, position, color, transparency)
    local frame = Instance.new("Frame")
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = color or theme.background
    frame.BackgroundTransparency = transparency or 0
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(50, 50, 70)
    stroke.Transparency = 0.5
    stroke.Parent = frame
    
    return frame
end

local function createButton(parent, position, size, text, callback, color)
    local button = Instance.new("TextButton")
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = color or theme.primary
    button.BackgroundTransparency = 0
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = theme.text
    button.TextSize = 16
    button.Font = Enum.Font.GothamSemibold
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = color or theme.primary
    stroke.Transparency = 0.3
    stroke.Parent = button
    
    -- Efeito hover
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = color and color + Color3.fromRGB(30, 30, 30) or theme.primaryHover}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = color or theme.primary}):Play()
    end)
    
    button.MouseButton1Click:Connect(callback)
    return button
end

local function createToggle(parent, position, labelText, defaultValue, onToggle)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 40)
    container.Position = position
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = theme.text
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.Parent = container
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 50, 0, 28)
    toggleBtn.Position = UDim2.new(1, -55, 0.5, -14)
    toggleBtn.BackgroundColor3 = defaultValue and theme.secondary or Color3.fromRGB(80, 80, 100)
    toggleBtn.BackgroundTransparency = 0
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = defaultValue and "ON" or "OFF"
    toggleBtn.TextColor3 = theme.text
    toggleBtn.TextSize = 12
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Parent = container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = toggleBtn
    
    local state = defaultValue
    
    local function updateToggle()
        state = not state
        toggleBtn.BackgroundColor3 = state and theme.secondary or Color3.fromRGB(80, 80, 100)
        toggleBtn.Text = state and "ON" or "OFF"
        if onToggle then onToggle(state) end
    end
    
    toggleBtn.MouseButton1Click:Connect(updateToggle)
    
    -- Também clicar no label ativa
    label.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateToggle()
        end
    end)
    
    return { toggle = toggleBtn, getState = function() return state end, setState = function(s) state = s; updateToggle() end }
end

local function createSlider(parent, position, labelText, minVal, maxVal, defaultValue, onUpdate)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 50)
    container.Position = position
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0.5, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = theme.text
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.Parent = container
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.4, 0, 0.5, 0)
    valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultValue)
    valueLabel.TextColor3 = theme.accent
    valueLabel.TextSize = 14
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.Parent = container
    
    local sliderTrack = Instance.new("Frame")
    sliderTrack.Size = UDim2.new(1, 0, 0, 4)
    sliderTrack.Position = UDim2.new(0, 0, 1, -6)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    sliderTrack.BackgroundTransparency = 0
    sliderTrack.BorderSizePixel = 0
    sliderTrack.Parent = container
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defaultValue - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.Position = UDim2.new(0, 0, 0, 0)
    fill.BackgroundColor3 = theme.primary
    fill.BackgroundTransparency = 0
    fill.BorderSizePixel = 0
    fill.Parent = sliderTrack
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((defaultValue - minVal) / (maxVal - minVal), -8, -0.5, -8)
    knob.BackgroundColor3 = theme.text
    knob.BackgroundTransparency = 0
    knob.BorderSizePixel = 0
    knob.Parent = sliderTrack
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0, 8)
    knobCorner.Parent = knob
    
    local value = defaultValue
    
    local function updateSlider(xPos)
        local trackSize = sliderTrack.AbsoluteSize.X
        local relativePos = math.clamp((xPos - sliderTrack.AbsolutePosition.X) / trackSize, 0, 1)
        value = minVal + (maxVal - minVal) * relativePos
        value = math.round(value * 10) / 10
        value = math.clamp(value, minVal, maxVal)
        
        fill.Size = UDim2.new(relativePos, 0, 1, 0)
        knob.Position = UDim2.new(relativePos, -8, -0.5, -8)
        valueLabel.Text = tostring(value)
        
        if onUpdate then onUpdate(value) end
    end
    
    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateSlider(input.Position.X)
        end
    end)
    
    sliderTrack.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            updateSlider(input.Position.X)
        end
    end)
    
    return { getValue = function() return value end, setValue = function(v) v = math.clamp(v, minVal, maxVal); value = v; updateSlider(sliderTrack.AbsolutePosition.X + (v - minVal) / (maxVal - minVal) * sliderTrack.AbsoluteSize.X) end }
end

-- ============================================
-- CONSTRUÇÃO DA INTERFACE
-- ============================================

-- Frame principal
local mainFrame = createRoundedFrame(screenGui, UDim2.new(0, 380, 0, 520), UDim2.new(0.5, -190, 0.5, -260), theme.background, 0.05)

-- Título
local titleFrame = Instance.new("Frame")
titleFrame.Size = UDim2.new(1, 0, 0, 50)
titleFrame.Position = UDim2.new(0, 0, 0, 0)
titleFrame.BackgroundTransparency = 1
titleFrame.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "⚔ KATANA HUB ⚔"
title.TextColor3 = Color3.fromRGB(255, 80, 80)
title.TextSize = 22
title.Font = Enum.Font.GothamBold
title.Parent = titleFrame

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0, 20)
subtitle.Position = UDim2.new(0, 0, 1, -2)
subtitle.BackgroundTransparency = 1
subtitle.Text = "ESP de NPCs + Kill Aura"
subtitle.TextColor3 = theme.textDim
subtitle.TextSize = 12
subtitle.Font = Enum.Font.Gotham
subtitle.Parent = titleFrame

-- Linha separadora
local divider = Instance.new("Frame")
divider.Size = UDim2.new(0.9, 0, 0, 1)
divider.Position = UDim2.new(0.05, 0, 0, 50)
divider.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
divider.BackgroundTransparency = 0
divider.BorderSizePixel = 0
divider.Parent = mainFrame

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Size = UDim2.new(1, 0, 1, -60)
contentFrame.Position = UDim2.new(0, 0, 0, 58)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 4
contentFrame.ScrollBarImageColor3 = theme.primary
contentFrame.Parent = mainFrame

local contentList = Instance.new("UIListLayout")
contentList.Padding = UDim.new(0, 10)
contentList.SortOrder = Enum.SortOrder.LayoutOrder
contentList.Parent = contentFrame

-- ============================================
-- SEÇÃO ESP
-- ============================================
local espSection = createRoundedFrame(contentFrame, UDim2.new(1, -20, 0, 110), UDim2.new(0, 10, 0, 5), theme.backgroundAlt, 0.3)
espSection.LayoutOrder = 1

local espTitle = Instance.new("TextLabel")
espTitle.Size = UDim2.new(1, -20, 0, 30)
espTitle.Position = UDim2.new(0, 10, 0, 5)
espTitle.BackgroundTransparency = 1
espTitle.Text = "👁 ESP de NPCs"
espTitle.TextColor3 = theme.primary
espTitle.TextSize = 16
espTitle.TextXAlignment = Enum.TextXAlignment.Left
espTitle.Font = Enum.Font.GothamBold
espTitle.Parent = espSection

local espToggle = createToggle(espSection, UDim2.new(0, 0, 0, 40), "Ativar ESP", false, function(state)
    config.espEnabled = state
    if not state then
        for model, _ in pairs(espObjects) do
            removeEsp(model)
        end
    end
end)

local espShowName = createToggle(espSection, UDim2.new(0, 0, 0, 70), "Mostrar Nome", true, function(state)
    config.showName = state
end)

-- ============================================
-- SEÇÃO KILL AURA
-- ============================================
local killSection = createRoundedFrame(contentFrame, UDim2.new(1, -20, 0, 200), UDim2.new(0, 10, 0, 5), theme.backgroundAlt, 0.3)
killSection.LayoutOrder = 2

local killTitle = Instance.new("TextLabel")
killTitle.Size = UDim2.new(1, -20, 0, 30)
killTitle.Position = UDim2.new(0, 10, 0, 5)
killTitle.BackgroundTransparency = 1
killTitle.Text = "🗡 Kill Aura (Melee)"
killTitle.TextColor3 = theme.primary
killTitle.TextSize = 16
killTitle.TextXAlignment = Enum.TextXAlignment.Left
killTitle.Font = Enum.Font.GothamBold
killTitle.Parent = killSection

local killToggle = createToggle(killSection, UDim2.new(0, 0, 0, 40), "Ativar Kill Aura", false, function(state)
    config.killAuraEnabled = state
    if state then
        killAuraRunning = true
    else
        killAuraRunning = false
        currentTarget = nil
    end
end)

local rangeSlider = createSlider(killSection, UDim2.new(0, 0, 0, 90), "Alcance (estudantes)", 5, 50, 20, function(value)
    config.range = value
end)

local speedSlider = createSlider(killSection, UDim2.new(0, 0, 0, 140), "Velocidade de ataque (s)", 0.1, 1.5, 0.3, function(value)
    config.attackSpeed = value
end)

-- ============================================
-- SEÇÃO INFORMAÇÕES
-- ============================================
local infoSection = createRoundedFrame(contentFrame, UDim2.new(1, -20, 0, 60), UDim2.new(0, 10, 0, 5), theme.backgroundAlt, 0.3)
infoSection.LayoutOrder = 3

local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(1, -20, 1, 0)
infoText.Position = UDim2.new(0, 10, 0, 5)
infoText.BackgroundTransparency = 1
infoText.Text = "📊 Alvo atual: Nenhum"
infoText.TextColor3 = theme.textDim
infoText.TextSize = 13
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.Font = Enum.Font.Gotham
infoText.Parent = infoSection

-- ============================================
-- BOTÃO FECHAR
-- ============================================
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -38, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
closeBtn.BackgroundTransparency = 0
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Botão de arrastar
local dragFrame = Instance.new("Frame")
dragFrame.Size = UDim2.new(1, 0, 0, 50)
dragFrame.Position = UDim2.new(0, 0, 0, 0)
dragFrame.BackgroundTransparency = 1
dragFrame.Parent = mainFrame

local dragging = false
local dragStart = nil
local frameStart = nil

dragFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        frameStart = mainFrame.Position
    end
end)

dragFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            frameStart.X.Scale,
            frameStart.X.Offset + delta.X,
            frameStart.Y.Scale,
            frameStart.Y.Offset + delta.Y
        )
    end
end)

-- ============================================
-- LOOP PRINCIPAL
-- ============================================
local function onCharacterAdded(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Loop de atualização do ESP
RunService.RenderStepped:Connect(function()
    updateEsp()
end)

-- Loop de Kill Aura
game:GetService("Heartbeat"):Connect(function(dt)
    if config.killAuraEnabled then
        performKillAura()
        
        -- Atualizar texto de informações
        if currentTarget then
            local dist = (currentTarget:FindFirstChild("HumanoidRootPart") and currentTarget.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude or 0
            infoText.Text = string.format("🎯 Alvo: %s | Distância: %.1fm", currentTarget.Name or "NPC", dist)
        else
            infoText.Text = "📊 Alvo atual: Nenhum"
        end
    else
        if infoText then
            infoText.Text = "📊 Kill Aura desativada"
        end
    end
end)

-- ============================================
-- LIMPEZA
-- ============================================
player.CharacterRemoving:Connect(function()
    for model, _ in pairs(espObjects) do
        removeEsp(model)
    end
    currentTarget = nil
end)

-- ============================================
-- COMANDOS NO CONSOLE (DEBUG)
-- ============================================
print("⚔ Katana Hub carregado com sucesso!")
print("Comandos:")
print("  - config.espEnabled = true/false")
print("  - config.killAuraEnabled = true/false")
print("  - config.range = 20 (alcance em estudantes)")
print("  - config.attackSpeed = 0.3 (segundos entre ataques)")