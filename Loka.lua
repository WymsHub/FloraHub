local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- ╔════════════════════════════════════════════════════════════════╗
-- ║          SUMMER VIBE COLOR PALETTE - Light & Airy             ║
-- ╚════════════════════════════════════════════════════════════════╝

local SummerColors = {
    -- Primary & Secondary
    SkyBlue = Color3.fromRGB(135, 206, 235),      -- Light sky blue
    CoralPink = Color3.fromRGB(255, 127, 127),    -- Soft coral
    SandBeige = Color3.fromRGB(238, 214, 175),    -- Warm sand
    PeachCream = Color3.fromRGB(255, 218, 185),   -- Peach puff
    
    -- Accent Colors
    TealAccent = Color3.fromRGB(72, 209, 204),    -- Medium turquoise
    LemonYellow = Color3.fromRGB(255, 250, 205),  -- Lemon chiffon
    LimeGreen = Color3.fromRGB(173, 255, 47),     -- Green-yellow
    
    -- UI Elements
    LightBackground = Color3.fromRGB(240, 248, 255),  -- Alice blue (very light)
    CreamWhite = Color3.fromRGB(255, 253, 248),       -- Off-white
    SoftGray = Color3.fromRGB(220, 220, 220),         -- Light gray for text
    WarmText = Color3.fromRGB(70, 70, 70),            -- Warm dark for readability
}

-- Configure for glassy summer aesthetic
WindUI.TransparencyValue = 0.15  -- More transparent for airy feel

-- Create custom WindUI summer theme with crisp, cooling tones
WindUI:AddTheme({
    Name = "SummerBreeze",
    Accent = "#87CEFA",           -- Sky blue
    Background = "#F0F8FF",       -- Alice blue (very light)
    Dialog = "#FFFAF0",           -- Floral white
    Outline = "#48D1CC",          -- Turquoise
    Text = "#464646",             -- Warm dark gray for readability
    Placeholder = "#B0B0B0",      -- Medium gray
    Button = "#E0F6FF",           -- Very light cyan
    Icon = "#FF7F7F",             -- Coral pink
})

local Window = WindUI:CreateWindow({
    Title = "MM2 Summer AutoFarm",
    Icon = "sun",
    CornerRadius = UDim.new(0, 20),
    Author = "discord.gg/vega-scripts",
    Folder = "SummerAutoFarm",
    Size = UDim2.new(0, 700, 0, 600),
    Transparent = true,
    Acrylic = true,
    Theme = "SummerBreeze",
    SideBarWidth = 240,
    Background = "",
    User = {
        Enabled = true,
        Anonymous = true,
        Callback = function() end,
    },
    Gradient = {
        Enabled = true,
        Color1 = SummerColors.SkyBlue,
        Color2 = SummerColors.TealAccent,
    }
})



-- ╔════════════════════════════════════════════════════════════════╗
-- ║                    GAME STATE MANAGEMENT                       ║
-- ╚════════════════════════════════════════════════════════════════╝

local AutoFarmState = {
    FlingMurdererEnabled = false,
    ResetOnFullEnabled = false,
    AntiAFKEnabled = false,
    AntiFlingEnabled = false,
    CurrentRole = nil,
    FarmingActive = false,
    ESPEnabled = false,
    FarmMode = "Nearest",
    StayAwayFromMurderer = false,
    FarmSpeed = 19,
}

local plr = game.Players.LocalPlayer

local function getLocalRoot()
    local char = plr.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getLocalHumanoid()
    local char = plr.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local CoinContainer = nil
local LastTeleportedCoin = nil
local LastTeleportTime = 0
local tweenService = game:GetService("TweenService")
local CoinCollected = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("CoinCollected")

local function getCoinContainer()
    if CoinContainer and CoinContainer.Parent then
        return CoinContainer
    end
    CoinContainer = workspace:FindFirstChild("CoinContainer", true)
    return CoinContainer
end

local function getRole(player)
    local character = player.Character
    if not character then return nil end
    local backpack = player:FindFirstChild("Backpack")
    if character:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife")) then 
        return "Murderer" 
    end
    if character:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun")) then 
        return "Sheriff" 
    end
    return "Innocent"
end

local ESP = {
    Enabled = false,
    Highlights = {},
}

local function UpdateESP()
    for player, highlight in pairs(ESP.Highlights) do
        if not player or not player.Parent or not player.Character or not highlight.Parent then
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
            ESP.Highlights[player] = nil
        end
    end

    if not ESP.Enabled then
        for _, highlight in pairs(ESP.Highlights) do
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
        end
        ESP.Highlights = {}
        return
    end
    
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= plr and player.Character then
            local role = getRole(player)
            local color = Color3.fromRGB(255, 255, 255)
            
            if role == "Murderer" then
                color = Color3.fromRGB(255, 100, 100)  -- Softer red for summer
            elseif role == "Sheriff" then
                color = Color3.fromRGB(135, 206, 235)  -- Sky blue
            elseif role == "Innocent" then
                color = Color3.fromRGB(173, 255, 47)   -- Lime green
            end
            
            local highlight = player.Character:FindFirstChild("ESP_Highlight")
            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Name = "ESP_Highlight"
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Adornee = player.Character
                highlight.Parent = player.Character
                ESP.Highlights[player] = highlight
            end
            highlight.FillColor = color
            highlight.OutlineColor = color
        end
    end
end

local AntiFling = {
    Enabled = false,
    OriginalCFrame = nil,
}

local function StartAntiFling()
    while AntiFling.Enabled do
        task.wait(0.1)
        local rootPart = getLocalRoot()
        if not rootPart then continue end
        
        if rootPart.Velocity.Magnitude > 500 then
            rootPart.Velocity = Vector3.new(0, 0, 0)
            rootPart.RotVelocity = Vector3.new(0, 0, 0)
            
            if AntiFling.OriginalCFrame then
                rootPart.CFrame = AntiFling.OriginalCFrame
            end
            
            local bv = Instance.new("BodyVelocity")
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.MaxForce = Vector3.new(9e8, 9e8, 9e8)
            bv.Parent = rootPart
            task.wait(0.1)
            bv:Destroy()
        end
        
        AntiFling.OriginalCFrame = rootPart.CFrame
    end
end

local function StartAntiAFK()
    local GC = getconnections or get_signal_cons
    if GC then
        for _, v in pairs(GC(plr.Idled)) do
            if v.Disable then v:Disable() 
            elseif v.Disconnect then v:Disconnect() end
        end
    else
        local vu = cloneref and cloneref(game:GetService("VirtualUser")) or game:GetService("VirtualUser")
        plr.Idled:Connect(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    end
end

local function FlingMurderer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    
    local localRoot = getLocalRoot()
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not localRoot or not targetRoot then return end
    
    local wasAnchored = localRoot.Anchored
    localRoot.Anchored = false
    
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(9e8, 9e8, 9e8)
    bv.MaxForce = Vector3.new(1/0, 1/0, 1/0)
    bv.Parent = localRoot
    
    localRoot.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0, 5, 0))
    localRoot.Velocity = Vector3.new(9e8, 9e8, 9e8)
    localRoot.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    
    task.wait(1)
    bv:Destroy()
    localRoot.Anchored = wasAnchored
end

local function ResetPlayer()
    local hum = getLocalHumanoid()
    if hum and hum.Health > 0 then
        hum.Health = 0
    end
end

local totalCoinsCollected = 0
local maxCoins = 40

CoinCollected.OnClientEvent:Connect(function(_, p118, p119, _)
    totalCoinsCollected = totalCoinsCollected + 1
    if p118 == p119 then
        local role = getRole(plr)
        
        if role == "Murderer" and AutoFarmState.ResetOnFullEnabled then
            ResetPlayer()
            WindUI:Notify({
                Title = "Bag Full",
                Content = "Resetting as Murderer!",
                Icon = "refresh-cw",
                Duration = 3,
                Color = SummerColors.CoralPink
            })
        elseif (role == "Innocent" or role == "Sheriff") and AutoFarmState.FlingMurdererEnabled then
            local murderer = nil
            for _, player in pairs(game.Players:GetPlayers()) do
                if player ~= plr and getRole(player) == "Murderer" then
                    murderer = player
                    break
                end
            end
            
            if murderer then
                FlingMurderer(murderer)
                WindUI:Notify({
                    Title = "Bag Full",
                    Content = "Flinging murderer!",
                    Icon = "zap",
                    Duration = 3,
                    Color = SummerColors.LimeGreen
                })
            end
        end
    end
end)

local function FindCoin(root)
    local cc = getCoinContainer()
    if not cc or not root then return nil end
    
    local murderer = nil
    if AutoFarmState.StayAwayFromMurderer then
        local role = getRole(plr)
        if role ~= "Murderer" then
            for _, player in pairs(game.Players:GetPlayers()) do
                if player ~= plr and getRole(player) == "Murderer" then
                    murderer = player
                    break
                end
            end
        end
    end
    
    local best, bestDist = nil, math.huge
    local all = {}
    
    for _, child in ipairs(cc:GetChildren()) do
        local part = child:IsA("BasePart") and child or (child:IsA("Model") and child.PrimaryPart)
        if part and part.Parent and part ~= LastTeleportedCoin then
            local isSafe = true
            if murderer and murderer.Character then
                local mudRoot = murderer.Character:FindFirstChild("HumanoidRootPart")
                if mudRoot then
                    local distToMud = (part.Position - mudRoot.Position).Magnitude
                    if distToMud < 40 then
                        isSafe = false
                    end
                end
            end
            
            if isSafe then
                if AutoFarmState.FarmMode == "Nearest" then
                    local d = (root.Position - part.Position).Magnitude
                    if d < bestDist then 
                        best = part 
                        bestDist = d 
                    end
                else
                    table.insert(all, part)
                end
            end
        end
    end
    
    if AutoFarmState.FarmMode == "Nearest" then 
        return best 
    end
    if #all > 0 then 
        return all[math.random(1, #all)] 
    end
end

local function FindFurthestCoinFromMurderer(murdererRoot)
    local cc = getCoinContainer()
    if not cc or not murdererRoot then return nil end
    
    local bestCoin, maxDist = nil, -1
    for _, child in ipairs(cc:GetChildren()) do
        local part = child:IsA("BasePart") and child or (child:IsA("Model") and child.PrimaryPart)
        if part and part.Parent then
            local dist = (part.Position - murdererRoot.Position).Magnitude
            if dist > maxDist then
                maxDist = dist
                bestCoin = part
            end
        end
    end
    return bestCoin
end

local function AutoFarmCoins()
    while AutoFarmState.FarmingActive do
        local cc = getCoinContainer()
        local coins = cc and cc:GetChildren() or {}
        
        local root = getLocalRoot()
        local hum = getLocalHumanoid()
        
        if not root or not hum or hum.Health <= 0 then
            task.wait(1)
            continue
        end
        
        if #coins > 0 then
            local now = os.clock()
            local interval = 2
            
            if now - LastTeleportTime >= interval then
                local coin = FindCoin(root)
                if coin then
                    local targetCFrame = coin.CFrame
                    
                    local speed = 22.5 / AutoFarmState.FarmSpeed
                    local tweenInfo = TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    local tween = tweenService:Create(root, tweenInfo, {CFrame = targetCFrame})
                    tween:Play()
                    tween.Completed:Wait()
                    
                    LastTeleportedCoin = coin
                    LastTeleportTime = now
                end
            end
        else
            task.wait(1)
        end
        
        task.wait(0.1)
    end
end

local function StartMurdererAvoidance()
    while true do
        task.wait(0.1)
        if not AutoFarmState.FarmingActive or not AutoFarmState.StayAwayFromMurderer then
            continue
        end
        
        local role = getRole(plr)
        if role == "Murderer" then
            continue
        end
        
        local root = getLocalRoot()
        if not root then continue end
        
        local murderer = nil
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= plr and getRole(player) == "Murderer" then
                murderer = player
                break
            end
        end
        
        if murderer and murderer.Character then
            local mudRoot = murderer.Character:FindFirstChild("HumanoidRootPart")
            if mudRoot then
                local dist = (root.Position - mudRoot.Position).Magnitude
                if dist < 35 then
                    local escapeCoin = FindFurthestCoinFromMurderer(mudRoot)
                    if escapeCoin then
                        local targetCFrame = escapeCoin.CFrame
                        root.CFrame = targetCFrame
                        LastTeleportTime = os.clock()
                        
                        WindUI:Notify({
                            Title = "Murderer Avoided",
                            Content = "Teleported away from " .. murderer.Name,
                            Icon = "shield-alert",
                            Duration = 2.5,
                            Color = SummerColors.CoralPink
                        })
                        task.wait(1.5)
                    end
                end
            end
        end
    end
end

-- ╔════════════════════════════════════════════════════════════════╗
-- ║                    UI TABS & SECTIONS                          ║
-- ╚════════════════════════════════════════════════════════════════╝

local Tabs = {
    AutoFarm = Window:Tab({ Title = "Autofarm", Icon = "sun" }),
    ESP = Window:Tab({ Title = "ESP", Icon = "eye" }),
    Character = Window:Tab({ Title = "Character", Icon = "user" }),
    Teleport = Window:Tab({ Title = "Teleport", Icon = "navigation" }),
    Socials = Window:Tab({ Title = "Socials", Icon = "users" }),
    Info = Window:Tab({ Title = "Info", Icon = "info" })
}

-- ╔════════════════════════════════════════════════════════════════╗
-- ║                    AUTOFARM TAB                                ║
-- ╚════════════════════════════════════════════════════════════════╝

Tabs.AutoFarm:Section({ 
    Title = "Summer Autofarm Settings",
    Icon = "sun"
})

Tabs.AutoFarm:Space()

Tabs.AutoFarm:Slider({
    Title = "Farm Speed",
    Description = "Adjust farming speed (15 = slower, 20 = faster)",
    Icon = "gauge",
    Value = { Min = 15, Max = 20, Default = 19 },
    Callback = function(value)
        AutoFarmState.FarmSpeed = value
    end
})

Tabs.AutoFarm:Space()

Tabs.AutoFarm:Toggle({
    Title = "Auto Farm Coins",
    Description = "Automatically collects all coins on the map",
    Icon = "dollar-sign",
    Default = false,
    Color = SummerColors.LemonYellow,
    Callback = function(state)
        AutoFarmState.FarmingActive = state
        if state then
            coroutine.wrap(AutoFarmCoins)()
            WindUI:Notify({
                Title = "Farming Active",
                Content = "Started collecting coins!",
                Icon = "play",
                Duration = 2,
                Color = SummerColors.TealAccent
            })
        end
    end
})

Tabs.AutoFarm:Toggle({
    Title = "Stay Away From Murderer",
    Description = "Automatically teleports away if the murderer gets too close",
    Icon = "shield-alert",
    Default = false,
    Color = SummerColors.CoralPink,
    Callback = function(state)
        AutoFarmState.StayAwayFromMurderer = state
        if state then
            local role = getRole(plr)
            if role == "Murderer" then
                WindUI:Notify({
                    Title = "Warning",
                    Content = "You are the murderer! Feature disabled for you.",
                    Icon = "alert-circle",
                    Duration = 3,
                    Color = SummerColors.CoralPink
                })
            end
        end
    end
})

Tabs.AutoFarm:Dropdown({
    Title = "Farm Mode",
    Description = "Nearest = closest coin | Random = random coin",
    Icon = "target",
    Values = {"Nearest", "Random"},
    Value = "Nearest",
    Callback = function(selected)
        AutoFarmState.FarmMode = selected
    end
})

Tabs.AutoFarm:Space()

Tabs.AutoFarm:Toggle({
    Title = "Fling Murderer When Full",
    Description = "Auto-detects and flings murderer when inventory is full",
    Icon = "zap",
    Default = false,
    Color = SummerColors.LimeGreen,
    Callback = function(state)
        AutoFarmState.FlingMurdererEnabled = state
    end
})

Tabs.AutoFarm:Toggle({
    Title = "Reset When Full",
    Description = "Auto-resets when inventory is full as Murderer",
    Icon = "refresh-cw",
    Default = false,
    Color = SummerColors.TealAccent,
    Callback = function(state)
        AutoFarmState.ResetOnFullEnabled = state
    end
})

Tabs.AutoFarm:Space()

Tabs.AutoFarm:Toggle({
    Title = "Anti-Fling",
    Description = "Prevents other players from flinging you",
    Icon = "shield",
    Default = false,
    Color = SummerColors.SkyBlue,
    Callback = function(state)
        AntiFling.Enabled = state
        if state then
            coroutine.wrap(StartAntiFling)()
        end
    end
})

Tabs.AutoFarm:Toggle({
    Title = "Anti-AFK",
    Description = "Prevents you from being kicked for inactivity",
    Icon = "clock",
    Default = false,
    Color = SummerColors.PeachCream,
    Callback = function(state)
        AutoFarmState.AntiAFKEnabled = state
        if state then
            StartAntiAFK()
        end
    end
})

-- ╔════════════════════════════════════════════════════════════════╗
-- ║                    ESP TAB                                     ║
-- ╚════════════════════════════════════════════════════════════════╝

Tabs.ESP:Section({ 
    Title = "ESP Options",
    Icon = "eye"
})

Tabs.ESP:Toggle({
    Title = "Enable ESP",
    Description = "Show player highlights (Red = Murderer, Blue = Sheriff, Green = Innocent)",
    Icon = "eye",
    Default = false,
    Color = SummerColors.TealAccent,
    Callback = function(state)
        ESP.Enabled = state
        UpdateESP()
        if state then
            coroutine.wrap(function()
                while ESP.Enabled do
                    UpdateESP()
                    task.wait(0.5)
                end
            end)()
        else
            UpdateESP()
        end
    end
})

-- ╔════════════════════════════════════════════════════════════════╗
-- ║                    CHARACTER TAB                               ║
-- ╚════════════════════════════════════════════════════════════════╝

Tabs.Character:Section({ 
    Title = "Character Settings",
    Icon = "user"
})

local CharacterSettings = {
    WalkSpeed = { Value = 16, Default = 16 },
    JumpPower = { Value = 50, Default = 50 }
}

Tabs.Character:Slider({
    Title = "Walk Speed",
    Description = "Adjust your character's walk speed",
    Icon = "wind",
    Value = { Min = 0, Max = 200, Default = 16 },
    Callback = function(value)
        CharacterSettings.WalkSpeed.Value = value
        local char = plr.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = value end
        end
    end
})

Tabs.Character:Slider({
    Title = "Jump Power",
    Description = "Adjust your character's jump power",
    Icon = "arrow-up",
    Value = { Min = 0, Max = 200, Default = 50 },
    Callback = function(value)
        CharacterSettings.JumpPower.Value = value
        local char = plr.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = value end
        end
    end
})

-- ╔════════════════════════════════════════════════════════════════╗
-- ║                    TELEPORT TAB                                ║
-- ╚════════════════════════════════════════════════════════════════╝

Tabs.Teleport:Section({ 
    Title = "Teleport System",
    Icon = "navigation"
})

local teleportTarget = nil

local function UpdatePlayerList()
    local players = {"Select Player"}
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= plr then
            table.insert(players, player.Name)
        end
    end
    return players
end

Tabs.Teleport:Dropdown({
    Title = "Select Player",
    Description = "Choose a player to teleport to",
    Icon = "users",
    Values = UpdatePlayerList(),
    Value = "Select Player",
    Callback = function(selected)
        if selected ~= "Select Player" then
            teleportTarget = game.Players:FindFirstChild(selected)
        else
            teleportTarget = nil
        end
    end
})

Tabs.Teleport:Button({
    Title = "Teleport to Player",
    Description = "Teleport to selected player",
    Icon = "navigation",
    Color = SummerColors.TealAccent,
    Callback = function()
        if teleportTarget and teleportTarget.Character then
            local targetRoot = teleportTarget.Character:FindFirstChild("HumanoidRootPart")
            local localRoot = getLocalRoot()
            if targetRoot and localRoot then
                localRoot.CFrame = targetRoot.CFrame
                WindUI:Notify({
                    Title = "Teleported",
                    Content = "Moved to " .. teleportTarget.Name,
                    Icon = "check-circle",
                    Duration = 2,
                    Color = SummerColors.LimeGreen
                })
            end
        end
    end
})

-- ╔════════════════════════════════════════════════════════════════╗
-- ║                    SOCIALS TAB                                 ║
-- ╚════════════════════════════════════════════════════════════════╝

Tabs.Socials:Section({ 
    Title = "Community",
    Icon = "users"
})

Tabs.Socials:Button({
    Title = "Join Discord",
    Description = "Click to copy Discord invite",
    Icon = "discord",
    Color = SummerColors.CoralPink,
    Callback = function()
        if pcall(setclipboard, "https://discord.gg/vega-scripts") then
            WindUI:Notify({
                Title = "Copied",
                Content = "Discord invite copied to clipboard!",
                Icon = "check-circle",
                Duration = 3,
                Color = SummerColors.LimeGreen
            })
        end
    end
})

Tabs.Socials:Button({
    Title = "Vega Scripts",
    Description = "Visit our community",
    Icon = "star",
    Color = SummerColors.LemonYellow,
    Callback = function()
        WindUI:Notify({
            Title = "Vega Scripts",
            Content = "discord.gg/vega-scripts",
            Icon = "star",
            Duration = 3,
            Color = SummerColors.TealAccent
        })
    end
})

-- ╔════════════════════════════════════════════════════════════════╗
-- ║                    INFO TAB                                    ║
-- ╚════════════════════════════════════════════════════════════════╝

Tabs.Info:Section({ 
    Title = "About This Script",
    Icon = "info"
})

Tabs.Info:Label({
    Title = "Summer AutoFarm v2.0",
    Icon = "info"
})

Tabs.Info:Label({
    Title = "Designed with summer vibes in mind",
    Icon = "sun"
})

-- ╔════════════════════════════════════════════════════════════════╗
-- ║                    STARTUP                                     ║
-- ╚════════════════════════════════════════════════════════════════╝

coroutine.wrap(StartMurdererAvoidance)()

WindUI:Notify({
    Title = "Welcome",
    Content = "Summer AutoFarm loaded! Enjoy the vibes",
    Icon = "sun",
    Duration = 4,
    Color = SummerColors.SkyBlue
})
