-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	updateOwner();
	if not Session.IsHost then
		DB.addHandler(DB.getPath(getDatabaseNode()), "onObserverUpdate", updateOwner);
	end
end

function onClose()
	if not Session.IsHost then
		DB.removeHandler(DB.getPath(getDatabaseNode()), "onObserverUpdate", updateOwner);
	end
end

function updateOwner()
	resetMenuItems();
	if allowEdit() then
		registerMenuItem(Interface.getString("ct_menu_effectdelete"), "deletepointer", 3);
		registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 3, 3);
	end
	setEditMode(DB.isOwner(getDatabaseNode()));
end

function allowEdit()
	if Session.IsHost then
		return true;
	end
	if getDatabaseNode().isOwner() then
		return true;
	end
	return false;
end

function setEditMode(bEditMode)
	local bShow = false;
	if allowEdit() then bShow = bEditMode; end
	
	idelete.setVisibility(bShow);
	targeting_add_button.setVisible(bShow);
end

function onMenuSelection(selection, subselection)
	if selection == 3 and subselection == 3 then
		windowlist.deleteChild(self, true);
	end
end

function checkData()
	if label.getValue() ~= DB.getValue(getDatabaseNode(), "label", "") then
		label.setValue(label.getValue());
	end
end

function onDragStart(button, x, y, draginfo)
	if not allowEdit() then
		return;
	end
	checkData();
	local rEffect = EffectManager.getEffect(getDatabaseNode());
	return ActionEffect.performRoll(draginfo, nil, rEffect);
end

function onDrop(x, y, draginfo)
	if not Session.IsHost then
		return;
	end
	if draginfo.isType("combattrackerentry") then
		EffectManager.setEffectSource(getDatabaseNode(), draginfo.getCustomData());
		return true;
	end
end
