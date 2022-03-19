-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local winParentBar = nil;
local sButtonID = "";

function onButtonPress()
	if winParentBar and winParentBar.onButtonPress then
		winParentBar.onButtonPress(sButtonID);
	end
end

function configure(win, sID, sIcon, sTooltip, bToggle)
	winParentBar = win;
	sButtonID = sID;

	local sColor0, sColor1;
	if iconcolor and iconcolor[1] then
		sColor0 = "60" .. iconcolor[1];
		sColor1 = "FF" .. iconcolor[1];
	else
		sColor0 = "60A0A0A0";
		sColor1 = "FFFFFFFF";
	end
	
	if bToggle then
		setStateIcons(0, sIcon);
		setStateColor(0, sColor0);
		setStateIcons(1, sIcon);
		setStateColor(1, sColor1);
	else
		setIcons(sIcon);
		setStateColor(0, sColor1);
	end
	
	setTooltipText(sTooltip);
end
