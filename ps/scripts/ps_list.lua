-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onListChanged()
	update();
end

function update()
	local bEditMode = (window.list_iedit.getValue() == 1);
	for _,w in ipairs(getWindows()) do
		w.idelete.setVisibility(bEditMode);
	end
end

function onDrop(x, y, draginfo)
	if Session.IsHost then
		if draginfo.isType("shortcut") then
			local sClass = draginfo.getShortcutData();
			if sClass == "charsheet" then
				PartyManager.addChar(draginfo.getDatabaseNode());
			end
			return true;
		end
	end
	return false;
end
