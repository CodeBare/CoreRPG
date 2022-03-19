-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _bReadOnly = false;
local _bActive = false;

local _tItems = {};
local _tOrderedItems = {};

local _sButtonIcon = "combobox_button";
local _sButtonIconActive = "combobox_button_active";
local _nButtonH = 10;
local _tButtonOffset = { x = 0, y = 0 };

local _sListDirection = nil;
local _tListOffset = { x = 0, y = 5 };
local _sListFont = "chatfont";
local _sListSelectedFont = "narratorfont";
local _sListFrame = "";
local _sListSelectedFrame = "rowshade";
local _nListMaxSize = 0;

local _ctrlList = nil;
local _ctrlButton = nil;
local _ctrlScroll = nil;

function onInit()
	-- Read button parameters
	if buttonoffset then
		local sOffset = buttonoffset[1];
		local nComma = string.find(sOffset, ",");
		if nComma then
			_tButtonOffset.x = tonumber(string.sub(sOffset, 1, nComma-1)) or 0;
			_tButtonOffset.y = tonumber(string.sub(sOffset, nComma+1)) or 0;
		end
	end
	
	-- Read list parameters
	if listdirection and listdirection[1] == "up" then
		_sListDirection = "up";
	end
	if listdirection and listdirection[1] == "down" then
		_sListDirection = "down";
	end
	if listoffset then
		local sPosition = listoffset[1];
		local nComma = string.find(sPosition, ",");
		if nComma then
			_tListOffset.x = tonumber(string.sub(sPosition, 1, nComma-1)) or 0;
			_tListOffset.y = tonumber(string.sub(sPosition, nComma+1)) or _tListOffset.y;
		else
			_tListOffset.y = tonumber(string.sub(sPosition, nComma+1)) or _tListOffset.y;
		end
	end
	if listfonts then
		_sListFont = listfonts[1].normal[1] or "";
		if type(_sListFont) ~= "string" then _sListFont = ""; end
		_sListSelectedFont = listfonts[1].selected[1] or "";
		if type(_sListSelectedFont) ~= "string" then _sListSelectedFont = ""; end
	end
	if listframes then
		_sListFrame = listframes[1].normal[1] or "";
		if type(_sListFrame) ~= "string" then _sListFrame = ""; end
		_sListSelectedFrame = listframes[1].selected[1] or "";
		if type(_sListSelectedFrame) ~= "string" then _sListSelectedFrame = ""; end
	end
	if listmaxsize then
		_nListMaxSize = tonumber(listmaxsize[1]) or 0;
	end
	
	-- Initialize button icon
	local sName = getName() or "";
	if (sName or "") ~= "" then
		local sButton = sName .. "_cbbutton";
		_ctrlButton = window.createControl("combobox_button", sButton);
		_ctrlButton.setTarget(sName);
		_ctrlButton.setAnchor("right", sName, "right", "absolute", _tButtonOffset.x);
		_ctrlButton.setAnchor("top", sName, "center", "absolute", -(math.floor(_nButtonH/2)) + _tButtonOffset.y);
		_ctrlButton.setIcon(_sButtonIcon);
		_ctrlButton.setVisible(isVisible());
	end

	-- Determine if underlying node is read only (only applies to stringfield version)
	local node = getDatabaseNode();
	if node then
		if (node.isReadOnly() or not node.isOwner()) then
			setComboBoxReadOnly(true);
		else
			refreshDisplay();
		end
		setTooltipText(getValue());
	else
		refreshDisplay();
	end
end

function onDestroy()
	if _ctrlScroll then
		_ctrlScroll.destroy();
		_ctrlScroll = nil;
	end
	if _ctrlList then
		_ctrlList.destroy();
		_ctrlList = nil;
	end
	if _ctrlButton then
		_ctrlButton.destroy();
		_ctrlButton = nil;
	end
end

function onClickDown(...)
	if not _bReadOnly then
		return true;
	end
end

function onClickRelease(button, x, y)
	if not _bReadOnly then
		return activate(button);
	end
end

function activate(button)
	if button == 1 or _bActive then
		toggle();
	end
	return true;
end

function isComboBoxReadOnly()
	return _bReadOnly;
end

function setComboBoxReadOnly(bState)
	if _bReadOnly == bState then
		return;
	end
	
	_bReadOnly = bState;
	if _bReadOnly and _bActive then
		toggle();
	end
	refreshDisplay();
end

function setComboBoxVisible(bState)
	if bState == isVisible() then
		return;
	end
	
	setVisible(bState);
	refreshDisplay();
end

function refreshDisplay()
	local bVisible = isVisible();
	
	if not bVisible and _bActive then
		hideList();
	end
	
	if _ctrlButton then
		_ctrlButton.setVisible(not _bReadOnly and bVisible);
	end
	
	if frame and frame[1] and type(frame[1]) == "table" and frame[1].hidereadonly and frame[1].name and frame[1].name[1] then
		if _bReadOnly then
			setFrame("");
		else
			local aOffsets = {};
			if frame[1].offset and frame[1].offset[1] then
				aOffsets = StringManager.split(frame[1].offset[1], ",", true);				
			end
			if #aOffsets == 4 then
				setFrame(frame[1].name[1], aOffsets[1], aOffsets[2], aOffsets[3], aOffsets[4]);
			else
				setFrame(frame[1].name[1]);
			end
		end
	end
end

function refreshButtonDisplay(bActiveParam)
	if _ctrlButton then
		if _bActive or bActiveParam then
			_ctrlButton.setIcon(_sButtonIconActive);
		else
			_ctrlButton.setIcon(_sButtonIcon);
		end
	end
end

function refreshSelectionDisplay()
	if not _bActive or not _ctrlList then
		return;
	end

	local sValue = getValue();
	local nSelection = 0;
	for k,v in ipairs(_tOrderedItems) do
		if v == sValue then
			nSelection = k;
			break;
		end
	end
	_ctrlList.setSelection(nSelection);
end

function toggle(button)
	if _bActive then
		hideList();
	else
		showList();
	end
end

function showList()
	-- Create the list if it does not exist
	local sName = getName() or "";
	if not _ctrlList and (sName or "") ~= "" then
		local sList = sName .. "_cblist";
		local sListScroll = sName .. "_cblistscroll";
		local w,h = getSize();
		
		-- Create the list control
		if unsorted then
			_ctrlList = window.createControl("combobox_list", sList);
		else
			_ctrlList = window.createControl("combobox_list_sorted", sList);
		end
		_ctrlList.setTarget(sName);
		_ctrlList.setAnchor("left", sName, "left", "absolute", -(_tListOffset.x));
		_ctrlList.setAnchor("right", sName, "right", "absolute", _tListOffset.x);
		if _sListDirection == "up" then
			_ctrlList.setAnchor("bottom", sName, "top", "absolute", -(_tListOffset.y));
			_ctrlList.resetAnchor("top");
		else
			_ctrlList.setAnchor("top", sName, "bottom", "absolute", _tListOffset.y);
			_ctrlList.resetAnchor("bottom");
		end
		
		-- Set the list parameters
		_ctrlList.setFonts(_sListFont, _sListSelectedFont);
		_ctrlList.setFrames(_sListFrame, _sListSelectedFrame);
		_ctrlList.setMaxRows(_nListMaxSize);
		
		-- Populate the list
		for k,v in ipairs(_tOrderedItems) do
			_ctrlList.add(k, v, _tItems[v].text, _tItems[v].allowdelete);
		end
		
		-- Create list scroll bar
		_ctrlScroll = window.createControl("combobox_scrollbar", sListScroll);
		_ctrlScroll.setAnchor("left", sList, "right", "absolute", -10);
		_ctrlScroll.setAnchor("top", sList, "top");
		_ctrlScroll.setAnchor("bottom", sList, "bottom");
		_ctrlScroll.setTarget(sList);
	end

	-- Show the list if it exists
	if _ctrlList then
		_bActive = true;
		_ctrlList.setVisible(true);
		_ctrlList.setFocus(true);
		_ctrlList.scrollToSelected();
	end
	refreshButtonDisplay();
	refreshSelectionDisplay();
end

function hideList()
	_bActive = false;
	if _ctrlList then
		_ctrlList.hide();
	end
	refreshButtonDisplay();
end

function hasValue(sValue)
	if _tItems[sValue] then
		return true;
	end
	return false;
end

function setListIndex(nIndex)
	if (nIndex > 0) or (nIndex <= #_tOrderedItems) then
		setListValue(_tItems[_tOrderedItems[nIndex]].text);
	else
		setListValue("");
	end
end

function setListValue(sValue)
	setValue(sValue);
	setTooltipText(sValue);
	refreshSelectionDisplay();
end

function add(sValue, sText, bAllowDelete)
	if not sValue then
		return;
	end
	if type(sText) ~= "string" then 
		sText = sValue;
	end
	
	if type(sValue) == "string" then
		if _tItems[sValue] then
			return;
		end
		_tItems[sValue] = { text = sText, allowdelete = bAllowDelete };
		table.insert(_tOrderedItems, sValue);

		if _ctrlList then
			_ctrlList.add(#_tOrderedItems, sValue, sText, bAllowDelete);
		end

		refreshSelectionDisplay();
	end
end

function addItems(aList)
	for _,sValue in ipairs(aList) do
		add(sValue);
	end
end

function replace(index, sValue, sText, bAllowDelete)
	if not sValue then
		return;
	end
	if type(sText) ~= "string" then 
		sText = sValue;
	end
	
	if type(sValue) == "string" then
		if #_tOrderedItems < index then
			return;
		end
		local sOriginalValue = _tItems[_tOrderedItems[index]];
		_tItems[_tOrderedItems[index]] = nil;
		_tItems[sValue] = { text = sText, allowdelete = bAllowDelete };
		_tOrderedItems[index] = sValue;

		if _ctrlList then
			_ctrlList.replace(index, sValue, sText, bAllowDelete);
		end

		if sOriginalValue and getValue() == sOriginalValue then
			setListValue(sValue);
		end
	end
end

function remove(sValue)
	if not sValue then
		return;
	end
	
	if type(sValue) == "string" then
		if not _tItems[sValue] then
			return;
		end

		local nItemCount = #_tOrderedItems;
		local nIndexToRemove = 0;

		_tItems[sValue] = nil;
		for k,v in ipairs(_tOrderedItems) do
			if sValue == v then
				nIndexToRemove = k;
				break;
			end
		end
		if nIndexToRemove > 0 then
			table.remove(_tOrderedItems, nIndexToRemove);

			if _ctrlList then
				_ctrlList.remove(nIndexToRemove);
			end
			
			if getValue() == sValue then
				setListValue("");
			end
		end
	end
end

function clear()
	_tItems = {};
	_tOrderedItems = {};

	if _ctrlList then
		_ctrlList.clear();
	end
	if _bActive then
		hideList();
	end
end

function getSelectedValue()
    local sValue = getValue();
    for k,v in pairs(_tItems) do
        if v.text == sValue then
            return k;
        end
    end
    return nil;
end

function getValues()
	return _tOrderedItems;
end

function optionClicked(wNewSelection)
	if wNewSelection then
		setListIndex(wNewSelection.Order.getValue());
	else
		setListIndex(0);
	end
	if self.onSelect then
		self.onSelect(getValue());
	end
	_bActive = false;
	hideList();
end

function optionDelete(wDelete)
	local sValue = wDelete.Value.getValue();
	if self.onDelete then
		if self.onDelete(sValue) then
			return;
		end
	end
	remove(sValue);
end
