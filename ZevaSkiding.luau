--========================
-- LOAD FLUENT
--========================
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Zeva Fluent",
    SubTitle = "by spacyxx007",
    TabWidth = 160,
    Size = UDim2.fromOffset(780, 460),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Player = Window:AddTab({Title = "Player", Icon = ""}),
    Visuals = Window:AddTab({Title = "Visuals", Icon = ""}),
    Radar = Window:AddTab({Title = "Radar", Icon = ""}),
    World = Window:AddTab({Title = "World", Icon = ""}),
    Item = Window:AddTab({Title = "Item", Icon = ""}),
    Perm = Window:AddTab({Title = "Perm", Icon = ""}),
    Brainrot = Window:AddTab({Title = "Brainrot", Icon = ""}),
    MovingBrainrot = Window:AddTab({Title = "Moving Brainrot", Icon = ""}),
    Misc = Window:AddTab({Title = "Misc", Icon = ""}),
    Steals = Window:AddTab({Title = "Steals", Icon = ""}),
    Settings = Window:AddTab({Title = "Settings", Icon = ""}),
}

-- Save / Interface
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("ZevaFluent")
SaveManager:SetFolder("ZevaFluent/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

--========================
-- SERVICES
--========================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
end)

--========================
-- PLAYER CONTROLS
--========================
local Noclip = false
RunService.Stepped:Connect(function()
    if Noclip and Character then
        for _, v in pairs(Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

Tabs.Player:AddToggle("Noclip", {Title="Noclip", Default=false}):OnChanged(function(val) Noclip = val end)
Tabs.Player:AddSlider("WalkSpeed", {Title="WalkSpeed", Min=5, Max=500, Default=16, Rounding=1}):OnChanged(function(val)
    if Humanoid then Humanoid.WalkSpeed = val end
end)

-- Anti Ragdoll
local AntiRagdoll = false
RunService.Stepped:Connect(function()
    if AntiRagdoll and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
end)

Tabs.Player:AddToggle("AntiRagdoll", {Title="Anti Ragdoll", Default=false}):OnChanged(function(val) AntiRagdoll = val end)

-- Infinite Jump
local InfiniteJumpEnabled = false

UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

Tabs.Player:AddToggle("InfiniteJump", {Title="Infinite Jump", Default=false}):OnChanged(function(val) InfiniteJumpEnabled = val end)

-- Fly
local Flying = false
local FlySpeed = 50
local BV, BG

local function StartFly()
    Flying = true
    BV = Instance.new("BodyVelocity", RootPart)
    BV.MaxForce = Vector3.new(1e5,1e5,1e5)
    BG = Instance.new("BodyGyro", RootPart)
    BG.MaxTorque = Vector3.new(1e5,1e5,1e5)

    RunService.RenderStepped:Connect(function()
        if not Flying then return end
        local dir = Vector3.zero
        local cam = Camera
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
        if dir.Magnitude > 0 then BV.Velocity = dir.Unit * FlySpeed else BV.Velocity = Vector3.zero end
        BG.CFrame = cam.CFrame
    end)
end

local function StopFly()
    Flying = false
    if BV then BV:Destroy() end
    if BG then BG:Destroy() end
end

Tabs.Player:AddToggle("Fly", {Title="Fly", Default=false}):OnChanged(function(val)
    if val then StartFly() else StopFly() end
end)
Tabs.Player:AddSlider("FlySpeed", {Title="Fly Speed", Min=10, Max=500, Default=50, Rounding=1}):OnChanged(function(val) FlySpeed = val end)

--========================
-- TELEPORT TO PLAYER
--========================
local TeleportTarget = nil
local TeleportOffset = Vector3.new(0, 3, 0)

local function GetPlayerList()
    local playerNames = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerNames, player.Name)
        end
    end
    return playerNames
end

local function TeleportToPlayer()
    if not TeleportTarget then 
        Fluent:Notify({Title="Teleport", Content="Aucun joueur sélectionné", Duration=3})
        return 
    end
    
    local targetPlayer = Players:FindFirstChild(TeleportTarget)
    if not targetPlayer then
        Fluent:Notify({Title="Teleport", Content="Joueur introuvable", Duration=3})
        return
    end
    
    local targetChar = targetPlayer.Character
    if not targetChar then
        Fluent:Notify({Title="Teleport", Content="Le joueur n'a pas de personnage", Duration=3})
        return
    end
    
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then
        Fluent:Notify({Title="Teleport", Content="HumanoidRootPart introuvable", Duration=3})
        return
    end
    
    if RootPart then
        RootPart.CFrame = targetRoot.CFrame + TeleportOffset
        Fluent:Notify({Title="Teleport", Content="Téléporté à " .. TeleportTarget, Duration=3})
    else
        Fluent:Notify({Title="Teleport", Content="Erreur: Votre personnage n'est pas valide", Duration=3})
    end
end

local TeleportDropdown = Tabs.Player:AddDropdown("TeleportTarget", {
    Title = "Sélectionner Joueur",
    Values = GetPlayerList(),
    Multi = false,
    Default = 1,
})

TeleportDropdown:OnChanged(function(val)
    TeleportTarget = val
end)

Tabs.Player:AddButton({
    Title = "Rafraîchir Liste",
    Description = "Met à jour la liste des joueurs",
    Callback = function()
        TeleportDropdown:SetValues(GetPlayerList())
        Fluent:Notify({Title="Teleport", Content="Liste rafraîchie", Duration=2})
    end
})

Tabs.Player:AddSlider("TeleportOffsetY", {
    Title = "Offset Vertical",
    Description = "Distance au-dessus du joueur",
    Min = 0,
    Max = 10,
    Default = 3,
    Rounding = 1
}):OnChanged(function(val)
    TeleportOffset = Vector3.new(0, val, 0)
end)

Tabs.Player:AddButton({
    Title = "Téléporter",
    Description = "Se téléporte au joueur sélectionné",
    Callback = function()
        TeleportToPlayer()
    end
})

local AutoTeleport = false
local AutoTeleportDelay = 5

Tabs.Player:AddToggle("AutoTeleport", {
    Title = "Auto Téléport",
    Description = "Se téléporte automatiquement toutes les X secondes",
    Default = false
}):OnChanged(function(val)
    AutoTeleport = val
    if val then
        Fluent:Notify({Title="Auto Teleport", Content="Activé", Duration=2})
    end
end)

Tabs.Player:AddSlider("AutoTeleportDelay", {
    Title = "Délai Auto TP (sec)",
    Min = 1,
    Max = 30,
    Default = 5,
    Rounding = 1
}):OnChanged(function(val)
    AutoTeleportDelay = val
end)

Tabs.Player:AddKeybind("TeleportKeybind", {
    Title = "Raccourci Téléport",
    Mode = "Toggle",
    Default = "T",
    Callback = function()
        TeleportToPlayer()
    end,
})

task.spawn(function()
    while true do
        task.wait(AutoTeleportDelay)
        if AutoTeleport and TeleportTarget then
            TeleportToPlayer()
        end
    end
end)

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    TeleportDropdown:SetValues(GetPlayerList())
end)

Players.PlayerRemoving:Connect(function()
    task.wait(0.5)
    TeleportDropdown:SetValues(GetPlayerList())
    if TeleportTarget and not Players:FindFirstChild(TeleportTarget) then
        TeleportTarget = nil
    end
end)

--========================
-- VISUALS : ESP COMPLET
--========================
local ESPEnabled = false
local ESPName = false
local ESPDistance = false
local ESPStyle = "2D"
local ESPColor = Color3.fromRGB(0, 89, 255)
local ESPAutoRefresh = false
local SnaplineEnabled = false
local SnaplineColor = Color3.fromRGB(255, 255, 255)
local ChamsEnabled = false
local ChamsColor = Color3.fromRGB(255, 0, 0)
local ChamsFillTransparency = 0.5
local ChamsOutlineTransparency = 0
local HealthBarEnabled = false
local SkeletonEnabled = false
local SkeletonColor = Color3.fromRGB(255, 255, 255)
local HeadDotEnabled = false
local HeadDotColor = Color3.fromRGB(255, 255, 255)
local HeadDotSize = 4
local BoxFillEnabled = false
local BoxFillColor = Color3.fromRGB(0, 89, 255)
local BoxFillTransparency = 0.3
local ESP = {}

local function CreateESP(player)
    if player == LocalPlayer then return end
    ESP[player] = {
        Box = Drawing.new("Square"),
        BoxFill = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Snapline = Drawing.new("Line"),
        HealthBarBG = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        HeadDot = Drawing.new("Circle"),
        Chams = Instance.new("Highlight"),
        CornedLines = {},
        SkeletonLines = {}
    }
    
    -- Box
    ESP[player].Box.Color = ESPColor
    ESP[player].Box.Thickness = 2
    ESP[player].Box.Filled = false
    
    -- Box Fill
    ESP[player].BoxFill.Color = BoxFillColor
    ESP[player].BoxFill.Thickness = 1
    ESP[player].BoxFill.Filled = true
    ESP[player].BoxFill.Transparency = BoxFillTransparency
    
    -- Name
    ESP[player].Name.Size = 13
    ESP[player].Name.Center = true
    ESP[player].Name.Outline = true
    ESP[player].Name.Color = Color3.fromRGB(255, 255, 255)
    
    -- Distance
    ESP[player].Distance.Size = 13
    ESP[player].Distance.Center = true
    ESP[player].Distance.Outline = true
    ESP[player].Distance.Color = Color3.fromRGB(255, 255, 255)
    
    -- Snapline
    ESP[player].Snapline.Thickness = 1
    ESP[player].Snapline.Color = SnaplineColor
    
    -- Health Bar Background
    ESP[player].HealthBarBG.Thickness = 1
    ESP[player].HealthBarBG.Filled = true
    ESP[player].HealthBarBG.Color = Color3.fromRGB(0, 0, 0)
    ESP[player].HealthBarBG.Transparency = 0.5
    
    -- Health Bar
    ESP[player].HealthBar.Thickness = 1
    ESP[player].HealthBar.Filled = true
    ESP[player].HealthBar.Transparency = 1
    
    -- Head Dot
    ESP[player].HeadDot.Thickness = 1
    ESP[player].HeadDot.Filled = true
    ESP[player].HeadDot.Color = HeadDotColor
    ESP[player].HeadDot.NumSides = 30
    ESP[player].HeadDot.Radius = HeadDotSize
    
    -- Chams
    ESP[player].Chams.Parent = nil
    ESP[player].Chams.Adornee = nil
    ESP[player].Chams.FillColor = ChamsColor
    ESP[player].Chams.OutlineColor = ChamsColor
    ESP[player].Chams.FillTransparency = ChamsFillTransparency
    ESP[player].Chams.OutlineTransparency = ChamsOutlineTransparency
end

local function RemoveESP(player)
    if ESP[player] then
        ESP[player].Box:Remove()
        ESP[player].BoxFill:Remove()
        ESP[player].Name:Remove()
        ESP[player].Distance:Remove()
        ESP[player].Snapline:Remove()
        ESP[player].HealthBarBG:Remove()
        ESP[player].HealthBar:Remove()
        ESP[player].HeadDot:Remove()
        ESP[player].Chams:Destroy()
        for _, line in pairs(ESP[player].CornedLines) do line:Remove() end
        for _, line in pairs(ESP[player].SkeletonLines) do line:Remove() end
        ESP[player].CornedLines = {}
        ESP[player].SkeletonLines = {}
        ESP[player] = nil
    end
end

local function RefreshESP()
    for _, player in pairs(Players:GetPlayers()) do
        if not ESP[player] then CreateESP(player) end
    end
end

Players.PlayerAdded:Connect(function(player)
    if ESPAutoRefresh then task.delay(0.1, RefreshESP) end
end)
Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
    if ESPAutoRefresh then task.delay(0.1, RefreshESP) end
end)

local function GetPlayerScreenBox(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not hrp or not head then return nil end

    local topPos, onScreen1 = Camera:WorldToViewportPoint(head.Position)
    local bottomPos, onScreen2 = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen1 and not onScreen2 then return nil end

    local centerX = (topPos.X + bottomPos.X)/2
    local centerY = (topPos.Y + bottomPos.Y)/2

    local width = 40
    local height = 60

    local topLeft = Vector2.new(centerX - width/2, centerY - height/2)
    return topLeft, width, height
end

RunService.RenderStepped:Connect(function()
    if not ESPEnabled then return end
    for player, esp in pairs(ESP) do
        local char = player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and hum and hum.Health > 0 then
            local topLeft, width, height = GetPlayerScreenBox(char)
            if topLeft then
                -- Reset Corned lines
                for _, line in pairs(esp.CornedLines) do line:Remove() end
                esp.CornedLines = {}

                -- Box Fill
                if BoxFillEnabled then
                    esp.BoxFill.Size = Vector2.new(width, height)
                    esp.BoxFill.Position = topLeft
                    esp.BoxFill.Color = BoxFillColor
                    esp.BoxFill.Transparency = BoxFillTransparency
                    esp.BoxFill.Visible = true
                else
                    esp.BoxFill.Visible = false
                end

                -- Box ESP
                if ESPStyle == "2D" then
                    esp.Box.Size = Vector2.new(width, height)
                    esp.Box.Position = topLeft
                    esp.Box.Color = ESPColor
                    esp.Box.Visible = true
                elseif ESPStyle == "Corned" then
                    local length = 10
                    local tl = topLeft
                    local tr = Vector2.new(topLeft.X + width, topLeft.Y)
                    local bl = Vector2.new(topLeft.X, topLeft.Y + height)
                    local br = Vector2.new(topLeft.X + width, topLeft.Y + height)
                    local lines = {
                        {tl, tl + Vector2.new(length,0)}, {tl, tl + Vector2.new(0,length)},
                        {tr, tr + Vector2.new(-length,0)}, {tr, tr + Vector2.new(0,length)},
                        {bl, bl + Vector2.new(length,0)}, {bl, bl + Vector2.new(0,-length)},
                        {br, br + Vector2.new(-length,0)}, {br, br + Vector2.new(0,-length)}
                    }
                    for _, l in pairs(lines) do
                        local line = Drawing.new("Line")
                        line.From = l[1]
                        line.To = l[2]
                        line.Color = ESPColor
                        line.Thickness = 2
                        line.Visible = true
                        table.insert(esp.CornedLines, line)
                    end
                    esp.Box.Visible = false
                end

                -- Name
                esp.Name.Text = player.Name
                esp.Name.Position = Vector2.new(topLeft.X + width/2, topLeft.Y - 15)
                esp.Name.Visible = ESPName

                -- Distance
                local distance = (RootPart.Position - hrp.Position).Magnitude
                esp.Distance.Text = string.format("%.1f", distance).." studs"
                esp.Distance.Position = Vector2.new(topLeft.X + width/2, topLeft.Y + height + 5)
                esp.Distance.Visible = ESPDistance

                -- Snapline
                if SnaplineEnabled then
                    local screenSize = Camera.ViewportSize
                    local bottomCenter = Vector2.new(screenSize.X / 2, screenSize.Y)
                    local playerBottom = Vector2.new(topLeft.X + width/2, topLeft.Y + height)
                    esp.Snapline.From = bottomCenter
                    esp.Snapline.To = playerBottom
                    esp.Snapline.Color = SnaplineColor
                    esp.Snapline.Visible = true
                else
                    esp.Snapline.Visible = false
                end
                
                -- Health Bar
                if HealthBarEnabled then
                    local healthPercent = hum.Health / hum.MaxHealth
                    local barHeight = height
                    local barWidth = 3
                    
                    esp.HealthBarBG.Size = Vector2.new(barWidth, barHeight)
                    esp.HealthBarBG.Position = Vector2.new(topLeft.X - barWidth - 2, topLeft.Y)
                    esp.HealthBarBG.Visible = true
                    
                    local currentHeight = barHeight * healthPercent
                    esp.HealthBar.Size = Vector2.new(barWidth, currentHeight)
                    esp.HealthBar.Position = Vector2.new(topLeft.X - barWidth - 2, topLeft.Y + barHeight - currentHeight)
                    esp.HealthBar.Color = Color3.fromRGB(
                        255 * (1 - healthPercent),
                        255 * healthPercent,
                        0
                    )
                    esp.HealthBar.Visible = true
                else
                    esp.HealthBarBG.Visible = false
                    esp.HealthBar.Visible = false
                end
                
                -- Head Dot
                if HeadDotEnabled then
                    local head = char:FindFirstChild("Head")
                    if head then
                        local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                        if onScreen then
                            esp.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
                            esp.HeadDot.Color = HeadDotColor
                            esp.HeadDot.Radius = HeadDotSize
                            esp.HeadDot.Visible = true
                        else
                            esp.HeadDot.Visible = false
                        end
                    else
                        esp.HeadDot.Visible = false
                    end
                else
                    esp.HeadDot.Visible = false
                end
                
            else
                esp.Box.Visible = false
                esp.BoxFill.Visible = false
                esp.Name.Visible = false
                esp.Distance.Visible = false
                esp.Snapline.Visible = false
                esp.HealthBarBG.Visible = false
                esp.HealthBar.Visible = false
                esp.HeadDot.Visible = false
                for _, line in pairs(esp.CornedLines) do line.Visible = false end
            end
            
            -- Chams
            if ChamsEnabled and char then
                esp.Chams.Parent = char
                esp.Chams.Adornee = char
                esp.Chams.FillColor = ChamsColor
                esp.Chams.FillTransparency = ChamsFillTransparency
                esp.Chams.OutlineTransparency = ChamsOutlineTransparency
                esp.Chams.Enabled = true
            else
                esp.Chams.Enabled = false
            end
            
            -- Skeleton ESP
            if SkeletonEnabled and char then
                for _, line in pairs(esp.SkeletonLines) do line:Remove() end
                esp.SkeletonLines = {}
                
                local parts = {
                    {"Head", "UpperTorso"},
                    {"UpperTorso", "LowerTorso"},
                    {"UpperTorso", "LeftUpperArm"},
                    {"LeftUpperArm", "LeftLowerArm"},
                    {"LeftLowerArm", "LeftHand"},
                    {"UpperTorso", "RightUpperArm"},
                    {"RightUpperArm", "RightLowerArm"},
                    {"RightLowerArm", "RightHand"},
                    {"LowerTorso", "LeftUpperLeg"},
                    {"LeftUpperLeg", "LeftLowerLeg"},
                    {"LeftLowerLeg", "LeftFoot"},
                    {"LowerTorso", "RightUpperLeg"},
                    {"RightUpperLeg", "RightLowerLeg"},
                    {"RightLowerLeg", "RightFoot"}
                }
                
                for _, pair in pairs(parts) do
                    local part1 = char:FindFirstChild(pair[1])
                    local part2 = char:FindFirstChild(pair[2])
                    if part1 and part2 then
                        local pos1, onScreen1 = Camera:WorldToViewportPoint(part1.Position)
                        local pos2, onScreen2 = Camera:WorldToViewportPoint(part2.Position)
                        if onScreen1 and onScreen2 then
                            local line = Drawing.new("Line")
                            line.From = Vector2.new(pos1.X, pos1.Y)
                            line.To = Vector2.new(pos2.X, pos2.Y)
                            line.Color = SkeletonColor
                            line.Thickness = 1
                            line.Visible = true
                            table.insert(esp.SkeletonLines, line)
                        end
                    end
                end
            else
                for _, line in pairs(esp.SkeletonLines) do line.Visible = false end
            end
            
        else
            esp.Box.Visible = false
            esp.BoxFill.Visible = false
            esp.Name.Visible = false
            esp.Distance.Visible = false
            esp.Snapline.Visible = false
            esp.HealthBarBG.Visible = false
            esp.HealthBar.Visible = false
            esp.HeadDot.Visible = false
            esp.Chams.Enabled = false
            for _, line in pairs(esp.CornedLines) do line.Visible = false end
            for _, line in pairs(esp.SkeletonLines) do line.Visible = false end
        end
    end
end)

-- Fluent Controls Visuals
Tabs.Visuals:AddToggle("ESPEnabled", {Title="Enable ESP", Default=false}):OnChanged(function(val) ESPEnabled = val end)
Tabs.Visuals:AddToggle("ESPName", {Title="Pseudo", Default=false}):OnChanged(function(val) ESPName = val end)
Tabs.Visuals:AddToggle("ESPDistance", {Title="Distance", Default=false}):OnChanged(function(val) ESPDistance = val end)
Tabs.Visuals:AddDropdown("ESPStyle", {Title="Style de box", Values={"2D","Corned"}, Multi=false, Default=1}):OnChanged(function(val) ESPStyle = val end)
Tabs.Visuals:AddColorpicker("ESPColor", {Title="ESP Color", Default=ESPColor}):OnChanged(function(val) ESPColor = val end)

Tabs.Visuals:AddToggle("BoxFillEnabled", {Title="Box Fill", Default=false}):OnChanged(function(val) BoxFillEnabled = val end)
Tabs.Visuals:AddColorpicker("BoxFillColor", {Title="Box Fill Color", Default=BoxFillColor}):OnChanged(function(val) BoxFillColor = val end)
Tabs.Visuals:AddSlider("BoxFillTransparency", {Title="Fill Transparency", Min=0, Max=1, Default=0.3, Rounding=2}):OnChanged(function(val) BoxFillTransparency = val end)

Tabs.Visuals:AddToggle("SnaplineEnabled", {Title="Snaplines", Default=false}):OnChanged(function(val) SnaplineEnabled = val end)
Tabs.Visuals:AddColorpicker("SnaplineColor", {Title="Snapline Color", Default=SnaplineColor}):OnChanged(function(val) SnaplineColor = val end)

Tabs.Visuals:AddToggle("ChamsEnabled", {Title="Chams", Default=false}):OnChanged(function(val) ChamsEnabled = val end)
Tabs.Visuals:AddColorpicker("ChamsColor", {Title="Chams Color", Default=ChamsColor}):OnChanged(function(val) ChamsColor = val end)
Tabs.Visuals:AddSlider("ChamsFillTransparency", {Title="Chams Transparency", Min=0, Max=1, Default=0.5, Rounding=2}):OnChanged(function(val) ChamsFillTransparency = val end)

Tabs.Visuals:AddToggle("HealthBarEnabled", {Title="Health Bar", Default=false}):OnChanged(function(val) HealthBarEnabled = val end)

Tabs.Visuals:AddToggle("SkeletonEnabled", {Title="Skeleton ESP", Default=false}):OnChanged(function(val) SkeletonEnabled = val end)
Tabs.Visuals:AddColorpicker("SkeletonColor", {Title="Skeleton Color", Default=SkeletonColor}):OnChanged(function(val) SkeletonColor = val end)

Tabs.Visuals:AddToggle("HeadDotEnabled", {Title="Head Dot", Default=false}):OnChanged(function(val) HeadDotEnabled = val end)
Tabs.Visuals:AddColorpicker("HeadDotColor", {Title="Head Dot Color", Default=HeadDotColor}):OnChanged(function(val) HeadDotColor = val end)
Tabs.Visuals:AddSlider("HeadDotSize", {Title="Dot Size", Min=2, Max=10, Default=4, Rounding=1}):OnChanged(function(val) HeadDotSize = val end)

Tabs.Visuals:AddToggle("ESPAutoRefresh", {Title="Auto Refresh", Default=true}):OnChanged(function(val) ESPAutoRefresh = val end)

--========================
-- RADAR SYSTEM
--========================
local RadarEnabled = false
local Radar3D = false
local RadarSize = 200
local RadarRange = 500
local RadarOpacity = 0.7
local ShowElevation = true
local EnemyColor = Color3.fromRGB(255, 0, 0)
local FriendlyColor = Color3.fromRGB(0, 255, 0)
local SelfColor = Color3.fromRGB(255, 255, 0)
local RadarBGColor = Color3.fromRGB(20, 20, 20)
local RadarBorderColor = Color3.fromRGB(255, 255, 255)

local RadarObjects = {
    Background = Drawing.new("Square"),
    Border = Drawing.new("Square"),
    CenterDot = Drawing.new("Circle"),
    PlayerDots = {}
}

-- Setup radar background
RadarObjects.Background.Filled = true
RadarObjects.Background.Thickness = 0
RadarObjects.Background.Color = RadarBGColor
RadarObjects.Background.Transparency = RadarOpacity

RadarObjects.Border.Filled = false
RadarObjects.Border.Thickness = 2
RadarObjects.Border.Color = RadarBorderColor
RadarObjects.Border.Transparency = 1

-- Center dot (player position)
RadarObjects.CenterDot.Filled = true
RadarObjects.CenterDot.Radius = 4
RadarObjects.CenterDot.Color = SelfColor
RadarObjects.CenterDot.NumSides = 30
RadarObjects.CenterDot.Transparency = 1

local function GetRadarPosition()
    local screenSize = Camera.ViewportSize
    return Vector2.new(screenSize.X - RadarSize - 20, 20)
end

local function WorldToRadar(worldPos)
    if not RootPart then return nil end
    
    local relativePos = worldPos - RootPart.Position
    local distance = relativePos.Magnitude
    
    if distance > RadarRange then
        relativePos = relativePos.Unit * RadarRange
    end
    
    -- Rotation selon la caméra
    local camLook = Camera.CFrame.LookVector
    local angle = math.atan2(camLook.X, camLook.Z)
    
    local rotatedX = relativePos.X * math.cos(angle) - relativePos.Z * math.sin(angle)
    local rotatedZ = relativePos.X * math.sin(angle) + relativePos.Z * math.cos(angle)
    
    local scale = RadarSize / 2 / RadarRange
    local radarPos = GetRadarPosition()
    
    return Vector2.new(
        radarPos.X + RadarSize / 2 + rotatedX * scale,
        radarPos.Y + RadarSize / 2 + rotatedZ * scale
    )
end

local function CreatePlayerDot(player)
    if player == LocalPlayer then return end
    
    local dot = {
        Circle = Drawing.new("Circle"),
        ElevationText = Drawing.new("Text")
    }
    
    dot.Circle.Filled = true
    dot.Circle.Radius = 3
    dot.Circle.NumSides = 30
    dot.Circle.Transparency = 1
    
    dot.ElevationText.Size = 10
    dot.ElevationText.Center = true
    dot.ElevationText.Outline = true
    dot.ElevationText.Color = Color3.fromRGB(255, 255, 255)
    
    RadarObjects.PlayerDots[player] = dot
end

local function RemovePlayerDot(player)
    if RadarObjects.PlayerDots[player] then
        RadarObjects.PlayerDots[player].Circle:Remove()
        RadarObjects.PlayerDots[player].ElevationText:Remove()
        RadarObjects.PlayerDots[player] = nil
    end
end

Players.PlayerAdded:Connect(function(player)
    CreatePlayerDot(player)
end)

Players.PlayerRemoving:Connect(function(player)
    RemovePlayerDot(player)
end)

RunService.RenderStepped:Connect(function()
    if not RadarEnabled then
        RadarObjects.Background.Visible = false
        RadarObjects.Border.Visible = false
        RadarObjects.CenterDot.Visible = false
        for _, dot in pairs(RadarObjects.PlayerDots) do
            dot.Circle.Visible = false
            dot.ElevationText.Visible = false
        end
        return
    end
    
    -- Update radar position and size
    local radarPos = GetRadarPosition()
    
    RadarObjects.Background.Size = Vector2.new(RadarSize, RadarSize)
    RadarObjects.Background.Position = radarPos
    RadarObjects.Background.Color = RadarBGColor
    RadarObjects.Background.Transparency = RadarOpacity
    RadarObjects.Background.Visible = true
    
    RadarObjects.Border.Size = Vector2.new(RadarSize, RadarSize)
    RadarObjects.Border.Position = radarPos
    RadarObjects.Border.Color = RadarBorderColor
    RadarObjects.Border.Visible = true
    
    -- Center dot
    RadarObjects.CenterDot.Position = Vector2.new(radarPos.X + RadarSize / 2, radarPos.Y + RadarSize / 2)
    RadarObjects.CenterDot.Color = SelfColor
    RadarObjects.CenterDot.Visible = true
    
    -- Update player dots
    for player, dot in pairs(RadarObjects.PlayerDots) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local hum = player.Character:FindFirstChild("Humanoid")
            
            if hum and hum.Health > 0 then
                local radarPos2D = WorldToRadar(hrp.Position)
                
                if radarPos2D then
                    dot.Circle.Position = radarPos2D
                    
                    -- Color based on team
                    local isEnemy = true
                    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                        isEnemy = false
                    end
                    
                    dot.Circle.Color = isEnemy and EnemyColor or FriendlyColor
                    dot.Circle.Visible = true
                    
                    -- Show elevation
                    if ShowElevation and RootPart then
                        local heightDiff = hrp.Position.Y - RootPart.Position.Y
                        if math.abs(heightDiff) > 5 then
                            if heightDiff > 0 then
                                dot.ElevationText.Text = "↑"
                            else
                                dot.ElevationText.Text = "↓"
                            end
                            dot.ElevationText.Position = Vector2.new(radarPos2D.X, radarPos2D.Y - 15)
                            dot.ElevationText.Visible = true
                        else
                            dot.ElevationText.Visible = false
                        end
                    else
                        dot.ElevationText.Visible = false
                    end
                else
                    dot.Circle.Visible = false
                    dot.ElevationText.Visible = false
                end
            else
                dot.Circle.Visible = false
                dot.ElevationText.Visible = false
            end
        else
            dot.Circle.Visible = false
            dot.ElevationText.Visible = false
        end
    end
end)

-- Radar Controls
Tabs.Radar:AddParagraph({
    Title = "Radar System",
    Content = "Mini-map radar pour voir les joueurs autour de toi"
})

Tabs.Radar:AddToggle("RadarEnabled", {Title="Enable Radar", Default=false}):OnChanged(function(val) 
    RadarEnabled = val 
    if val then
        -- Create dots for existing players
        for _, player in pairs(Players:GetPlayers()) do
            if not RadarObjects.PlayerDots[player] then
                CreatePlayerDot(player)
            end
        end
    end
end)

Tabs.Radar:AddToggle("Radar3D", {Title="3D Radar (WIP)", Default=false}):OnChanged(function(val) 
    Radar3D = val 
    Fluent:Notify({Title="Radar", Content="3D Radar en développement", Duration=3})
end)

Tabs.Radar:AddSlider("RadarSize", {
    Title="Radar Size",
    Description="Taille du radar en pixels",
    Min=100,
    Max=400,
    Default=200,
    Rounding=10
}):OnChanged(function(val) 
    RadarSize = val 
end)

Tabs.Radar:AddSlider("RadarRange", {
    Title="Radar Range",
    Description="Portée du radar en studs",
    Min=100,
    Max=2000,
    Default=500,
    Rounding=50
}):OnChanged(function(val) 
    RadarRange = val 
end)

Tabs.Radar:AddSlider("RadarOpacity", {
    Title="Radar Opacity",
    Description="Transparence du fond",
    Min=0,
    Max=1,
    Default=0.7,
    Rounding=2
}):OnChanged(function(val) 
    RadarOpacity = val 
end)

Tabs.Radar:AddToggle("ShowElevation", {
    Title="Show Elevation",
    Description="Affiche si joueurs au-dessus/en-dessous",
    Default=true
}):OnChanged(function(val) 
    ShowElevation = val 
end)

Tabs.Radar:AddParagraph({
    Title = "─────────────",
    Content = "Couleurs"
})

Tabs.Radar:AddColorpicker("EnemyColor", {
    Title="Enemy Color",
    Default=EnemyColor
}):OnChanged(function(val) 
    EnemyColor = val 
end)

Tabs.Radar:AddColorpicker("FriendlyColor", {
    Title="Friendly Color",
    Default=FriendlyColor
}):OnChanged(function(val) 
    FriendlyColor = val 
end)

Tabs.Radar:AddColorpicker("SelfColor", {
    Title="Self Color",
    Default=SelfColor
}):OnChanged(function(val) 
    SelfColor = val 
end)

Tabs.Radar:AddColorpicker("RadarBGColor", {
    Title="Background Color",
    Default=RadarBGColor
}):OnChanged(function(val) 
    RadarBGColor = val 
end)

Tabs.Radar:AddColorpicker("RadarBorderColor", {
    Title="Border Color",
    Default=RadarBorderColor
}):OnChanged(function(val) 
    RadarBorderColor = val 
end)

Tabs.Radar:AddParagraph({
    Title = "ℹ️ Info",
    Content = "Le radar tourne avec votre caméra. Les points hors de portée sont clampés aux bords."
})

--========================
-- WORLD
--========================
local OriginalLighting = {
    Ambient = Lighting.Ambient,
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

-- FullBright
local FullBrightEnabled = false
local function ToggleFullBright(enabled)
    if enabled then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    else
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    end
end

Tabs.World:AddToggle("FullBright", {Title="FullBright", Default=false}):OnChanged(function(val) 
    FullBrightEnabled = val 
    ToggleFullBright(val)
end)

-- No Fog
local NoFogEnabled = false
Tabs.World:AddToggle("NoFog", {Title="No Fog", Default=false}):OnChanged(function(val) 
    NoFogEnabled = val 
    if val then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
    else
        Lighting.FogEnd = OriginalLighting.FogEnd
        Lighting.FogStart = OriginalLighting.FogStart
    end
end)

-- Ambient Changer
Tabs.World:AddColorpicker("AmbientColor", {Title="Ambient Color", Default=Color3.new(1,1,1)}):OnChanged(function(val) 
    Lighting.Ambient = val
end)

Tabs.World:AddColorpicker("OutdoorAmbient", {Title="Outdoor Ambient", Default=Color3.new(1,1,1)}):OnChanged(function(val) 
    Lighting.OutdoorAmbient = val
end)

-- Time Changer
local TimeChangerEnabled = false
local CustomTime = 12

Tabs.World:AddToggle("TimeChanger", {Title="Time Changer", Default=false}):OnChanged(function(val) 
    TimeChangerEnabled = val 
end)

Tabs.World:AddSlider("CustomTime", {Title="Time (Hour)", Min=0, Max=24, Default=12, Rounding=1}):OnChanged(function(val) 
    CustomTime = val 
end)

RunService.RenderStepped:Connect(function()
    if TimeChangerEnabled then
        Lighting.ClockTime = CustomTime
    end
end)

-- Gravity Changer
Tabs.World:AddSlider("Gravity", {Title="Gravity", Min=0, Max=196.2, Default=196.2, Rounding=1}):OnChanged(function(val) 
    workspace.Gravity = val 
end)

-- Jump Height Multiplier
local JumpPowerMultiplier = 1
Tabs.World:AddSlider("JumpMultiplier", {Title="Jump Height Multiplier", Min=1, Max=5, Default=1, Rounding=1}):OnChanged(function(val) 
    JumpPowerMultiplier = val 
    if Humanoid then
        Humanoid.JumpPower = 50 * val
    end
end)

-- Remove Obstacles
local RemovedParts = {}
local ObstaclesToRemove = {"Door", "Wall", "Barrier"}

Tabs.World:AddButton({
    Title = "Remove Obstacles",
    Description = "Supprime portes/murs (non permanent)",
    Callback = function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                for _, name in pairs(ObstaclesToRemove) do
                    if string.find(obj.Name:lower(), name:lower()) then
                        if not RemovedParts[obj] then
                            RemovedParts[obj] = obj.Parent
                            obj.Parent = nil
                        end
                    end
                end
            end
        end
        Fluent:Notify({Title="World", Content="Obstacles supprimés", Duration=3})
    end
})

Tabs.World:AddButton({
    Title = "Restore Obstacles",
    Description = "Restaure les obstacles supprimés",
    Callback = function()
        for obj, parent in pairs(RemovedParts) do
            obj.Parent = parent
        end
        RemovedParts = {}
        Fluent:Notify({Title="World", Content="Obstacles restaurés", Duration=3})
    end
})

-- X-Ray
local XRayEnabled = false
local XRayTransparency = 0.7

local function ToggleXRay(enabled)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Parent:FindFirstChild("Humanoid") then
            if enabled then
                if not obj:GetAttribute("OriginalTransparency") then
                    obj:SetAttribute("OriginalTransparency", obj.Transparency)
                end
                obj.Transparency = XRayTransparency
            else
                if obj:GetAttribute("OriginalTransparency") then
                    obj.Transparency = obj:GetAttribute("OriginalTransparency")
                end
            end
        end
    end
end

Tabs.World:AddToggle("XRay", {Title="X-Ray", Default=false}):OnChanged(function(val) 
    XRayEnabled = val 
    ToggleXRay(val)
end)

Tabs.World:AddSlider("XRayTransparency", {Title="X-Ray Transparency", Min=0, Max=1, Default=0.7, Rounding=2}):OnChanged(function(val) 
    XRayTransparency = val 
    if XRayEnabled then
        ToggleXRay(true)
    end
end)

--========================
-- PERMISSION SPOOF
--========================
local PermTarget = nil
local OriginalSettings = {
    UserId = LocalPlayer.UserId,
    Name = LocalPlayer.Name,
    DisplayName = LocalPlayer.DisplayName,
    AccountAge = LocalPlayer.AccountAge,
    Character = LocalPlayer.Character,
}

Tabs.Perm:AddParagraph({
    Title = "Permission Spoof",
    Content = "Copie les permissions/attributs d'un joueur pour tromper le jeu (client-side uniquement)"
})

-- Dropdown pour sélectionner le joueur cible
local function GetPermPlayerList()
    local playerNames = {}
    for _, player in pairs(Players:GetPlayers()) do
        table.insert(playerNames, player.Name)
    end
    return playerNames
end

local PermDropdown = Tabs.Perm:AddDropdown("PermTarget", {
    Title = "Sélectionner Joueur",
    Values = GetPermPlayerList(),
    Multi = false,
    Default = 1,
})

PermDropdown:OnChanged(function(val)
    PermTarget = val
end)

Tabs.Perm:AddButton({
    Title = "Rafraîchir Liste",
    Description = "Met à jour la liste des joueurs",
    Callback = function()
        PermDropdown:SetValues(GetPermPlayerList())
        Fluent:Notify({Title="Permission Spoof", Content="Liste rafraîchie", Duration=2})
    end
})

-- Fonction pour copier les permissions
local function CopyPermissions()
    if not PermTarget then
        Fluent:Notify({Title="Permission Spoof", Content="Aucun joueur sélectionné", Duration=3})
        return
    end
    
    local targetPlayer = Players:FindFirstChild(PermTarget)
    if not targetPlayer then
        Fluent:Notify({Title="Permission Spoof", Content="Joueur introuvable", Duration=3})
        return
    end
    
    local success = 0
    local total = 0
    
    -- Copier UserId
    total = total + 1
    pcall(function()
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "GetUserId" or method == "getUserId" then
                return targetPlayer.UserId
            end
            return oldNamecall(self, ...)
        end)
        
        setreadonly(mt, true)
        success = success + 1
    end)
    
    -- Copier Name
    total = total + 1
    pcall(function()
        local mt = getrawmetatable(game)
        local oldIndex = mt.__index
        setreadonly(mt, false)
        
        mt.__index = newcclosure(function(self, key)
            if self == LocalPlayer and key == "Name" then
                return targetPlayer.Name
            end
            return oldIndex(self, key)
        end)
        
        setreadonly(mt, true)
        success = success + 1
    end)
    
    -- Copier DisplayName
    total = total + 1
    pcall(function()
        local mt = getrawmetatable(game)
        local oldIndex = mt.__index
        setreadonly(mt, false)
        
        mt.__index = newcclosure(function(self, key)
            if self == LocalPlayer and key == "DisplayName" then
                return targetPlayer.DisplayName
            end
            return oldIndex(self, key)
        end)
        
        setreadonly(mt, true)
        success = success + 1
    end)
    
    -- Copier AccountAge
    total = total + 1
    pcall(function()
        local mt = getrawmetatable(game)
        local oldIndex = mt.__index
        setreadonly(mt, false)
        
        mt.__index = newcclosure(function(self, key)
            if self == LocalPlayer and key == "AccountAge" then
                return targetPlayer.AccountAge
            end
            return oldIndex(self, key)
        end)
        
        setreadonly(mt, true)
        success = success + 1
    end)
    
    -- Copier Team
    total = total + 1
    pcall(function()
        LocalPlayer.Team = targetPlayer.Team
        success = success + 1
    end)
    
    -- Copier tous les attributs
    total = total + 1
    pcall(function()
        for _, attr in pairs(targetPlayer:GetAttributes()) do
            LocalPlayer:SetAttribute(_, targetPlayer:GetAttribute(_))
        end
        success = success + 1
    end)
    
    -- Copier le Character (visuel)
    total = total + 1
    pcall(function()
        if targetPlayer.Character then
            local targetChar = targetPlayer.Character
            if Character then
                -- Copier l'apparence
                for _, obj in pairs(targetChar:GetDescendants()) do
                    if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then
                        local clone = obj:Clone()
                        local existing = Character:FindFirstChildOfClass(obj.ClassName)
                        if existing then existing:Destroy() end
                        clone.Parent = Character
                    end
                    
                    if obj:IsA("BodyColors") then
                        local existing = Character:FindFirstChildOfClass("BodyColors")
                        if existing then
                            existing.HeadColor = obj.HeadColor
                            existing.TorsoColor = obj.TorsoColor
                            existing.LeftArmColor = obj.LeftArmColor
                            existing.RightArmColor = obj.RightArmColor
                            existing.LeftLegColor = obj.LeftLegColor
                            existing.RightLegColor = obj.RightLegColor
                        end
                    end
                    
                    if obj:IsA("Accessory") then
                        local clone = obj:Clone()
                        clone.Parent = Character
                    end
                end
            end
        end
        success = success + 1
    end)
    
    Fluent:Notify({
        Title = "Permission Spoof",
        Content = string.format("Copié %d/%d attributs de %s", success, total, targetPlayer.Name),
        Duration = 5
    })
end

Tabs.Perm:AddButton({
    Title = "Copy Permissions",
    Description = "Copie tous les attributs du joueur sélectionné",
    Callback = function()
        CopyPermissions()
    end
})

-- Fonction pour reset les permissions
local function ResetPermissions()
    -- Reset métamethods
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        mt.__index = nil
        mt.__namecall = nil
        setreadonly(mt, true)
    end)
    
    -- Reset attributs
    pcall(function()
        for attr, _ in pairs(LocalPlayer:GetAttributes()) do
            LocalPlayer:SetAttribute(attr, nil)
        end
    end)
    
    -- Reset character appearance
    pcall(function()
        if Character then
            for _, obj in pairs(Character:GetDescendants()) do
                if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("Accessory") then
                    obj:Destroy()
                end
            end
        end
    end)
    
    Fluent:Notify({
        Title = "Permission Spoof",
        Content = "Permissions réinitialisées",
        Duration = 3
    })
end

Tabs.Perm:AddButton({
    Title = "Reset Permissions",
    Description = "Restaure tes permissions originales",
    Callback = function()
        ResetPermissions()
    end
})

Tabs.Perm:AddParagraph({
    Title = "─────────────",
    Content = "Options avancées"
})

-- Spoof spécifiques
Tabs.Perm:AddButton({
    Title = "Copy Name Only",
    Description = "Copie uniquement le nom",
    Callback = function()
        if not PermTarget then return end
        local targetPlayer = Players:FindFirstChild(PermTarget)
        if targetPlayer then
            pcall(function()
                local mt = getrawmetatable(game)
                local oldIndex = mt.__index
                setreadonly(mt, false)
                mt.__index = newcclosure(function(self, key)
                    if self == LocalPlayer and key == "Name" then
                        return targetPlayer.Name
                    end
                    return oldIndex(self, key)
                end)
                setreadonly(mt, true)
            end)
            Fluent:Notify({Title="Permission Spoof", Content="Nom copié: " .. targetPlayer.Name, Duration=3})
        end
    end
})

Tabs.Perm:AddButton({
    Title = "Copy UserId Only",
    Description = "Copie uniquement l'UserId",
    Callback = function()
        if not PermTarget then return end
        local targetPlayer = Players:FindFirstChild(PermTarget)
        if targetPlayer then
            pcall(function()
                local mt = getrawmetatable(game)
                local oldNamecall = mt.__namecall
                setreadonly(mt, false)
                mt.__namecall = newcclosure(function(self, ...)
                    local method = getnamecallmethod()
                    if method == "GetUserId" or method == "getUserId" then
                        return targetPlayer.UserId
                    end
                    return oldNamecall(self, ...)
                end)
                setreadonly(mt, true)
            end)
            Fluent:Notify({Title="Permission Spoof", Content="UserId copié: " .. targetPlayer.UserId, Duration=3})
        end
    end
})

Tabs.Perm:AddButton({
    Title = "Copy Team Only",
    Description = "Copie uniquement l'équipe",
    Callback = function()
        if not PermTarget then return end
        local targetPlayer = Players:FindFirstChild(PermTarget)
        if targetPlayer and targetPlayer.Team then
            pcall(function()
                LocalPlayer.Team = targetPlayer.Team
            end)
            Fluent:Notify({Title="Permission Spoof", Content="Équipe copiée: " .. targetPlayer.Team.Name, Duration=3})
        end
    end
})

Tabs.Perm:AddButton({
    Title = "Copy Appearance Only",
    Description = "Copie uniquement l'apparence",
    Callback = function()
        if not PermTarget then return end
        local targetPlayer = Players:FindFirstChild(PermTarget)
        if targetPlayer and targetPlayer.Character and Character then
            pcall(function()
                local targetChar = targetPlayer.Character
                for _, obj in pairs(targetChar:GetDescendants()) do
                    if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") or obj:IsA("Accessory") then
                        local clone = obj:Clone()
                        local existing = Character:FindFirstChild(obj.Name)
                        if existing then existing:Destroy() end
                        clone.Parent = Character
                    end
                end
            end)
            Fluent:Notify({Title="Permission Spoof", Content="Apparence copiée", Duration=3})
        end
    end
})

Tabs.Perm:AddParagraph({
    Title = "ℹ️ Information",
    Content = "Ces modifications sont CLIENT-SIDE uniquement. Le serveur voit toujours vos vraies informations."
})

-- Auto-refresh
Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    PermDropdown:SetValues(GetPermPlayerList())
end)

Players.PlayerRemoving:Connect(function()
    task.wait(0.5)
    PermDropdown:SetValues(GetPermPlayerList())
end)

--========================
-- BRAINROT (AnimalPodiums TP)
--========================
local BrainrotButtons = {}
local BrainrotSelectedPlot = nil

Tabs.Brainrot:AddParagraph({
    Title = "Animal Podiums Teleporter",
    Content = "Téléportation rapide vers les podiums d'animaux"
})

-- Fonction pour obtenir la liste des plots
local function GetBrainrotPlotList()
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then return {} end
    
    local plotNames = {}
    for _, plot in pairs(plotsFolder:GetChildren()) do
        if plot:IsA("Model") or plot:IsA("Folder") then
            table.insert(plotNames, plot.Name)
        end
    end
    return plotNames
end

-- Fonction pour obtenir le plot sélectionné
local function GetSelectedPlot()
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then return nil end
    
    -- Utiliser le plot sélectionné dans le dropdown Brainrot
    if BrainrotSelectedPlot and plotsFolder:FindFirstChild(BrainrotSelectedPlot) then
        return plotsFolder[BrainrotSelectedPlot]
    end
    
    return nil
end

-- Fonction pour TP vers un podium
local function TeleportToPodium(podiumName)
    local plot = GetSelectedPlot()
    
    if not plot then
        Fluent:Notify({
            Title = "Brainrot",
            Content = "Aucun plot sélectionné! Choisis un plot dans le dropdown",
            Duration = 3
        })
        return
    end
    
    local animalPodiums = plot:FindFirstChild("AnimalPodiums")
    if not animalPodiums then
        Fluent:Notify({
            Title = "Brainrot",
            Content = "AnimalPodiums introuvable dans le plot",
            Duration = 3
        })
        return
    end
    
    local podium = animalPodiums:FindFirstChild(podiumName)
    if not podium then
        Fluent:Notify({
            Title = "Brainrot",
            Content = "Podium " .. podiumName .. " introuvable",
            Duration = 3
        })
        return
    end
    
    local claim = podium:FindFirstChild("Claim")
    if not claim then
        Fluent:Notify({
            Title = "Brainrot",
            Content = "Claim introuvable dans le podium",
            Duration = 3
        })
        return
    end
    
    local hitbox = claim:FindFirstChild("Hitbox")
    if not hitbox then
        Fluent:Notify({
            Title = "Brainrot",
            Content = "Hitbox introuvable",
            Duration = 3
        })
        return
    end
    
    if RootPart then
        RootPart.CFrame = hitbox.CFrame + Vector3.new(0, 3, 0)
        Fluent:Notify({
            Title = "Brainrot",
            Content = "Téléporté au podium " .. podiumName,
            Duration = 2
        })
    end
end

-- Dropdown pour sélectionner le plot
local BrainrotPlotDropdown = Tabs.Brainrot:AddDropdown("BrainrotPlotSelect", {
    Title = "Sélectionner Plot",
    Values = GetBrainrotPlotList(),
    Multi = false,
    Default = 1,
})

BrainrotPlotDropdown:OnChanged(function(val)
    BrainrotSelectedPlot = val
    Fluent:Notify({
        Title = "Brainrot",
        Content = "Plot sélectionné: " .. val,
        Duration = 2
    })
end)

-- Bouton pour rafraîchir la liste des plots
Tabs.Brainrot:AddButton({
    Title = "Rafraîchir Liste Plots",
    Description = "Met à jour la liste des plots",
    Callback = function()
        BrainrotPlotDropdown:SetValues(GetBrainrotPlotList())
        Fluent:Notify({Title="Brainrot", Content="Liste des plots rafraîchie", Duration=2})
    end
})

-- Fonction pour refresh les boutons
local function RefreshBrainrotButtons()
    -- Clear existing buttons
    for _, btn in pairs(BrainrotButtons) do
        -- Les boutons Fluent ne peuvent pas être supprimés, on les garde
    end
    BrainrotButtons = {}
    
    local plot = GetSelectedPlot()
    
    if not plot then
        return
    end
    
    local animalPodiums = plot:FindFirstChild("AnimalPodiums")
    if not animalPodiums then
        return
    end
    
    -- Créer un bouton pour chaque podium
    local podiumList = {}
    for _, podium in pairs(animalPodiums:GetChildren()) do
        table.insert(podiumList, podium.Name)
    end
    
    -- Trier par ordre numérique/alphabétique
    table.sort(podiumList, function(a, b)
        local numA = tonumber(a)
        local numB = tonumber(b)
        if numA and numB then
            return numA < numB
        end
        return a < b
    end)
    
    return podiumList
end

-- Info sur le plot actuel
local CurrentPlotInfo = Tabs.Brainrot:AddParagraph({
    Title = "Plot actuel",
    Content = "Sélectionne un plot dans le dropdown ci-dessus"
})

-- Bouton pour afficher les podiums
Tabs.Brainrot:AddButton({
    Title = "Afficher Podiums",
    Description = "Affiche les podiums du plot sélectionné",
    Callback = function()
        local plot = GetSelectedPlot()
        if not plot then
            CurrentPlotInfo:SetDesc("Aucun plot sélectionné")
            Fluent:Notify({
                Title = "Brainrot",
                Content = "Sélectionne un plot d'abord",
                Duration = 3
            })
            return
        end
        
        local animalPodiums = plot:FindFirstChild("AnimalPodiums")
        if not animalPodiums then
            CurrentPlotInfo:SetDesc("Pas d'AnimalPodiums dans ce plot")
            Fluent:Notify({
                Title = "Brainrot",
                Content = "AnimalPodiums introuvable",
                Duration = 3
            })
            return
        end
        
        local podiumCount = 0
        for _, podium in pairs(animalPodiums:GetChildren()) do
            podiumCount = podiumCount + 1
        end
        
        CurrentPlotInfo:SetDesc(string.format("Plot: %s (%d podiums)", plot.Name, podiumCount))
        Fluent:Notify({
            Title = "Brainrot",
            Content = string.format("%d podiums trouvés", podiumCount),
            Duration = 3
        })
    end
})

-- Toggle pour TP automatique en boucle
local AutoTPBrainrot = false
local AutoTPDelay = 1
local CurrentPodiumIndex = 1

Tabs.Brainrot:AddToggle("AutoTPBrainrot", {
    Title = "Auto TP Loop",
    Description = "TP automatique entre tous les podiums",
    Default = false
}):OnChanged(function(val)
    AutoTPBrainrot = val
    if val then
        CurrentPodiumIndex = 1
    end
end)

Tabs.Brainrot:AddSlider("AutoTPDelay", {
    Title = "Délai Auto TP (sec)",
    Min = 0.01,
    Max = 10,
    Default = 1,
    Rounding = 1
}):OnChanged(function(val)
    AutoTPDelay = val
end)

-- Loop auto TP
task.spawn(function()
    while true do
        task.wait(AutoTPDelay)
        if AutoTPBrainrot then
            local podiumList = RefreshBrainrotButtons()
            if podiumList and #podiumList > 0 then
                TeleportToPodium(podiumList[CurrentPodiumIndex])
                CurrentPodiumIndex = CurrentPodiumIndex + 1
                if CurrentPodiumIndex > #podiumList then
                    CurrentPodiumIndex = 1
                end
            end
        end
    end
end)

Tabs.Brainrot:AddParagraph({
    Title = "─────────────",
    Content = "Podiums disponibles"
})

-- Dropdown pour sélectionner le podium
local PodiumDropdown = Tabs.Brainrot:AddDropdown("PodiumSelect", {
    Title = "Sélectionner Podium",
    Values = {"Sélectionne un plot d'abord"},
    Multi = false,
    Default = 1,
})

local SelectedPodium = nil

PodiumDropdown:OnChanged(function(val)
    SelectedPodium = val
end)

-- Bouton pour rafraîchir les podiums
Tabs.Brainrot:AddButton({
    Title = "Charger Podiums",
    Description = "Charge les podiums du plot sélectionné",
    Callback = function()
        local plot = GetSelectedPlot()
        if not plot then
            Fluent:Notify({
                Title = "Brainrot",
                Content = "Sélectionne un plot d'abord",
                Duration = 3
            })
            return
        end
        
        local animalPodiums = plot:FindFirstChild("AnimalPodiums")
        if not animalPodiums then
            Fluent:Notify({
                Title = "Brainrot",
                Content = "AnimalPodiums introuvable",
                Duration = 3
            })
            return
        end
        
        local podiumList = {}
        for _, podium in pairs(animalPodiums:GetChildren()) do
            table.insert(podiumList, podium.Name)
        end
        
        -- Trier
        table.sort(podiumList, function(a, b)
            local numA = tonumber(a)
            local numB = tonumber(b)
            if numA and numB then
                return numA < numB
            end
            return a < b
        end)
        
        if #podiumList == 0 then
            PodiumDropdown:SetValues({"Aucun podium trouvé"})
            Fluent:Notify({
                Title = "Brainrot",
                Content = "Aucun podium trouvé",
                Duration = 3
            })
        else
            PodiumDropdown:SetValues(podiumList)
            Fluent:Notify({
                Title = "Brainrot",
                Content = string.format("%d podiums chargés", #podiumList),
                Duration = 3
            })
        end
    end
})

-- Bouton pour TP au podium sélectionné
Tabs.Brainrot:AddButton({
    Title = "Téléporter au Podium",
    Description = "TP vers le podium sélectionné",
    Callback = function()
        if not SelectedPodium or SelectedPodium == "Sélectionne un plot d'abord" or SelectedPodium == "Aucun podium trouvé" then
            Fluent:Notify({
                Title = "Brainrot",
                Content = "Sélectionne un podium d'abord",
                Duration = 3
            })
            return
        end
        TeleportToPodium(SelectedPodium)
    end
})

-- Keybind pour TP rapide au prochain podium
Tabs.Brainrot:AddKeybind("NextPodiumKeybind", {
    Title = "Next Podium",
    Mode = "Toggle",
    Default = "N",
    Callback = function()
        local podiumList = RefreshBrainrotButtons()
        if podiumList and #podiumList > 0 then
            TeleportToPodium(podiumList[CurrentPodiumIndex])
            CurrentPodiumIndex = CurrentPodiumIndex + 1
            if CurrentPodiumIndex > #podiumList then
                CurrentPodiumIndex = 1
            end
        end
    end,
})

Tabs.Brainrot:AddParagraph({
    Title = "ℹ️ Info",
    Content = "Les podiums sont liés au plot sélectionné dans l'onglet Steals. Change de plot là-bas puis clique sur 'Refresh Podiums'."
})

--========================
-- MISC
--========================
local StartTime = tick()
local PlayerStats = {
    Kills = 0,
    Deaths = 0,
    PlayTime = 0
}

-- Server Info
Tabs.Misc:AddButton({
    Title = "Server Info",
    Description = "Affiche les infos du serveur",
    Callback = function()
        local jobId = game.JobId
        local placeId = game.PlaceId
        local players = #Players:GetPlayers()
        local maxPlayers = Players.MaxPlayers
        local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
        
        Fluent:Notify({
            Title = "Server Info",
            Content = string.format("Job ID: %s\nPlace ID: %s\nPlayers: %d/%d\nPing: %s", 
                jobId:sub(1, 8), placeId, players, maxPlayers, ping),
            Duration = 10
        })
    end
})

-- Player List avec infos
local PlayerListWindow = nil

Tabs.Misc:AddButton({
    Title = "Player List",
    Description = "Affiche la liste des joueurs",
    Callback = function()
        local playerInfo = "=== PLAYER LIST ===\n"
        for _, player in pairs(Players:GetPlayers()) do
            local char = player.Character
            local health = "N/A"
            local distance = "N/A"
            
            if char then
                local hum = char:FindFirstChild("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hum then health = string.format("%.0f", hum.Health) end
                if hrp and RootPart then 
                    distance = string.format("%.1f", (RootPart.Position - hrp.Position).Magnitude)
                end
            end
            
            playerInfo = playerInfo .. string.format("%s | HP: %s | Dist: %s\n", player.Name, health, distance)
        end
        
        print(playerInfo)
        Fluent:Notify({Title="Player List", Content="Liste affichée dans la console (F9)", Duration=3})
    end
})

-- Copy Coordinates
Tabs.Misc:AddButton({
    Title = "Copy Coordinates",
    Description = "Copie ta position actuelle",
    Callback = function()
        if RootPart then
            local pos = RootPart.Position
            local coords = string.format("Vector3.new(%.2f, %.2f, %.2f)", pos.X, pos.Y, pos.Z)
            setclipboard(coords)
            Fluent:Notify({Title="Coordinates", Content="Position copiée!", Duration=3})
        end
    end
})

-- Speed Hack Detection
local SpeedHackDetection = false
local SpeedThreshold = 50

Tabs.Misc:AddToggle("SpeedHackDetection", {Title="Speed Hack Detection", Default=false}):OnChanged(function(val) 
    SpeedHackDetection = val 
end)

Tabs.Misc:AddSlider("SpeedThreshold", {Title="Speed Threshold", Min=20, Max=200, Default=50, Rounding=1}):OnChanged(function(val) 
    SpeedThreshold = val 
end)

task.spawn(function()
    while true do
        task.wait(1)
        if SpeedHackDetection then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hum = player.Character:FindFirstChild("Humanoid")
                    if hum and hum.WalkSpeed > SpeedThreshold then
                        Fluent:Notify({
                            Title="Speed Hack Detected",
                            Content=string.format("%s: %.0f speed", player.Name, hum.WalkSpeed),
                            Duration=3
                        })
                    end
                end
            end
        end
    end
end)

-- Stat Tracker
Tabs.Misc:AddButton({
    Title = "Show Stats",
    Description = "Affiche tes statistiques",
    Callback = function()
        PlayerStats.PlayTime = math.floor(tick() - StartTime)
        local minutes = math.floor(PlayerStats.PlayTime / 60)
        local seconds = PlayerStats.PlayTime % 60
        
        Fluent:Notify({
            Title = "Stats",
            Content = string.format("Kills: %d\nDeaths: %d\nPlaytime: %dm %ds", 
                PlayerStats.Kills, PlayerStats.Deaths, minutes, seconds),
            Duration = 8
        })
    end
})

-- Screenshot Tool
Tabs.Misc:AddButton({
    Title = "Hide UI (Screenshot)",
    Description = "Cache l'UI pendant 3 secondes",
    Callback = function()
        game:GetService("CoreGui"):FindFirstChild("FluentUI").Enabled = false
        Fluent:Notify({Title="Screenshot", Content="UI cachée pour 3 secondes", Duration=2})
        task.wait(3)
        game:GetService("CoreGui"):FindFirstChild("FluentUI").Enabled = true
    end
})

-- Fake Lag
local FakeLagEnabled = false
local LagAmount = 100

Tabs.Misc:AddToggle("FakeLag", {Title="Fake Lag", Default=false}):OnChanged(function(val) 
    FakeLagEnabled = val 
end)

Tabs.Misc:AddSlider("LagAmount", {Title="Lag Amount (ms)", Min=50, Max=500, Default=100, Rounding=10}):OnChanged(function(val) 
    LagAmount = val 
end)

RunService.Heartbeat:Connect(function()
    if FakeLagEnabled then
        task.wait(LagAmount / 1000)
    end
end)

-- Chat Logger
local ChatLogs = {}
local ChatLoggerEnabled = false

Tabs.Misc:AddToggle("ChatLogger", {Title="Chat Logger", Default=false}):OnChanged(function(val) 
    ChatLoggerEnabled = val 
end)

Tabs.Misc:AddButton({
    Title = "Show Chat Logs",
    Description = "Affiche les messages loggés",
    Callback = function()
        local logs = "=== CHAT LOGS ===\n"
        for i, log in ipairs(ChatLogs) do
            logs = logs .. log .. "\n"
        end
        print(logs)
        Fluent:Notify({Title="Chat Logger", Content="Logs affichés dans console (F9)", Duration=3})
    end
})

for _, player in pairs(Players:GetPlayers()) do
    player.Chatted:Connect(function(msg)
        if ChatLoggerEnabled then
            local timestamp = os.date("%H:%M:%S")
            local logEntry = string.format("[%s] %s: %s", timestamp, player.Name, msg)
            table.insert(ChatLogs, logEntry)
            if #ChatLogs > 100 then table.remove(ChatLogs, 1) end
        end
    end)
end

Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(msg)
        if ChatLoggerEnabled then
            local timestamp = os.date("%H:%M:%S")
            local logEntry = string.format("[%s] %s: %s", timestamp, player.Name, msg)
            table.insert(ChatLogs, logEntry)
            if #ChatLogs > 100 then table.remove(ChatLogs, 1) end
        end
    end)
end)

-- Join Date Display
Tabs.Misc:AddButton({
    Title = "Player Join Times",
    Description = "Affiche quand les joueurs ont rejoint",
    Callback = function()
        local joinInfo = "=== JOIN TIMES ===\n"
        for _, player in pairs(Players:GetPlayers()) do
            local joinTime = tick() - (player:GetAttribute("JoinTime") or tick())
            local minutes = math.floor(joinTime / 60)
            joinInfo = joinInfo .. string.format("%s: %d minutes ago\n", player.Name, minutes)
        end
        print(joinInfo)
        Fluent:Notify({Title="Join Times", Content="Infos affichées dans console (F9)", Duration=3})
    end
})

Players.PlayerAdded:Connect(function(player)
    player:SetAttribute("JoinTime", tick())
end)

--========================
-- ITEM SPAWNER
--========================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemsFolder = ReplicatedStorage:FindFirstChild("Items")

if ItemsFolder then
    Tabs.Item:AddParagraph({
        Title = "Item Spawner",
        Content = "Cliquez sur un item pour l'ajouter à votre inventaire"
    })
    
    -- Fonction pour donner un item
    local function GiveItem(item)
        if not item then return end
        
        -- Essayer plusieurs méthodes pour ajouter l'item
        local success = false
        
        -- Méthode 1: Clone direct dans le Backpack
        pcall(function()
            local clone = item:Clone()
            clone.Parent = LocalPlayer.Backpack
            success = true
        end)
        
        -- Méthode 2: Clone dans le Character (si échec méthode 1)
        if not success then
            pcall(function()
                local clone = item:Clone()
                clone.Parent = Character
                success = true
            end)
        end
        
        -- Méthode 3: Fire un remote (certains jeux utilisent ça)
        if not success then
            pcall(function()
                for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
                    if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                        if string.find(remote.Name:lower(), "item") or 
                           string.find(remote.Name:lower(), "give") or
                           string.find(remote.Name:lower(), "tool") then
                            if remote:IsA("RemoteEvent") then
                                remote:FireServer(item.Name)
                            else
                                remote:InvokeServer(item.Name)
                            end
                            success = true
                        end
                    end
                end
            end)
        end
        
        if success then
            Fluent:Notify({
                Title = "Item Spawner",
                Content = "Item ajouté: " .. item.Name,
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "Item Spawner",
                Content = "Erreur: Impossible d'ajouter " .. item.Name,
                Duration = 3
            })
        end
    end
    
    -- Compter les items
    local itemCount = 0
    for _, item in pairs(ItemsFolder:GetChildren()) do
        if item:IsA("Tool") or item:IsA("Model") or item:IsA("Part") then
            itemCount = itemCount + 1
        end
    end
    
    Tabs.Item:AddParagraph({
        Title = "Items disponibles",
        Content = string.format("%d items trouvés", itemCount)
    })
    
    -- Bouton pour give tous les items
    Tabs.Item:AddButton({
        Title = "Give All Items",
        Description = "Donne tous les items disponibles",
        Callback = function()
            local count = 0
            for _, item in pairs(ItemsFolder:GetChildren()) do
                if item:IsA("Tool") or item:IsA("Model") then
                    GiveItem(item)
                    count = count + 1
                    task.wait(0.1) -- Petit délai pour éviter le spam
                end
            end
            Fluent:Notify({
                Title = "Item Spawner",
                Content = string.format("%d items ajoutés!", count),
                Duration = 5
            })
        end
    })
    
    -- Bouton pour clear l'inventaire
    Tabs.Item:AddButton({
        Title = "Clear Inventory",
        Description = "Vide ton inventaire",
        Callback = function()
            for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
                item:Destroy()
            end
            for _, item in pairs(Character:GetChildren()) do
                if item:IsA("Tool") then
                    item:Destroy()
                end
            end
            Fluent:Notify({
                Title = "Item Spawner",
                Content = "Inventaire vidé!",
                Duration = 3
            })
        end
    })
    
    Tabs.Item:AddParagraph({
        Title = "─────────────",
        Content = "Liste des items ci-dessous"
    })
    
    -- Créer un bouton pour chaque item
    local itemsList = {}
    for _, item in pairs(ItemsFolder:GetChildren()) do
        if item:IsA("Tool") or item:IsA("Model") or item:IsA("Part") then
            table.insert(itemsList, item)
        end
    end
    
    -- Trier par ordre alphabétique
    table.sort(itemsList, function(a, b)
        return a.Name < b.Name
    end)
    
    -- Ajouter les boutons
    for _, item in ipairs(itemsList) do
        Tabs.Item:AddButton({
            Title = item.Name,
            Description = "Click pour obtenir cet item",
            Callback = function()
                GiveItem(item)
            end
        })
    end
    
    -- Auto-refresh si de nouveaux items sont ajoutés
    ItemsFolder.ChildAdded:Connect(function(newItem)
        task.wait(0.5)
        Fluent:Notify({
            Title = "Item Spawner",
            Content = "Nouvel item détecté: " .. newItem.Name,
            Duration = 3
        })
    end)
    
else
    Tabs.Item:AddParagraph({
        Title = "Erreur",
        Content = "Dossier 'Items' introuvable dans ReplicatedStorage"
    })
    
    Tabs.Item:AddButton({
        Title = "Rechercher Items",
        Description = "Cherche les items ailleurs",
        Callback = function()
            local found = false
            local locations = {
                game:GetService("ReplicatedStorage"),
                game:GetService("ServerStorage"),
                workspace,
                game:GetService("Lighting")
            }
            
            for _, location in pairs(locations) do
                for _, child in pairs(location:GetDescendants()) do
                    if child.Name:lower():find("item") or child.Name:lower():find("tool") then
                        print("Items trouvés dans:", location.Name, "->", child:GetFullName())
                        found = true
                    end
                end
            end
            
            if found then
                Fluent:Notify({
                    Title = "Item Spawner",
                    Content = "Items trouvés! Vérifie la console (F9)",
                    Duration = 5
                })
            else
                Fluent:Notify({
                    Title = "Item Spawner",
                    Content = "Aucun item trouvé",
                    Duration = 3
                })
            end
        end
    })
end

--========================
-- STEALS
--========================
local StealEnabled = false
local SelectedPlotName = nil
local plotsFolder
repeat plotsFolder = workspace:FindFirstChild("Plots") task.wait(0.5) until plotsFolder

for _, plot in pairs(plotsFolder:GetChildren()) do
    if plot:IsA("Model") or plot:IsA("Folder") then
        local cb = Tabs.Steals:AddToggle(plot.Name, {Title=plot.Name, Default=false})
        cb:OnChanged(function(value)
            if value then SelectedPlotName = plot.Name else if SelectedPlotName == plot.Name then SelectedPlotName = nil end end
        end)
    end
end

local StealToggle = Tabs.Steals:AddToggle("StealMode", {Title="Steal Mode (INSERT TP)", Default=false})
StealToggle:OnChanged(function(value) StealEnabled = value end)

local function TeleportToPlot()
    if not StealEnabled then return end
    local plot = nil
    if SelectedPlotName and plotsFolder:FindFirstChild(SelectedPlotName) then plot = plotsFolder[SelectedPlotName]
    else
        for _, p in pairs(plotsFolder:GetChildren()) do
            local owner = p:FindFirstChild("Owner")
            if owner and owner.Value == LocalPlayer then plot = p break end
            local ownerId = p:FindFirstChild("OwnerId")
            if ownerId and ownerId.Value == LocalPlayer.UserId then plot = p break end
            if p:GetAttribute("OwnerId") == LocalPlayer.UserId then plot = p break end
        end
    end
    if plot then
        local hitbox = plot:FindFirstChild("DeliveryHitbox")
        if hitbox and RootPart then RootPart.CFrame = hitbox.CFrame + Vector3.new(0,3,0)
        else warn("DeliveryHitbox not found") end
    else warn("Plot not found") end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Insert then TeleportToPlot() end
end)

Fluent:Notify({Title="Zeva Fluent", Content="Script Loaded - Full Version", Duration=5})
