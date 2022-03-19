-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _sCategory;
local _sLabel;

--
--	Data
--

function setCategory(sCategory, tButtons)
	_sCategory = sCategory;
	_sLabel = LibraryData.getCategoryDisplayText(_sCategory);
    iconbase.setTooltipText(_sLabel);

    updateTheming();
    updateState();

    if sCategory == DesktopManager.getSidebarToolCategory() then
	    for _,vButton in ipairs(tButtons) do
			local w = list.createWindowWithClass("sidebar_stack_entry");
			w.setData(vButton);
	    end
    else
		for _,vButton in ipairs(tButtons) do
			local w = list.createWindow();
			w.setData(vButton);
		end
    end
end
function getCategory()
	return _sCategory;
end

function updateTheming()
	local nSidebarVisState = DesktopManager.getSidebarVisibilityState();
	local nSidebarWidth = DesktopManager.getSidebarDockWidth();
	local nDockIconWidth = DesktopManager.getSidebarDockIconWidth();

	local szArea;
	if nSidebarVisState <= 0 then
		szArea = DesktopManager.getSidebarDockCategorySize();
	else
		szArea = DesktopManager.getSidebarDockCategorySize();
		szArea.w = DesktopManager.getSidebarDockWidth();
	end

	local rcOffset = DesktopManager.getSidebarDockCategoryOffset();

	local szPadding = DesktopManager.getSidebarDockCategoryPadding();
	if nSidebarVisState == 2 then
		szPadding.w = math.floor(szPadding.w / 2);
	end
	local nTextOffset = DesktopManager.getSidebarDockCategoryTextOffset();
	if nSidebarVisState > 0 then
		nTextOffset = 0;
	end

	local sIconColor = DesktopManager.getSidebarDockCategoryIconColor();
	local sTextColor = DesktopManager.getSidebarDockCategoryTextColor();

	local nIconSize = math.min(szArea.w - (szPadding.w * 2), szArea.h - (szPadding.h * 2));

	spacer.setAnchoredWidth(szArea.w + (rcOffset.left + rcOffset.right));
	spacer.setAnchoredHeight(szArea.h + (rcOffset.top + rcOffset.bottom));

	base.setAnchor("left", "", "left", "absolute", rcOffset.left);
	base.setAnchor("top", "", "top", "absolute", rcOffset.top);
	base.setAnchoredWidth(szArea.w);
	base.setAnchoredHeight(szArea.h);
	iconbase.setAnchor("left", "", "left", "absolute", rcOffset.left);
	iconbase.setAnchor("top", "", "top", "absolute", rcOffset.top);
	iconbase.setAnchoredWidth(nIconSize + szPadding.w + nTextOffset);
	iconbase.setAnchoredHeight(nIconSize + (szPadding.h * 2));
	icon.setAnchor("left", "", "left", "absolute", rcOffset.left + math.min(szPadding.w, szArea.w));
	icon.setAnchor("top", "", "top", "absolute", rcOffset.top + math.min(szPadding.h, szArea.h));
	icon.setAnchoredWidth(math.max(nIconSize, 0));
	icon.setAnchoredHeight(math.max(nIconSize, 0));
	label.setAnchor("left", "", "left", "absolute", rcOffset.left + math.min(szPadding.w + nIconSize + nTextOffset, szArea.w));
	label.setAnchor("top", "", "top", "absolute", rcOffset.top + math.min(szPadding.h, szArea.h));
	label.setAnchoredWidth(math.max(szArea.w - nIconSize - nTextOffset - (szPadding.w * 2), 0));
	label.setAnchoredHeight(math.max(szArea.h - (szPadding.h * 2), 0));

	icon.setColor(sIconColor);
	label.setColor(sTextColor);

	if nSidebarVisState == 2 then
	    label.setValue(_sLabel:sub(1,1));
	elseif nSidebarVisState == 1 then
	    label.setValue(_sLabel:sub(1,4));
	else
	    label.setValue(_sLabel);
	end

	list.setAnchoredWidth(nSidebarWidth);
	if _sCategory == DesktopManager.getSidebarToolCategory() then
		list.setColumnWidth(nDockIconWidth);
	else
		if nSidebarVisState > 0 then
			list.setColumnWidth(nDockIconWidth);
		else
			list.setColumnWidth(0);
		end
	end

	for _,w in ipairs(list.getWindows()) do
		w.updateTheming();
	end
end
function updateState()
	if DesktopManager.getSidebarCategoryState(_sCategory) then
		icon.setIcon("sidebar_dock_category_expanded");
		list.setVisible(true);
	else
		icon.setIcon("sidebar_dock_category_collapsed");
		list.setVisible(false);
	end
end
function updateFrame(bPressed)
	if bPressed then
		base.setFrame("sidebar_dock_category_down");
	else
		base.setFrame("sidebar_dock_category");
	end		
end

--
--	UI Events
--

function onClickDown()
	updateFrame(true);
	return true;
end
function onClickRelease()
    DesktopManager.toggleSidebarCategoryState(_sCategory);
	updateFrame(false);
    return true;
end

function onDragStart(button, x, y, draginfo)
	return true;
end
function onDragEnd(draginfo)
	updateFrame(false);
end
