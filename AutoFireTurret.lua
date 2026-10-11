-- Roblox ServerScript for Auto-Fire Turret with Player Detection
-- Place this Script inside the turret model

local turret = script.Parent
local head = turret:WaitForChild("TurretHead")
local barrel = turret:WaitForChild("Barrel")

-- Configuration
local RANGE = 100
local FIRE_RATE = 0.5
local ROTATION_SPEED = 0.15
local FOV = math.rad(60)
local PROJECTILE_SPEED = 120
local DAMAGE = 25

local cooldown = 0
local currentTarget = nil

-- Function to detect all players in range
local function getClosestPlayer()
    local bestTarget = nil
    local bestDistance = math.huge

    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player.Character then
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

            if humanoidRootPart and humanoid and humanoid.Health > 0 then
                local distance = (humanoidRootPart.Position - head.Position).Magnitude

                -- Check if within range
                if distance <= RANGE then
                    -- Check FOV (field of view)
                    local directionToPlayer = (humanoidRootPart.Position - head.Position).Unit
                    local turretForward = head.CFrame.LookVector
                    local angle = math.acos(math.clamp(turretForward:Dot(directionToPlayer), -1, 1))

                    if angle <= FOV then
                        -- Prefer closest target
                        if distance < bestDistance then
                            bestTarget = humanoidRootPart
                            bestDistance = distance
                        end
                    end
                end
            end
        end
    end

    return bestTarget
end

-- Function to fire a projectile
local function fireProjectile(targetPosition)
    local direction = (targetPosition - barrel.Position).Unit

    local projectile = Instance.new("Part")
    projectile.Shape = Enum.PartType.Ball
    projectile.Material = Enum.Material.Neon
    projectile.Size = Vector3.new(0.5, 0.5, 0.5)
    projectile.BrickColor = BrickColor.new("Bright red")
    projectile.CanCollide = false
    projectile.Anchored = false
    projectile.CFrame = CFrame.new(barrel.Position)
    projectile.Parent = workspace

    -- Add velocity
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = direction * PROJECTILE_SPEED
    bodyVelocity.Parent = projectile

    -- Hit detection
    local hitPlayers = {}
    local touchConnection
    touchConnection = projectile.Touched:Connect(function(hit)
        if hit:IsDescendantOf(turret) then return end

        local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid and not hitPlayers[hit.Parent] then
            hitPlayers[hit.Parent] = true
            humanoid:TakeDamage(DAMAGE)
            projectile:Destroy()
            touchConnection:Disconnect()
        end
    end)

    -- Cleanup after 5 seconds
    game.Debris:AddItem(projectile, 5)
end

-- Main loop
while true do
    task.wait(0.05)
    cooldown = math.max(0, cooldown - 0.05)

    -- Detect closest player
    local target = getClosestPlayer()

    if target then
        currentTarget = target

        -- Rotate turret head towards target
        local targetCFrame = CFrame.lookAt(head.Position, target.Position)
        head.CFrame = head.CFrame:Lerp(targetCFrame, ROTATION_SPEED)

        -- Auto-fire when cooldown is ready
        if cooldown <= 0 then
            fireProjectile(target.Position)
            cooldown = FIRE_RATE
        end
    else
        currentTarget = nil
    end
end
