-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	self.initRecordType();
	self.update();
end

function getRecordTypeAndDisplayClass()
	local wTop = UtilityManager.getTopWindow(self);
	local sClass = wTop.getClass();
	return LibraryData.getRecordTypeFromDisplayClass(sClass), sClass;
end
function initRecordType()
	local sRecordType, sClass = self.getRecordTypeAndDisplayClass();
	link.setValue(sClass);
	name.setEmptyText(Interface.getString("library_recordtype_empty_" .. sRecordType));
	nonid_name.setEmptyText(Interface.getString("library_recordtype_empty_nonid_" .. sRecordType));
end
function update()
	local nodeRecord = getDatabaseNode();

	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	name.setReadOnly(bReadOnly);
	nonid_name.setReadOnly(bReadOnly);

	local sRecordType = self.getRecordTypeAndDisplayClass();
	local bID = LibraryData.getIDState(sRecordType, nodeRecord);
	name.setVisible(bID);
	nonid_name.setVisible(not bID);
end
