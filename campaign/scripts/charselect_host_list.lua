-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onListChanged()
	update();
end

function update()
	local bEditMode = (window.list_iedit.getValue() == 1);
	for _,w in pairs(getWindows()) do
		w.idelete.setVisibility(bEditMode);
		w.iexport.setVisible(bEditMode);
	end
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		return CampaignDataManager.handleDrop("charsheet", draginfo);
	end
end
