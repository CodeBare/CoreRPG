-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onStateChanged();
	onNameUpdated();
end

function onLockChanged()
	onStateChanged();
end

function onIDChanged()
	onStateChanged();
	onNameUpdated();
end

function onStateChanged()
	if header.subwindow then
		header.subwindow.update();
	end
	if main.subwindow then
		main.subwindow.update();
	end
end

function onNameUpdated()
	local nodeRecord = getDatabaseNode();
	local bID = LibraryData.getIDState("item", nodeRecord, true);
	
	local sTooltip = "";
	if bID then
		sTooltip = DB.getValue(nodeRecord, "name", "");
		if sTooltip == "" then
			sTooltip = Interface.getString("library_recordtype_empty_item")
		end
	else
		sTooltip = DB.getValue(nodeRecord, "nonid_name", "");
		if sTooltip == "" then
			sTooltip = Interface.getString("library_recordtype_empty_nonid_item")
		end
	end
	setTooltipText(sTooltip);
	if header.subwindow and header.subwindow.link then
		header.subwindow.link.setTooltipText(sTooltip);
	end
end
