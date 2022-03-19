--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local cButton = nil;

function onInit()
	Interface.onDesktopInit = onDesktopInit
end

function onDesktopInit()
	update();
	OptionsManager.registerCallback("MANUALROLL", update);
end

function update()
	if OptionsManager.isOption("MANUALROLL", "on") then
		if not cButton then
			local w = ChatManager.getChatWindow();
			if w then
				cButton = w.createControl("button_manualrolls", "manualrolls");
			end
		end
	else
		if cButton then
			cButton.destroy();
			cButton = nil;
		end
		local wRolls = Interface.openWindow("manualrolls", "");
		if wRolls then
			wRolls.list.closeAll();
			wRolls.close();
		end
	end
end

function addRoll(rRoll, rSource, vTargets)
	local wMain = Interface.openWindow("manualrolls", "");
	local wRoll = wMain.list.createWindow();
	wRoll.setData(rRoll, rSource, vTargets);
end
