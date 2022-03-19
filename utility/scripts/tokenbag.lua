-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local savedPath = "";
local savedFilter = "";

function onInit()
	local sLoadFilter = "";
	if CampaignRegistry and 
			CampaignRegistry.windowstate and
			CampaignRegistry.windowstate.tokenbag then
		sLoadFilter = CampaignRegistry.windowstate.tokenbag.lastfilter or "";
	end
	if Session.IsHost then
		if sLoadFilter == "image" or
				sLoadFilter == "token" or
				sLoadFilter == "portrait" then
			setTypeFilter(sLoadFilter);
		elseif sLoadFilter == "all" then
			setTypeFilter("");
		end
	else
		if sLoadFilter == "token" or
				sLoadFilter == "portrait" then
			setTypeFilter(sLoadFilter);
		elseif sLoadFilter == "all" then
			setTypeFilter("");
		end
		anchor_assetview_filter.setAnchor("left", "", "center", "absolute", -110);
	end
end

function onClose()
	if CampaignRegistry then
		if not CampaignRegistry.windowstate then
			CampaignRegistry.windowstate = {};
		end
		if not CampaignRegistry.windowstate.tokenbag then
			CampaignRegistry.windowstate.tokenbag = {};
		end
		local sSaveFilter = tokens.getTypeFilter();
		if sSaveFilter == "" then
			sSaveFilter = "all";
		end
		CampaignRegistry.windowstate.tokenbag.lastfilter = sSaveFilter;
	end
end

function handleAssetActivate(sAssetName, sAssetType)
	local w = Interface.openWindow("asset_preview", "");
	if w then
		w.setData(sAssetName, sAssetType);
	end
end

function handleViewUpdate()
	button_assetview_viewchange.update();
end

function handleValueUpdate()
	local sFilterName = tokens.getTypeFilter();
	if sFilterName == "image" then
		button_assetview_filter_token.setValue(0);
		button_assetview_filter_portrait.setValue(0);
		button_assetview_filter_image.setValue(1);
		button_assetview_filter_all.setValue(0);
	elseif sFilterName == "portrait" then
		button_assetview_filter_token.setValue(0);
		button_assetview_filter_portrait.setValue(1);
		button_assetview_filter_image.setValue(0);
		button_assetview_filter_all.setValue(0);
	elseif sFilterName == "token" then
		button_assetview_filter_token.setValue(1);
		button_assetview_filter_portrait.setValue(0);
		button_assetview_filter_image.setValue(0);
		button_assetview_filter_all.setValue(0);
	else
		button_assetview_filter_token.setValue(0);
		button_assetview_filter_portrait.setValue(0);
		button_assetview_filter_image.setValue(0);
		button_assetview_filter_all.setValue(1);
	end
	
	local nPage = tokens.getPage();
	local nMaxPage = tokens.getPageMax();
	button_assetview_page_prev.setVisible(nPage > 1);
	button_assetview_page_next.setVisible(nPage < nMaxPage);
	
	local sCurrentPath = tokens.getPathFilter();
	local sCurrentFilter = tokens.getSearchFilter();
	if (savedPath ~= sCurrentPath) or (savedFilter ~= sCurrentFilter) then
		savedPath = sCurrentPath;
		savedFilter = sCurrentFilter;
		rebuildPathList();
	end
end

function rebuildPathList()
	list_path.closeAll();
	
	if (savedPath == "") and (savedFilter == "") then
		button_top.setVisible(false);
		list_path.setVisible(false);
		return;
	end
	
	button_top.setVisible(true);
	list_path.setVisible(true);
	
	if savedFilter ~= "" then
		local w = list_path.createWindowWithClass("assetview_path_filter");
		w.setData(savedFilter);
	end
	if savedPath ~= "" then
		local aPathComps = StringManager.split(savedPath, "/");
		local sPathSoFar = "";
		for k,v in ipairs(aPathComps) do
			if k == #aPathComps then
				local w = list_path.createWindowWithClass("assetview_path_item_current");
				w.setData(v);
			else
				local w = list_path.createWindow();
				if sPathSoFar == "" then
					sPathSoFar = v;
				else
					sPathSoFar = sPathSoFar .. "/" .. v;
				end
				w.setData(v, sPathSoFar);
			end
		end
	end
end

function getView()
	return tokens.getView();
end
function setView(sView)
	tokens.setView(sView);
end
function getTypeFilter()
	return tokens.getTypeFilter();
end
function setTypeFilter(sAssetType)
	tokens.setTypeFilter(sAssetType);
end
function setPathFilter(sPath)
	tokens.setPathFilter(sPath);
end
function setSearchFilter(sFilter)
	tokens.setSearchFilter(sFilter);
end

function handlePageTop()
	tokens.setSearchFilter("");
	tokens.setPathFilter("");
end
function handlePagePrev()
	tokens.setPage(tokens.getPage() - 1);
end
function handlePageNext()
	tokens.setPage(tokens.getPage() + 1);
end
