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
end
function update()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	name.setReadOnly(bReadOnly);
end
