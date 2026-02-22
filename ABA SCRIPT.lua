local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

-- Janela Principal
local Window = Fluent:CreateWindow({
    Title = "ABA Helper",
    SubTitle = "by josepi",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Tween = Window:AddTab({ Title = "Tween", Icon = "target" }),
    Rage = Window:AddTab({ Title = "Rage", Icon = "swords" }),
    AutoQTE = Window:AddTab({ Title = "Auto QTE", Icon = "activity" }),
    Esp = Window:AddTab({ Title = "Esp", Icon = "eye" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- Variáveis de controle
local status_nanami = false
local status_camera = false
local status_kokushibo = false
local status_esp_mode = false
local cam_lock_enabled = false
local camera_lock_timing = false
local Target = nil
local CamLockTarget = nil
local TweenConnection = nil

-- Círculos de FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.NumSides = 64
FOVCircle.Filled = false
FOVCircle.Transparency = 0.5
FOVCircle.Color = Color3.fromRGB(255, 255, 255)

local CamLockFOVCircle = Drawing.new("Circle")
CamLockFOVCircle.Thickness = 1
CamLockFOVCircle.NumSides = 64
CamLockFOVCircle.Transparency = 0.5
CamLockFOVCircle.Color = Color3.fromRGB(255, 50, 50)

-- ============================================================================
--                 LÓGICA ESP MODO
-- ============================================================================

local function criarEspModo(player)
    if player == LocalPlayer then return end
    local function setupGui(character)
        local root = character:WaitForChild("HumanoidRootPart", 10)
        if not root then return end
        local bill = Instance.new("BillboardGui", root)
        bill.Name = "ModeEsp_Josepi"
        bill.Size = UDim2.new(0, 150, 0, 70)
        bill.StudsOffset = Vector3.new(0, -4.5, 0)
        bill.AlwaysOnTop = true
        local label = Instance.new("TextLabel", bill)
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 25
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0
        local chargeValue = player:WaitForChild("Charge", 10)
        local maxChargeDetectado = 325
        local function atualizar()
            if not status_esp_mode then bill.Enabled = false return end
            bill.Enabled = true
            if chargeValue then
                if chargeValue.Value > maxChargeDetectado then maxChargeDetectado = chargeValue.Value end
                local percent = math.floor((chargeValue.Value / maxChargeDetectado) * 100)
                label.Text = percent .. "%"
                label.TextColor3 = percent >= 90 and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 255, 255)
            end
        end
        if chargeValue then chargeValue.Changed:Connect(atualizar) end
        local conn; conn = RunService.RenderStepped:Connect(function()
            if character.Parent and root.Parent then atualizar() else bill:Destroy() conn:Disconnect() end
        end)
    end
    player.CharacterAdded:Connect(setupGui)
    if player.Character then setupGui(player.Character) end
end
for _, p in pairs(Players:GetPlayers()) do criarEspModo(p) end
Players.PlayerAdded:Connect(criarEspModo)

-- ============================================================================
--                 AUTO QTEs
-- ============================================================================

local function clicarM1()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local function clicarM2()
    VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
    task.wait(0.05) 
    VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
end

local function processarKokushibo(gui)
    local jaClicou = false
    local function checar(obj)
        if status_kokushibo and obj.Name == "ImageLabel" and not jaClicou then
            jaClicou = true
            task.wait(0.30)
            clicarM2()
        end
    end
    for _, desc in pairs(gui:GetDescendants()) do checar(desc) end
    local conn = gui.DescendantAdded:Connect(checar)
    gui.AncestryChanged:Connect(function() if not gui.Parent and conn then conn:Disconnect() end end)
end

PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "FrenchKokushibo" then processarKokushibo(child) end
end)

Camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
    if not status_camera then camera_lock_timing = false return end
    local fov = Camera.FieldOfView
    if fov <= 10 then camera_lock_timing = true end
    if camera_lock_timing and fov >= 15 then
        camera_lock_timing = false
        clicarM1()
    end
end)

local function handleNanami(gui)
    local bar = gui:WaitForChild("MainBar", 5)
    local g = bar and bar:WaitForChild("Goal", 5)
    local c = bar and bar:WaitForChild("Cutter", 5)
    if not g or not c then return end
    task.wait(0.2)
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not status_nanami or not gui.Parent then connection:Disconnect() return end
        local gpos = g.AbsolutePosition.X + (g.AbsoluteSize.X / 2)
        local cpos = c.AbsolutePosition.X
        if cpos > 10 and cpos >= gpos + 1 then
            clicarM1()
            connection:Disconnect()
        end
    end)
end

Workspace.Live.DescendantAdded:Connect(function(obj)
    if obj.Name == "NanamiCutGUI" and status_nanami then handleNanami(obj) end
end)

-- ============================================================================
--                 SISTEMA DE TWEEN (LÓGICA ORIGINAL RESTAURADA)
-- ============================================================================

local function getTarget()
    local closestTarget = nil
    local shortestDistance = math.huge
    local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local potentialTargets = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then table.insert(potentialTargets, p.Character) end
    end
    local liveFolder = Workspace:FindFirstChild("Live")
    if liveFolder then
        for _, npc in pairs(liveFolder:GetChildren()) do
            if npc:IsA("Model") and npc ~= LocalPlayer.Character then table.insert(potentialTargets, npc) end
        end
    end
    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for _, char in pairs(potentialTargets) do
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if char ~= LocalPlayer.Character and hum and hrp and hum.Health > 0 then
            local distFromMe = myHrp and (hrp.Position - myHrp.Position).Magnitude or 0
            if distFromMe <= (Options.TweenRange and Options.TweenRange.Value or 500) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if distFromCenter <= (Options.FOVRadius and Options.FOVRadius.Value or 150) then
                        local score = distFromCenter + (distFromMe * 0.5)
                        if score < shortestDistance then
                            shortestDistance = score
                            closestTarget = char
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end

local function startTweenLoop()
    if TweenConnection then TweenConnection:Disconnect() end
    TweenConnection = RunService.Heartbeat:Connect(function(dt)
        if not Options.TweenKey.Value then return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if Target then
            local hum = Target:FindFirstChildOfClass("Humanoid")
            if not Target.Parent or (hum and hum.Health <= 0) then
                Target = nil
                Options.TweenKey:SetValue(false)
                return
            end
        else
            Target = getTarget()
            if not Target then return end
        end
        local head = Target:FindFirstChild("Head") or Target:FindFirstChild("HumanoidRootPart")
        if not head then return end
        local desired = head.Position + Vector3.new(0, Options.Height.Value, 0) + head.CFrame.LookVector * Options.Offset.Value
        local delta = desired - hrp.Position
        local dist = delta.Magnitude
        if dist < 0.1 then return end
        local step = math.min(dist, Options.Speed.Value * dt * 1.05)
        hrp.CFrame = hrp.CFrame + delta.Unit * step
    end)
end

-- ============================================================================
--                 SISTEMA RAGE (CAMERA LOCK COM SMOOTH EXPONENCIAL)
-- ============================================================================

local function getCamLockTarget()
    local closestTarget = nil
    local shortestDistance = math.huge
    local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local potentialTargets = {}
    for _, p in pairs(Players:GetPlayers()) do 
        if p ~= LocalPlayer and p.Character then table.insert(potentialTargets, p.Character) end 
    end
    local live = Workspace:FindFirstChild("Live")
    if live then 
        for _, npc in pairs(live:GetChildren()) do 
            if npc:IsA("Model") and npc ~= LocalPlayer.Character then table.insert(potentialTargets, npc) end 
        end 
    end
    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for _, char in pairs(potentialTargets) do
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if char ~= LocalPlayer.Character and hum and hrp and hum.Health > 0 then
            local distFromMe = myHrp and (hrp.Position - myHrp.Position).Magnitude or 0
            if distFromMe <= Options.CamLockRange.Value then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if distFromCenter <= Options.CamLockFovSize.Value then
                        local score = distFromCenter + (distFromMe * 0.5)
                        if score < shortestDistance then shortestDistance = score; closestTarget = char end
                    end
                end
            end
        end
    end
    return closestTarget
end

-- ============================================================================
--                               INTERFACE
-- ============================================================================

-- RAGE
Tabs.Rage:AddKeybind("CamLockBind", {
    Title = "Camera Lock Keybind",
    Mode = "Toggle",
    Default = "",
    Callback = function(Value) cam_lock_enabled = Value end
})
Tabs.Rage:AddToggle("ShowCamLockFov", {Title = "Show Fov", Default = false})
Tabs.Rage:AddSlider("CamLockFovSize", {Title = "Fov Size", Min = 50, Max = 800, Default = 150, Rounding = 0})
Tabs.Rage:AddSlider("CamLockRange", {Title = "Range", Min = 10, Max = 500, Default = 250, Rounding = 0})
Tabs.Rage:AddSlider("CamLockSmoothness", {Title = "Smoothness", Min = 0, Max = 100, Default = 25, Rounding = 0})

-- TWEEN
Tabs.Tween:AddKeybind("TweenKey", {
    Title = "Toggle Tween",
    Mode = "Toggle",
    Default = "",
    Callback = function(Value)
        if Value then Target = getTarget() startTweenLoop()
        else if TweenConnection then TweenConnection:Disconnect() end Target = nil end
    end
})
Tabs.Tween:AddToggle("ShowFOV", {Title = "Show Fov", Default = false})
Tabs.Tween:AddSlider("FOVRadius", {Title = "Fov Size", Min = 50, Max = 500, Default = 150, Rounding = 0})
Tabs.Tween:AddSlider("TweenRange", {Title = "Range", Min = 10, Max = 500, Default = 250, Rounding = 0})
Tabs.Tween:AddSlider("Speed", {Title = "Speed", Min = 5, Max = 200, Default = 60, Rounding = 0})
Tabs.Tween:AddSlider("Height", {Title = "Height", Min = -5, Max = 10, Default = 3.5, Rounding = 1})
Tabs.Tween:AddSlider("Offset", {Title = "Offset", Min = -5, Max = 5, Default = 0.2, Rounding = 1})

-- RESTANTE
Tabs.AutoQTE:AddToggle("Nanami_Tgl", {Title = "Auto Nanami", Default = false}):OnChanged(function(v) status_nanami = v end)
Tabs.AutoQTE:AddToggle("Koku_Tgl", {Title = "Auto Kokushibo", Default = false}):OnChanged(function(v) status_kokushibo = v end)
Tabs.AutoQTE:AddToggle("Camera_Tgl", {Title = "Auto Camera Timing", Default = false}):OnChanged(function(v) status_camera = v end)
Tabs.Esp:AddToggle("EspModeTgl", {Title = "Show Mode %", Default = false}):OnChanged(function(v) status_esp_mode = v end)

-- LOOP RENDER
RunService.RenderStepped:Connect(function()
    if Options.ShowFOV then
        FOVCircle.Visible = Options.ShowFOV.Value
        FOVCircle.Radius = Options.FOVRadius.Value
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
    
    if Options.ShowCamLockFov then
        CamLockFOVCircle.Visible = Options.ShowCamLockFov.Value
        CamLockFOVCircle.Radius = Options.CamLockFovSize.Value
        CamLockFOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end

    if cam_lock_enabled then
        if not CamLockTarget or not CamLockTarget.Parent or (CamLockTarget:FindFirstChild("Humanoid") and CamLockTarget.Humanoid.Health <= 0) then
            CamLockTarget = getCamLockTarget()
        end
        if CamLockTarget and CamLockTarget:FindFirstChild("HumanoidRootPart") then
            local rawSmooth = Options.CamLockSmoothness.Value
            
            -- LÓGICA EXPONENCIAL: Distribuindo o smooth de forma natural de 0 a 100
            local alpha = math.pow(0.5, rawSmooth / 15)
            alpha = math.clamp(alpha, 0.005, 1) 
            
            local targetCF = CFrame.lookAt(Camera.CFrame.Position, CamLockTarget.HumanoidRootPart.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, alpha)
        end
    else
        CamLockTarget = nil
    end
end)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()

