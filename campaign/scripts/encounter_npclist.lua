-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onListChanged()
	update();
end

function update()
	local bEditMode = (window.npcs_iedit.getValue() == 1);
	if window.idelete_header then
		window.idelete_header.setVisible(bEditMode);
	end
	for _,w in ipairs(getWindows()) do
		w.idelete.setVisibility(bEditMode);
	end
end

function addEntry(bFocus)
	local w = createWindow();
	if bFocus then
		if w.getClass() == "battlerandom_npc" then
			w.expr.setFocus();
		else
			w.count.setFocus();
		end
	end
	return w;
end

function onDrop(x, y, draginfo)
	if isReadOnly() then
		return;
	end
	
	if draginfo.isType("shortcut") then
		local sClass,sRecord = draginfo.getShortcutData();
		NPCManager.addLinkToBattle(window.getDatabaseNode(), sClass, sRecord);
		return true;
	end
end
