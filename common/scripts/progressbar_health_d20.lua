-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sMaxHealthNodePath = nil;
local sTempHealthNodePath = nil;
local sWoundNodePath = nil;
local sNonlethalWoundNodePath = nil;

function onInit()
	local node = window.getDatabaseNode();
	sMaxHealthNodePath = DB.getPath(node, "hptotal");
	sTempHealthNodePath = DB.getPath(node, "hptemp");
	sWoundNodePath = DB.getPath(node, "wounds");
	sNonlethalWoundNodePath = DB.getPath(node, "nonlethal");


	OptionsManager.registerCallback("BARC", update);
	OptionsManager.registerCallback("WNDC", update);
	if not Session.IsHost then
		OptionsManager.registerCallback("SHPC", update);
	end
end
function onClose()
	if sMaxHealthNodePath then
		DB.removeHandler(sMaxHealthNodePath, "onUpdate", onMaxChanged);
	end
	if sTempHealthNodePath then
		DB.removeHandler(sTempHealthNodePath, "onUpdate", onTempChanged);
	end
	if sWoundNodePath then
		DB.removeHandler(sWoundNodePath, "onUpdate", onWoundChanged);
	end
	if sNonlethalWoundNodePath then
		DB.removeHandler(sNonlethalWoundNodePath, "onUpdate", onNonlethalChanged);
	end

	OptionsManager.unregisterCallback("BARC", update);
	OptionsManager.unregisterCallback("WNDC", update);
	if not Session.IsHost then
		OptionsManager.unregisterCallback("SHPC", update);
	end
end

function onFirstLayout()
	super.onFirstLayout();

	if sMaxHealthNodePath then
		DB.addHandler(sMaxHealthNodePath, "onUpdate", onMaxChanged);
	end
	if sTempHealthNodePath then
		DB.addHandler(sTempHealthNodePath, "onUpdate", onTempChanged);
	end
	if sWoundNodePath then
		DB.addHandler(sWoundNodePath, "onUpdate", onWoundChanged);
	end
	if sNonlethalWoundNodePath then
		DB.addHandler(sNonlethalWoundNodePath, "onUpdate", onNonlethalChanged);
	end
	onValueChanged();
end

function onMaxChanged()
	onValueChanged();
end
function onTempChanged()
	onValueChanged();
end
function onWoundChanged()
	onValueChanged();
end
function onNonlethalChanged()
	onValueChanged();
end

function onValueChanged()
	local nHP = DB.getValue(sMaxHealthNodePath, 0);
	local nTempHP = DB.getValue(sTempHealthNodePath, 0);

	local nWounds = DB.getValue(sWoundNodePath, 0);
	local nNonlethal = DB.getValue(sNonlethalWoundNodePath, 0);

	local nPercentWounded = 0;
	local nPercentNonlethal = 0;
	if nHP > 0 then
		nPercentWounded = nWounds / (nHP + nTempHP);
		nPercentNonlethal = (nWounds + nNonlethal) / (nHP + nTempHP);
	end
	
	setMax(nHP + nTempHP, true);
	setValue(nHP + nTempHP - nWounds, true);
	
	local sColor;
	if nPercentWounded <= 1 and nPercentNonlethal > 1 then
		sColor = ColorManager.COLOR_HEALTH_UNCONSCIOUS;
	elseif nPercentWounded == 1 or nPercentNonlethal == 1 then
		sColor = ColorManager.COLOR_HEALTH_SIMPLE_BLOODIED;
	else
		sColor = ColorManager.getHealthColor(nPercentNonlethal, true);
	end
	setFillColor(sColor);
	
	if Session.IsHost or OptionsManager.isOption("SHPC", "detailed") then
		local sText = "" .. (nHP - nWounds);
		if nTempHP > 0 then
			sText = sText .. " (+" .. nTempHP .. ")";
		end
		sText = sText .. " / " .. nHP;
		if nTempHP > 0 then
			sText = sText .. " (+" .. nTempHP .. ")";
		end
		local sPrefix = Interface.getString("hp");
		if (sPrefix or "") ~= "" then
			sText = sPrefix .. ": " .. sText;
		end
		setText(sText);
	else
		setText("");
	end
end
