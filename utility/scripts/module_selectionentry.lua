-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _sModule = nil;

function onMenuSelection(selection)
	if selection == 8 then
		Module.revert(_sModule);
	end
end

function update(tModuleInfo)
	name.setValue(tModuleInfo.displayname or tModuleInfo.name);
	author.setValue(tModuleInfo.author);
	
	if tModuleInfo.loaded then
		load.setIcon(load.states[1].loaded[1]);
		button_load.setValue(1);
	else
		load.setIcon(load.states[1].unloaded[1]);
		button_load.setValue(0);
	end
	
	if tModuleInfo.permission == "allow" then
		permissions.setValue(1);
	else
		permissions.setValue(0);
	end
	
	local thumbwidget = thumbnail.findWidget("remote");
	if tModuleInfo.installed then
		if thumbwidget then
			thumbwidget.destroy();
		end
	else
		if not thumbwidget then
			thumbwidget = thumbnail.addBitmapWidget("module_remote");
			thumbwidget.setPosition("bottomleft", 10, 0);
			thumbwidget.setName("remote");
		end
	end
	
	if tModuleInfo.intact then
		resetMenuItems();
	else
		registerMenuItem(Interface.getString("module_menu_revert"), "shuffle", 8);
	end
end

function setData(tModuleInfo)
	_sModule = tModuleInfo.name;
	thumbnail.setIcon("module_" .. _sModule);
	update(tModuleInfo);
end

function getModuleName()
	return _sModule;
end

function toggleActivation()
	windowlist.window.toggleActivation(_sModule);
end

function setPermissions(sPermissions)
	windowlist.window.setModulePermissions(_sModule, sPermissions);
end