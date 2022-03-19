-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	Interface.onHotkeyActivated = onHotkey;
	
	local node = getDatabaseNode();
	DB.addHandler(DB.getPath(node, "*.name"), "onUpdate", onNameUpdated);
	DB.addHandler(DB.getPath(node, "*.nonid_name"), "onUpdate", onNameUpdated);
	DB.addHandler(DB.getPath(node, "*.isidentified"), "onUpdate", onNameUpdated);

	OptionsManager.registerCallback("CTSI", onOptionCTSIChanged);
end

function onClose()
	local node = getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "*.name"), "onUpdate", onNameUpdated);
	DB.removeHandler(DB.getPath(node, "*.nonid_name"), "onUpdate", onNameUpdated);
	DB.removeHandler(DB.getPath(node, "*.isidentified"), "onUpdate", onNameUpdated);

	OptionsManager.unregisterCallback("CTSI", onOptionCTSIChanged);
end

function onNameUpdated(vNode)
	for _,w in pairs(getWindows()) do
		w.target_summary.onTargetsChanged();
	end
end

function onOptionCTSIChanged()
	for _,v in pairs(getWindows()) do
		v.updateDisplay();
	end
	applySort();
end

function onSortCompare(w1, w2)
	return CombatManager.onSortCompare(w1.getDatabaseNode(), w2.getDatabaseNode());
end

function onHotkey(draginfo)
	local sDragType = draginfo.getType();
	if sDragType == "combattrackernextactor" then
		CombatManager.notifyEndTurn();
		return true;
	end
end

function onFilter(w)
	if w.friendfoe.getStringValue() == "friend" then
		return true;
	end
	if w.tokenvis.getValue() ~= 0 then
		return true;
	end
	return false;
end

function onDrop(x, y, draginfo)
	local w = getWindowAt(x,y);
	if w then
		local nodeWin = w.getDatabaseNode();
		if nodeWin then
			return CombatManager.onDrop("ct", nodeWin.getPath(), draginfo);
		end
	end
end

function onClickDown(button, x, y)
	if Input.isControlPressed() then
		return true;
	end
end

function onClickRelease(button, x, y)
	if Input.isControlPressed() then
		local w = getWindowAt(x, y);
		if w then
			TargetingManager.toggleClientCTTarget(w.getDatabaseNode());
		end

		return true;
	end
end
