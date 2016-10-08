--v0.5

--[[
Mini map button option
	fix update to run on load instead of timer
loot spec veiw/change

--]]

--Setup Addon
SpecPlus = LibStub("AceAddon-3.0"):NewAddon("SpecPlus", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0");
SpecPlus.SP = {};
local SP = SpecPlus.SP;

--Load Libraries
SP.AceDB = LibStub("AceDB-3.0");
SP.AceConfig = LibStub("AceConfig-3.0");
SP.AceConfigDialog = LibStub("AceConfigDialog-3.0");
SP.LibQTip = LibStub("LibQTip-1.0");
SP.LibDataBroker = LibStub("LibDataBroker-1.1");
SP.LibDBIcon = LibStub("LibDBIcon-1.0");

--Setup Variables
SP.tooltip = nil;
SP.currentTime = 0;
SP.oldTime = 0;
SP.currentSpec = GetSpecialization();
SP.specs = {};
SP.sets = {"--none--"};
SP.setIcons = {"Interface\\Icons\\INV_Misc_QuestionMark.blp"};
SP.clickSelect = {"Toggle Specs", "Show Talents"};

SP.defaults = {
	char = {
		equipSets = {},
		equipSetIcons = {},
		equipSetsIndex = {},
		toggleSpecs = false,
		toggleSpec = {1,2},
		showIcon = true,
		showLoot = false,
	},
	profile = {
		clickSelectIndex = 1,
		showLabel = true,
		showTextIcon = true,
		showClassColorLDB = false,
		showPrintIcon = true,
		showChatPrint = true,
		showSetPrint = true,
		showSetIcon = true,
		showClassColorPrint = false,
		showLibDBIcon = true,
	},
}

--[[-----------------------------------------------------------------------------------
Options 
--]]-----------------------------------------------------------------------------------
SP.options = {
	name = "Spec+ Settings",
	handler = SpecPlus,
	type = "group",
	get = function(info)
		return SP.db.profile[info[#info]];
	end,
	set = function(info, value)
		SP.db.profile[info[#info]] = value;
		SpecPlus:UpdateLDB();
	end,
	args = {
		OnClickOptions = {
			name = "OnClick",
			type = "group",
			inline = true,
			order = 1,
			args = {
				clickSelectIndex = {
					type = "select",
					style = "dropdown",
					name = "Click action",
					desc = "Choose what happens when you click the addon",
					values = SP.clickSelect,
					order = 1,
				},
				specPrim = {
					type = "select",
					style = "dropdown",
					name  = "  Primary Spec",
					desc = "Primary specialization to toggle between (default if current spec is not one of these two)",
					values = SP.specs,
					get = function(info) return SP.db.char.toggleSpec[1] end,
					set = function(info, value) SP.db.char.toggleSpec[1] = value end,
					order = 2,
					disabled = function() if SP.db.profile.clickSelectIndex == 1 then return false else return true end end,
				},
				specSecd = {
					type = "select",
					style = "dropdown",
					name  = "  Secondary Spec",
					desc = "Secondary specialization to toggle between",
					values = SP.specs,
					get = function(info) return SP.db.char.toggleSpec[2] end,
					set = function(info, value) SP.db.char.toggleSpec[2] = value end,
					order = 3,
					disabled = function() if SP.db.profile.clickSelectIndex == 1 then return false else return true end end,
				},
			},
		},
		equipSetsOptions = {
			name = "Equipment Sets",
			type = "group",
			inline = true,
			order = 2,
			get = function(info)
				return SP.db.char.equipSetsIndex[info.option.order];
			end,
			set = function(info, value)
				SP.db.char.equipSets[info.option.order] = SP.sets[value];
				SP.db.char.equipSetsIndex[info.option.order] = value;
				SP.db.char.equipSetIcons[info.option.order] = SP.setIcons[value];
			end,
			args = {
				setDropDown1 = {
					type = "select",
					style = "dropdown",
					name  = function() return "  "..(SP.specs[1] or "") end,
					desc = "Set the equipment set for this specialization",
					values = SP.sets,
					order = 1,
				},
				setDropDown2 = {
					type = "select",
					style = "dropdown",
					name  = function() return "  "..(SP.specs[2] or "") end,
					desc = "Set the equipment set for this specialization",
					values = SP.sets,
					order = 2,
				},
				setDropDown3 = {
					type = "select",
					style = "dropdown",
					name  = function() return "  "..(SP.specs[3] or "") end,
					desc = "Set the equipment set for this specialization",
					values = SP.sets,
					order = 3,
					hidden = function() if SP.numspecs > 2 then return false else return true end end,
				},
				setDropDown4 = {
					type = "select",
					style = "dropdown",
					name  = function() return "  "..(SP.specs[4] or "") end,
					desc = "Set the equipment set for this specialization",
					values = SP.sets,
					order = 4,
					hidden = function() if SP.numspecs > 3 then return false else return true end end,
				},
			},
		},
		ldbOptions = {
			name = "LDB Options",
			type = "group",
			inline = true,
			order = 3,
			args = {
				showLabel = {
					type = "toggle",
					name = "Show Label Text",
					desc = "Shows the \"Spec+\" label on the Data Broker",
					order = 1,
				},
				showTextIcon = {
					type = "toggle",
					name = "Show Text Icon",
					desc = "Shows the spec icon in the broker text",
					order = 2,
				},
				showClassColorLDB = {
					type = "toggle",
					name = "Show Class Color",
					desc = "Shows the broker text with your class color",
					order = 3,
				},
			},
		},
		printOptions = {
			name = "Chat Print Options",
			type = "group",
			inline = true,
			order = 4,
			args = {
				showChatPrint = {
					type = "toggle",
					name = "Print Spec Change",
					desc = "Show a chat printout when your spec has changed",
					order = 1,
				},
				showPrintIcon = {
					type = "toggle",
					name = "Show Print Icon",
					desc = "Shows the spec icon in the chat printout",
					order = 2,
				},
				showClassColorPrint = {
					type = "toggle",
					name = "Show Class Color",
					desc = "Shows the chat printout with your class color",
					order = 3,
				},
				showSetPrint = {
					type = "toggle",
					name = "Print Equip Change",
					desc = "Show a chat printout when your equipment set has changed",
					order = 4,
				},
				showSetIcon = {
					type = "toggle",
					name = "Show Print Icon",
					desc = "Shows the equipment set icon in the chat printout",
					order = 5,
				},
			},
		},
		miscellaneous = {
			name = "Miscellaneous",
			type = "group",
			inline = true,
			order = 5,
			args = {
				showLibDBIcon = {
					type = "toggle",
					name = "Show Minimap Icon",
					desc = "Show a Minimap icon that will display the tooltip",
					order = 1,
				},
			},
		},
	},
}
--]]


local function GetLootSpecializationIndex()
	local lootID = GetLootSpecialization();
	for i = 1, SP.numspecs do
		local specID = GetSpecializationInfo(i);
		if lootID == specID then
			return i
		end
	end
	return 0
end

--[[-----------------------------------------------------------------------------------
UpdateLDB
--]]-----------------------------------------------------------------------------------
function SpecPlus:UpdateLDB()
	local id, name, description, icon, background, role = GetSpecializationInfo(SP.currentSpec);
	
	if SP.currentSpec ~= nil then		
		if SP.db.profile.showClassColorLDB == true then
			name = SpecPlus:ColorName(name);
		end
		
		if SP.db.profile.showTextIcon == true then
			name = format(("|T%s:16|t%s"), icon, " "..name);
		end
	else
		icon = "Interface\\Icons\\INV_Misc_QuestionMark.blp";
		name = "None";
	end
	
	SP.ldb.icon = icon;
	SP.ldb.text = name;
	
	if SP.db.profile.showLabel == true then
		SP.ldb.label = "Spec+";
	else 
		SP.ldb.label = nil
	end
	
	if SP.db.profile.showLibDBIcon == true then
		SP.LibDBIcon:Show("Spec+")
	else
		SP.LibDBIcon:Hide("Spec+")
	end
end

--[[-----------------------------------------------------------------------------------
SpecChanged
--]]-----------------------------------------------------------------------------------
function SpecPlus:SpecChanged()
	SpecPlus:UpdateLDB();
	
	local id, name, description, icon, background, role = GetSpecializationInfo(SP.currentSpec);
	
	if SP.db.profile.showChatPrint == true then
		if SP.db.profile.showPrintIcon == true then
			name = format(("|T%s:16|t%s"), icon, " "..name);
		end
		if SP.db.profile.showClassColorPrint == true then
			name = SpecPlus:ColorName(name);
		end
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff96Spec+|r: Specialization changed to "..name..".");
	end
	SpecPlus:ChangeEquip();
end

--[[-----------------------------------------------------------------------------------
ChangeEquip
--]]-----------------------------------------------------------------------------------
function SpecPlus:ChangeEquip()
	local name = SP.db.char.equipSets[SP.currentSpec];
	local icon = SP.db.char.equipSetIcons[SP.currentSpec];
	if name ~= nil and name ~= "--none--" then
		UseEquipmentSet(name);
		if SP.db.profile.showSetPrint == true then
			if SP.db.profile.showSetIcon == true and icon ~= nil then
				name = format(("|T%s:16|t%s"),icon, name)
			end
			DEFAULT_CHAT_FRAME:AddMessage("|cff00ff96Spec+|r: Equipment Set changed to "..name..".");
		end
	end
end

--[[-----------------------------------------------------------------------------------
ColorName
--]]-----------------------------------------------------------------------------------
function SpecPlus:ColorName(name)
	local _, class = UnitClass("Player");
	local coloredName = "|c"..RAID_CLASS_COLORS[class].colorStr..name.."|r";
	return coloredName;
end

--[[-----------------------------------------------------------------------------------
OnEnter
--]]-----------------------------------------------------------------------------------
function SpecPlus:OnEnter(self)
	--GameTooltip:Hide();
	SP.tooltip = SP.LibQTip:Acquire("SpecPlusTooltip", 2, "LEFT", "RIGHT");
	--SP.tooltip:SetScale(1.0);
	SP.tooltip:SmartAnchorTo(self);
	--SP.tooltip:SetCellMarginH(1)
	SP.tooltip:Clear(); 

	SP.tooltip:AddHeader("|cff00ff96Spec+|r");
	SP.tooltip:AddLine("Click to activate spec", "Gear");
	SP.tooltip:AddSeparator(2, 0, 55, 255);
	

	local numlines = 3; --number of lines created above this
		
	for i = 1, SP.numspecs do
		local id, name, description, icon, background, role = GetSpecializationInfo(i);
		numlines = numlines + 1;
		if SP.currentSpec ~= i then
			name = "|cff999999" .. name .. "|r"
		end
		SP.tooltip:AddLine(format("|T%s:16|t%s", icon, name), SP.db.char.equipSets[i]);
		SP.tooltip:SetCellScript(numlines, 1, "OnMouseUp", function(self)
			SpecPlus:LibQTipClick(i);
		end);
	end

	SP.tooltip:AddLine("Click to activate loot spec");
	SP.tooltip:AddSeparator(2, 0, 55, 255);


	numlines = numlines + 2;

	for i = 1, SP.numspecs do
		local id, name, description, icon, background, role = GetSpecializationInfo(i);
		numlines = numlines + 1;
		if SP.currentLootSpec ~= i then
			name = "|cff999999" .. name .. "|r"
		end
		SP.tooltip:AddLine(format("|T%s:16|t%s", icon, name));
		SP.tooltip:SetCellScript(numlines, 1, "OnMouseUp", function(self)
			SpecPlus:LibQTipClick(-i);
		end);
	end

	SP.tooltip:AddLine("|cffffff00Left Click|r to change specs");
	SP.tooltip:AddLine("|cffffff00Right Click|r for options");
	--SP.tooltip:AddLine(" ")
	--SP.tooltip:EnableMouse(true);
	--SP.tooltip:SmartAnchorTo(self);
	SP.tooltip:SetAutoHideDelay(.1, self);
	SP.tooltip:UpdateScrolling();
	SP.tooltip:Show();
end

--[[-----------------------------------------------------------------------------------
OnClick
--]]-----------------------------------------------------------------------------------
function SpecPlus:OnClick(button)
	button = button or "LeftButton";
	
	if button == "LeftButton" then
		if SP.db.profile.clickSelectIndex == 1 then
			if SP.currentSpec == SP.db.char.toggleSpec[1] then
				SetSpecialization(SP.db.char.toggleSpec[2]);
			else
				SetSpecialization(SP.db.char.toggleSpec[1]);
			end	
		else
			ToggleTalentFrame(2)
		end
	elseif button == "RightButton" then
		InterfaceOptionsFrame_OpenToCategory(SP.optionsFrame);
	end
end

--[[-----------------------------------------------------------------------------------
LibQTipClick
--]]-----------------------------------------------------------------------------------
function SpecPlus:LibQTipClick(index)
	if index > 0 then  -- spec
		if SP.currentSpec == index then
			DEFAULT_CHAT_FRAME:AddMessage("|cff00ff96Spec+|r: That Specialization is already active.");
		else
			SetSpecialization(index);
			SP.LibQTip:Release(SP.tooltip);
			SP.tooltip = nil;
		end
	else  -- loot spec
		index = math.abs(index);
		local specID;
		if SP.currentLootSpec == index then
			specID = 0;
		else
			specID = GetSpecializationInfo(index);
		end
		SetLootSpecialization(specID);
		SP.LibQTip:Release(SP.tooltip);
		SP.tooltip = nil;
	end
end

--[[-----------------------------------------------------------------------------------
OnInitialize
--]]-----------------------------------------------------------------------------------
function SpecPlus:OnInitialize()
	--Load Database
	SP.db = SP.AceDB:New("SpecPlusDB", SP.defaults, true);
	
	--Register Options Table
	SP.AceConfig:RegisterOptionsTable("SpecPlus", SP.options);
	SP.optionsFrame = SP.AceConfigDialog:AddToBlizOptions("SpecPlus", "Spec+");
	
	--Load Data Broker Object
	SP.ldb = SP.LibDataBroker:NewDataObject("Spec+", {
		type = "data source",
		label = "Spec+",
		text = "Spec+",
		icon = "Interface\\Icons\\INV_Misc_QuestionMark.blp",
		OnEnter = function(self) SpecPlus:OnEnter(self) end,
		OnClick = function (self, button) SpecPlus:OnClick(button) end,
	});
	
	--Register Icon
	SP.LibDBIcon:Register("Spec+", SP.ldb, {hide=not SP.db.profile.showLibDBIcon});
	
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("PLAYER_LEAVING_WORLD");
	
	SP.oldTime = GetTime();
end

--[[-----------------------------------------------------------------------------------
OnEnable
--]]-----------------------------------------------------------------------------------
function SpecPlus:OnEnable()
	SP.numspecs = GetNumSpecializations();
	for i = 1, SP.numspecs do
		local id, name, description, icon, background, role = GetSpecializationInfo(i);
		SP.specs[i] = name;
	end
	SP.numsets = GetNumEquipmentSets();
	for i = 1, SP.numsets do
		local name, icon, setID, isEquipped, numItems, numEquipped, numInventory, numMissing, numIgnored = GetEquipmentSetInfo(i);
		SP.sets[i+1] = name;
		SP.setIcons[i+1] = icon;
	end	
	SP.currentLootSpec = GetLootSpecializationIndex();
	SpecPlus:UpdateLDB();
	SpecPlus:ScheduleTimer("UpdateLDB", 0.25);
end

function SpecPlus:ACTIVE_TALENT_GROUP_CHANGED(event)
	SP.currentSpec = GetSpecialization();
	SP.currentTime = GetTime();
	if SP.currentTime > SP.oldTime + 3 then
		SpecPlus:ScheduleTimer("SpecChanged", 0.25);
		SP.oldTime = GetTime();
	end
end

function SpecPlus:PLAYER_LOOT_SPEC_UPDATED(event)
	SP.currentLootSpec = GetLootSpecializationIndex();
end

function SpecPlus:PLAYER_ENTERING_WORLD(event)
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
	self:RegisterEvent("PLAYER_LOOT_SPEC_UPDATED");
end

function SpecPlus:PLAYER_LEAVING_WORLD(event)
	self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
	self:UnregisterEvent("PLAYER_LOOT_SPEC_UPDATED");
end	

SLASH_SPECPLUS1, SLASH_SPECPLUS2 , SLASH_SPECPLUS3 , SLASH_SPECPLUS4 = "/sc", "/spec", "/specp", "/specplus";
local function handler(msg, editbox)
	if msg == "hw" then
		print("Hello, World!");
	else
		InterfaceOptionsFrame_OpenToCategory(SP.optionsFrame);
	end
end
SlashCmdList["SPECPLUS"] = handler;
