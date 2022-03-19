-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	buildWindows();
end

function buildWindows()
	closeAll();

	createWindow().setData("");

	for _,sName in ipairs(ReferenceManualManager.getBlockFrames()) do
		createWindow().setData(sName);
	end
end
