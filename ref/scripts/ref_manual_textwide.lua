-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onLockChanged()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	name.setReadOnly(bReadOnly);
	
	if content and content.subwindow then
		content.subwindow.update();
	end
end
