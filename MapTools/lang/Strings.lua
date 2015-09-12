--[[

Map Tools
by CaptainBlagbird
https://github.com/CaptainBlagbird

--]]

local strings = {
	MAPTOOLS_BINDING_CATEGORY_TITLE           = "|c70C0DEMap Tools|r",
	SI_BINDING_NAME_MAPTOOLS_BINDING_ZOOM_OUT = "Zoom all the way out",
	SI_BINDING_NAME_MAPTOOLS_BINDING_ZOOM_IN  = "Zoom all the way in",
	SI_BINDING_NAME_MAPTOOLS_BINDING_STEP_OUT = "Show higher level map",
	SI_BINDING_NAME_MAPTOOLS_BINDING_STEP_IN  = "Show lower level map |c777777- Mouse cursor has to be over the subzone map.|r",
}

for key, value in pairs(strings) do
   ZO_CreateStringId(key, value)
   SafeAddVersion(key, 1)
end