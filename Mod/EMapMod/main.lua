--[[
Title: 
Author(s):  
Date: 
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/EMapMod/main.lua");
local EMapMod = commonlib.gettable("Mod.EMapMod");
------------------------------------------------------------
]]
NPL.load("(gl)Mod/EMapMod/MapBlock.lua");
local EMapMod = commonlib.inherit(commonlib.gettable("Mod.ModBase"),commonlib.gettable("Mod.EMapMod"));
local MapBlock = commonlib.gettable("Mod.EMapMod.MapBlock");

function EMapMod:ctor()
end

-- virtual function get mod name

function EMapMod:GetName()
	return "EMapMod"
end

-- virtual function get mod description 

function EMapMod:GetDesc()
	return "EMapMod is a plugin in paracraft"
end

function EMapMod:init()
	LOG.std(nil, "info", "EMapMod", "plugin initialized");
	MapBlock:init()
end

function EMapMod:OnLogin()
end
-- called when a new world is loaded. 

function EMapMod:OnWorldLoad()
	MapBlock:OnWorldLoad();
end
-- called when a world is unloaded. 

function EMapMod:OnLeaveWorld()
	MapBlock:OnLeaveWorld()
end

function EMapMod:OnDestroy()
end
