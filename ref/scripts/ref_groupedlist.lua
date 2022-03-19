-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

DEFAULT_START_WIDTH = 450;
DEFAULT_START_HEIGHT = 450;
MAX_START_HEIGHT = 650;

DEFAULT_COL_WIDTH = 50;
LINK_OFFSET = 25;
COL_PADDING = 5;

local bInitialized = false;
local _tList = nil;
local _tRecords = {};
local _nFilteredRecordCount = 0;
local _tGroups = {};
local _tColumnSort = {};

local _nDisplayOffset = 0;
local _tCollapsedGroups = {};
local _sFilter = "";

function onInit()
	if Interface.getRuleset() == "SavageWorlds" then
		DEFAULT_COL_WIDTH = 250;
	end
	
	local rList = buildListRecord();
	if rList then
		init(rList);
	end
end

function buildListRecord()
	local rList = nil;
	
	local nodeMain = getDatabaseNode();
	local sSource = DB.getValue(nodeMain, "source");
	local sRecordType = DB.getValue(nodeMain, "recordtype");
	if nodeMain and (sSource or sRecordType) then
		rList = {};
		
		-- Determine basic list data
		rList.sSource = sSource;
		rList.sRecordType = sRecordType;
		rList.sDisplayClass = DB.getValue(nodeMain, "displayclass");
		if not rList.sDisplayClass and (Interface.getRuleset() == "SavageWorlds") then
			rList.sDisplayClass = DB.getValue(nodeMain, "itemclass");
		end
		rList.sListView = DB.getValue(nodeMain, "listview");
		
		rList.sTitle = DB.getValue(nodeMain, "name", "");
		if (rList.sTitle == "") and (rList.sRecordType or "") ~= "" then
			rList.sTitle = LibraryData.getDisplayText(rList.sRecordType);
		end
		rList.nWidth = tonumber(DB.getValue(nodeMain, "width")) or nil;
		rList.nHeight = tonumber(DB.getValue(nodeMain, "height")) or nil;
		if DB.getChild(nodeMain, "notes") then
			rList.sDBNotesField = "notes";
		end
		
		-- Determine list column data
		rList.aColumns = {};
		for _,nodeColumn in ipairs(UtilityManager.getSortedTable(DB.getChildren(nodeMain, "columns"))) do
			local rColumn = {};
			rColumn.sName = DB.getValue(nodeColumn, "name");
			rColumn.sTooltip = DB.getValue(nodeColumn, "tooltip");
			rColumn.sTooltipRes = DB.getValue(nodeColumn, "tooltipres");
			rColumn.sHeading = DB.getValue(nodeColumn, "heading");
			rColumn.sHeadingRes = DB.getValue(nodeColumn, "headingres");
			rColumn.nWidth = tonumber(DB.getValue(nodeColumn, "width")) or nil;
			if nodeColumn.getChild("center") then
				rColumn.bCentered = true;
			end
			if nodeColumn.getChild("wrap") then
				rColumn.bWrapped = true;
			end
			rColumn.nSortOrder = DB.getValue(nodeColumn, "sortorder");
			if nodeColumn.getChild("sortdesc") then
				rColumn.bSortDesc = true;
			end
			
			local sTempType = DB.getValue(nodeColumn, "type");
			if sTempType then
				if sTempType == "custom" then
					rColumn.sType = "custom";
				elseif sTempType:match("formattedtext") then
					rColumn.sType = "formattedtext";
				elseif sTempType:match("number") then
					rColumn.sType = "number";
					if nodeColumn.getChild("displaysign") then
						rColumn.bDisplaySign = true;
					end
				end
			end
			if not rColumn.sType then
				rColumn.sType = "string";
			end

			rColumn.sTemplate = DB.getValue(nodeColumn, "template");

			table.insert(rList.aColumns, rColumn);
		end
		
		-- Determine list filter data
		rList.aFilters = {};
		for _,nodeFilter in pairs(DB.getChildren(nodeMain, "filters")) do
			local rFilter = {};
			rFilter.sDBField = DB.getValue(nodeFilter, "field");
			rFilter.vFilterValue = DB.getValue(nodeFilter, "value");
			if rFilter.sDBField and rFilter.vFilterValue then
				rFilter.vDefaultVal = DB.getValue(nodeFilter, "defaultvalue");
				table.insert(rList.aFilters, rFilter);
			end
		end
		if #(rList.aFilters) == 0 and (Interface.getRuleset() == "SavageWorlds") then
			local sOldFilter = DB.getValue(nodeMain, "catname");
			if sOldFilter then
				table.insert(rList.aFilters, { sDBField = "catname", vFilterValue = sOldFilter });
			end
		end
		
		-- Determine list group data
		rList.aGroups = {};
		for _,nodeGroup in ipairs(UtilityManager.getSortedTable(DB.getChildren(nodeMain, "groups"))) do
			local rGroup = {};
			rGroup.sDBField = DB.getValue(nodeGroup, "field");
			rGroup.sType = DB.getValue(nodeGroup, "type");
			rGroup.nLength = DB.getValue(nodeGroup, "length");
			rGroup.sPrefix = DB.getValue(nodeGroup, "prefix");
			if rGroup.sDBField then
				table.insert(rList.aGroups, rGroup);
			end
		end
		if #(rList.aGroups) == 0 and (Interface.getRuleset() == "SavageWorlds") then
			table.insert(rList.aGroups, { sDBField = "group" });
		end
		rList.aGroupValueOrder = StringManager.split(DB.getValue(nodeMain, "grouporder", ""), "|", true);
		if #(rList.aGroupValueOrder) == 0 and (Interface.getRuleset() == "SavageWorlds") then
			rList.aGroupValueOrder = StringManager.split(DB.getValue(nodeMain, "order", ""), ",", true);
		end
	end

	return rList;
end
function getListRecord()
	return _tList;
end

function init(rList)
	if not rList then
		return;
	end
	if bInitialized then
		return;
	end
	bInitialized = true;
	
	-- Save list definition
	if (rList.sListView or "") ~= "" then
		local tView = LibraryData.getListView(rList.sRecordType, rList.sListView)
		if not tView then
			Interface.openWindow("reference_list", getDatabaseNode());
			close();
			return;
		end
		_tList = UtilityManager.copyDeep(tView);
		_tList.sSource = rList.sSource;
		_tList.sRecordType = rList.sRecordType;
	else
		_tList = UtilityManager.copyDeep(rList);
	end
	
	-- Set window title
	local sTitle = _tList.sDisplayText;
	if (sTitle or "") == "" then
		sTitle = _tList.sTitle;
	end
	if (sTitle or "") == "" then
		sTitle = Interface.getString(_tList.sTitleRes);
	end
	reftitle.setValue(sTitle);
	
	-- Check for notes field
	if _tList.sDBNotesField then
		notes.setVisible(true);
		notes.setValue("reference_groupedlist_notes", getDatabaseNode());
		notes.subwindow.createControl("ft_refgroupedlist_notes", _tList.sDBNotesField);
	end
	
	-- Create column headers
	local nTotalColumnWidth = LINK_OFFSET;
	for _,rColumn in ipairs(_tList.aColumns) do
		local cColumn = nil;
		if rColumn.bCentered then
			cColumn = createControl("label_refgroupedlist_center", rColumn.sName);
		else
			cColumn = createControl("label_refgroupedlist", rColumn.sName);
		end
		local sHeading = rColumn.sHeading;
		if (sHeading or "") == "" then
			sHeading = Interface.getString(rColumn.sHeadingRes);
		end
		local sTooltip = rColumn.sTooltip;
		if (sTooltip or "") == "" then
			sTooltip = Interface.getString(rColumn.sTooltipRes);
		end
		cColumn.setValue(sHeading);
		cColumn.setTooltipText(sTooltip);
		cColumn.setAnchoredWidth(rColumn.nWidth or DEFAULT_COL_WIDTH);
		
		nTotalColumnWidth = nTotalColumnWidth + (rColumn.nWidth or DEFAULT_COL_WIDTH) + COL_PADDING;
	end
	
	-- Initialize the data records
	_tRecords = {};
	_tGroups = {};
	if _tList.sSource then
		initDataBySource();
	elseif _tList.sRecordType then
		initDataByType();
	end

	-- Initialize sorting data
	initGroupOrder();
	initColumnSortOrder();

	-- Populate the list
	_nDisplayOffset = 0;
	_tCollapsedGroups = {};
	refreshDisplayList(true);

	-- Set the starting size
	local ww, wh = getSize();
	local lw, lh = list.getSize();
	local nTotalWidth = nTotalColumnWidth + (ww - lw);
	local nTotalHeight = math.min((_nFilteredRecordCount * 24) + (wh-lh), MAX_START_HEIGHT);
	
	local wStart = _tList.nWidth or math.max(DEFAULT_START_WIDTH, nTotalWidth);
	local hStart = _tList.nHeight or math.max(DEFAULT_START_HEIGHT, nTotalHeight);
	setSize(wStart, hStart);
end

function initDataBySource()
	local sModule = DB.getModule(getDatabaseNode());
	if sModule and not _tList.sSource:match("@") then
		_tList.sSource = _tList.sSource .. "@" .. sModule;
	end
	for _,vNode in pairs(DB.getChildren(_tList.sSource)) do
		addDataRecord(vNode);
	end
end
function initDataByType()
	local sModule = DB.getModule(getDatabaseNode());
	local aMappings = LibraryData.getMappings(_tList.sRecordType);
	for _,vMapping in ipairs(aMappings) do
		if (sModule or "") ~= "" then
			local nodeSource = DB.findNode(vMapping .. "@" .. sModule);
			if nodeSource then
				for _,vNode in pairs(nodeSource.getChildren()) do
					addDataRecord(vNode);
				end
			end
		else
			for _,vNode in pairs(DB.getChildrenGlobal(vMapping)) do
				addDataRecord(vNode);
			end
		end
	end
end
function addDataRecord(node)
	if not addDataRecordFilterCheck(node) then
		return;
	end

	local aGroups = {};
	for _,rGroup in ipairs(_tList.aGroups) do
		local sSubGroup = DB.getValue(node, rGroup.sDBField);
		if rGroup.sCustom then
			sSubGroup = LibraryData.getCustomGroupOutput(rGroup.sCustom, sSubGroup);
		elseif rGroup.nLength then
			sSubGroup = sSubGroup:sub(1, rGroup.nLength);
		end
		if rGroup.sPrefix then
			if (sSubGroup or "") ~= "" then
				sSubGroup = " " .. sSubGroup;
			end
			sSubGroup = rGroup.sPrefix .. (sSubGroup or "");
		end
		table.insert(aGroups, (sSubGroup or ""));
	end
	local sGroup = StringManager.capitalizeAll(table.concat(aGroups, " - "));
	_tGroups[sGroup] = { nOrder = 10000 };

	local rRecord = {};
	rRecord.vNode = node;
	rRecord.sDisplayName = DB.getValue(node, "name", "");
	rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();
	rRecord.sGroup = sGroup;
	_tRecords[node] = rRecord;
end
function addDataRecordFilterCheck(node)
	local bAdd = true;
	for _,rFilter in ipairs(_tList.aFilters) do
		local v;
		if rFilter.sCustom then
			if not LibraryData.getCustomFilterValue(rFilter.sCustom, node, rFilter.vDefaultVal) then
				bAdd = false;
				break;
			end
		else
			if rFilter.fGetValue then
				v = rFilter.fGetValue(node);
			else
				v = DB.getValue(node, rFilter.sDBField, rFilter.vDefaultVal);
			end
			if v ~= rFilter.vFilterValue then
				bAdd = false;
				break;
			end
		end
	end
	return bAdd;
end

function initGroupOrder()
	if _tList.aGroupValueOrder then
		for k,sGroup in ipairs(_tList.aGroupValueOrder) do
			if _tGroups[sGroup] then
				_tGroups[sGroup].nOrder = k;
			end
		end
	end
end
function initColumnSortOrder()
	_tColumnSort = {};
	for _,rColumn in ipairs(_tList.aColumns) do
		if (rColumn.nSortOrder or 0) > 0 then
			_tColumnSort[rColumn.nSortOrder] = { sName = rColumn.sName, sType = rColumn.sType, bDesc = rColumn.bSortDesc };
		end
	end
	for _,rColumn in ipairs(_tList.aColumns) do
		if (rColumn.nSortOrder or 0) <= 0 then
			_tColumnSort[#_tColumnSort + 1] = { sName = rColumn.sName, sType = rColumn.sType, bDesc = rColumn.bSortDesc };
		end
	end
end

function onFilterChanged()
	_sFilter = filter.getValue():lower();
	refreshDisplayList(true);
end
function onGroupToggle(sGroup)
	if _tCollapsedGroups[sGroup] then
		_tCollapsedGroups[sGroup] = nil;
	else
		_tCollapsedGroups[sGroup] = true;
	end
	refreshDisplayList();
end

--
--	LIST HANDLING
--

local _nDisplayWindowCount = 0;
local _tDisplayedGroupHeaders = {};
local _nSavedScrollPos = nil;

function refreshDisplayList(bResetScroll)
	_nDisplayWindowCount = 0;
	_tDisplayedGroupHeaders = {};

	saveDisplayListScrollPosition(bResetScroll);
	ListManager.refreshDisplayList(self);
	restoreDisplayListScrollPosition();
end
function addDisplayListItem(v)
	if not _tDisplayedGroupHeaders[v.sGroup] then
		local wGroup = list.createWindowWithClass("reference_groupedlist_group");
		wGroup.group.setValue(v.sGroup);
		_tDisplayedGroupHeaders[v.sGroup] = true;

		_nDisplayWindowCount = _nDisplayWindowCount + 1;
		wGroup.order.setValue(_nDisplayWindowCount);
	end

	if not _tCollapsedGroups[v.sGroup] then
		local wItem = list.createWindow(v.vNode);
		if _tList.sDisplayClass then
			wItem.setItemClass(_tList.sDisplayClass);
		else
			wItem.setItemRecordType(_tList.sRecordType);
		end
		wItem.setColumnInfo(_tList.aColumns, DEFAULT_COL_WIDTH);

		_nDisplayWindowCount = _nDisplayWindowCount + 1;
		wItem.order.setValue(_nDisplayWindowCount);
	end

	list.applySort();
end
function saveDisplayListScrollPosition(bResetScroll)
	if bResetScroll then
		_nSavedScrollPos = nil;
	elseif not _nSavedScrollPos then
		_,_,_,_,_nSavedScrollPos,_ = list.getScrollState();
	end
end
function restoreDisplayListScrollPosition()
	if _nSavedScrollPos then
		list.setScrollPosition(0, _nSavedScrollPos);
		_nSavedScrollPos = nil;
	end
end

function getAllRecords()
	return _tRecords;
end
function getDisplayOffset()
	return _nDisplayOffset;
end
function setDisplayOffset(n)
	_nDisplayOffset = n;
	_tCollapsedGroups = {};
	refreshDisplayList(true);
end
function getDisplayRecordCount()
	return _nFilteredRecordCount;
end
function setDisplayRecordCount(n)
	_nFilteredRecordCount = n;
end

function getSortFunction()
	return sortRecordFunc;
end
function sortRecordFunc(a, b)
	-- First, sort by group
	if _tGroups[a.sGroup].nOrder ~= _tGroups[b.sGroup].nOrder then
		return _tGroups[a.sGroup].nOrder < _tGroups[b.sGroup].nOrder;
	end
	if a.sGroup ~= b.sGroup then
		return a.sGroup < b.sGroup;
	end

	-- Then, sort by item sort order
	for _,vColumn in ipairs(_tColumnSort) do
		local v1 = DB.getValue(a.vNode, vColumn.sName);
		if not v1 then
			if (vColumn.sType or "") == "number" then
				v1 = 0;
			else
				v1 = "";
			end
		end
		local v2 = DB.getValue(b.vNode, vColumn.sName);
		if not v2 then
			if (vColumn.sType or "") == "number" then
				v2 = 0;
			else
				v2 = "";
			end
		end
		if v1 ~= v2 then
			if vColumn.bDesc then
				return v1 > v2;
			else
				return v1 < v2;
			end
		end
	end

	return DB.getPath(a.vNode) < DB.getPath(b.vNode);
end

function isFilteredRecord(v)
	if _sFilter ~= "" then
		if not string.find(v.sDisplayNameLower, _sFilter, 0, true) then
			return false;
		end
	end
	return true;
end
