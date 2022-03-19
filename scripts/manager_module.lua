-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _tAllModuleInfo = {};
local _tLoadedModuleInfo = {};
local _tLoadedModuleCategories = {};

function onInit()
	Interface.onDesktopInit = onDesktopInit;
end

function onDesktopInit()
	ModuleManager.initModuleData();

	Module.onModuleLoad = onModuleLoad;
	Module.onModuleUnload = onModuleUnload;

	Module.onModuleAdded = onModuleAdded;
	Module.onModuleUpdated = onModuleUpdated;
	Module.onModuleRemoved = onModuleRemoved;
end
function initModuleData()
	for _,sModule in ipairs(Module.getModules()) do
		local tInfo = Module.getModuleInfo(sModule);
		if tInfo then
			_tAllModuleInfo[sModule] = tInfo;
			if tInfo.loaded then
				_tLoadedModuleInfo[sModule] = tInfo;
				ModuleManager.checkLoadedCategory(sModule);
			end
		end
	end
	for sModule,tInfo in pairs(_tLoadedModuleInfo) do
		if (tInfo.category or "") ~= "" then
			_tLoadedModuleCategories[tInfo.category] = true;
		end
	end
end

function getAllModuleInfo()
	return _tAllModuleInfo;
end
function getModuleInfo(sModule)
	return _tAllModuleInfo[sModule];
end
function getLoadedModuleInfo()
	return _tLoadedModuleInfo;
end
function getLoadedModuleCategories()
	return _tLoadedModuleCategories;
end
function onModuleLoad(sModule)
	local tInfo = _tAllModuleInfo[sModule];
	if tInfo and tInfo.loaded then
		_tLoadedModuleInfo[sModule] = tInfo;
		ModuleManager.checkLoadedCategory(sModule);
		ModuleManager.rebuildLoadedCategories();
		ModuleManager.updateDisplayOnModuleLoad(sModule);
	end
end
function onModuleUnload(sModule)
	if _tLoadedModuleInfo[sModule] then
		_tLoadedModuleInfo[sModule] = nil;
		ModuleManager.rebuildLoadedCategories();
		ModuleManager.updateDisplayOnModuleUnload(sModule);
	end
end
function rebuildLoadedCategories()
	local tNewCategories = {};
	for _,tInfo in pairs(_tLoadedModuleInfo) do
		if (tInfo.category or "") ~= "" then
			tNewCategories[tInfo.category] = true;
		end
	end
	for sCategory,_ in pairs(_tLoadedModuleCategories) do
		if not tNewCategories[sCategory] then
			ModuleManager.updateDisplayOnCategoryRemoved(sCategory);
		end
	end
	for sCategory,_ in pairs(tNewCategories) do
		if not _tLoadedModuleCategories[sCategory] then
			ModuleManager.updateDisplayOnCategoryAdded(sCategory);
		end
	end
	_tLoadedModuleCategories = tNewCategories;
end
function checkLoadedCategory(sModule)
	if _tLoadedModuleInfo[sModule] then
		local tInfo = _tLoadedModuleInfo[sModule];
		if (tInfo.category or "") == "" then
			for _,nodeChild in pairs(DB.getChildren("library@" .. sModule)) do
				tInfo.category = DB.getValue(nodeChild, "categoryname", "");
				break;
			end
		end
	end
end

function onModuleAdded(sModule)
	local tInfo = Module.getModuleInfo(sModule);
	if tInfo then
		_tAllModuleInfo[sModule] = tInfo;
		if tInfo.loaded then
			_tLoadedModuleInfo[sModule] = tInfo;
			ModuleManager.checkLoadedCategory(sModule);
		end
		ModuleManager.updateDisplayOnModuleAdded(sModule);
	end
end
function onModuleUpdated(sModule)
	local tInfo = Module.getModuleInfo(sModule);
	if tInfo then
		_tAllModuleInfo[sModule] = tInfo;
		ModuleManager.updateDisplayOnModuleUpdated(sModule);
	end
end
function onModuleRemoved(sModule)
	_tAllModuleInfo[sModule] = nil;
	_tLoadedModuleInfo[sModule] = nil;
	ModuleManager.updateDisplayOnModuleRemoved(sModule);
end

function getModuleDataWindow()
	return Interface.findWindow("library", "");
end
function updateDisplayOnModuleLoad(sModule)
	local wData = ModuleManager.getModuleDataWindow();
	if wData then
		wData.onModuleLoad(sModule, _tLoadedModuleInfo[sModule]);
	end
end
function updateDisplayOnModuleUnload(sModule)
	local wData = ModuleManager.getModuleDataWindow();
	if wData then
		wData.onModuleUnload(sModule);
	end
end
function updateDisplayOnCategoryAdded(sCategory)
	local wData = ModuleManager.getModuleDataWindow();
	if wData then
		wData.onCategoryAdded(sCategory);
	end
end
function updateDisplayOnCategoryRemoved(sCategory)
	local wData = ModuleManager.getModuleDataWindow();
	if wData then
		wData.onCategoryRemoved(sCategory);
	end
end

function getModuleActivationWindow()
	return Interface.findWindow("moduleselection", "");
end
function updateDisplayOnModuleAdded(sModule)
	local wActivate = ModuleManager.getModuleActivationWindow();
	if wActivate then
		wActivate.onModuleAdded(sModule);
	end
end
function updateDisplayOnModuleUpdated(sModule)
	local wActivate = ModuleManager.getModuleActivationWindow();
	if wActivate then
		wActivate.onModuleUpdated(sModule);
	end
end
function updateDisplayOnModuleRemoved(sModule)
	local wActivate = ModuleManager.getModuleActivationWindow();
	if wActivate then
		wActivate.onModuleRemoved(sModule);
	end
end

function onDataWindowActivate(sModule)
	local wData = ModuleManager.getModuleDataWindow();
	if wData then
		local nodeSource = nil;
		if (sModule or "") ~= "" then
			for _,nodeChild in pairs(DB.getChildren("library@" .. sModule)) do
				nodeSource = nodeChild.getChild("entries");
				break;
			end
		end
		wData.pagelist.setDatabaseNode(nodeSource);
		wData.pagelist.setVisible(true);
	end
end
