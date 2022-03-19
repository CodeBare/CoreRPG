-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	for _,w in pairs(getWindows()) do
		ReferenceManualManager.onBlockRebuild(w);
	end
end

function onDrop(x, y, draginfo)
	return ReferenceManualManager.onBlockDrop(getWindowAt(x, y), draginfo);
end

function activate()
    local sRecord = DB.getPath(window.getDatabaseNode());
    local wTop = UtilityManager.getTopWindow(window);
    wTop.activateLink("reference_manualtextwide", sRecord);
end
