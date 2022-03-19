-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- NOTE: Reference lists are static; and will not update dynamically if record data changes

DEFAULT_START_WIDTH = 350;
DEFAULT_START_HEIGHT = 450;
MAX_START_HEIGHT = 650;

ROW_SIZE = 24;
LINK_OFFSET = 25;

local _tList = nil;
local _tRecords = {};
local _nFilteredRecordCount = 0;
local _nDisplayOffset = 0;

function onInit()
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
		
		rList.sSource = sSource;
		rList.sRecordType = sRecordType;
		rList.sDisplayClass = DB.getValue(nodeMain, "displayclass");
		
		rList.sTitle = DB.getValue(nodeMain, "name", "");
		if (rList.sTitle == "") and (rList.sRecordType or "") ~= "" then
			rList.sTitle = LibraryData.getDisplayText(rList.sRecordType);
		end
		rList.nWidth = tonumber(DB.getValue(nodeMain, "width")) or nil;
		rList.nHeight = tonumber(DB.getValue(nodeMain, "height")) or nil;
		if DB.getChild(nodeMain, "notes") then
			rList.sDBNotesField = "notes";
		end
		
		rList.aFilters = {};
		for _,nodeFilter in pairs(DB.getChildren(nodeMain, "filters")) do
			local rFilter = {};
			rFilter.sDBField = DB.getValue(nodeFilter, "field");
			rFilter.vFilterValue = DB.getValue(nodeFilter, "value");
			if rFilter.sDBField and rFilter.vFilterValue then
				table.insert(rList.aFilters, rFilter);
			end
		end
	end
	
	return rList;	
end

function init(rList)
	_tList = rList;

	-- Set window title
	reftitle.setValue(_tList.sTitle);
	
	-- Check for notes field
	if _tList.sDBNotesField then
		notes.setVisible(true);
		notes.setValue("reference_list_notes", getDatabaseNode());
		notes.subwindow.createControl("ft_reflist_notes", _tList.sDBNotesField);
	end
	
	-- Initialize the data records
	_tRecords = {};
	if _tList.sSource then
		initDataBySource();
	elseif _tList.sRecordType then
		initDataByType();
	end
	
	-- Populate the list
	_nDisplayOffset = 0;
	refreshDisplayList();

	-- Set the starting size
	local ww, wh = getSize();
	local lw, lh = list.getSize();
	local nTotalWidth = LINK_OFFSET + 200 + (ww - lw);
	local nTotalHeight = math.min((_nFilteredRecordCount * ROW_SIZE) + (wh - lh), MAX_START_HEIGHT);
	
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
	local bAdd = true;
	for _,rFilter in ipairs(_tList.aFilters) do
		if DB.getValue(node, rFilter.sDBField, rFilter.vDefaultVal) ~= rFilter.vFilterValue then
			bAdd = false;
		end
	end
	if bAdd then
		local rRecord = {};
		rRecord.vNode = node;
		rRecord.sDisplayName = DB.getValue(node, "name", "");
		rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();
		_tRecords[node] = rRecord;
	end
end

--
--	LIST HANDLING
--

function refreshDisplayList()
	ListManager.refreshDisplayList(self);
end
function addDisplayListItem(v)
	local wItem = list.createWindow(v.vNode);
	if _tList.sDisplayClass then
		wItem.setItemClass(_tList.sDisplayClass);
	else
		wItem.setItemRecordType(_tList.sRecordType);
	end
	wItem.name.setValue(v.sDisplayName);
end

function getAllRecords()
	return _tRecords;
end
function getDisplayOffset()
	return _nDisplayOffset;
end
function setDisplayOffset(n)
	_nDisplayOffset = n;
	refreshDisplayList();
end
function getDisplayRecordCount()
	return _nFilteredRecordCount;
end
function setDisplayRecordCount(n)
	_nFilteredRecordCount = n;
end

function isFilteredRecord(v)
	return true;
end
