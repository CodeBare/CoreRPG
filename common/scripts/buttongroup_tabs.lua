-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bHorizontal = false;

local aTabs = {};
local tabIndex = 0;

local helperWidget = nil;
local aVerticalHelperIconOffset = { 8, 7 };
local aHorizontalHelperIconOffset = { 7,10 };

local aVerticalTabIconOffset = { 7, 41 };
local aHorizontalTabTextOffset = { 41,8 };
local nTabSize = 67;
local nMargins = 25;

function onInit()
	if horizontal then
		bHorizontal = true;
	end
	
	-- Create a helper graphic widget to indicate that the selected tab is on top
	if bHorizontal then
		helperWidget = addBitmapWidget("tabtop_h");
	else
		helperWidget = addBitmapWidget("tabtop");
	end
	helperWidget.setVisible(false);

	-- Deactivate all labels
	if tab and type(tab) == "table" then
		for n, v in ipairs(tab) do
			if type(v) == "table" then
				if bHorizontal then
					local sText = "";
					if v.textres then
						sText = Interface.getString(v.textres[1]);
					elseif v.text then
						sText = v.text[1];
					end
					setTab(n, v.subwindow[1], sText);
				else
					setTab(n, v.subwindow[1], v.icon[1]);
				end
			end
		end
	end

	if activate then
		activateTab(activate[1]);
	else
		activateTab(1);
	end
end

function hideControls(index)
	if aTabs[index] then
		for _,v in ipairs(aTabs[index].controls) do
			window[v].setVisible(false);
		end
	end
end

function showControls(index)
	if aTabs[index] then
		for _,v in ipairs(aTabs[index].controls) do
			window[v].setVisible(true);
		end
	end
end

function activateTab(index)
	local newIndex = tonumber(index) or 1;
	if tabIndex == newIndex then
		return;
	end
	
	-- Deactivate current tab
	deactivateEntry(tabIndex);

	-- Set new index
	tabIndex = newIndex;

	-- Move helper graphic into position
	if bHorizontal then
		helperWidget.setPosition("topleft", (nTabSize * (tabIndex - 1)) + aHorizontalHelperIconOffset[1], aHorizontalHelperIconOffset[2]);
	else
		helperWidget.setPosition("topleft", aVerticalHelperIconOffset[1], (nTabSize * (tabIndex - 1)) + aVerticalHelperIconOffset[2]);
	end
	if tabIndex == 1 then
		helperWidget.setVisible(false);
	else
		helperWidget.setVisible(true);
	end
		
	-- Activate new tab
	activateEntry(tabIndex);
end

-- Show tab controls and brighten tab text/icon label
function activateEntry(index)
	if index >= 1 and index <= #aTabs then
		if bHorizontal then
			aTabs[tabIndex].widget.setColor("FF000000");
		else
			aTabs[tabIndex].widget.setColor("FFFFFFFF");
		end
		showControls(tabIndex);
	end
end

-- Hide tab controls and fade tab text/icon label
function deactivateEntry(index)
	if index >= 1 and index <= #aTabs then
		if bHorizontal then
			aTabs[index].widget.setColor("80000000");
		else
			aTabs[index].widget.setColor("80FFFFFF");
		end
		hideControls(index);
	end
end

function setVisibility(bState)
	setVisible(bState);
	if bState then
		showControls(tabIndex);
	else
		hideControls(tabIndex);
	end
end

function getTabCount()
	return #aTabs;
end

function getTab(index)
	if aTabs[index] then
		return aTabs[index].sub, aTabs[index].display;
	end
	return nil, nil;
end

function setTab(index, sSub, sDisplay)
	local rTab = aTabs[index];
	if sSub and sDisplay then
		if rTab then
			if sSub == rTab.sub and sDisplay == rTab.display then
				return;
			end
			if index == tabIndex then
				hideControls(index);
			end
			if rTab.widget then
				rTab.widget.destroy();
				rTab.widget = nil;
			end
		else
			rTab = {};
			aTabs[index] = rTab;
		end
		
		rTab.sub = sSub;
		rTab.controls = StringManager.split(sSub, ",", true);
		
		rTab.display = sDisplay;
		if bHorizontal then
			rTab.widget = addTextWidget("tabfont", sDisplay);
			rTab.widget.setPosition("topleft", (nTabSize * (index - 1)) + aHorizontalTabTextOffset[1], aHorizontalTabTextOffset[2]);
		else
			rTab.widget = addBitmapWidget(sDisplay);
			rTab.widget.setPosition("topleft", aVerticalTabIconOffset[1], (nTabSize * (index - 1)) + aVerticalTabIconOffset[2]);
		end
		
		if index == tabIndex then
			activateEntry(index);
		else
			deactivateEntry(index);
		end
	else
		if rTab then
			if index == tabIndex then
				hideControls(index);
			end
			
			if rTab.widget then
				rTab.widget.destroy();
			end
			aTabs[index] = nil;
		end
	end
	
	local nMax = 0;
	for k,_ in pairs(aTabs) do
		nMax = math.max(k, nMax);
	end
	if bHorizontal then
		setAnchoredWidth(nMargins + (nTabSize * nMax));
	else
		setAnchoredHeight(nMargins + (nTabSize * nMax));
	end
	
	if tabIndex > nMax then
		activateTab(nMax);
	end
end

function addTab(sSub, sDisplay, bActivate)
	local nIndex = #aTabs+1
	setTab(nIndex, sSub, sDisplay)
	if bActivate then
		activateTab(nIndex)
	end
end

function getIndex()
	return tabIndex;
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	local i;
	if bHorizontal then
		i = math.ceil(x / nTabSize);
	else
		i = math.ceil(y / nTabSize);
	end

	if i >= 1 and i <= #aTabs then
		activateTab(i);
	end
	
	return true;
end

function onDoubleClick(x, y)
	-- Emulate click
	onClickRelease(1, x, y);
end
