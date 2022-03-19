-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _sTarget = "";

local _sFont = "";
local _sSelectedFont = "";
local _sFrame = "";
local _sSelectedFrame = "";

local _nDisplayRows = 0;
local _nMaxRows = 0;
local _nRowHeight = 20;

function onLoseFocus()
	window[_sTarget].hideList();
end

function optionClicked(opt)
	window[_sTarget].optionClicked(opt);
end

function optionDelete(opt)
	window[_sTarget].optionDelete(opt);
end

function setTarget(sTarget)
	_sTarget = sTarget;
end

function setFonts(sNormal, sSelection)
	_sFont = sNormal or "";
	_sSelectedFont = sSelection or "";

	for _,w in ipairs(getWindows()) do
		w.setFonts(_sFont, _sSelectedFont);
	end
end

function setFrames(sNormal, sSelection)
	_sFrame = sNormal or "";
	_sSelectedFrame = sSelection or "";

	for _,w in ipairs(getWindows()) do
		w.setFrames(_sFrame, _sSelectedFrame);
	end
end

function setMaxRows(nNewMaxRows)
	_nMaxRows = nNewMaxRows;
	adjustHeight();
end

function adjustHeight()
	local nNewDisplayRows = getWindowCount();
	if _nMaxRows > 0 then
		nNewDisplayRows = math.min(_nMaxRows, nNewDisplayRows);
	end
	if nNewDisplayRows ~= _nDisplayRows then
		_nDisplayRows = nNewDisplayRows
		setAnchoredHeight(_nDisplayRows * _nRowHeight);
	end
end

function hide()
	setVisible(false);
	for _,w in ipairs(getWindows()) do
		w.idelete.setValue(0);
	end
end

function setSelection(index)
	local wSelected = nil;
	for _,w in ipairs(getWindows()) do
		if w.Order.getValue() == index then
			w.setSelected(true);
		else
			w.setSelected(false);
		end
	end
	scrollToSelected();
end

function scrollToSelected()
	local wSelected = nil;
	for _,w in ipairs(getWindows()) do
		if w.isSelected() then
			scrollToWindow(w);
			break;
		end
	end
end

function add(index, sValue, sText, bAllowDelete)
	local wExisting = getIndexWindow(index);
	if wExisting then
		replace(index, sValue, sText, bAllowDelete);
		return;
	end

	local w = createWindow();
	w.setFonts(_sFont, _sSelectedFont);
	w.setFrames(_sFrame, _sSelectedFrame);
	w.Text.setValue(sText);
	w.Value.setValue(sValue);
	w.Order.setValue(index);
	if bAllowDelete then
		w.idelete.setVisible(true);
	end
	adjustHeight();
end

function replace(index, sValue, sText, bAllowDelete)
	local w = getIndexWindow(index);
	if not w then
		return;
	end

	w.Text.setValue(sText);
	w.Value.setValue(sValue);
	if bAllowDelete then
		w.idelete.setVisible(true);
	else
		w.idelete.setVisible(false);
	end
end

function remove(index)
	local w = getIndexWindow(index);
	if not w then
		return;
	end

	w.close();
	for _,w in ipairs(getWindows()) do
		if w.Order.getValue() > index then
			w.Order.setValue(w.Order.getValue() - 1);
		end
	end
	adjustHeight();
end

function clear()
	closeAll();
end

function getIndexWindow(index)
	for _,w in ipairs(getWindows()) do
		if w.Order.getValue() == index then
			return w;
		end
	end
	return nil;
end
