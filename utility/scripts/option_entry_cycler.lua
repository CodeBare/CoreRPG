-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sOptionKey = nil;
local sDefaultVal = "";
local enable_update = true;

function onClose()
	if sOptionKey then
		OptionsManager.unregisterCallback(sOptionKey, onOptionChanged);
	end
end

function onOptionChanged(sKey)
	if sOptionKey then
		setCyclerValue(OptionsManager.getOption(sOptionKey));
	end
end

function setLabel(sLabel)
	label.setValue(sLabel);
end

function setReadOnly(bValue)
	cycler.setReadOnly(bValue);
	left.setVisible(not bValue);
	right.setVisible(not bValue);
end

function initialize(sKey, aCustom)
	sOptionKey = sKey;
	
	if sOptionKey then
		if aCustom then
			cycler.initialize(aCustom.labels, aCustom.values, aCustom.baselabel);
			sDefaultVal = aCustom.baseval or "";
		end

		setCyclerValue(OptionsManager.getOption(sOptionKey));
		OptionsManager.registerCallback(sOptionKey, onOptionChanged);
	end
end

function onHover(bOnWindow)
	if bOnWindow then
		setFrame("rowshade");
	else
		setFrame(nil);
	end
end

function getCyclerValue()
	local sValue = cycler.getStringValue();
	if sValue == "" then
		sValue = sDefaultVal;
	end
	return sValue;
end

function setCyclerValue(sValue)
	enable_update = false;

	if sValue == sDefaultVal then
		sValue = "";
	end
	cycler.setStringValue(sValue);

	enable_update = true;
end

function onValueChanged()
	if enable_update and sOptionKey then
		OptionsManager.setOption(sOptionKey, getCyclerValue());
	end
end

function onDragStart(draginfo)
	if sOptionKey then
		draginfo.setType("string");
		draginfo.setIcon("action_option");
		draginfo.setDescription(label.getValue() .. " = " .. cycler.getValue());
		draginfo.setStringData("/option " .. sOptionKey .. " " .. getCyclerValue());
		return true;
	end
end
