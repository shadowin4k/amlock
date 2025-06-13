-- Load Kavo UI (safe fetch with pcall)
local function safeLoad(url)
    local ok, res = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if ok then return res end
    return nil
end

local kavoLib = safeLoad("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua")
if not kavoLib then return end

-- Setup UI container
local plr = game:GetService("Players").LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local containerGui = Instance.new("ScreenGui")
containerGui.Name = "KavoUIContainer"
containerGui.Parent = playerGui
containerGui.ResetOnSpawn = false
containerGui.Enabled = true -- visible initially

local Window = kavoLib.CreateLib("Hold Lock (K)", "DarkTheme")

-- Move Kavo UI's CoreGui element if found
task.spawn(function()
    task.wait(1)
    local coreGui = game:GetService("CoreGui")
    local kavoUIRoot = coreGui:FindFirstChild("Kavo UI")
    if kavoUIRoot then
        kavoUIRoot.Parent = containerGui
    end
end)

-- Variables
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local localPlayer = plr

local aimPartName = "Head"
local lockEnabled, useFov, usePrediction, toggleLock = false, true, true, false
local fovRadius = 100
local predictionValue = 0.1
local isHolding = false
local lockedTarget = nil
local lastTargetUpdate = 0
local targetUpdateInterval = 0.15 -- seconds, throttle target updates

-- Create FOV circle
local Drawing_new = Drawing.new
local fovCircle = Drawing_new and Drawing_new("Circle") or nil
if fovCircle then
    fovCircle.Color = Color3.fromRGB(255, 255, 255)
    fovCircle.Thickness = 2
    fovCircle.Transparency = 1
    fovCircle.Filled = false
    fovCircle.Radius = fovRadius
    fovCircle.Visible = false
end

-- UI Setup
local tab = Window:NewTab("Aimbot")
local section = tab:NewSection("Lock Settings")

section:NewToggle("Enable Lock-On", "Toggle hold-to-lock aimbot", function(val)
    lockEnabled = val
    if not val then
        isHolding = false
        lockedTarget = nil
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        if fovCircle then fovCircle.Visible = false end
    else
        if fovCircle then fovCircle.Visible = useFov end
    end
end)

section:NewToggle("Enable FOV", "Toggle FOV radius check", function(val)
    useFov = val
    if fovCircle then fovCircle.Visible = val and lockEnabled end
end)

section:NewToggle("Enable Prediction", "Toggle position prediction", function(val)
    usePrediction = val
end)

section:NewToggle("Toggle Mode (instead of Hold)", "Toggle lock-on with key instead of holding", function(val)
    toggleLock = val
    if not val then
        isHolding = false
        lockedTarget = nil
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end)

section:NewSlider("FOV Radius", "Adjust target radius", 300, 10, function(val)
    fovRadius = val
    if fovCircle then
        fovCircle.Radius = val
    end
end)

section:NewSlider("Prediction", "Adjust prediction multiplier", 100, 0, function(val)
    predictionValue = val / 100
end)

-- Find closest target respecting FOV and visibility
local function getClosestTarget()
    local closest = nil
    local shortestDist = fovRadius
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild(aimPartName) then
            local part = player.Character[aimPartName]
            local screenPos, visible = Camera:WorldToViewportPoint(part.Position)
            if visible then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                if (not useFov or dist < shortestDist) then
                    shortestDist = dist
                    closest = player
                end
            end
        end
    end
    return closest
end

-- Update loop
RunService.RenderStepped:Connect(function()
    if not lockEnabled then
        if fovCircle then fovCircle.Visible = false end
        return
    end

    local mousePos = UserInputService:GetMouseLocation()

    -- Update FOV circle position & visibility
    if fovCircle then
        fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
        fovCircle.Radius = fovRadius
        fovCircle.Visible = useFov and lockEnabled and containerGui.Enabled
    end

    if isHolding and lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild(aimPartName) then
        -- Throttle target updates to reduce CPU usage & detection risk
        if tick() - lastTargetUpdate > targetUpdateInterval then
            lockedTarget = getClosestTarget() or lockedTarget
            lastTargetUpdate = tick()
        end

        local targetPart = lockedTarget.Character[aimPartName]
        if targetPart then
            local targetPos = targetPart.Position
            if usePrediction then
                local rootPart = lockedTarget.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    targetPos = targetPos + rootPart.Velocity * predictionValue
                end
            end

            -- Smoothly set camera CFrame to target
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, targetPos)
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, 0.3) -- smooth lerp (0.3 blend)
        end
    end
end)

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not lockEnabled then return end

    if input.KeyCode == Enum.KeyCode.K then
        if toggleLock then
            if isHolding then
                isHolding = false
                lockedTarget = nil
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            else
                lockedTarget = getClosestTarget()
                isHolding = true
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            end
        else
            lockedTarget = getClosestTarget()
            isHolding = true
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
    elseif input.KeyCode == Enum.KeyCode.V then
        containerGui.Enabled = not containerGui.Enabled
        if fovCircle then
            fovCircle.Visible = containerGui.Enabled and useFov and lockEnabled
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.K then
        if not toggleLock then
            isHolding = false
            lockedTarget = nil
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
    end
end)
