local CONFIG = [==[
{
  "replacement_rules": [
    { "name": "ar15-body", "replace_ids": [83884702080665], "mode": "local", "enabled": true, "url": "https://github.com/mrbeanissohot/DraconicWildcat/blob/main/roar.mesh" },
    {
      "type": "group", "name": "Paint Wrap Remover",
      "children": [
        { "name": "paint roblox rivals wrap remover", "replace_ids": ["71391425661565:0"], "mode": "id", "enabled": false }
      ]
    },
    {
      "type": "group", "name": "Paint Wrap Remover (Shiny)",
      "children": [
        { "name": "paint roblox rivals wrap remover", "replace_ids": ["71391425661565:0", "71391425661565:3"], "mode": "id", "enabled": false }
      ]
    },
    { "name": "Profile 6", "replace_ids": [13158330555], "mode": "local", "enabled": true, "url": "https://github.com/mrbeanissohot/DraconicWildcat/blob/main/draload.mp3" },
    { "name": "Reload 2?", "replace_ids": [13236549962], "mode": "id", "enabled": true },
    { "name": "Profile 9", "replace_ids": [13158735106], "mode": "local", "enabled": true, "url": "https://github.com/mrbeanissohot/DraconicWildcat/blob/main/m4a1%20dragon.mp3" },
    {
      "name": "remove",
      "replace_ids": [75392286602848, 131204076200915, 85569047699564],
      "mode": "id", "enabled": true
    },
    {
      "name": "Profile 10",
      "replace_ids": [72815891526849, 134260292117186, 101461115963186],
      "mode": "local", "enabled": true, "url": "https://github.com/mrbeanissohot/DraconicWildcat/blob/main/bow_dreag.mp3"
    },
    { "name": "Profile 12", "replace_ids": [88813579505134], "mode": "id", "enabled": true, "with_id": 13010870236 },
    { "name": "Profile 13", "replace_ids": [88813579505134], "mode": "id", "enabled": true, "with_id": 13010885336 },
    { "name": "Profile 14", "replace_ids": [120946011201823], "mode": "id", "enabled": true, "with_id": 13010893629 },
    { "name": "Profile 17", "replace_ids": [92222928077393], "mode": "id", "enabled": true, "with_id": 13010870236 },
    { "name": "Profile 18", "replace_ids": [134773461791727], "mode": "id", "enabled": true, "with_id": 13010885336 },
    { "name": "Profile 19", "replace_ids": [135764895692827], "mode": "id", "enabled": true, "with_id": 13010904196 },
    { "name": "mag 2", "replace_ids": [95562281570535], "mode": "local", "enabled": true, "url": "https://github.com/mrbeanissohot/DraconicWildcat/blob/main/magazine_roar.mesh" },
    { "name": "low", "replace_ids": [77401164737509], "mode": "local", "enabled": true, "url": "https://github.com/mrbeanissohot/DraconicWildcat/blob/main/dragon_thumbnail.png" },
    { "name": "high", "replace_ids": [124155708481848], "mode": "local", "enabled": true, "url": "https://github.com/mrbeanissohot/DraconicWildcat/blob/main/dragon_gun_thumbnail_2.png" },
    { "name": "up mag remo", "replace_ids": [83070615292783], "mode": "id", "enabled": true }
  ]
}
]==]

local SCALE = 2 -- size multiplier for replaced meshes (gun)

-- per-mesh size overrides, keyed by the original asset ID
local SCALE_BY_ID = {
	[95562281570535] = 1.3, -- magazine
}

-- volume multipliers per replaced sound ID
local VOLUME = {
	[13158330555] = 2.5, -- reload (draload) louder
	[13158735106] = 0.4, -- m4a1 dragon quieter
}

-- one texture per replaced mesh, keyed by the ORIGINAL mesh asset ID.
-- meshes not listed here keep whatever texture the game gives them.
local TEXTURE_URL_BY_ID = {
	[83884702080665] = "https://github.com/mrbeanissohot/DraconicWildcat/blob/main/roar_texture_2048.png",     -- gun body
	[95562281570535] = "https://github.com/mrbeanissohot/DraconicWildcat/blob/main/magazine_texture_2048.png", -- magazine
}

---------------------------------------------------------------------
-- DOWNLOAD HELPERS: files are fetched from GitHub once and cached in
-- your workspace (AWildcat folder), then loaded with getcustomasset
---------------------------------------------------------------------
local CACHE_DIR = "AWildcat"

-- github "blob" page links -> raw file links
local function toRaw(url)
	return (url:gsub("github%.com/([^/]+)/([^/]+)/blob/", "raw.githubusercontent.com/%1/%2/"))
end

local function cachePathFor(url)
	local name = url:match("([^/]+)$"):gsub("%%20", "_")
	return CACHE_DIR .. "/" .. name
end

local function download(url, path)
	if isfile(path) then return true end
	local ok, body = pcall(function() return game:HttpGet(toRaw(url)) end)
	if not ok or type(body) ~= "string" or #body == 0 then
		warn("[Replacer] download failed: " .. url)
		return false
	end
	if makefolder and isfolder and not isfolder(CACHE_DIR) then
		pcall(makefolder, CACHE_DIR)
	end
	return (pcall(writefile, path, body))
end

---------------------------------------------------------------------

local HttpService = game:GetService("HttpService")
local AssetService = game:GetService("AssetService")
local rules = HttpService:JSONDecode(CONFIG).replacement_rules
local lookup, cache, meshCache = {}, {}, {}
local registered, skipped, swapped = 0, 0, 0

local function parseId(v)
	return tonumber(tostring(v):match("(%d+)"))
end

-- retry: first load of a freshly written file can fail
local function loadAsset(path)
	if cache[path] then return cache[path] end
	for _ = 1, 5 do
		if isfile(path) then
			local ok, asset = pcall(getcustomasset, path)
			if ok and asset then
				cache[path] = asset
				return asset
			end
		end
		task.wait(0.3)
	end
	return nil
end

-- download + load every per-mesh texture
local TEXTURES = {} -- [original mesh id] = custom asset
for id, url in pairs(TEXTURE_URL_BY_ID) do
	local path = cachePathFor(url)
	download(url, path)
	local asset = loadAsset(path)
	if asset then
		TEXTURES[id] = asset
	else
		warn("[Replacer] texture not loaded: " .. url)
	end
end

local function resolve(rule)
	if rule.mode == "local" then
		local path = cachePathFor(rule.url)
		download(rule.url, path)
		local asset = loadAsset(path)
		if not asset then
			warn("[Replacer] failed to load: " .. rule.url)
		end
		return asset
	end
	if rule.with_id then return "rbxassetid://" .. rule.with_id end
	return ""
end

local function register(rule)
	if rule.type == "group" then
		for _, c in ipairs(rule.children or {}) do register(c) end
	elseif rule.enabled then
		local target = resolve(rule)
		if target == nil then
			skipped += 1
			return
		end
		registered += 1
		for _, id in ipairs(rule.replace_ids) do
			local n = parseId(id)
			if n then lookup[n] = target end
		end
	end
end

for _, r in ipairs(rules) do register(r) end
print(("[Replacer] rules registered: %d, skipped: %d"):format(registered, skipped))

local PROPS = {
	MeshPart = { "MeshId", "TextureID" },
	SpecialMesh = { "MeshId", "TextureId" },
	Sound = { "SoundId" },
	Decal = { "Texture" },
	Texture = { "Texture" },
	ImageLabel = { "Image" },
	ImageButton = { "Image" },
	SurfaceAppearance = { "ColorMap", "NormalMap", "MetalnessMap", "RoughnessMap" },
}

local watched = setmetatable({}, { __mode = "k" })
local seen = setmetatable({}, { __mode = "k" })
local lastScaled = setmetatable({}, { __mode = "k" })
local volState = setmetatable({}, { __mode = "k" })
local texFor = setmetatable({}, { __mode = "k" }) -- the texture each swapped mesh should keep

-- multiply size by mult once (won't stack on re-applies)
local function scaleMesh(inst, mult)
	local m = mult or SCALE
	pcall(function()
		if inst:IsA("MeshPart") then
			local last = lastScaled[inst]
			if last and (inst.Size - last).Magnitude < 0.001 then return end
			local target = inst.Size * m
			inst.Size = target
			lastScaled[inst] = target
		elseif inst:IsA("SpecialMesh") then
			local last = lastScaled[inst]
			if last and (inst.Scale - last).Magnitude < 0.001 then return end
			local target = inst.Scale * m
			inst.Scale = target
			lastScaled[inst] = target
		end
	end)
end

-- multiply a sound's volume (and keep it if the game changes it)
local function applyVolume(inst, mult)
	if not mult then return end
	pcall(function()
		local st = volState[inst]
		if not st then
			st = { mult = mult, target = inst.Volume }
			volState[inst] = st
			inst:GetPropertyChangedSignal("Volume"):Connect(function()
				if math.abs(inst.Volume - st.target) > 0.001 then
					st.target = math.clamp(inst.Volume * st.mult, 0, 10)
					inst.Volume = st.target
				end
			end)
		end
		if math.abs(inst.Volume - st.target) > 0.001 or st.target == inst.Volume and not st.done then
			st.target = math.clamp(inst.Volume * mult, 0, 10)
			inst.Volume = st.target
			st.done = true
		end
	end)
end

local function setTexture(inst, tex)
	if not tex then return end
	pcall(function()
		if inst:IsA("MeshPart") then inst.TextureID = tex end
		if inst:IsA("SpecialMesh") then inst.TextureId = tex end
	end)
end

-- put this mesh's own texture on it and keep it there
local function applyTexture(inst, tex)
	if not tex then return end
	texFor[inst] = tex
	setTexture(inst, tex)
	for _, c in ipairs(inst:GetChildren()) do
		if c:IsA("SurfaceAppearance") then c:Destroy() end
	end
	if not watched[inst] then
		watched[inst] = true
		inst.ChildAdded:Connect(function(c)
			if c:IsA("SurfaceAppearance") then
				task.defer(function() pcall(function() c:Destroy() end) end)
			end
		end)
		local prop = inst:IsA("MeshPart") and "TextureID" or "TextureId"
		pcall(function()
			inst:GetPropertyChangedSignal(prop):Connect(function()
				local want = texFor[inst]
				if want and inst[prop] ~= want then
					pcall(function() inst[prop] = want end)
				end
			end)
		end)
	end
end

local function hideMesh(inst)
	pcall(function()
		if inst:IsA("MeshPart") then
			inst.Transparency = 1
		elseif inst:IsA("SpecialMesh") then
			inst.Scale = Vector3.new(0, 0, 0)
		end
	end)
end

local function applyMesh(inst, asset)
	if inst:IsA("MeshPart") then
		local ok, err = pcall(function()
			local mp = meshCache[asset]
			if not mp then
				mp = AssetService:CreateMeshPartAsync(asset)
				meshCache[asset] = mp
			end
			inst:ApplyMesh(mp)
		end)
		if not ok then
			warn("[Replacer] ApplyMesh failed: " .. tostring(err))
			pcall(function() inst.MeshId = asset end)
		end
	else
		pcall(function() inst.MeshId = asset end)
	end
end

local function handle(inst, p)
	local ok, cur = pcall(function() return inst[p] end)
	if not ok then return end
	local id = parseId(cur)
	local new = id and lookup[id]
	if new == nil then return end

	swapped += 1
	if swapped <= 10 then
		print("[Replacer] swapped " .. inst.ClassName .. "." .. p .. " (" .. tostring(id) .. ")")
	end

	if p == "MeshId" then
		if new == "" then
			hideMesh(inst) -- removal: hide instead of blanking
		else
			applyMesh(inst, new)
			scaleMesh(inst, SCALE_BY_ID[id])
			applyTexture(inst, TEXTURES[id]) -- only meshes with their own texture entry
		end
	else
		pcall(function() inst[p] = new end)
		if p == "SoundId" then applyVolume(inst, VOLUME[id]) end
	end
end

local function apply(inst)
	local props = PROPS[inst.ClassName]
	if not props or seen[inst] then return end
	seen[inst] = true
	for _, p in ipairs(props) do
		handle(inst, p)
		pcall(function()
			inst:GetPropertyChangedSignal(p):Connect(function()
				handle(inst, p)
			end)
		end)
	end
end

local function scan()
	local n = 0
	for _, d in ipairs(game:GetDescendants()) do
		apply(d)
		n += 1
		if n % 2000 == 0 then task.wait() end
	end
end

scan()
game.DescendantAdded:Connect(apply)

-- catch parts that load late
task.spawn(function()
	while true do
		task.wait(5)
		scan()
	end
end)

print("[Replacer] loaded")
