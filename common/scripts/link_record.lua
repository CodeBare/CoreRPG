-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onDragStart(button, x, y, draginfo)
	local sClass, sRecord = getValue();
	local sRecordType = LibraryData.getRecordTypeFromDisplayClass(sClass);

	draginfo.setType("shortcut");
	draginfo.setIcon("button_link");
	draginfo.setShortcutData(sClass, sRecord);
	
	local nodeWin = window.getDatabaseNode();
	
	local sDesc;
	local bID = true;
	if (sRecordType or "") ~= "" then
		bID = LibraryData.getIDState(sRecordType, nodeWin, true);

		if bID == true then
			sDesc = DB.getValue(nodeWin, "name", "");
			if sDesc == "" then
				sDesc = Interface.getString("library_recordtype_empty_" .. sRecordType);
			end
		else
			sDesc = DB.getValue(nodeWin, "nonid_name", "");
			if sDesc == "" then
				sDesc = Interface.getString("library_recordtype_empty_nonid_" .. sRecordType);
			end
		end

		local sDisplayTitle = LibraryData.getSingleDisplayText(sRecordType);
		if (sDisplayTitle or "") ~= "" then
			sDesc = sDisplayTitle .. ": " .. sDesc;
		end
	else
		sDesc = DB.getValue(nodeWin, "name", "");
	end
	
	draginfo.setDescription(sDesc);
	return true;
end
