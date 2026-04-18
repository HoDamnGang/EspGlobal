-- loadstring Lua para Solara Executor
-- Versão minimal > server-side > ambientado 2026
local loadstring = loadstring or load
local script = Instance.new("Script")
script.Name = "SolaraTargetProcessor"
script.Parent = game:GetService("ServerScriptService")

local function main()
    local Players = game:GetService("Players")
    local workspace = game:GetService("Workspace")

    local function logStuff()
        print("== SOLARA TARGET LIST ==")
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    print(("PLAYER => %s | HEALTH %.1f/%.1f"):format(
                        p.Name, hum.Health, hum.MaxHealth))
                end
            end
        end
        for _, m in ipairs(workspace:GetDescendants()) do
            if m ~= workspace and m:IsA("Model") then
                local hum = m:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    print(("ENTITY => %s | HEALTH %.1f/%.1f"):format(
                        m.Name, hum.Health, hum.MaxHealth))
                end
            end
        end
    end

    while true do
        logStuff()
        task.wait(2)
    end
end

loadstring([[
    -- Solara injetável
    loadstring(game:GetService("ServerScriptService").SolaraTargetProcessor.Source)()
]])()
