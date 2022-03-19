-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onClickDown()
	if isReadOnly() then
		return true;
	end
end

function onClickRelease()
	if isReadOnly() then
		window.list.setVisible(not window.list.isVisible());
		if window.list.isVisible() then
			local tPageWindows = window.list.getWindows(true);
			if #tPageWindows ~= 0 then
				tPageWindows[1].name.activate();
			end
		end
	end
end
