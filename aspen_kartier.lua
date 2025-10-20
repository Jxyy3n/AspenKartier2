-- Global Constants {Syde Loader} --
local Syde = loadstring(game:HttpGet('https://raw.githubusercontent.com/Jxyy3n/AspenKartier2/refs/heads/main/MainLib', true))()
-- Constants {Services} --
local PlayersService = game:GetService('Players')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')
-- Constants {Player References} --
local LocalPlayer = PlayersService.LocalPlayer
-- Run {Adonis} --

----

-- Constants {Window Initialization} --
local Window = Syde:Init({
    Title = 'Aspen Kartier',
    SubText = 'Version 1.0.0'
})
----

-- Constants {Tab References} --
local InformationTab = Window:InitTab({Title = 'Information'})
local CharacterTab = Window:InitTab({Title = 'Character'})
local GameplayTab = Window:InitTab({Title = 'Gameplay'})
local VisualsTab = Window:InitTab({Title = 'Visuals'})
local UtilityTab = Window:InitTab({Title = 'Utiility'})
----

-- Constants {Global Spoof Variables} --
getgenv().IsSpoofed = getgenv().IsSpoofed or false
getgenv().SpoofWalkSpeed = getgenv().SpoofWalkSpeed or 16
getgenv().SpoofJumpPower = getgenv().SpoofJumpPower or 50
-- TouchInterest defaults
getgenv().TouchInterestEnabled = getgenv().TouchInterestEnabled or false
getgenv().TouchInterestDistance = getgenv().TouchInterestDistance or 5
getgenv().TouchInterestPower = getgenv().TouchInterestPower or 1
----

-- Functions {Utilities} --
local function SafeIsA(Instance, ClassName)
    -- Check {Type is Instance} --
    if typeof(Instance) ~= 'Instance' then return false end
    -- Check {IsA Safely} --
    local Ok, Result = pcall(function() return Instance:IsA(ClassName) end)
    return Ok and Result
end
----
local function GetLocalHumanoid()
    -- Constants {Character Reference} --
    local Character = LocalPlayer and LocalPlayer.Character
    -- Check {Character Exists} --
    if not Character then return nil end
    -- Find {Humanoid} --
    local Humanoid = Character:FindFirstChildOfClass('Humanoid')
    return Humanoid
end
local function GetLocalHitbox()
    -- Constants {Character Reference} --
    local Character = LocalPlayer and LocalPlayer.Character
    -- Check {Character Exists} --
    if not Character then return nil end
    -- Find {Humanoid} --
    local Hitbox = Character:FindFirstChild('Hitbox')
    return Hitbox
end
local function GetHumanoidRootPart()
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild('HumanoidRootPart') or char:FindFirstChild('Torso') or char:FindFirstChild('UpperTorso')
end
----

-- Functions {Enforcement Control} --
local EnforcementConnection
local function StartEnforcement()
    -- Check {Connection Active} --
    if EnforcementConnection then return end
    -- Connection {RunService Heartbeat} --
    EnforcementConnection = RunService.Heartbeat:Connect(function()
        -- Check {Spoof Active} --
        if not getgenv().IsSpoofed then return end
        -- Constants {Humanoid Reference} --
        local Humanoid = GetLocalHumanoid()
        -- Check {Humanoid Exists} --
        if Humanoid then
            -- PCall {Enforce Spoofed Values} --
            pcall(function()
                if getgenv().SpoofWalkSpeed then {
                    Humanoid.WalkSpeed = getgenv().SpoofWalkSpeed
                end
                if getgenv().SpoofJumpPower then
                    Humanoid.JumpPower = getgenv().SpoofJumpPower
                end
            end)
        end
    end)
end
----
local function StopEnforcement()
    -- Check {Connection Active} --
    if EnforcementConnection then
        EnforcementConnection:Disconnect()
        EnforcementConnection = nil
    end
end
----

-- TouchInterest: optimized implementation (tracks Football parts named exactly "Football")
local footballParts = {} -- set of tracked parts (weak keys)
setmetatable(footballParts, {__mode = 'k'})
local footballTrackConnAdd, footballTrackConnRemove

local function TrackPart(part)
    if not part or not part:IsA('BasePart') then return end
    if part.Name == 'Football' then
        footballParts[part] = true
    end
end

local function UntrackPart(part)
    if not part then return end
    footballParts[part] = nil
end

-- initialize existing footballs (single pass)
for _,desc in ipairs(workspace:GetDescendants()) do
    if desc:IsA('BasePart') and desc.Name == 'Football' then
        footballParts[desc] = true
    end
end

-- listen for changes to workspace to keep the set small and efficient
footballTrackConnAdd = workspace.DescendantAdded:Connect(function(desc)
    -- if a whole model is added, its parts will also fire DescendantAdded
    if desc:IsA('BasePart') and desc.Name == 'Football' then
        footballParts[desc] = true
    end
end)
footballTrackConnRemove = workspace.DescendantRemoving:Connect(function(desc)
    if desc:IsA('BasePart') and desc.Name == 'Football' then
        footballParts[desc] = nil
    end
end)

-- Internal touch-interest state (connections, target tracking)
local TouchLoopTask
local Mouse
local CurrentTouchTarget
local TouchDebounce = false

local function FindClosestTrackedFootball()
    local hrp = GetHumanoidRootPart()
    if not hrp then return nil, math.huge end

    local closestPart = nil
    local closestDistSq = math.huge
    for part,_ in pairs(footballParts) do
        if part and part.Parent then
            local ok, distSq = pcall(function()
                return (part.Position - hrp.Position).Magnitude^2
            end)
            if ok and distSq and distSq < closestDistSq then
                closestDistSq = distSq
                closestPart = part
            end
        end
    end

    return closestPart, closestDistSq
end

local function DoFireTouch(partA, partB)
    if type(firetouchinterest) == 'function' then
        pcall(function()
            firetouchinterest(partA, partB, 0)
            task.wait(0.02)
            firetouchinterest(partA, partB, 1)
        end)
    else
        -- not available in this environment
    end
end

local function StartTouchInterest()
    if TouchLoopTask then return end

    -- create mouse if not yet
    if not Mouse and LocalPlayer then
        Mouse = LocalPlayer:GetMouse()
    end

    -- background loop: update nearest target at a lower frequency to avoid FPS drops
    TouchLoopTask = task.spawn(function()
        while getgenv().TouchInterestEnabled do
            -- update current closest football every 0.12s (configurable)
            local part, distSq = FindClosestTrackedFootball()
            if part then
                local dist = math.sqrt(distSq)
                if dist <= (getgenv().TouchInterestDistance or 5) then
                    CurrentTouchTarget = part
                else
                    CurrentTouchTarget = nil
                end
            else
                CurrentTouchTarget = nil
            end
            task.wait(0.12)
        end
        CurrentTouchTarget = nil
        TouchLoopTask = nil
    end)

    -- connect mouse click (more reliable than UserInputService for simple left-clicks)
    if Mouse then
        Mouse.Button1Down:Connect(function()
            if not getgenv().TouchInterestEnabled then return end
            local target = CurrentTouchTarget
            if not target or not target.Parent then return end
            local hrp = GetHumanoidRootPart()
            if not hrp then return end

            if TouchDebounce then return end
            TouchDebounce = true

            local power = math.max(1, math.floor(getgenv().TouchInterestPower or 1))
            for i = 1, power do
                if not getgenv().TouchInterestEnabled then break end
                local ok, stillNear = pcall(function()
                    return (target.Position - hrp.Position).Magnitude <= (getgenv().TouchInterestDistance or 5)
                end)
                if not ok or not stillNear then break end
                -- call firetouchinterest with Football first (as requested)
                DoFireTouch(target, hrp)
                task.wait(0.03)
            end

            task.delay(0.15, function() TouchDebounce = false end)
        end)
    end
end

local function StopTouchInterest()
    -- stopping the loop is enough; mouse connection will naturally be GC'd with the closure
    getgenv().TouchInterestEnabled = false
    CurrentTouchTarget = nil
    TouchDebounce = false
    -- ensure task is cleaned
    TouchLoopTask = nil
end

----
-- Functions {Metamethod Hook} --
local OldIndex
if type(hookmetamethod) == 'function' then
    -- Hook {__index} --
    OldIndex = hookmetamethod(game, '__index', function(self, key)
        -- Check {Spoof Active & Is Humanoid} --
        if getgenv().IsSpoofed and SafeIsA(self, 'Humanoid') then
            -- Check {WalkSpeed Key} --
            if key == 'WalkSpeed' then
                return getgenv().SpoofWalkSpeed or OldIndex(self, key)
                -- Check {JumpPower Key} --
            elseif key == 'JumpPower' then
                return getgenv().SpoofJumpPower or OldIndex(self, key)
            elseif key == 'Transparency' then
                return 1
            elseif key == 'Size' then
                return 2, 4.2, 4
            end
        end
        return OldIndex(self, key)
    end)
else
    warn('[AspenKartier] hookmetamethod not available; server-side reads wont be spoofed. Local enforcement will still work.')
end
----

-- Functions {Initialization & State Watcher} --
task.spawn(function()
    local PreviousSpoofedState = getgenv().IsSpoofed
    -- While Loop {Check Global State} --
    while task.wait(0.15) do
        -- Check {State Change} --
        if getgenv().IsSpoofed ~= PreviousSpoofedState then
            PreviousSpoofedState = getgenv().IsSpoofed
            -- Toggle {Enforcement} --
            if PreviousSpoofedState then
                StartEnforcement()
            else
                StopEnforcement()
            end
        end
    end
end)
----
local function CleanupAspenSpoof()
    -- Set {Global State} --
    getgenv().IsSpoofed = false
    -- Call {Stop Enforcement} --
    StopEnforcement()
    -- Notify {Cleanup Complete} --
    Syde:Notify({
        Title = 'Spoof',
        Content = 'Cleanup executed, spoofing disabled.',
        Duration = 2,
    })
end
----
-- Expose {Cleanup Function} --
getgenv().CleanupAspenSpoof = CleanupAspenSpoof
----

-- Tab {Information} --
InformationTab:Paragraph({
    Title = 'About Aspen Kartier',
    Content = 'Aspen Kartier is an advanced Roblox Football cheat with a wide range of elements that are customizable to your liking.'
})
----

-- Tab {Character} --
CharacterTab:Section('Spoofing Section')
CharacterTab:Button({
    Title = 'Spoof All',
    Description = 'Spoof the temporary requirements in order to change hitbox size, hitbox transparency, jumppower, and walkspeed.',
    CallBack = function()
        -- Toggle {Global Spoof Flag} --
        getgenv().IsSpoofed = not getgenv().IsSpoofed
        -- Toggle {Enforcement} --
        if getgenv().IsSpoofed then
            StartEnforcement()
        else
            StopEnforcement()
        end
        -- Notify {State Change} --
        Syde:Notify({
            Title = 'Spoofed Values',
            Content = getgenv().IsSpoofed and 'Spoofing enabled (WalkSpeed: ' .. tostring(getgenv().SpoofWalkSpeed) .. ', JumpPower: ' .. tostring(getgenv().SpoofJumpPower) .. ')' or 'Spoofing disabled!',
            Duration = 2,
        })
    end,
})
----
CharacterTab:Section('Hitbox Section')
CharacterTab:CreateSlider({
    Title = 'Hitbox Size',
    Description = 'Adjust your hitbox size',
    Sliders = {
        {
            Title = 'Z',
            Range = {0, 5},
            Increment = 1,
            StarterValue = 0,
            CallBack = function(Value)
                if getgenv().IsSpoofed then
                    getgenv().HitboxZSize = Value
                    -- Update {Hitbox} --
                    local Hitbox = GetLocalHitbox()
                    if Hitbox then
                        pcall(function() TweenService:Create(Hitbox, TweenInfo.new(.5), {Size = Vector3.new(Hitbox.Size.X, Hitbox.Size.Y, getgenv().HitboxZSize)}):Play() end)
                    end
                end
            end,
        },
        {
            Title = 'X',
            Range = {0, 5},
            Increment = 1,
            StarterValue = 0,
            CallBack = function(Value)
                if getgenv().IsSpoofed then
                    getgenv().HitboxXSize = Value
                    -- Update {Hitbox} --
                    local Hitbox = GetLocalHitbox()
                    if Hitbox then
                        pcall(function() TweenService:Create(Hitbox, TweenInfo.new(.5), {Size = Vector3.new(getgenv().HitboxXSize, Hitbox.Size.Y, Hitbox.Size.Z)}):Play() end)
                    end
                end
            end,
        },
        {
            Title = 'Y',
            Range = {0, 5},
            Increment = 1,
            StarterValue = 0,
            CallBack = function(Value)
                if getgenv().IsSpoofed then
                    getgenv().HitboxYSize = Value
                    -- Update {Hitbox} --
                    local Hitbox = GetLocalHitbox()
                    if Hitbox then
                        pcall(function() TweenService:Create(Hitbox, TweenInfo.new(.5), {Size = Vector3.new(Hitbox.Size.X, getgenv().HitboxYSize, Hitbox.Size.Z)}):Play() end)
                    end
                end
            end,
        }
    }
})
----
CharacterTab:CreateSlider({
    Title = 'Hitbox Transparency',
    Description = 'Adjust how visible your hitbox is',
    Sliders = {
        {
            Title = 'Hitbox Transparency',
            Range = {0, 1},
            Increment = .1,
            StarterValue = 1,
            CallBack = function(Value)
                -- Update {Spoof Value} --
                getgenv().SpoofHitboxTransparency = Value
                -- Apply {Immediately If Spoofed} --
                if getgenv().IsSpoofed then
                    local Hitbox = GetLocalHitbox()
                    if Hitbox then
                        pcall(function() Hitbox.Transparency = Value end)
                    end
                end
            end,
        }
    }
})
----
CharacterTab:Section('Humanoid Section')
CharacterTab:CreateSlider({
    Title = 'Humanoid Controller',
    Description = 'Adjust your walkspeed & jumppower',
    Sliders = {
        {
            Title = 'Walk Speed',
            Range = {16, 35},
            Increment = 1,
            StarterValue = getgenv().SpoofWalkSpeed,
            CallBack = function(Value)
                -- Update {Global Spoof Value} --
                getgenv().SpoofWalkSpeed = Value
                print('Walkspeed set to ' .. Value)
                -- Apply {Immediately If Spoofing} --
                if getgenv().IsSpoofed then
                    local Humanoid = GetLocalHumanoid()
                    if Humanoid then
                        pcall(function() Humanoid.WalkSpeed = Value end)
                    end
                end
            end,
        },
        {
            Title = 'Jump Power',
            Range = {50, 85},
            Increment = 1,
            StarterValue = getgenv().SpoofJumpPower,
            CallBack = function(Value)
                -- Update {Global Spoof Value} --
                getgenv().SpoofJumpPower = Value
                print('Jumppower set to ' .. Value)
                -- Apply {Immediately If Spoofing} --
                if getgenv().IsSpoofed then
                    local Humanoid = GetLocalHumanoid()
                    if Humanoid then
                        pcall(function() Humanoid.JumpPower = Value end)
                    end
                end
            end,
        }
    }
})
--
CharacterTab:Section('Player Section')
CharacterTab:Toggle({
    Title = 'Big Head',
    Description = 'Enhance your head size',
    Value = false,
    CallBack = function(Value)
        print('FireTouch magnet toggle state:', Value)
    end,
})
----

-- Tab {Gameplay} --
GameplayTab:Section('Vector Section')
GameplayTab:Toggle({
    Title = 'Pull Vector',
    Description = 'Pull vector magnet type',
    Value = false,
    CallBack = function(Value)
        print('Pull Vector magnet toggle state:', Value)
    end,
})
GameplayTab:CreateSlider({
    Title = 'Vector Controller',
    Description = 'Adjust your vector magnet settings',
    Sliders = {
        {
            Title = 'Speed',
            Range = {0, 5},
            Increment = 1,
            StarterValue = getgenv().PullVectorSpeed,
            CallBack = function(Value)
                -- Update {Global Spoof Value} --
                getgenv().PullVectorSpeed = Value
                print('PullVectorSpeed set to ' .. Value)
                -- Apply {Immediately If Spoofing} --
                if getgenv().PullVectorEnabled then
                    
                end
            end,
        },
        {
            Title = 'Power',
            Range = {0, 5},
            Increment = 1,
            StarterValue = getgenv().PullVectorPower,
            CallBack = function(Value)
                -- Update {Global Spoof Value} --
                getgenv().PullVectorPower = Value
                print('PullVectorPower set to ' .. Value)
                -- Apply {Immediately If Spoofing} --
                if getgenv().PullVectorEnabled then
                    
                end
            end,
        }
    }
})
--
GameplayTab:Section('Touch Interest Section')
GameplayTab:Toggle({
    Title = 'Touch Interest',
    Description = 'FireTouch interest magnet type (click to use when a football is near)',
    Value = getgenv().TouchInterestEnabled,
    CallBack = function(Value)
        getgenv().TouchInterestEnabled = Value and true or false
        if getgenv().TouchInterestEnabled then
            StartTouchInterest()
            Syde:Notify({
                Title = 'Touch Interest',
                Content = 'Touch Interest enabled.',
                Duration = 2,
            })
        else
            StopTouchInterest()
            Syde:Notify({
                Title = 'Touch Interest',
                Content = 'Touch Interest disabled.',
                Duration = 2,
            })
        end
    end,
})
GameplayTab:CreateSlider({
    Title = 'Touch Interest Controller',
    Description = 'Adjust your touch interest magnet settings',
    Sliders = {
        {
            Title = 'Distance',
            Range = {0, 30},
            Increment = 1,
            StarterValue = getgenv().TouchInterestDistance,
            CallBack = function(Value)
                -- Update {Global Spoof Value} --
                getgenv().TouchInterestDistance = Value
                print('TouchInterestDistance set to ' .. Value)
                -- Apply {Immediately If Enabled} --
                if getgenv().TouchInterestEnabled then
                    -- heartbeat will use updated value automatically
                end
            end,
        },
        {
            Title = 'Power',
            Range = {1, 10},
            Increment = 1,
            StarterValue = getgenv().TouchInterestPower,
            CallBack = function(Value)
                -- Update {Global Spoof Value} --
                getgenv().TouchInterestPower = Value
                print('TouchInterestPower set to ' .. Value)
                -- Apply {Immediately If Enabled} --
                if getgenv().TouchInterestEnabled then
                    -- will affect next click
                end
            end,
        }
    }
})
----

-- Tab {Visuals} --
----
-- Tab {Utility} --
