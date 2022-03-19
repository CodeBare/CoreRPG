-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Portrait Select (Native Asset Browser - Requires Client Update to enable Client Assets)
-- local _nodeChar = nil;
-- function setLocalNode(nodeChar)
-- 	_nodeChar = nodeChar;
-- end

-- function onActivate(sAsset)
-- 	CampaignDataManager.setCharPortrait(_nodeChar, sAsset);
-- 	close();
-- end

-- function onValueUpdate()
-- 	local nPage = assets.getPage();
-- 	page_prev.setVisible(nPage > 1);
-- 	page_next.setVisible(nPage < assets.getPageMax());
-- end
-- function handlePagePrev()
-- 	assets.setPage(assets.getPage() - 1);
-- end
-- function handlePageNext()
-- 	assets.setPage(assets.getPage() + 1);
-- end


-- Portrait Select (Old Style)

local _nodeChar = nil;
local _tPath = {};

function onInit()
	buildWindows();
end

function buildWindows()
	list.closeAll();
	
	if #_tPath > 0 then
		local w = list.createWindowWithClass("portrait_select_up");
		w.icon.setIcon("tokenbagup");
	end
	
	local sPath = table.concat(_tPath, "/");
	for _, v in ipairs(User.getPortraitDirectoryList(sPath)) do
		local w = list.createWindowWithClass("portrait_select_folder");
		w.icon.setIcon("tokenbag");
		w.icon.setTooltipText(v);
	end
	
	for _, v in ipairs(User.getPortraitFileList(sPath)) do
		local w = list.createWindow();
		w.portrait.setFile(v);
		local sPortraitSansModule = StringManager.split(v, "@")[1];
		local aPortraitPath = StringManager.split(sPortraitSansModule, "/");
		if #aPortraitPath > 0 then
			w.portrait.setTooltipText(aPortraitPath[#aPortraitPath]);
		end
	end
end

function setLocalNode(nodeChar)
	_nodeChar = nodeChar;
end

function onActivate(sFile)
	CampaignDataManager.setCharPortrait(_nodeChar, sFile);
	close();
end
function onPathUp()
	if #_tPath > 0 then
		table.remove(_tPath);
		buildWindows();
	end
end
function onPathSelect(sFolder)
	table.insert(_tPath, sFolder);
	buildWindows();
end
