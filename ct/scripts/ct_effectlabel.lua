-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onDragStart(button, x, y, draginfo)
	if window.onDragStart then
		return window.onDragStart(button, x, y, draginfo);
	end
end

function onDrop(x, y, draginfo)
	if window.onDrop then
		return window.onDrop(x, y, draginfo);
	end
end

function onEnter()
	if window.windowlist and window.windowlist.onEnter then
		return window.windowlist.onEnter();
	end
end

function onGainFocus()
	window.setFrame("rowshade");
end

function onLoseFocus()
	window.setFrame(nil);
end
