-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _bLocked = false;
local _sLink = nil;

function onInit()
	local nIndent = DB.getValue(window.getDatabaseNode(), "indent", 0);
	if (nIndent > 0) then
		setAnchor("left", "frame", "left", "absolute", 10 + (nIndent * 10));
	end

	updateLink();
end

function onClose()
	if _sLink then
		DB.removeHandler(_sLink, "onUpdate", onLinkUpdated);
	end
end

function onHover(bOnControl)
	setUnderline(bOnControl);
end

function onGainFocus()
	if not isReadOnly() then
		activate();
	end
end

function onClickDown(button, x, y)
	if isReadOnly() then
		return true;
	end
end

function onClickRelease(button, x, y)
	if isReadOnly() then
		activate();
		return true;
	end
end

function activate()
	local sClass, sRecord = window.listlink.getValue();
	local wTop = UtilityManager.getTopWindow(window);
	wTop.activateLink(sClass, sRecord);
end

function onValueChanged()
	if _sLink and not _bLocked then
		_bLocked = true;
		DB.setValue(_sLink, "string", getValue());
		_bLocked = false;
	end
end

function onLinkUpdated()
	if _sLink and not _bLocked then
		_bLocked = true;
		setValue(DB.getValue(_sLink, ""));
		_bLocked = false;
	end
end

function updateLink()
	if _sLink then
		DB.removeHandler(_sLink, "onUpdate", onLinkUpdated);
		_sLink = nil;
	end

	local nodeWin = window.getDatabaseNode();
	if nodeWin.isStatic() then
		return;
	end

	local node = nil;
	local _,sRecord = window.listlink.getValue();
	if (sRecord or "") ~= "" then
		node = DB.createNode(sRecord);
	end
	if node then
		if nodeWin ~= node then
			local nodeName = node.createChild("name", "string");
			if nodeName then
				_sLink = nodeName.getPath();
				DB.addHandler(_sLink, "onUpdate", onLinkUpdated);
				onLinkUpdated();
			end
		end
	end
end
