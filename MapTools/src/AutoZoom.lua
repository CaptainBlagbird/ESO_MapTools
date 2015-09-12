--[[

Map Tools
by CaptainBlagbird
https://github.com/CaptainBlagbird

--]]

-- Addon info
MapTools.AutoZoom = {}
MapTools.AutoZoom.name = "AutoZoom"

-- Constatnts
local NUM_KEEPS = 144  -- GetNumKeeps() returns 93 which isn't correct


local function GetZoneAndSubzone()
	return select(3,(GetMapTileTexture()):lower():find("maps/([%w%-]+/[%w%-]+_[%w%-]+)"))
end

-- Function to get the correct battleground context
local function GetBattlegroundContext()
	local bgquery = BGQUERY_UNKNOWN 
	if GetCurrentCampaignId() == GetAssignedCampaignId() then
		bgquery = BGQUERY_ASSIGNED_CAMPAIGN
	else
		bgquery = BGQUERY_LOCAL 
	end
	return bgquery
end

-- Function to find closest keep being attacked, returns nil if no keep is being attacked
local function GetNearestKeepUnderAttack()
	local nearestKeepUnderAttack
	
	-- Check every keep if under attack and remember the closest one
	for keep=1, NUM_KEEPS, 1 do
		if GetKeepUnderAttack(keep, GetBattlegroundContext()) then
			local _, x, y = GetKeepPinInfo(keep, GetBattlegroundContext())
			local x2, y2, _ = GetMapPlayerPosition("player")
			local dx = x2-x
			local dy = y2-y
			local dist = math.sqrt(dx*dx+dy*dy)
			if nearestKeepUnderAttack == nil or nearestKeepUnderAttack.distance < dist then
				nearestKeepUnderAttack = {id=keep, distance=dist}
			end
		end
	end
	
	return nearestKeepUnderAttack
end

-- Table to convert normalized Cyrodiil distance to mouse wheel zoom steps
local max_dists = {
	-- [zoom] = distance
	[00] = 0.052,
	[01] = 0.054,
	[02] = 0.057,
	[03] = 0.059,
	[04] = 0.061,
	[05] = 0.064,
	[06] = 0.068,
	[07] = 0.071,
	[08] = 0.075,
	[09] = 0.078,
	[10] = 0.084,
	[11] = 0.089,
	[12] = 0.095,
	[13] = 0.102,
	[14] = 0.111,
	[15] = 0.120,
	[16] = 0.131,
	[17] = 0.147,
	[18] = 0.162,
	[19] = 0.186,
	[20] = 0.216,
	[21] = 0.252,
}

-- Returns the required mouse wheel zoom steps to have the location at x,y in Cyrodiil visible on the map
local function GetRequiredZoom(x, y)
	local x2, y2, _ = GetMapPlayerPosition("player")
	local dx = x2-x
	local dy = y2-y
	
	-- We only need the larger rectangular distance to get the required zoom
	local dist = math.abs(dx)
	if math.abs(dy) > dist then dist = math.abs(dy) end
	
	-- Convert the distance to zoom steps using the table
	local zoom = 0
	for i=0, 25, 1 do
		local max_dist = max_dists[i]
		if max_dist == nil then
			zoom = -25
		elseif max_dist > dist then
			break
		end
		zoom = -i
	end
	return zoom
end

-- Event handler function for EVENT_RETICLE_HIDDEN_UPDATE
local function OnReticleHidden(eventCode, isReticleHidden)
	if not isReticleHidden then return end
	if ZO_WorldMap:IsHidden() then return end
	if GetZoneAndSubzone() ~= "cyrodiil/ava_whole" then return end
	
	local zoom
	
	-- Get required zoom for group rally point
	local xr, yr = GetMapRallyPoint()
	if xr ~= 0 or yr ~= 0 then
		zoom = GetRequiredZoom(xr, yr)
	end
	
	-- Get required zoom for group leader
	local xg, yg, _ = GetMapPlayerPosition(GetGroupLeaderUnitTag())
	if xg ~= 0 or yg ~= 0 then
		local z = GetRequiredZoom(xg, yg)
		if zoom == nil or zoom > z then zoom = z end
	end
	
	-- Get required zoom for waypoint
	local xw, yw = GetMapPlayerWaypoint()
	if xw ~= 0 or yw ~= 0 then
		local z = GetRequiredZoom(xw, yw)
		if zoom == nil or zoom > z then zoom = z end
	end
	
	-- Check if current keep is being attacked
	if zoom == nil then
		nearestKeepUnderAttack = GetNearestKeepUnderAttack()
		if nearestKeepUnderAttack == nil or nearestKeepUnderAttack.distance >= max_dists[0] then
			zoom = -25
		else
			zoom = 0
		end
	end
	
	-- Finally zoom the map out so every thing is visible
	ZO_WorldMapZoom_OnMouseWheel(zoom)
end
EVENT_MANAGER:RegisterForEvent(MapTools.AutoZoom.name, EVENT_RETICLE_HIDDEN_UPDATE, OnReticleHidden)