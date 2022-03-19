-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function getReadOnlyState(vNode)
	if not DB.isOwner(vNode) then
		return true;
	end
	if DB.isReadOnly(vNode) then
		return true;
	end
	return WindowManager.getLockedState(vNode);
end

function getLockedState(vNode)
	local nDefault = 0;
	if (DB.getModule(vNode) or "") ~= "" then
		nDefault = 1;
	end
	local bLocked = (DB.getValue(DB.getPath(vNode, "locked"), nDefault) ~= 0);
	return bLocked;
end
