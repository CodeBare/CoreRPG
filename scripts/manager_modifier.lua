-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

DRAGTYPE_MODIFIERKEY = "modifierkey";

local _tModWindowPresets = {};

local _tKeyExclusionSets = {};
local _tKeysActive = {};

local _nLocked = 0;
local _bLockReset = false;
local _tKeysUsed = {};

function onInit()
	Interface.onHotkeyActivated = onHotkey;
end

--
--	Hot Key Support
--

function onHotkey(draginfo)
	local sDragType = draginfo.getType();
	if sDragType == ModifierManager.DRAGTYPE_MODIFIERKEY then
		ModifierManager.toggleKey(draginfo.getMetaData("sKey"));
		return true;
	end
end	

--
--	Setup
--

function getModWindowPresets()
	return _tModWindowPresets;
end
function addModWindowPresets(tPresets)
	for _,tModCategory in ipairs(tPresets) do
		table.insert(_tModWindowPresets, tModCategory);
	end
end
function addModWindowPresetButton(sCategory, sButtonID, nPosition)
	for _,tModCategory in ipairs(_tModWindowPresets) do
		if tModCategory.sCategory == sCategory then
			if nPosition and (#(tModCategory.tPresets) >= nPosition) then
				table.insert(tModCategory.tPresets, nPosition, sButtonID);
			else
				table.insert(tModCategory.tPresets, sButtonID);
			end
			return;
		end
	end
	table.insert(_tModWindowPresets, { sCategory = sCategory, tPresets = { sButtonID } });
end

function addKeyExclusionSets(tPresetExclusionSets)
	for _,tModSet in ipairs(tPresetExclusionSets) do
		table.insert(_tKeyExclusionSets, tModSet);
	end
end

--
-- 	Lock handling
-- 		Used to keep the modifier stack from being cleared when making multiple rolls (i.e. full attack)
--

function isLocked()
	return (_nLocked > 0);
end
function lock()
	if _nLocked == 0 then
		_bLockReset = false;
	end
	_nLocked = _nLocked + 1;
end
function unlock(bReset)
	_nLocked = _nLocked - 1;
	if _nLocked < 0 then
		_nLocked = 0;
	end
	if bReset then
		_bLockReset = _bLockReset or bReset;
	end
		
	if (_nLocked == 0) and _bLockReset then
		ModifierStack.reset();

		for sKey,_ in pairs(_tKeysUsed) do
			ModifierManager.setKey(sKey, false, true);
		end
		_tKeysUsed = {};
	end
end

--
-- 	Key management
--

local _tKeyCallbacks = {};
function registerKeyCallback(sKey, fCallback)
	if not _tKeyCallbacks[sKey] then
		_tKeyCallbacks[sKey] = {};
	end
	table.insert(_tKeyCallbacks[sKey], fCallback);
end
function unregisterKeyCallback(sKey, fCallback)
	if _tKeyCallbacks[sKey] then
		for k,v in ipairs(_tKeyCallbacks[sKey]) do
			if v == fCallback then
				table.remove(_tKeyCallbacks[sKey], k);
				break;
			end
		end
	end
end
function makeKeyCallback(sKey)
	if _tKeyCallbacks[sKey] then
		for _,v in ipairs(_tKeyCallbacks[sKey]) do
			v(sKey);
		end
	end
end

function getKey(sKey)
	local bState = _tKeysActive[sKey];
	
	if _nLocked > 0 then
		_tKeysUsed[sKey] = true;
	else
		if bState then
			ModifierManager.setKey(sKey, false, true);
		end
	end
	
	return bState;
end
function getRawKey(sKey)
	return _tKeysActive[sKey];
end
function setKey(sKey, bState)
	if (sKey or "") == "" then
		return;
	end
	
	if bState then
		if _tKeysActive[sKey] then
			return;
		end
		_tKeysActive[sKey] = true;
	else
		if not _tKeysActive[sKey] then
			return;
		end
		_tKeysActive[sKey] = nil;
	end

	ModifierManager.onKeyUpdate(sKey);
end
function toggleKey(sKey)
	if (sKey or "") == "" then
		return;
	end
	if _tKeysActive[sKey] then
		_tKeysActive[sKey] = nil;
	else
		_tKeysActive[sKey] = true;
	end
	ModifierManager.onKeyUpdate(sKey);
end
function onKeyUpdate(sKey)
	ModifierManager.makeKeyCallback(sKey);

	if _tKeysActive[sKey] then
		for _,tExclusionSet in ipairs(_tKeyExclusionSets) do
			if StringManager.contains(tExclusionSet, sKey) then
				for _,sExclusionKey in ipairs(tExclusionSet) do
					if sExclusionKey ~= sKey then
						setKey(sExclusionKey, false);
					end
				end
			end
		end
	end
end