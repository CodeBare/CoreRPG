-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bUpdating = false;
local nodeSrc = nil;
local nDefault = 1;

function onInit()
	nodeSrc = window.getDatabaseNode();
	if nodeSrc then
		onUpdate();
		local sPath = DB.getPath(nodeSrc, "isidentified");
		DB.addHandler(sPath, "onAdd", onUpdate);
		DB.addHandler(sPath, "onUpdate", onUpdate);
	end
	notify();
end
function onClose()
	if nodeSrc then
		local sPath = DB.getPath(nodeSrc, "isidentified");
		DB.removeHandler(sPath, "onAdd", onUpdate);
		DB.removeHandler(sPath, "onUpdate", onUpdate);
	end
end
	
function onUpdate()
	if bUpdating then
		return;
	end
	bUpdating = true;
	local nValue = DB.getValue(nodeSrc, "isidentified", nDefault);
	if nValue == 0 then
		setValue(0);
	else
		setValue(1);
	end
	bUpdating = false;
end
function onValueChanged()
	if not bUpdating then
		bUpdating = true;
		if nodeSrc then
			local nValue = getValue();
			-- Workaround to force field update on client; client does not pass network update to other clients if setValue creates value node with default value
			if not nodeSrc.getChild("isidentified") and (nValue == 0) then
				DB.setValue(nodeSrc, "isidentified", "number", 1);
			end
			DB.setValue(nodeSrc, "isidentified", "number", nValue);
		end
		bUpdating = false;
	end
	notify();
end

function notify()
	if window.parentcontrol and window.parentcontrol.window.onIDChanged then
		window.parentcontrol.window.onIDChanged();
	elseif window.onIDChanged then
		window.onIDChanged();
	end
end
