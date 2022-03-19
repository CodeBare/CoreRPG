-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if Session.IsHost then
		setTokenOrientationMode(false);
	end
	onCursorModeChanged();
end

function onCursorModeChanged(sTool)
	window.onCursorModeChanged();
end

function onStateChanged()
	window.onStateChanged();
end

function onTargetSelect(aTargets)
	local aSelected = getSelectedTokens();
	if #aSelected == 0 then
		local tokenActive = TargetingManager.getActiveToken(self);
		if tokenActive then
			local bAllTargeted = true;
			for _,vToken in ipairs(aTargets) do
				if not vToken.isTargetedBy(tokenActive) then
					bAllTargeted = false;
					break;
				end
			end
			
			for _,vToken in ipairs(aTargets) do
				tokenActive.setTarget(not bAllTargeted, vToken);
			end
			return true;
		end
	end
end

function onDrop(x, y, draginfo)
	local sDragType = draginfo.getType();
	
	if sDragType == "shortcut" then
		local sClass,_ = draginfo.getShortcutData();
		if sClass == "charsheet" then
			if not Input.isShiftPressed() then
				return true;
			end
		end
		
	elseif sDragType == "combattrackerff" then
		return CombatManager.handleFactionDropOnImage(draginfo, self, x, y);
	end
end
