-- 
-- Please see the readme.txt file included with this distribution for 
-- attribution and copyright information.
--

function onDrop(x, y, draginfo)
	local sPrototype, dropref = draginfo.getTokenData();
	if (sPrototype or "") == "" then
		return nil;
	end
	
	setPrototype(sPrototype);
	PartyManager.replacePartyToken(window.getDatabaseNode(), dropref);
	return true;
end

function onDragStart(button, x, y, draginfo)
	if not Session.IsHost then
		return false;
	end
end
function onDragEnd(draginfo)
	local _, dropref = draginfo.getTokenData();
	if dropref then
		PartyManager.replacePartyToken(window.getDatabaseNode(), dropref);
	end
	return true;
end

function onClickDown(button, x, y)
	return true;
end
function onClickRelease(button, x, y)
	-- Left click to toggle activation outline for linked token
	if button == 1 then
		if Session.IsHost then
			window.link.activate();
		end
	end

	return true;
end

function onWheel(notches)
	TokenManager.onWheelCT(window.getDatabaseNode(), notches);
	return true;
end
