--// Load Rayfield UI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
   Name = "MM2 ESP",
   LoadingTitle = "ESP Loader",
   LoadingSubtitle = "By EnderMH",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "MM2ESP",
      FileName = "Config"
   }
})

--// ESP Variables
local ESP = {}
local enabled = false
local tracked = {}

--// Role detection
local function getRole(player)
    local character = player.Character
    if character then
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                if tool.Name:lower():find("knife") then
                    return "Murderer"
                elseif tool.Name:lower():find("gun") or tool.Name:lower():find("revolver") then
                    return "Sheriff"
                end
            end
        end
    end
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                if tool.Name:lower():find("knife") then
                    return "Murderer"
                elseif tool.Name:lower():find("gun") or tool.Name:lower():find("revolver") then
                    return "Sheriff"
                end
            end
        end
    end
    return "Innocent"
end

--// Create Skeleton ESP
function ESP.Add(model)
    if tracked[model] then return end
    local parts = {}
    for _, part in ipairs({"Head","Torso","UpperTorso","LowerTorso","LeftArm","RightArm","LeftLeg","RightLeg"}) do
        parts[part] = Drawing.new("Line")
        parts[part].Thickness = 2
        parts[part].Visible = false
    end
    local label = Drawing.new("Text")
    label.Size = 16
    label.Center = true
    label.Outline = true
    label.Visible = false
    tracked[model] = {parts=parts,label=label}

    game:GetService("RunService").RenderStepped:Connect(function()
        if not enabled then
            for _,line in pairs(parts) do line.Visible = false end
            label.Visible = false
            return
        end

        if model and model.Parent and model:FindFirstChild("HumanoidRootPart") then
            local cam = workspace.CurrentCamera
            local function worldToView(obj)
                local pos, vis = cam:WorldToViewportPoint(obj.Position)
                return Vector2.new(pos.X,pos.Y), vis
            end

            local color = Color3.fromRGB(255,255,255)
            local textLabel = model.Name
            local plr = game.Players:GetPlayerFromCharacter(model)
            if plr then
                local role = getRole(plr)
                if role == "Murderer" then
                    color = Color3.fromRGB(255,0,0)
                elseif role == "Sheriff" then
                    color = Color3.fromRGB(0,0,255)
                else
                    color = Color3.fromRGB(0,255,0)
                end
                textLabel = plr.Name .. " ["..role.."]"
            end

            local function connect(p1,p2)
                if model:FindFirstChild(p1) and model:FindFirstChild(p2) then
                    local v1,vis1 = worldToView(model[p1])
                    local v2,vis2 = worldToView(model[p2])
                    if vis1 and vis2 then
                        parts[p1].From = v1
                        parts[p1].To = v2
                        parts[p1].Color = color
                        parts[p1].Visible = true
                    else
                        parts[p1].Visible = false
                    end
                end
            end

            -- Skeleton lines
            connect("Head","Torso")
            connect("Torso","LeftArm")
            connect("Torso","RightArm")
            connect("Torso","LeftLeg")
            connect("Torso","RightLeg")

            -- Text above head
            local head = model:FindFirstChild("Head")
            if head then
                local pos,vis = cam:WorldToViewportPoint(head.Position + Vector3.new(0,2,0))
                if vis then
                    label.Visible = true
                    label.Text = textLabel
                    label.Position = Vector2.new(pos.X,pos.Y)
                    label.Color = color
                else
                    label.Visible = false
                end
            end
        else
            for _,line in pairs(parts) do line.Visible = false end
            label.Visible = false
        end
    end)
end

--// Remove Skeleton ESP
function ESP.Remove(model)
    if tracked[model] then
        for _,line in pairs(tracked[model].parts) do line:Remove() end
        tracked[model].label:Remove()
        tracked[model] = nil
    end
end

--// Rayfield Tabs
local espTab = Window:CreateTab("ESP", 4483362458)
espTab:CreateToggle({
   Name = "Enable ESP",
   CurrentValue = false,
   Flag = "ESPEnabled",
   Callback = function(value)
       enabled = value
   end,
})

local gunTab = Window:CreateTab("Gun Tracker", 4483362458)

-- Toggle for dropped gun highlight
local gunToggle = false
gunTab:CreateToggle({
    Name = "Highlight Dropped Gun",
    CurrentValue = true,
    Flag = "HighlightGun",
    Callback = function(value)
        gunToggle = value
    end
})

-- Button: focus nearest dropped gun
local trackedGun = Drawing.new("Text")
trackedGun.Size = 18
trackedGun.Center = true
trackedGun.Outline = true
trackedGun.Color = Color3.fromRGB(0,0,255)
trackedGun.Visible = false

gunTab:CreateButton({
    Name = "Show Nearest Gun",
    Callback = function()
        local nearestGun = nil
        local minDist = math.huge
        local localChar = game.Players.LocalPlayer.Character
        if not localChar then return end
        local hrp = localChar:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name:lower():find("gun") then
                local dist = (obj.Position - hrp.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearestGun = obj
                end
            end
        end

        if nearestGun then
            local cam = workspace.CurrentCamera
            local pos, onScreen = cam:WorldToViewportPoint(nearestGun.Position)
            if onScreen then
                trackedGun.Text = "[Gun] "..math.floor(minDist).." studs away"
                trackedGun.Position = Vector2.new(pos.X,pos.Y)
                trackedGun.Visible = true
            else
                trackedGun.Visible = false
            end
        end
    end
})

--// Track humanoids
local function trackAll()
    for _, m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then
            ESP.Add(m)
        end
    end
end

workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Humanoid") and obj.Parent then
        ESP.Add(obj.Parent)
    end
end)

-- Initial scan
trackAll()

--// Gun highlight updater
game:GetService("RunService").RenderStepped:Connect(function()
    if not gunToggle then
        trackedGun.Visible = false
        return
    end
    local nearestGun = nil
    local minDist = math.huge
    local localChar = game.Players.LocalPlayer.Character
    if not localChar then return end
    local hrp = localChar:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("gun") then
            local dist = (obj.Position - hrp.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearestGun = obj
            end
        end
    end
    if nearestGun then
        local cam = workspace.CurrentCamera
        local pos, onScreen = cam:WorldToViewportPoint(nearestGun.Position)
        if onScreen then
            trackedGun.Text = "[Gun] "..math.floor(minDist).." studs away"
            trackedGun.Position = Vector2.new(pos.X,pos.Y)
            trackedGun.Visible = true
        else
            trackedGun.Visible = false
        end
    else
        trackedGun.Visible = false
    end
end)
