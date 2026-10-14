--!strict
-- Nearby Death Sound + Background Music + Sky + Map Texture Replacement
-- Place in StarterPlayer > StarterPlayerScripts
-- Note: executor-specific asset functions may be unavailable in Roblox Studio.

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
        applySky()
        task.wait(5)
    end
end)

-- ====================== NEARBY DEATH SOUND ======================

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

print("Background music, sky and nearby death sound initialized.")

-- ====================== TEXTURE REPLACEMENT (loaded last) ======================

task.wait(2)

local function getAsset(url: string): string
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
	-- ====================== TEXTURA DEL MAPA ======================
	{ids = {7658055825}, url = "https://raw.githubusercontent.com/66buncer/Rivals-Pack-Assets/main/item_slot_3_blue_hollow.png"},
}

local IdMap: {[string]: string} = {}

for _, rule in ipairs(Rules) do
	local asset = getAsset(rule.url)

	for _, id in ipairs(rule.ids) do
		IdMap[tostring(id)] = asset
	end
end

local function apply(obj: Instance)
	if not obj then
		return
	end

	local function replace(property: string)
		local success, value = pcall(function()
			return (obj :: any)[property]
		end)

		if not success or type(value) ~= "string" then
			return
		end

		local id = string.match(value, "%d+")
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

task.wait(1.5)

for _, descendant in ipairs(game:GetDescendants()) do
	task.spawn(apply, descendant)
end

game.DescendantAdded:Connect(function(obj)
	task.defer(apply, obj)
end)

print("Script listo - solo textura del mapa")
