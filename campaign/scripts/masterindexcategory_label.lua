-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _bFocus = false;
local _sOriginalValue = "";

function initialize(sCategory)
	setValue(sCategory);
	_sOriginalValue = sCategory;
	if not _bFocus then
		setTooltipText(_sOriginalValue);
	end
end

function onGainFocus()
	_bFocus = true;
	_sOriginalValue = getValue();
	setTooltipText("");
end
function onLoseFocus()
	local sCurrentValue = getValue();
	if _sOriginalValue ~= sCurrentValue then
		window.handleCategoryNameChange(_sOriginalValue, sCurrentValue);
		_sOriginalValue = sCurrentValue;
	end
	_bFocus = false;
	setTooltipText(sCurrentValue);
end

function onDrop(x, y, draginfo)
	window.handleDrop(draginfo);
end
function onClickDown()
	if isReadOnly() then
		return true;
	end
end
function onClickRelease()
	if isReadOnly() then
		window.handleSelect();
	end
end
