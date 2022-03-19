-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sName;

function onInit()
	sName = getName();
end

function onEnter()
	if not isReadOnly() and window.windowlist.addEntry then
		window.windowlist.addEntry(true);
	end
	return true;
end

function onNavigateDown()
	local winNext = window.windowlist.getNextWindow(window);
	if winNext and winNext[sName] then
		winNext[sName].setFocus();
		winNext[sName].setCursorPosition(1);
		winNext[sName].setSelectionPosition(1);
	end
	return winNext;
end

function onNavigateUp()
	local winPrev = window.windowlist.getPrevWindow(window);
	if winPrev and winPrev[sName] then
		winPrev[sName].setFocus();
		winPrev[sName].setCursorPosition(#winPrev[sName].getValue()+1);
		winPrev[sName].setSelectionPosition(#winPrev[sName].getValue()+1);
	end
	return winPrev;
end

function onGainFocus()
	if nohighlight then
		return;
	end
	window.setFrame("rowshade");
end

function onLoseFocus()
	if nohighlight then
		return;
	end
	window.setFrame(nil);
end
