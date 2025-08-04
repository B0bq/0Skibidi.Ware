-- Settings

local aimbot = {
    Enabled = false,
    Key = Enum.UserInputType.MouseButton2,
    Players = false,
    PlayerPart = 'Head',
    FriendlyPlayers = {},
    TeamCheck = false,
    AliveCheck = false,
    VisibilityCheck = false,
    Smoothing = 0,
    SmoothingMethod = 0,
    Offset = {0, 0},
    FOV = 200,
    ShowFOV = false,
    CustomParts = {},
    FOVCircleColor = Color3.fromRGB(255, 255, 255)
}

-- Variables

local UserInputService = game:GetService('UserInputService')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local plr = Players.LocalPlayer
local mouse = plr:GetMouse()
local keypressed = false
local fovcircle = Drawing.new('Circle')
fovcircle.Filled = false
fovcircle.Thickness = 1

-- Functions

aimbot.GetClosestPart = function(camera, mousePos)
    local target
    local parts = {}

    for _, v in pairs(aimbot.CustomParts) do
        if v:IsA("BasePart") then
            table.insert(parts, v)
        end
    end

    if aimbot.Players then
        for _, v in pairs(Players:GetPlayers()) do
            if not table.find(aimbot.FriendlyPlayers, v.Name) and v ~= plr then
                local char = v.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local alive = hum and hum.Health > 0

                if (not aimbot.AliveCheck or alive) and (not aimbot.TeamCheck or v.TeamColor ~= plr.TeamColor) then
                    local part = char and char:FindFirstChild(aimbot.PlayerPart)
                    if part then
                        if aimbot.VisibilityCheck then
                            local direction = (part.Position - camera.CFrame.Position)
                            local params = RaycastParams.new()
                            params.FilterType = Enum.RaycastFilterType.Blacklist
                            params.IgnoreWater = true
                            params.FilterDescendantsInstances = {plr.Character, char}
                            
                            local result = workspace:Raycast(camera.CFrame.Position, direction, params)
                            
                            -- If something is in the way that's NOT the target part, skip it
                            if result and result.Instance ~= part then
                                continue
                            end
                        end
                        table.insert(parts, part)
                    end
                end
            end
        end
    end

    for _, v in pairs(parts) do
        local pos, onScreen = camera:WorldToScreenPoint(v.Position)
        local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
        if onScreen and dist <= aimbot.FOV then
            if not target or dist < target.Distance then
                target = {Part = v, Position = pos, Distance = dist}
            end
        end
    end

    return target
end

aimbot.Aim = function(x, y, smooth)
    smooth = smooth or aimbot.Smoothing
    local dx = x + aimbot.Offset[1] - mouse.X
    local dy = y + aimbot.Offset[2] - mouse.Y

    if smooth == 0 then
        mousemoverel(dx, dy)
    else
        local divisor = aimbot.SmoothingMethod == 0 and (5 * (smooth + 1)) or (smooth + 1)
        mousemoverel(dx / divisor, dy / divisor)
    end
end

-- Key Pressing

UserInputService.InputBegan:Connect(function(input)
    if not aimbot.Key or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == aimbot.Key or input.UserInputType == aimbot.Key then
        keypressed = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not aimbot.Key or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == aimbot.Key or input.UserInputType == aimbot.Key then
        keypressed = false
    end
end)

-- Loops

RunService.RenderStepped:Connect(function() -- FOV Updating
    fovcircle.Visible = aimbot.ShowFOV
    fovcircle.Color = aimbot.FOVCircleColor
    fovcircle.Radius = aimbot.FOV
    fovcircle.Position = Vector2.new(mouse.X + aimbot.Offset[1], mouse.Y + 35 + aimbot.Offset[2])
end)

RunService.RenderStepped:Connect(function() -- Aiming
    if aimbot.Enabled and keypressed then
        local camera = workspace.CurrentCamera
        local mousePos = Vector2.new(mouse.X, mouse.Y)
        local part = aimbot.GetClosestPart(camera, mousePos)
        if part then
            aimbot.Aim(part.Position.X, part.Position.Y, aimbot.Smoothing)
        end
    end
end)

return aimbot
