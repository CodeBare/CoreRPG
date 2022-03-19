-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onHover(bHover)
	setUnderline(bHover, -1);
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	local sValue = getValue();
	if sValue ~= "" then
		window.windowlist.window.handleCategorySelect(sValue);
	end
	return true;
end
