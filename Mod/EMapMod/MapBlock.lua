--[[
Title: MapBlock
Author(s):  Bl.Chock, refactored by LiXizhi 2017.11.2 (Still needs factoring)
Date: 2017年4月1日
Desc: map block item
## review by LXizhi 
- is_show_in_list added
- TODO: this mod should be non-aggressive and register as few block types as possible. 

use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/EMapMod/MapBlock.lua");
local MapBlock = commonlib.gettable("Mod.EMapMod.MapBlock");
------------------------------------------------------------
]]
NPL.load("(gl)script/apps/Aries/Creator/Game/blocks/block_types.lua");
NPL.load("(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua");
local block_types = commonlib.gettable("MyCompany.Aries.Game.block_types");
local MapBlock = commonlib.inherit(nil,commonlib.gettable("Mod.EMapMod.MapBlock"));
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local CommandManager  = commonlib.gettable("MyCompany.Aries.Game.CommandManager");
MapBlock.ID = 2333 -- 彩色地图方块
MapBlock.IDM = 2339 -- id上限

local Materials = {
{ 
	id = 2333, -- 虚拟校园地图方块
	is_show_in_list = false,
	name = "MapBlock",
	item_class="ItemColorBlock", -- 这个决定了颜色方块显示(来自彩色方块10)
	text = "虚拟校园地图方块",
	disable_gen_icon="true",
	icon="Texture/blocks/items/color_block.png",
	texture="Texture/blocks/colorblock.png",
	color_data="true",
	obstruction="true",
	solid="true",
	cubeMode="true",
	mapcolor="#f88633",
	-- 这个决定了是否能存储entity(来自物理模型22)
	-- class="BlockModel",
	-- entity_class="EntityBlockModel",
	-- hasAction="false",
	-- class="BlockCommandBlock",
	-- entity_class="EntityCommandBlock",
},
{ 
	id = 2334, -- 预留地图方块(51)
	is_show_in_list = false,
	name = "m_magma",
	text = "虚拟校园方块-预留",
	mapcolor = "#f88633",
	obstruction = "true",
	solid = "true",
	icon = "Texture/blocks/items/lava_flow.png",
	light="true",
	categoryID="5",
	texture = "Texture/blocks/lava/lava_fps10_a010.png"
},
{  	
	id = 2335, -- 砖头(51)
	is_show_in_list = false,
	name = "m_brick",
	text = "虚拟校园方块-砖头",
	mapcolor = "#ebdcb3",
	step_sound = "sand",
	material = "sand",
	obstruction = "true",
	solid = "true",
	icon = "Texture/blocks/items/sand.png",
	texture = "Texture/blocks/sand.png"
},
{  	
	id = 2336, -- 马路(241/180)
	is_show_in_list = false,
	name = "m_highway",
	text = "虚拟校园方块-马路",
	mapcolor = "#524630",
	step_sound = "stone",
	material = "sand",
	obstruction = "false",
	template="carpet",
	icon = "Texture/blocks/items/carpet_gray.png",
	texture = "Texture/blocks/wool_colored_gray.png"
},
{  	
	id = 2337, -- 水围石(185/4)
	is_show_in_list = false,
	name = "m_wstone",
	class = "BlockSlab",
	item_class = "ItemSlab",
	text = "虚拟校园方块-水围石",
	mapcolor = "#88572f",
	step_sound = "wood",
	obstruction = "true",
	modelName="slab",
	shape="slab",
	blockcamera="true",
	customModel="true",
	template="DataOnlyTwo",
	icon = "Texture/blocks/items/slab_jungle.png",
	texture = "Texture/blocks/planks_jungle.png"
},
{  
	id = 2338, -- 动态水(75)
	is_show_in_list = false,
	name = "m_water",
	class = "BlockLiquidFlow",
	text = "虚拟校园方块-水",
	texture = "Texture/blocks/water/water_fps10_a009.png",
	speedReduction = "0.4",
	mapcolor = "#ddeaf0",
	associated_blockid = "76",
	material = "water",
	normalMap = "Texture/ripple/WaterBumpMap.dds",
	disable_gen_icon = "true",
	categoryID = "8",
	liquid="true",
	blendedTexture="true",
	transparent="true"
},
{  
	id = 2339, -- 水(76)
	is_show_in_list = false,
	name = "m_waterStill",
	class = "BlockLiquidStill",
	text = "虚拟校园方块-静态水",
	texture = "Texture/blocks/water/water_fps10_a009.png",
	speedReduction = "0.4",
	mapcolor = "#ddeaf0",
	associated_blockid = "75",
	material = "water",
	normalMap = "Texture/ripple/WaterBumpMap.dds",
	disable_gen_icon = "true",
	categoryID = "8",
	liquid="true",
	blendedTexture="true",
	transparent="true"
},
}

-- 百度地图水的像素颜色
local BaiduWater = {2749,2750,2765,2766,2494,2495,2509,2510,3054,3055,3037,3038,3039}

function MapBlock:ctor()
end

function MapBlock:init()
	LOG.std(nil, "info", "MapBlock", "init");
	self:initMaterial()
end

function MapBlock:OnWorldLoad()
	if(self.isInited) then
		return 
	end
	self.isInited = true;
end

-- function MapBlock:DB()
-- 	return DBStore.GetInstance():MapDB()
-- end

function MapBlock:OnLeaveWorld()
	-- self:DB():flush({})
end

-- 添加地图模块(isMaterial为true则直接加载定义的id，否则加载彩色方块)
function MapBlock:addBlock(spx,spy,spz,color,isUpdate,isMaterial)
	if ComVar.DrawAllMap then return true end
	local curid = BlockEngine:GetBlockId(spx,spy,spz);
	if curid then curid = tonumber(curid) end -- 获取当前方块id
	local function insertBlock()
		if isMaterial then
			BlockEngine:SetBlock(spx, spy, spz, color)
		else
			if curid > MapBlock.ID and curid <= MapBlock.IDM then return true end
			-- baidu color:167,192,223 [2749/2750/2765/2766] ctrl + T 取方块位置并到剪贴板
			if ComVar.drawWater then
				local setWater = nil
				if ComVar.usingMap == "OSM" and color == 3037 then setWater = true end
				if ComVar.usingMap == "BAIDU" then
					for k,c in pairs(BaiduWater) do
						if c == color then setWater = true; break; end
					end
				end
				if setWater then -- 水的颜色
					BlockEngine:SetBlock(spx, spy, spz, 2339)
					return true
				end
			end
			BlockEngine:SetBlock(spx,spy,spz, MapBlock.ID, color) -- , nil, data
		end
		-- self:DB():insertOne(nil, {world=DBStore.GetInstance().worldName,x=spx,y=spy,z=spz,type="map"})
	end
	if isUpdate then -- 为假时将不进入更新模式，而是全部重新绘制，为真时更新地图元素，不覆盖非地图元素
		if isUpdate == "fill" then -- 填充模式 填充非地图的草地模块
			if self:isMap(curid,true) then
				self:delete(spx,spy,spz)
				insertBlock()
				return true
			end
		else -- 更新模式
			if self:isMap(curid) then
				self:delete(spx,spy,spz)
				insertBlock()
				return true
			end
		end
		return false
	end
	insertBlock()
	-- local data = {attr={},{name="cmd","m"}} -- filename="Mod/EMapMod/textures/nil.fbx"
end

-- {attr={filename="Mod/EMapMod/textures/nil.fbx"},{name="cmd","map"}}
-- 检测是否是地图块
function MapBlock:isMap(fid,checkAir) -- ,func
	if ComVar.fillAll then return true end
	if fid then
		if checkAir or ComVar.fillAirMode then
			if fid == 0 then return true end -- 检测草地(id:62) 空气0
		else
			if MapBlock.airIsMap and fid == 0 then return true end
			if fid == MapBlock.ID then return true end
		end
	end
	return false
end

function MapBlock:cmd(str)
	CommandManager:RunCommand("/" .. str)
end

-- self:cmd("setblock " .. x .. " " .. y .. " " .. z .. " 0")
function MapBlock:delete(x,y,z)
	BlockEngine:SetBlockToAir(x,y,z)
end

-- 删除某区域内的地图元素 高,横向,竖向顺序：y,x,z
function MapBlock:deleteArea(po1,po2,blockID)
	po1 = {x=math.ceil(po1.x),y=math.ceil(po1.y),z=math.ceil(po1.z)}
	po2 = {x=math.ceil(po2.x),y=math.ceil(po2.y),z=math.ceil(po2.z)}
	for y = po1.y,po2.y do -- 垂直
		for x = po1.x,po2.x do -- 水平x
			for z = po1.z,po2.z do -- 水平y
				local id = BlockEngine:GetBlockId(x,y,z)
				if id then
					if blockID then
						if id == blockID then
							BlockEngine:SetBlockToAir(x,y,z)
						end
					else
						if id >= MapBlock.ID and id <= MapBlock.IDM then
							BlockEngine:SetBlockToAir(x,y,z)
						end
					end
				end
			end
		end
	end
end

function MapBlock:initMaterial()
	GameLogic.GetFilters():add_filter("block_types", function(xmlRoot) 
		local blocks = commonlib.XPath.selectNode(xmlRoot, "/blocks/");
		if(blocks) then
			for _,Mat in ipairs(Materials) do
				blocks[#blocks+1] = {name="block", attr={
					singleSideTex="true",
					name=Mat.name,
					id=Mat.id,
					mc_id=Mat.mc_id,
					class=Mat.class,
					item_class=Mat.item_class,
					text=Mat.text,
					searchkey=Mat.text,
					disable_gen_icon=Mat.disable_gen_icon,
					icon=Mat.icon,
					texture=Mat.texture,
					obstruction=Mat.obstruction,
					solid=Mat.solid,
					cubeMode="true",
					speedReduction=Mat.speedReduction,
					mapcolor=Mat.mapcolor,
					associated_blockid=Mat.associated_blockid,
					material=Mat.material;
					normalMap = Mat.normalMap;
					categoryID = Mat.categoryID;
					liquid = Mat.liquid;
					blendedTexture = Mat.blendedTexture;
					transparent = Mat.transparent;
					step_sound = Mat.step_sound;
					template = Mat.template;
					modelName = Mat.modelName;
					shape = Mat.shape;
					blockcamera = Mat.blockcamera;
					customModel = Mat.customModel;
				}}
				LOG.std(nil, "info", "MapBlock", "block %s (%d) is registered",  Mat.name, Mat.id);
			end
		end
		return xmlRoot;
	end)
	GameLogic.GetFilters():add_filter("block_list", function(xmlRoot) 
		for node in commonlib.XPath.eachNode(xmlRoot, "/blocklist/category") do
			if(node.attr.name == "tool") then
				for _, Mat in ipairs(Materials) do
					if(Mat.is_show_in_list) then
						node[#node+1] = {name="block", attr={ name=Mat.name }};
					end
				end
			end
		end
		return xmlRoot;
	end)
end