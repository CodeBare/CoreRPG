-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _sClass;
local _sRecord;

function setData(tButton)
	_sClass = tButton.sClass;
	_sRecord = tButton.sPath;
	local sLabel = Interface.getString(tButton.sLabelRes or ("sidebar_tooltip_" .. _sClass));
	iconbase.setTooltipText(sLabel);

	updateTheming();
	updateIcon(tButton.sIcon);
end

function getCategory()
	return DesktopManager.getSidebarToolCategory();
end

function updateTheming()
	local szArea = DesktopManager.getSidebarDockButtonSize();
	local rcOffset = DesktopManager.getSidebarDockButtonOffset();
	local szIconPadding = DesktopManager.getSidebarDockButtonIconPadding();
	local nIconArea = math.min(szArea.w, szArea.h);

	spacer.setAnchoredWidth(nIconArea + (rcOffset.left + rcOffset.right));
	spacer.setAnchoredHeight(nIconArea + (rcOffset.top + rcOffset.bottom));

	iconbase.setAnchor("left", "", "left", "absolute", rcOffset.left);
	iconbase.setAnchor("top", "", "top", "absolute", rcOffset.top);
	iconbase.setAnchoredWidth(nIconArea);
	iconbase.setAnchoredHeight(nIconArea);
	icon.setAnchor("left", "", "left", "absolute", rcOffset.left + math.min(szIconPadding.w, szArea.w));
	icon.setAnchor("top", "", "top", "absolute", rcOffset.top + math.min(szIconPadding.h, szArea.h));
	icon.setAnchoredWidth(math.max(nIconArea - (szIconPadding.w * 2), 0));
	icon.setAnchoredHeight(math.max(nIconArea - (szIconPadding.h * 2), 0));
end

function updateIcon(sIcon)
	if not sIcon then
		sIcon = "sidebar_icon_link_" .. _sClass;
	end
	if Interface.isIcon(sIcon) then
		icon.setIcon(sIcon);
	else
		icon.setIcon("sidebar_icon_default");
	end
	icon.setColor(DesktopManager.getSidebarDockIconColor());
end

--
--  UI Events
--

function updateFrame(bPressed)
	if bPressed then
		if Interface.isFrame("sidebar_dock_entry_icon_down") then
			iconbase.setFrame("sidebar_dock_entry_icon_down");
		elseif Interface.isFrame("sidebar_dock_entry_down") then
			iconbase.setFrame("sidebar_dock_entry_down");
		end
	else
		iconbase.setFrame("sidebar_dock_entry_icon");
	end
end

function onClickDown()
	updateFrame(true);
	return true;
end
function onClickRelease()
	if _sClass then
		Interface.toggleWindow(_sClass, _sRecord);
	end
	updateFrame(false);
	return true;
end

function onDragStart(button, x, y, draginfo)
	if _sClass then
		draginfo.setType("shortcut");
		draginfo.setIcon("button_link");
		draginfo.setShortcutData(_sClass, _sRecord or "");
		draginfo.setDescription(getTooltipText());
	end
	return true;
end
function onDragEnd(draginfo)
	updateFrame(false);
end
