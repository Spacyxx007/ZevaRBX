--========================
-- LOAD UI
--========================
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

--========================
-- SERVICES
--========================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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
-- THEME
--========================
WindUI:AddTheme({
    Name = "Zeva",
    Accent = Color3.fromHex("#0059ff"),
    Background = Color3.fromHex("#0a0a0a"),
    Outline = Color3.fromHex("#1f1f1f"),
    Text = Color3.fromHex("#ffffff"),
    Placeholder = Color3.fromHex("#8a8a8a"),
    Button = Color3.fromHex("#111827"),
    Icon = Color3.fromHex("#9ca3af"),
})

--========================
-- WINDOW
--========================
local Window = WindUI:CreateWindow({
    Title = "Zeva",
    Icon = "door-open",
    Author = "by spacyxx007",
    Folder = "ZevaRBX",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Zeva",
    Resizable = true,
    HideSearchBar = true,
})

Window:EditOpenButton({
    Title = "Open Zeva",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new( -- gradient
        Color3.fromHex("0059ff"), 
        Color3.fromHex("F89B29")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

--========================
-- TABS
--========================
local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
local VisualTab = Window:Tab({ Title = "Visuals", Icon = "eye" })
local StealsTab = Window:Tab({ Title = "Steals", Icon = "package" })

--========================
-- PLAYER CONTROLS
--========================
local Noclip = false
RunService.Stepped:Connect(function()
    if Noclip and Character then
        for _, v in pairs(Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
end)

PlayerTab:Toggle({
    Title = "Noclip",
    Value = false,
    Callback = function(state) Noclip = state end
})

PlayerTab:Slider({
    Title = "WalkSpeed",
    Step = 1,
    Value = { Min = 5, Max = 500, Default = 16 },
    Callback = function(val)
        if Humanoid then Humanoid.WalkSpeed = val end
    end
})

-- FLY
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
        if dir.Magnitude > 0 then
            BV.Velocity = dir.Unit * FlySpeed
        else
            BV.Velocity = Vector3.zero
        end
        BG.CFrame = cam.CFrame
    end)
end

local function StopFly()
    Flying = false
    if BV then BV:Destroy() end
    if BG then BG:Destroy() end
end

PlayerTab:Toggle({
    Title = "Fly",
    Value = false,
    Callback = function(state) if state then StartFly() else StopFly() end end
})

PlayerTab:Slider({
    Title = "Fly Speed",
    Step = 1,
    Value = { Min = 10, Max = 500, Default = 50 },
    Callback = function(val) FlySpeed = val end
})

--========================
-- VISUALS : PLAYER ESP
--========================
local ESPEnabled = false
local ESP = {}

local function CreateESP(player)
    if player == LocalPlayer then return end
    ESP[player] = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text")
    }
    local box = ESP[player].Box
    box.Color = Color3.fromRGB(0,89,255)
    box.Thickness = 2
    box.Filled = false

    local name = ESP[player].Name
    name.Size = 13
    name.Center = true
    name.Outline = true
    name.Color = Color3.fromRGB(255,255,255)

    local dist = ESP[player].Distance
    dist.Size = 13
    dist.Center = true
    dist.Outline = true
    dist.Color = Color3.fromRGB(255,255,255)
end

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(function(p)
    if ESP[p] then
        ESP[p].Box:Remove()
        ESP[p].Name:Remove()
        ESP[p].Distance:Remove()
        ESP[p] = nil
    end
end)

RunService.RenderStepped:Connect(function()
    if not ESPEnabled then return end
    for plr, esp in pairs(ESP) do
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if hrp and hum and hum.Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local size = Vector2.new(40,60)
                esp.Box.Size = size
                esp.Box.Position = Vector2.new(pos.X - size.X/2, pos.Y - size.Y/2)
                esp.Box.Visible = ESPEnabled

                esp.Name.Text = plr.Name
                esp.Name.Position = Vector2.new(pos.X, pos.Y - 40)
                esp.Name.Visible = ESPEnabled

                local distance = (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                esp.Distance.Text = string.format("%.1f", distance).." studs"
                esp.Distance.Position = Vector2.new(pos.X, pos.Y + 40)
                esp.Distance.Visible = ESPEnabled
            else
                esp.Box.Visible = false
                esp.Name.Visible = false
                esp.Distance.Visible = false
            end
        else
            esp.Box.Visible = false
            esp.Name.Visible = false
            esp.Distance.Visible = false
        end
    end
end)

VisualTab:Toggle({
    Title = "Player ESP",
    Value = false,
    Callback = function(state) ESPEnabled = state end
})

--========================
-- STEALS : CHECKBOX PLOTS
--========================
local StealEnabled = false
local SelectedPlotName = nil

-- Wait for Plots folder
local plotsFolder
repeat
    plotsFolder = workspace:FindFirstChild("Plots")
    task.wait(0.5)
until plotsFolder

-- Créer checkbox pour chaque plot
for _, plot in pairs(plotsFolder:GetChildren()) do
    if plot:IsA("Model") or plot:IsA("Folder") then
        StealsTab:Toggle({
            Title = plot.Name,
            Value = false,
            Callback = function(state)
                if state then
                    SelectedPlotName = plot.Name
                    -- décocher les autres plots
                    for _, otherPlot in pairs(plotsFolder:GetChildren()) do
                        if otherPlot.Name ~= plot.Name then
                            -- windui toggle update faux : besoin manuel si api disponible
                        end
                    end
                else
                    if SelectedPlotName == plot.Name then
                        SelectedPlotName = nil
                    end
                end
            end
        })
    end
end

-- Toggle global Steal mode
StealsTab:Toggle({
    Title = "Steal Mode (INSERT TP)",
    Value = false,
    Callback = function(state) StealEnabled = state end
})

-- Teleport function
local function TeleportToPlot()
    if not StealEnabled then return end
    local plot = nil
    if SelectedPlotName and plotsFolder:FindFirstChild(SelectedPlotName) then
        plot = plotsFolder[SelectedPlotName]
    else
        -- fallback : plot du joueur
        for _, p in pairs(plotsFolder:GetChildren()) do
            local owner = p:FindFirstChild("Owner")
            if owner and owner.Value == LocalPlayer then
                plot = p
                break
            end
            local ownerId = p:FindFirstChild("OwnerId")
            if ownerId and ownerId.Value == LocalPlayer.UserId then
                plot = p
                break
            end
            if p:GetAttribute("OwnerId") == LocalPlayer.UserId then
                plot = p
                break
            end
        end
    end

    if plot then
        local hitbox = plot:FindFirstChild("DeliveryHitbox")
        if hitbox and RootPart then
            RootPart.CFrame = hitbox.CFrame + Vector3.new(0,3,0)
        else
            warn("DeliveryHitbox not found")
        end
    else
        warn("Plot not found")
    end
end

-- Keybind INSERT
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        TeleportToPlot()
    end
end)
