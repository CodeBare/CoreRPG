-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bUpdating = false;
local nodeSrc = nil;
local nDefault = 0;

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	
	nodeSrc = window.getDatabaseNode();
	if nodeSrc and nodeSrc.getModule() then
		nDefault = 1;
	end
	if nodeSrc and not nodeSrc.isReadOnly() then
		onUpdate();
		DB.addHandler(DB.getPath(nodeSrc, "locked"), "onUpdate", onUpdate);
	else
		nodeSrc = nil;
		setVisible(false);
	end
	notify();
end
function onClose()
	if nodeSrc then
		DB.removeHandler(DB.getPath(nodeSrc, "locked"), "onUpdate", onUpdate);
	end
end
	
function onUpdate()
	if bUpdating then
		return;
	end
	bUpdating = true;
	local nValue = DB.getValue(nodeSrc, "locked", nDefault);
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
			DB.setValue(nodeSrc, "locked", "number", getValue());
		end
		bUpdating = false;
	end
	notify();
end

function notify()
	if window.onLockChanged then
		window.onLockChanged();
	elseif window.parentcontrol and window.parentcontrol.window.onLockChanged then
		window.parentcontrol.window.onLockChanged();
	end
end
