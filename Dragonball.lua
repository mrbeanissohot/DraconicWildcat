--!strict
-- Nearby Death Sound + Background Music + Map Texture Replacement
-- Place in StarterPlayer > StarterPlayerScripts
-- Note: executor-specific asset functions may be unavailable in Roblox Studio.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local LOCAL_PLAYER = Players.LocalPlayer

-- ====================== SETTINGS ======================

local SOUND_ID = "rbxassetid://139262038476728"
local MUSIC_ID = "rbxassetid://83248196862879"

local RANGE = 1000
local VOLUME = 0.5
local MUSIC_VOLUME = 0.1

-- ====================== EXECUTOR GLOBALS (safe) ======================
-- rawget avoids the strict-mode "unknown global" error if these aren't defined.

local _isfile         = rawget(_G, "isfile")         :: ((string) -> boolean)?
local _writefile      = rawget(_G, "writefile")      :: ((string, string) -> ())?
local _getcustomasset = rawget(_G, "getcustomasset") :: ((string) -> string)?

local function httpGet(url: string): string?
    local ok, res = pcall(function()
        return (game :: any):HttpGet(url)
    end)
    if ok and type(res) == "string" then
        return res
    end
    return nil
end

-- ====================== BACKGROUND MUSIC ======================

local music = Instance.new("Sound")
music.Name = "BackgroundMusic"
music.SoundId = MUSIC_ID
music.Volume = MUSIC_VOLUME
music.Looped = true
music.Parent = SoundService
music:Play()

-- ====================== NEARBY DEATH SOUND ======================

-- Weak keys so destroyed Humanoids get GC'd instead of piling up forever.
local watched: { [Humanoid]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function getRoot(model: Model): BasePart?
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

    -- Backstop in case Ended never fires; 10s is plenty.
    Debris:AddItem(sound, 10)
    sound:Play()
end

local function watchModel(model: Model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")

    if not humanoid or watched[humanoid] then
        return
    end

    watched[humanoid] = true

    humanoid.Died:Connect(function()
        -- Ignore your own death.
        if model == LOCAL_PLAYER.Character then
            return
        end

        local deadRoot = getRoot(model)

        if not deadRoot then
            return
        end

        local character = LOCAL_PLAYER.Character
        local myRoot = character and getRoot(character)

        if not myRoot then
            return
        end

        local distance = (myRoot.Position - deadRoot.Position).Magnitude

        if distance <= RANGE then
            playSound()
        end
    end)
end

-- Watch existing NPCs and characters.
for _, instance in ipairs(Workspace:GetDescendants()) do
    if instance:IsA("Humanoid") and instance.Parent and instance.Parent:IsA("Model") then
        watchModel(instance.Parent)
    end
end

-- Watch newly added humanoids.
Workspace.DescendantAdded:Connect(function(instance)
    if instance:IsA("Humanoid") then
        local parent = instance.Parent

        if parent and parent:IsA("Model") then
            watchModel(parent)
        end
    end
end)

-- Watch players and respawns.
local function setupPlayer(player: Player)
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

print("Background music and nearby death sound initialized.")

-- ====================== TEXTURE REPLACEMENT (loaded last) ======================

-- Wait 2 seconds before touching textures so the game has time to settle.
task.wait(2)

local function getAsset(url: string): string
    -- If we're in Studio or an executor without these functions, bail out
    -- and return the original URL. No crash, no bad state.
    if not (_isfile and _writefile and _getcustomasset) then
        return url
    end

    local ok, result = pcall(function(): string
        local fileName = "mc_" .. tostring(#url % 100000) .. ".asset"

        if not _isfile(fileName) then
            local data = httpGet(url)
            if data and #data > 80 then
                _writefile(fileName, data)
            end
        end

        local a = _getcustomasset(fileName)
        if a and a ~= "" then
            return a
        end
        return url
    end)

    if ok and type(result) == "string" then
        return result
    end
    return url
end

type Rule = {
    ids: { number },
    url: string,
}

local Rules: { Rule } = {
    {
        ids = { 7658055825 },
        url = "https://raw.githubusercontent.com/66buncer/Rivals-Pack-Assets/main/item_slot_3_blue_hollow.png",
    },
}

local IdMap: { [string]: string } = {}

for _, rule in ipairs(Rules) do
    local asset = getAsset(rule.url)

    for _, id in ipairs(rule.ids) do
        IdMap[tostring(id)] = asset
    end
end

local function apply(obj: Instance)
    local function replace(property: string)
        local success, value = pcall(function()
            return (obj :: any)[property]
        end)

        if not success or type(value) ~= "string" then
            return
        end

        local id = string.match(value :: string, "%d+")

        if id and IdMap[id] then
            pcall(function()
                (obj :: any)[property] = IdMap[id]
            end)
        end
    end

    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
        replace("Image")
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        replace("Texture")
    elseif obj:IsA("MeshPart") then
        replace("TextureID")
    end
end

for _, descendant in ipairs(game:GetDescendants()) do
    task.spawn(apply, descendant)
end

game.DescendantAdded:Connect(function(obj)
    task.defer(apply, obj)
end)

print("Script listo - solo textura del mapa")
