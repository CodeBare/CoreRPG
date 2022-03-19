-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onDrop(x, y, draginfo)
	local sDragType = draginfo.getType();
	if sDragType == "string" then
		local sLang = draginfo.getStringData();
		local wFound = nil;
		for _,w in ipairs(getWindows()) do
			if w.name.getValue() == sLang then
				wFound = w;
				break;
			end
		end
		if wFound then
			wFound.name.setFocus(true);
		else
			local w = addEntry(true);
			w.name.setValue(draginfo.getStringData());
		end
		return true;
	end
end
