--[[

Map Tools
by CaptainBlagbird
https://github.com/CaptainBlagbird

--]]

-- Addon info
MapTools.MapPing = {}
MapTools.MapPing.name = "MapPing"

-- Constatnts
local MAP_INDEX_CYRODIIL = 14


local function GetZoneAndSubzone()
	return select(3,(GetMapTileTexture()):lower():find("maps/([%w%-]+/[%w%-]+_[%w%-]+)"))
end

local function isMapPointSet(x,y)
	if x==0 and y==0 then
		return false
	else
		return true
	end
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

-- Function that tries to find a keep mentioned in text
local function FindKeep(text)
	-- Check the text for all the keywords (pattern)
	text = string.lower(text)
	for pattern, keepId in pairs(MapTools.keepPatterns) do
		if string.match(text, "%?") == nil then
			pattern = string.lower(pattern.."[a-z]*")
			local found_match = string.match(text, pattern)
			if found_match ~= nil then
				-- Return the keep ID for the first matching keyword
				return keepId, found_match
			end
		end
	end
end

-- Event handler function for EVENT_CHAT_MESSAGE_CHANNEL
local function OnChatMessage(eventCode, channel, fromName, text, isCustomerService)
	if GetZoneAndSubzone() ~= "cyrodiil/ava_whole" then return end
	
	-- Only continue if the sender is the group leader and no rally point is set
	if channel == CHAT_CHANNEL_PARTY and fromName == GetRawUnitName(GetGroupLeaderUnitTag()) then
		if isMapPointSet(GetMapRallyPoint()) then return end
	else
		return
	end
	
	-- Try to find a keep
	local keepId, found_match = FindKeep(text)
	if keepId ~= nil then
		-- Get keep info and add waypoint on keep location
		local pinType, x, y = GetKeepPinInfo(keepId, GetBattlegroundContext())
		PingMap(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_TYPE_LOCATION_CENTERED, x, y)
		-- Check if waypoint was set
		if isMapPointSet(GetMapPlayerWaypoint()) then
			d("Map ping: waypoint (auto '"..found_match.."')")
		end
	end
end
EVENT_MANAGER:RegisterForEvent(MapTools.MapPing.name, EVENT_CHAT_MESSAGE_CHANNEL, OnChatMessage)

local function SlashPing(text)
	if text == "" then
		local isWpSet = isMapPointSet(GetMapPlayerWaypoint())
		RemovePlayerWaypoint()
		if isWpSet then d("Map ping: Removed") end
	else
		-- Try to find a keep
		local keepId, found_match = FindKeep(text)
		if keepId ~= nil then
			-- Open Cyrodiil map
			ZO_WorldMap_ShowWorldMap()
			ZO_WorldMap_SetMapByIndex(MAP_INDEX_CYRODIIL)
			zo_callLater(function() ZO_WorldMapZoom_OnMouseWheel(-25) end, 20)
			-- Get keep info and add waypoint on keep location
			local pinType, x, y = GetKeepPinInfo(keepId, GetBattlegroundContext())
			PingMap(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_TYPE_LOCATION_CENTERED, x, y)
			-- Check if waypoint was set
			if isMapPointSet(GetMapPlayerWaypoint()) then
				d("Map ping: waypoint (auto '"..found_match.."')")
			end
		end
	end
end
SLASH_COMMANDS["/ping"] = SlashPing

-- Display map ping notification if it didn't come from the user, remove waypoint if the new map ping is a rally point
local function EventMapPing(eventCode, pingEventType, pingType, pingTag, offsetX, offsetY, isLocalPlayerOwner)
	if isLocalPlayerOwner then return end
	if pingType ~= MAP_PIN_TYPE_RALLY_POINT then return end
	RemovePlayerWaypoint()
	
	if pingEventType == PING_EVENT_ADDED then
		d("Map ping: "..pingTag)
	elseif pingEventType == PING_EVENT_REMOVED then
		d("Map ping "..pingTag.." removed")
	end
end
EVENT_MANAGER:RegisterForEvent(MapTools.MapPing.name, EVENT_MAP_PING, EventMapPing)