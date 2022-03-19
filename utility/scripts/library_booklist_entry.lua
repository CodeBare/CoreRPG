-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _sModule = "";
local _sCategory = "";

function getName()
	return _sModule;
end
function getCategory()
	return _sCategory;
end
function setData(sModule, tInfo)
	_sModule = sModule;
	_sCategory = tInfo.category;

	name.setValue(tInfo.displayname or tInfo.name);
	category.setValue(tInfo.category);
	thumbnail.setIcon("module_" .. sModule);

	resetMenuItems();
	if Session.IsHost then
		registerMenuItem(Interface.getString("module_menu_revert"), "shuffle", 8);
	end
	registerMenuItem(Interface.getString("module_unload"), "delete", 6);
end

function activate()
	ModuleManager.onDataWindowActivate(_sModule);
end
function onMenuSelection(selection)
	if selection == 8 then
		Module.revert(_sModule);
	elseif selection == 6 then
		Module.deactivate(_sModule);
	end
end
