-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _tGroups = {};
local _tOptions = {};
local _tCallbacks = {};

local _tButtons = {};

function isMouseWheelEditEnabled()
	return Input.isControlPressed();
end

function onInit()
	ChatManager.registerSlashCommand("option", processOption, "[option_name] <option_value>");

	DB.addHandler("options.*", "onUpdate", onOptionChanged);
end

function processOption(sCommand, sParams)
	local aWords = StringManager.parseWords(sParams, "%._");
	if #aWords >= 1 then
		local sOptionKey = aWords[1];

		if _tOptions[sOptionKey] then
			local sOptionLabel = OptionsManager.getOptionLabel(sOptionKey);
			if #aWords >= 2 then
				local sOptionValue = aWords[2];
				OptionsManager.setOption(sOptionKey, sOptionValue);
				local sOptionValueLabel = OptionsManager.getOptionValueLabel(sOptionKey, sOptionValue);
				ChatManager.SystemMessage(string.format(Interface.getString("option_command_result_set"), sOptionLabel, sOptionValueLabel));
			else
				local sOptionValue = OptionsManager.getOption(sOptionKey);
				local sOptionValueLabel = OptionsManager.getOptionValueLabel(sOptionKey, sOptionValue);
				ChatManager.SystemMessage(string.format(Interface.getString("option_command_result_get"), sOptionLabel, sOptionValueLabel));
			end
		else
			ChatManager.SystemMessage(string.format(Interface.getString("option_command_error_not_registered"), sOptionKey));
		end
	end
end

function populate(w)
	for _, rGroup in pairs(_tGroups) do
		local winSet = w.list.createWindow();
		if winSet then
			winSet.label.setValue(rGroup.sLabel);
			winSet.sort.setValue(rGroup.nOrder);

			for _, rOption in pairs(rGroup.tOptions) do
				local winOption = winSet.options_list.createWindowWithClass(rOption.sType);
				if winOption then
					winOption.setLabel(rOption.sLabel);
					winOption.initialize(rOption.sKey, rOption.aCustom);
					winOption.setReadOnly(not (rOption.bLocal or Session.IsHost));
				end
			end
			
			winSet.options_list.applySort();
		end
	end
	w.list.applySort();

	for _,tButton in pairs(_tButtons) do
		local winButton = w.list_buttons.createWindow();
		if winButton then
			winButton.setData(tButton);
		end
	end
end

function registerOption(sKey, bLocal, sGroup, sLabel, sOptionType, aCustom)
	OptionsManager.deleteOption(sKey);
	
	local rOption = {};
	rOption.sKey = sKey;
	rOption.bLocal = bLocal;
	rOption.sLabel = sLabel;
	rOption.aCustom = aCustom;
	rOption.sType = sOptionType;
	
	_tOptions[sKey] = rOption;
	_tOptions[sKey].value = (_tOptions[sKey].aCustom[default]) or "";

	OptionsManager.addOptionToGroup(rOption, sGroup);
end
function registerOption2(sKey, bLocal, sGroupRes, sLabelRes, sOptionType, aCustom)
	local sGroup = Interface.getString(sGroupRes);
	local sLabel = Interface.getString(sLabelRes);

	if aCustom.labels then
		local aLabels = StringManager.split(aCustom.labels, "|");
		for k,v in ipairs(aLabels) do
			local sLabel = Interface.getString(v);
			if sLabel ~= "" then
				aLabels[k] = Interface.getString(v);
			end
		end
		aCustom.labels = table.concat(aLabels, "|");
	end
	if aCustom.labelsraw then
		aCustom.labels = aCustom.labelsraw;
	end
	aCustom.baselabel = Interface.getString(aCustom.baselabel);
	
	OptionsManager.registerOption(sKey, bLocal, sGroup, sLabel, sOptionType, aCustom);
end
function deleteOption(sKey)
	if _tOptions[sKey] then
		local bFound = false;
		for _, rGroup in pairs(_tGroups) do
			for kOption, rOption in pairs(rGroup.tOptions) do
				if rOption.sKey == sKey then
					bFound = true;
					table.remove(rGroup.tOptions, kOption);
					break;
				end
			end
			if bFound then
				if #rGroup.tOptions <= 0 then
					_tGroups[rGroup.sLabel] = nil;
				end
				break;
			end
		end
		
		_tOptions[sKey] = nil;
	end
end

function addOptionToGroup(rOption, sGroup)
	local rGroup = _tGroups[sGroup];
	if not rGroup then
		rGroup = { };
		rGroup.sLabel = sGroup;
		rGroup.nOrder = OptionsManager.getNewGroupOrder(sGroup)
		rGroup.tOptions = { };

		_tGroups[sGroup] = rGroup;
	end

	table.insert(rGroup.tOptions, rOption);
end
function getNewGroupOrder(sGroup)
	if sGroup == Interface.getString("option_header_client") then
		return 1;
	elseif sGroup == Interface.getString("option_header_game") then
		return 2;
	elseif sGroup == Interface.getString("option_header_combat") then
		return 3;
	elseif sGroup == Interface.getString("option_header_token") then
		return 4;
	elseif sGroup == Interface.getString("option_header_houserule") then
		return 5;
	else
		local nMax = 5;
		for _, rGroup in pairs(_tGroups) do
			nMax = math.max(nMax, rGroup.nOrder);
		end
		return nMax + 1;
	end		
end

function registerButton(sLabelRes, sClass, sRecord)
	_tButtons[sLabelRes] = { sLabelRes = sLabelRes, sClass = sClass, sRecord = sRecord };
end
function unregisterButton(sLabelRes)
	_tButtons[sLabelRes] = nil;
end

function onOptionChanged(nodeOption)
	local sKey = nodeOption.getName();
	CampaignRegistry["Opt" .. sKey] = getOption(sKey);
	OptionsManager.makeCallback(sKey);
end

function registerCallback(sKey, fCallback)
	if not _tCallbacks[sKey] then
		_tCallbacks[sKey] = {};
	end
	
	table.insert(_tCallbacks[sKey], fCallback);
end
function unregisterCallback(sKey, fCallback)
	if _tCallbacks[sKey] then
		for k, v in pairs(_tCallbacks[sKey]) do
			if v == fCallback then
				table.remove(_tCallbacks[sKey], k);
				break;
			end
		end
	end
end
function makeCallback(sKey)
	if _tCallbacks[sKey] then
		for k, v in pairs(_tCallbacks[sKey]) do
			v(sKey);
		end
	end
end

function isOption(sKey, sTargetValue)
	return (OptionsManager.getOption(sKey) == sTargetValue);
end
function setOption(sKey, sValue)
	if _tOptions[sKey] then
		CampaignRegistry["Opt" .. sKey] = sValue;
		if _tOptions[sKey].bLocal then
			OptionsManager.makeCallback(sKey);
		else
			if Session.IsHost then
				DB.setValue("options." .. sKey, "string", sValue);
			end
		end
	end
end
function getOption(sKey)
	if _tOptions[sKey] then
		local sValue = "";
		if _tOptions[sKey].bLocal then
			if CampaignRegistry["Opt" .. sKey] then
				sValue = CampaignRegistry["Opt" .. sKey];
			end
		else
			sValue = DB.getValue("options." .. sKey, "");
		end
		if sValue ~= "" then
			return sValue;
		end

		return (_tOptions[sKey].aCustom.default) or "";
	end

	return "";
end

function addOptionValue(sKey, sLabel, sValue, bUseResource)
	local rOption = _tOptions[sKey];
	if rOption and rOption.aCustom then
		if bUseResource then
			sLabel = Interface.getString(sLabel);
		end
		
		if rOption.aCustom.labels and (rOption.aCustom.labels ~= "") then
			rOption.aCustom.labels = rOption.aCustom.labels .. "|" .. sLabel;
		else
			rOption.aCustom.labels = sLabel;
		end
		
		if rOption.aCustom.values and (rOption.aCustom.values ~= "") then
			rOption.aCustom.values = rOption.aCustom.values .. "|" .. sValue;
		else
			rOption.aCustom.values = sValue;
		end
	end
end
function setOptionDefault(sKey, sDefaultValue)
	local rOption = _tOptions[sKey];
	if rOption and rOption.aCustom then
		_tOptions[sKey].aCustom.default = sDefaultValue;
	end
end
function getOptionLabel(sKey)
	local rOption = _tOptions[sKey];
	if rOption then
		return rOption.sLabel or "";
	end
	return "";
end
function getOptionValueLabel(sKey, sValue)
	local rOption = _tOptions[sKey];
	if rOption and rOption.aCustom then
		local nValue = 0;
		local tValues = StringManager.split(rOption.aCustom.values, "|");
		for k,v in ipairs(tValues) do
			if v == sValue then
				nValue = k;
				break;
			end
		end

		if nValue > 0 then
			local tLabels = StringManager.split(rOption.aCustom.labels, "|");
			if tLabels[nValue] then
				return tLabels[nValue];
			end
		end
		return rOption.aCustom.baselabel or "";
	end
	return "";
end
