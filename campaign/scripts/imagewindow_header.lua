-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if Session.IsHost then
		nonid_name.resetAnchor("left");
		nonid_name.setAnchor("left", nil, "center", "absolute", 10);
		self.onSizeChanged = update;
	end
	update();
end

function update()
	local nodeRecord = getDatabaseNode();

	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	name.setReadOnly(bReadOnly);
	nonid_name.setReadOnly(bReadOnly);
	
	local bID = LibraryData.getIDState("image", nodeRecord);
	if Session.IsHost then
		local w,h = getSize();
		local bShowNonID = (w >= 450);
		isidentified.setVisible(bShowNonID);
		nonid_name.setVisible(bShowNonID);
	else
		name.setVisible(bID);
		nonid_name.setVisible(not bID);
	end
end
