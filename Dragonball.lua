-- Nearby Death Sound + Background Music + Sky + Map Texture + Custom Font
-- Place in StarterPlayer > StarterPlayerScripts

local Players       = game:GetService("Players")
local Workspace     = game:GetService("Workspace")
local SoundService  = game:GetService("SoundService")
local Lighting      = game:GetService("Lighting")
local Debris        = game:GetService("Debris")

local LOCAL_PLAYER = Players.LocalPlayer

-- ====================== SETTINGS ======================

local SOUND_ID = "rbxassetid://139262038476728"
local MUSIC_ID = "rbxassetid://113141545914097"

local RANGE = 1000
local VOLUME = 0.5
local MUSIC_VOLUME = 0.2

-- ====================== BACKGROUND MUSIC ======================

local music = Instance.new("Sound")
music.Name = "BackgroundMusic"
music.SoundId = MUSIC_ID
music.Volume = MUSIC_VOLUME
music.Looped = true
music.Parent = SoundService
music:Play()

print("[bundle] music started")

-- ====================== SKY (background loop) ======================

local skyIds = {
    "2606419958", -- SkyboxBK
    "3343496544", -- SkyboxDn
    "2606419958", -- SkyboxFt
    "2606419958", -- SkyboxLf
    "2606419958", -- SkyboxRt
    "3343489819", -- SkyboxUp
}

local function applySky()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") then
            obj:Destroy()
        end
    end

    local sky = Instance.new("Sky")
    sky.SkyboxBk = "rbxassetid://" .. skyIds[1]
    sky.SkyboxDn = "rbxassetid://" .. skyIds[2]
    sky.SkyboxFt = "rbxassetid://" .. skyIds[3]
    sky.SkyboxLf = "rbxassetid://" .. skyIds[4]
    sky.SkyboxRt = "rbxassetid://" .. skyIds[5]
    sky.SkyboxUp = "rbxassetid://" .. skyIds[6]
    sky.Parent = Lighting
end

task.spawn(function()
    while true do
        pcall(applySky)
        task.wait(5)
    end
end)

print("[bundle] sky loop started")

-- ====================== CUSTOM HAND-DRAWN FONT ======================

local FONT = Font.new(
    "rbxasset://fonts/families/PatrickHand.json",
    Enum.FontWeight.Regular,
    Enum.FontStyle.Normal
)

local function applyFontTo(instance)
    if instance:IsA("TextLabel")
        or instance:IsA("TextButton")
        or instance:IsA("TextBox") then
        pcall(function()
            instance.FontFace = FONT
        end)
    end
end

local function setupPlayerFont(player)
    local function onCharacterAdded(character)
        for _, descendant in ipairs(character:GetDescendants()) do
            applyFontTo(descendant)
        end
        character.DescendantAdded:Connect(applyFontTo)
    end

    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
end

local playerGui = LOCAL_PLAYER:WaitForChild("PlayerGui")

for _, descendant in ipairs(playerGui:GetDescendants()) do
    applyFontTo(descendant)
end
playerGui.DescendantAdded:Connect(applyFontTo)

setupPlayerFont(LOCAL_PLAYER)

print("[bundle] hand-drawn font applied")

-- ====================== YELLOW-COLORED ICON SWAP ======================
-- Any ImageLabel / ImageButton whose ImageColor3 is yellow-ish gets its
-- Image forced to 96982876852417 and its color forced to white.

local REPLACE_TO_ID = "rbxassetid://96982876852417"
local WHITE         = Color3.fromRGB(255, 255, 255)

-- Yellow heuristic: strong red + strong green + weak blue, and R/G close together.
-- Covers pure yellow (255,255,0), gold (255,192,57), amber, etc.
local function isYellowish(c)
    if typeof(c) ~= "Color3" then return false end
    if c.R < 0.75 then return false end        -- red channel high
    if c.G < 0.6  then return false end        -- green channel reasonably high
    if c.B > 0.5  then return false end        -- blue channel must be low-ish
    if math.abs(c.R - c.G) > 0.35 then return false end -- R and G should be similar
    return true
end

local function swapYellowIcon(obj)
    if not (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) then return end

    local ok, col = pcall(function()
        return obj.ImageColor3
    end)
    if not ok then return end

    if isYellowish(col) then
        pcall(function()
            obj.Image = REPLACE_TO_ID
            obj.ImageColor3 = WHITE
        end)
        print("[bundle] yellow icon swapped:", obj:GetFullName())
    end
end

for _, d in ipairs(game:GetDescendants()) do
    swapYellowIcon(d)
end

game.DescendantAdded:Connect(function(obj)
    task.defer(swapYellowIcon, obj)
end)

print("[bundle] yellow-icon swap armed")

-- ====================== NEARBY DEATH SOUND ======================

local watched = setmetatable({}, { __mode = "k" })

local function getRoot(model)
    local root = model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Torso")

    if root and root:IsA("BasePart") then
        return root
    end
    return nil
end

local function playSound()
    local sound = Instance.new("Sound")
    sound.Name = "NearbyDeathSound"
    sound.SoundId = SOUND_ID
    sound.Volume = VOLUME
    sound.Looped = false
    sound.Parent = SoundService

    sound.Ended:Connect(function()
        sound:Destroy()
    end)

    Debris:AddItem(sound, 10)
    sound:Play()
end

local function watchModel(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")

    if not humanoid or watched[humanoid] then
        return
    end

    watched[humanoid] = true

    humanoid.Died:Connect(function()
        if model == LOCAL_PLAYER.Character then
            return
        end

        local deadRoot = getRoot(model)
        if not deadRoot then return end

        local character = LOCAL_PLAYER.Character
        local myRoot = character and getRoot(character)
        if not myRoot then return end

        local distance = (myRoot.Position - deadRoot.Position).Magnitude
        if distance <= RANGE then
            playSound()
        end
    end)
end

for _, instance in ipairs(Workspace:GetDescendants()) do
    if instance:IsA("Humanoid") and instance.Parent and instance.Parent:IsA("Model") then
        watchModel(instance.Parent)
    end
end

Workspace.DescendantAdded:Connect(function(instance)
    if instance:IsA("Humanoid") then
        local parent = instance.Parent
        if parent and parent:IsA("Model") then
            watchModel(parent)
        end
    end
end)

local function setupPlayer(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(0.2)
        watchModel(character)
    end)

    if player.Character then
        watchModel(player.Character)
    end
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

print("[bundle] death-sound watchers armed")

-- ====================== TEXTURE REPLACEMENT (loaded last) ======================

task.wait(2)

local function getAsset(url)
    local success, result = pcall(function()
        if writefile and isfile and getcustomasset then
            local fileName = "mc_" .. tostring(#url % 100000) .. ".asset"

            if not isfile(fileName) then
                local data = game:HttpGet(url)
                if data and #data > 80 then
                    writefile(fileName, data)
                end
            end

            local asset = getcustomasset(fileName)
            if asset and asset ~= "" then
                return asset
            end
        end

        return url
    end)

    return (success and result) or url
end

local Rules = {
    { ids = {7658055825}, url = "https://raw.githubusercontent.com/66buncer/Rivals-Pack-Assets/main/item_slot_3_blue_hollow.png" },
}

local IdMap = {}

for _, rule in ipairs(Rules) do
    local asset = getAsset(rule.url)
    for _, id in ipairs(rule.ids) do
        IdMap[tostring(id)] = asset
    end
end

local function apply(obj)
    if not obj then return end

    local function replace(property)
        local success, value = pcall(function()
            return obj[property]
        end)

        if not success or type(value) ~= "string" then
            return
        end

        local id = string.match(value, "%d+")
        if id and IdMap[id] then
            pcall(function()
                obj[property] = IdMap[id]
            end)
        end
    end

    if obj:IsA("Decal") or obj:IsA("Texture") then
        replace("Texture")
    elseif obj:IsA("MeshPart") then
        replace("TextureID")
    end
end

task.wait(1.5)

for _, descendant in ipairs(game:GetDescendants()) do
    task.spawn(apply, descendant)
end

game.DescendantAdded:Connect(function(obj)
    task.defer(apply, obj)
end)

print("[bundle] texture replacement done")
