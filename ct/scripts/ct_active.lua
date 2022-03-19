-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onValueChanged();
end

function onValueChanged()
	local bActive = (getValue() == 1);
	
	window.updateDisplay();
	if bActive then
		window.windowlist.scrollToWindow(window);
	end
	
	if window.onActiveChanged then
		window.onActiveChanged(bActive)
	end
	
	if bActive and OptionsManager.isOption("CMAT", "on") then
		CombatManager.centerOnToken(window.getDatabaseNode(), false);
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if (getValue() == 0) and Session.IsHost then
		CombatManager.requestActivation(window.getDatabaseNode(), true);
	end
	return true;
end

function onDragStart(button, x, y, draginfo)
	if (getValue() == 1) and Session.IsHost then
		draginfo.setType("combattrackeractivation");
		draginfo.setIcon("ct_active");
		return true;
	end
end

function onDrop(x, y, draginfo)
	if draginfo.isType("combattrackeractivation") then
		CombatManager.requestActivation(window.getDatabaseNode(), true);
		return true;
	end
end