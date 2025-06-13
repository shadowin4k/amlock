-- Load xHeptc Kavo UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Hold Lock (K)", "DarkTheme")
local Tab = Window:NewTab("Aimbot")
local Section = Tab:NewSection("Lock Settings")

-- Services
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local lp = players.LocalPlayer
local camera = workspace.CurrentCamera

-- Create a ScreenGui container in PlayerGui for Kavo UI
local playerGui = lp:WaitForChild("PlayerGui")
local containerGui = Instance.new("ScreenGui")
containerGui.Name = "KavoUIContainer"
containerGui.Parent = playerGui
containerGui.ResetOnSpawn = false

-- Load Kavo UI
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Hold Lock (K)", "DarkTheme")

-- Wait a moment to ensure UI is created, then move Kavo UI into containerGui
task.wait()
-- Kavo UI's root ScreenGui is usually named "Kavo UI"
local coreGui = game:GetService("CoreGui")
local kavoUIRoot = coreGui:FindFirstChild("Kavo UI")
if kavoUIRoot then
    kavoUIRoot.Parent = containerGui
end

-- Config
local aimPart = "Head"
local lockEnabled = false
local useFov = true
local usePrediction = true
local fov = 100
local prediction = 0.1
local holding = false
local toggleLock = false -- toggle or hold mode
local lockedTarget = nil

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Radius = fov
fovCircle.Thickness = 2
fovCircle.Transparency = 1
fovCircle.Color = Color3.fromRGB(255, 255, 255) -- white
fovCircle.Filled = false
fovCircle.Visible = useFov

-- Tabs and sections
local Tab = Window:NewTab("Aimbot")
local Section = Tab:NewSection("Lock Settings")

-- UI Toggles
Section:NewToggle("Enable Lock-On", "Toggle hold-to-lock aimbot", function(value)
    lockEnabled = value
    if not lockEnabled then
        holding = false
        toggleLock = false
        lockedTarget = nil
        uis.MouseBehavior = Enum.MouseBehavior.Default
    end
end)

Section:NewToggle("Enable FOV", "Toggle FOV radius check", function(val)
    useFov = val
    fovCircle.Visible = val and lockEnabled
end)

Section:NewToggle("Enable Prediction", "Toggle position prediction", function(val)
    usePrediction = val
end)

Section:NewToggle("Toggle Mode (instead of Hold)", "Toggle lock-on with key instead of holding", function(val)
    toggleLock = val
    if not toggleLock then
        holding = false
        lockedTarget = nil
        uis.MouseBehavior = Enum.MouseBehavior.Default
    end
end)

-- Sliders
Section:NewSlider("FOV Radius", "Adjust target radius", 300, 10, function(v)
    fov = v
    fovCircle.Radius = v
end)

Section:NewSlider("Prediction", "Adjust prediction multiplier", 100, 0, function(v)
    prediction = v / 100
end)

-- Get closest target function
local function getClosestTarget()
    local closest, shortest = nil, fov
    for _, player in pairs(players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild(aimPart) then
            local part = player.Character[aimPart]
            local screenPos, visible = camera:WorldToViewportPoint(part.Position)
            if visible then
                local mousePos = uis:GetMouseLocation()
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                if (not useFov or dist < shortest) then
                    if useFov then shortest = dist end
                    closest = player
                end
            end
        end
    end
    return closest
end

-- Aimbot logic + FOV circle update
runService.RenderStepped:Connect(function()
    local mousePos = uis:GetMouseLocation()
    fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
    fovCircle.Radius = fov
    fovCircle.Visible = useFov and lockEnabled

    if holding and lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild(aimPart) then
        local part = lockedTarget.Character[aimPart]
        local targetPos = part.Position

        if usePrediction then
            local root = lockedTarget.Character:FindFirstChild("HumanoidRootPart")
            if root then
                targetPos += root.Velocity * prediction
            end
        end

        camera.CFrame = CFrame.new(camera.CFrame.Position, targetPos)
    end
end)

-- Input handlers
uis.InputBegan:Connect(function(input, gp)
    if gp or not lockEnabled then return end

    if input.KeyCode == Enum.KeyCode.K then
        if toggleLock then
            if holding then
                holding = false
                lockedTarget = nil
                uis.MouseBehavior = Enum.MouseBehavior.Default
            else
                holding = true
                lockedTarget = getClosestTarget()
                uis.MouseBehavior = Enum.MouseBehavior.LockCenter
            end
        else
            holding = true
            if not lockedTarget then
                lockedTarget = getClosestTarget()
            end
            uis.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
    end

    -- Toggle GUI visibility with V key
    if input.KeyCode == Enum.KeyCode.V then
        containerGui.Enabled = not containerGui.Enabled
    end
end)

uis.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.K then
        if not toggleLock then
            holding = false
            lockedTarget = nil
            uis.MouseBehavior = Enum.MouseBehavior.Default
        end
    end
end)
