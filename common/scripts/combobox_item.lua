-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bSelected = false;

local sFont = "";
local sSelectedFont = "";
local sFrame = "";
local sSelectedFrame = "";

function onInit()
	setSelected(bSelected);
end

function setFonts(sNormal, sSelection)
	sFont = sNormal or "";
	sSelectedFont = sSelection or "";

	setSelected(bSelected);
end

function setFrames(sNormal, sSelection)
	sFrame = sNormal or "";
	sSelectedFrame = sSelection or "";

	setSelected(bSelected);
end

function isSelected()
	return bSelected;
end

function setSelected(bValue)
	if bValue then
		bSelected = true;
		setFrame(sSelectedFrame);
		Text.setFont(sSelectedFont);
	else
		bSelected = false;
		setFrame(sFrame);
		Text.setFont(sFont);
	end
end

function clicked()
	windowlist.optionClicked(self);
end

function delete()
	windowlist.optionDelete(self);
end
