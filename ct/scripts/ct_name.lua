-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if Session.IsHost then
		setHoverCursor("hand");
	end
end

function onDragStart(button, x, y, draginfo)
	if Session.IsHost then
		draginfo.setType("combattrackerentry");
		draginfo.setStringData(getValue());
		draginfo.setCustomData(window.getDatabaseNode());
		return true;
	end
end
