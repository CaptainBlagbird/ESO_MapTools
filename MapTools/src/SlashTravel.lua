--[[

Map Tools
by CaptainBlagbird
https://github.com/CaptainBlagbird

--]]


-- Slash command function for traveling to group leader/member
local function JumpToPlayer(name)
	-- Argument specified --> Jump to player with that name
	if name ~= "" then
		if IsFriend(name) then
			JumpToFriend(name)
		elseif IsPlayerInGroup(name) then
			JumpToGroupMember(name)
		else
			JumpToGuildMember(name)
		end
		return
	end
	
	-- No argument specified --> Jump to group leader (or to other player if in a group of 2)
	if GetGroupSize() == 2 and IsUnitGroupLeader("player") then
		name = GetUnitName("group1")
		if name == GetUnitName("player") then
			name = GetUnitName("group2")
		end
		JumpToGroupMember(name)
	else  -- Group has at least 2 members and player isn't leader
		JumpToGroupLeader()
	end
end
SLASH_COMMANDS["/tp"] = JumpToPlayer