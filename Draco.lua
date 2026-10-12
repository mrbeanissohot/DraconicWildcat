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

local TEXTURE_URL = "https://github.com/mrbeanissohot/DraconicWildcat/blob/main/dragon_scales_gen.png"

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

local TEXTURE_PATH = cachePathFor(TEXTURE_URL)

---------------------------------------------------------------------
-- TEXTURE GENERATOR: draws red dragon scales with gold outlines and
-- saves it as a PNG in your workspace (fallback if download fails)
---------------------------------------------------------------------
local function generateScaleTexture(path)
	if isfile and isfile(path) then return true end
	if not (writefile and bit32) then return false end

	local W, N = 512, 32
	local cw = W / N
	local rh = cw / 2
	local rad = cw * 0.62
	local floor, sqrt = math.floor, math.sqrt

	local function pixel(x, y)
		local rowMax = floor((y + rad) / rh)
		local rowMin = floor((y - rad) / rh)
		for row = rowMax, rowMin, -1 do
			local cy = row * rh
			local off = (row % 2 == 1) and (cw / 2) or 0
			local col = floor((x - off) / cw + 0.5)
			local cx = col * cw + off
			local dx, dy = x - cx, y - cy
			local d = sqrt(dx * dx + dy * dy)
			if d <= rad then
				local t = d / rad
				if t > 0.92 then return 150, 105, 20 end -- dark gold edge
				if t > 0.80 then return 222, 175, 45 end -- gold outline
				local s = t / 0.80
				return floor(222 + (95 - 222) * s), floor(48 + (6 - 48) * s), floor(40 + (10 - 40) * s)
			end
		end
		return 70, 5, 8
	end

	local rows, a, b = {}, 1, 0
	for y = 0, W - 1 do
		local r = { 0 }
		local n = 1
		for x = 0, W - 1 do
			local pr, pg, pb = pixel(x + 0.5, y + 0.5)
			r[n + 1], r[n + 2], r[n + 3] = pr, pg, pb
			n = n + 3
		end
		for i = 1, n do
			a = (a + r[i]) % 65521
			b = (b + a) % 65521
		end
		rows[#rows + 1] = string.char(table.unpack(r))
		if y % 32 == 31 then task.wait() end
	end
	local raw = table.concat(rows)

	-- zlib stream made of uncompressed blocks
	local blocks, pos, L = {}, 1, #raw
	while pos <= L do
		local chunk = raw:sub(pos, pos + 65534)
		local len = #chunk
		local final = (pos + 65534 >= L) and 1 or 0
		local nlen = 65535 - len
		blocks[#blocks + 1] = string.char(final, len % 256, floor(len / 256), nlen % 256, floor(nlen / 256)) .. chunk
		pos = pos + 65535
	end

	local function be32(n)
		return string.char(floor(n / 16777216) % 256, floor(n / 65536) % 256, floor(n / 256) % 256, n % 256)
	end

	local zdata = "\120\1" .. table.concat(blocks) .. be32(b * 65536 + a)

	local crcTable = {}
	for i = 0, 255 do
		local c = i
		for _ = 1, 8 do
			if bit32.band(c, 1) == 1 then
				c = bit32.bxor(0xEDB88320, bit32.rshift(c, 1))
			else
				c = bit32.rshift(c, 1)
			end
		end
		crcTable[i] = c
	end

	local function crc32(s)
		local c = 0xFFFFFFFF
		for i = 1, #s do
			c = bit32.bxor(crcTable[bit32.band(bit32.bxor(c, s:byte(i)), 0xFF)], bit32.rshift(c, 8))
		end
		return bit32.bxor(c, 0xFFFFFFFF)
	end

	local function pngChunk(typ, data)
		return be32(#data) .. typ .. data .. be32(crc32(typ .. data))
	end

	local png = "\137PNG\r\n\26\n"
		.. pngChunk("IHDR", be32(W) .. be32(W) .. string.char(8, 2, 0, 0, 0))
		.. pngChunk("IDAT", zdata)
		.. pngChunk("IEND", "")

	if makefolder and isfolder and not isfolder("AWildcat") then
		pcall(makefolder, "AWildcat")
	end
	local ok = pcall(writefile, path, png)
	return ok
end

-- download the texture; fall back to generating it if that fails
if not download(TEXTURE_URL, TEXTURE_PATH) then
	if not generateScaleTexture(TEXTURE_PATH) then
		warn("[Replacer] could not download or generate texture")
	end
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

local TEXTURE = loadAsset(TEXTURE_PATH)
if not TEXTURE then warn("[Replacer] texture not loaded: " .. TEXTURE_PATH) end

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

local function setTexture(inst)
	if not TEXTURE then return end
	pcall(function()
		if inst:IsA("MeshPart") then inst.TextureID = TEXTURE end
		if inst:IsA("SpecialMesh") then inst.TextureId = TEXTURE end
	end)
end

-- put the scale texture on a swapped mesh and keep it there
local function applyTexture(inst)
	setTexture(inst)
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
				if TEXTURE and inst[prop] ~= TEXTURE then
					pcall(function() inst[prop] = TEXTURE end)
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
			applyTexture(inst)
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
