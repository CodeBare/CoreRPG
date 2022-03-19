-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _tRecords = {};
local _nFilteredRecordCount = 0;
local _nDisplayOffset = 0;
local _nSavedScrollPos = nil;

local bDelayedChildrenChanged = false;
local bDelayedRebuild = false;

local fName = "";
local fSharedOnly = false;
local fCategory = "";

local bAllowCategories = true;

local sInternalRecordType = "";
local bProcessListChanged = false;

local cButtonAnchor = nil;
local aButtonControls = {};

local aEditControls = {};

local aCustomFilters = {};
local nCustomFilters = 0;
local aCustomFilterControls = {};
local aCustomFilterValueControls = {};
local aCustomFilterValues = {};

local sDelayedCategoryFocus = nil;

function onInit()
	local node = getDatabaseNode();
	if node then
		local sRecordType = LibraryData.getRecordTypeFromPath(node.getPath());
		if (sRecordType or "") ~= "" then
			setRecordType(sRecordType);
		end
	end

	Module.onModuleLoad = onModuleLoadAndUnload;
	Module.onModuleUnload = onModuleLoadAndUnload;
end
function onClose()
	removeHandlers();
end

function onModuleLoadAndUnload(sModule)
	local nodeRoot = DB.getRoot(sModule);
	if nodeRoot then
		local vNodes = LibraryData.getMappings(sInternalRecordType);
		for i = 1, #vNodes do
			if nodeRoot.getChild(vNodes[i]) then
				bDelayedRebuild = true;
				onListRecordsChanged(true);
				break;
			end
		end
	end
end
function addHandlers()
	function addHandlerHelper(vNode)
		local sPath = DB.getPath(vNode);
		local sChildPath = sPath .. ".*@*";
		DB.addHandler(sChildPath, "onAdd", onChildAdded);
		DB.addHandler(sChildPath, "onDelete", onChildDeleted);
		DB.addHandler(sChildPath, "onCategoryChange", onChildCategoryChange);
		DB.addHandler(sChildPath, "onObserverUpdate", onChildObserverUpdate);
		DB.addHandler(DB.getPath(sChildPath, "name"), "onUpdate", onChildNameChange);
		DB.addHandler(DB.getPath(sChildPath, "nonid_name"), "onUpdate", onChildUnidentifiedNameChange);
		DB.addHandler(DB.getPath(sChildPath, "isidentified"), "onUpdate", onChildIdentifiedChange);
		for kCustomFilter,vCustomFilter in pairs(aCustomFilters) do
			DB.addHandler(DB.getPath(sChildPath, vCustomFilter.sField), "onUpdate", onChildCustomFilterValueChange);
		end
		DB.addHandler(sPath, "onChildCategoriesChange", onChildCategoriesChanged);
	end
	
	local vNodes = LibraryData.getMappings(sInternalRecordType);
	for i = 1, #vNodes do
		addHandlerHelper(vNodes[i]);
	end
end
function removeHandlers()
	function removeHandlerHelper(vNode)
		local sPath = DB.getPath(vNode);
		local sChildPath = sPath .. ".*@*";
		DB.removeHandler(sChildPath, "onAdd", onChildAdded);
		DB.removeHandler(sChildPath, "onDelete", onChildDeleted);
		DB.removeHandler(sChildPath, "onCategoryChange", onChildCategoryChange);
		DB.removeHandler(sChildPath, "onObserverUpdate", onChildObserverUpdate);
		DB.removeHandler(DB.getPath(sChildPath, "name"), "onUpdate", onChildNameChange);
		DB.removeHandler(DB.getPath(sChildPath, "nonid_name"), "onUpdate", onChildUnidentifiedNameChange);
		DB.removeHandler(DB.getPath(sChildPath, "isidentified"), "onUpdate", onChildIdentifiedChange);
		for kCustomFilter,vCustomFilter in pairs(aCustomFilters) do
			DB.removeHandler(DB.getPath(sChildPath, vCustomFilter.sField), "onUpdate", onChildCustomFilterValueChange);
		end
		DB.removeHandler(sPath, "onChildCategoriesChange", onChildCategoriesChanged);
	end
	
	local vNodes = LibraryData.getMappings(sInternalRecordType);
	for i = 1, #vNodes do
		removeHandlerHelper(vNodes[i]);
	end
end

function onListChanged()
	if bDelayedChildrenChanged then
		onListRecordsChanged(false);
	else
		list.update();
	end
end
function onSortCompare(w1, w2)
	return not ListManager.defaultSortFunc(_tRecords[w1.getDatabaseNode()], _tRecords[w2.getDatabaseNode()]);
end

function getRecordType()
	return sInternalRecordType;
end
function setRecordType(sRecordType)
	if sRecordType == sInternalRecordType then
		return;
	end
	
	removeHandlers();
	clearButtons();
	clearCustomFilters();

	sInternalRecordType = sRecordType;

	local sDisplayTitle = LibraryData.getDisplayText(sRecordType);
	reftitle.setValue(sDisplayTitle);
	
	setupEditTools();
	setupCategories();
	setupButtons();
	setupCustomFilters();

	rebuildList();
	addHandlers();
end

function setupEditTools()
	list_iadd.setRecordType(LibraryData.getRecordDisplayClass(sInternalRecordType));
	local bAllowEdit = LibraryData.allowEdit(sInternalRecordType);
	list_iedit.setVisible(bAllowEdit);
	list_iadd.setVisible(bAllowEdit);

	list.setReadOnly(not bAllowEdit);
	list.resetMenuItems();
	if not list.isReadOnly() and bAllowEdit then
		list.registerMenuItem(Interface.getString("list_menu_createitem"), "insert", 5);
	end
end
function setupCategories()
	bAllowCategories = LibraryData.allowCategories(sInternalRecordType);
	label_category.setVisible(bAllowCategories);
	filter_category_label.setVisible(bAllowCategories);
	button_category_detail.setVisible(bAllowCategories);
	handleCategorySelect("*");
end

function clearButtons()
	for _,v in ipairs(aButtonControls) do
		v.destroy();
	end
	if cButtonAnchor then
		cButtonAnchor.destroy();
		cButtonAnchor = nil;
	end
	aButtonControls = {};
	
	for _,v in ipairs(aEditControls) do
		v.destroy();
	end
	aEditControls = {};
end
function setupButtons()
	local aIndexButtons = LibraryData.getIndexButtons(sInternalRecordType);
	if #aIndexButtons > 0 then
		cButtonAnchor = createControl("masterindex_anchor_button", "buttonanchor");
		for k,v in ipairs(aIndexButtons) do
			local c = createControl(v, "button_custom" .. k);
			if c then
				table.insert(aButtonControls, c);
			end
		end
	end

	local aEditButtons = LibraryData.getEditButtons(sInternalRecordType);
	if #aEditButtons > 0 then
		for k,v in ipairs(aEditButtons) do
			local c = createControl(v, "button_edit" .. k);
			if c then
				c.setVisible(true);
				table.insert(aEditControls, c);
			end
		end
	end
end

function clearCustomFilters()
	for _,c in pairs(aCustomFilterValueControls) do
		c.onDestroy();
		c.destroy();
	end
	aCustomFilterValueControls = {};
	for _,c in pairs(aCustomFilterControls) do
		c.destroy();
	end
	aCustomFilterControls = {};
	aCustomFilters = {};
	nCustomFilters = 0;
end
function setupCustomFilters()
	aCustomFilters = LibraryData.getCustomFilters(sInternalRecordType);
	
	local aSortedFilters = {};
	for kFilter,_ in pairs(aCustomFilters) do
		table.insert(aSortedFilters, kFilter);
	end
	table.sort(aSortedFilters);
	for _,vFilter in ipairs(aSortedFilters) do
		addCustomFilter(vFilter);
	end
	nCustomFilters = #aSortedFilters;
end
function addCustomFilter(sCustomType)
	local c = createControl("masterindex_filter_custom", "filter_custom_" .. sCustomType);
	c.setValue(sCustomType);
	aCustomFilterControls[sCustomType] = c;
	
	local c2 = createControl("masterindex_filter_custom_value",  "filter_custom_value_" .. sCustomType);
	c2.setFilterType(sCustomType);
	aCustomFilterValueControls[sCustomType] = c2;
	
	aCustomFilterValues[sCustomType] = "";
end
function clearFilterValues()
	if fSharedOnly then
		filter_sharedonly.setValue(0);
	end
	if fName ~= "" then
		filter_name.setValue();
	end
	for kCustomFilter,_ in pairs(aCustomFilters) do
		aCustomFilterValueControls[kCustomFilter].setValue("");
	end
end

function rebuildList()
	bProcessListChanged = false;
	
	local sListDisplayClass = LibraryData.getIndexDisplayClass(sInternalRecordType);
	if sListDisplayClass ~= "" then
		list.setChildClass(sListDisplayClass);
	end
	
	_tRecords = {};
	local aMappings = LibraryData.getMappings(sInternalRecordType);
	for _,vMapping in ipairs(aMappings) do
		for _,vNode in pairs(DB.getChildrenGlobal(vMapping)) do
			addListRecord(vNode);
		end
	end

	_nDisplayOffset = 0;
	onListRecordsChanged();
	
	bProcessListChanged = true;
end

function onChildAdded(vNode)
	addListRecord(vNode);
	onListRecordsChanged(true);
end
function onChildDeleted(vNode)
	if _tRecords[vNode] then
		_tRecords[vNode] = nil;
		onListRecordsChanged(true);
	end
end
function onChildCategoriesChanged()
	onListRecordsChanged(true);
end
function onListRecordsChanged(bAllowDelay)
	if bAllowDelay then
		bDelayedChildrenChanged = true;
		saveDisplayListScrollPosition();
		list.setDatabaseNode(nil);
	else
		bDelayedChildrenChanged = false;
		if bDelayedRebuild then
			bDelayedRebuild = false;
			rebuildList();
		end
		rebuildCategories();
		rebuildCustomFilterValues();
		refreshDisplayList();
	end
end
function addListRecord(vNode)
	local rRecord = {};
	rRecord.vNode = vNode;
	rRecord.sCategory = UtilityManager.getNodeCategory(vNode);
	rRecord.nAccess = UtilityManager.getNodeAccessLevel(vNode);
	
	rRecord.bIdentifiable = LibraryData.isIdentifiable(sInternalRecordType, vNode);
	if rRecord.bIdentifiable and not getRecordIDState(rRecord) then
		rRecord.sDisplayName = DB.getValue(vNode, "nonid_name", "");
	else
		rRecord.sDisplayName = DB.getValue(vNode, "name", "");
	end
	rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();

	rRecord.aCustomValues = {};
	for kCustomFilter,vCustomFilter in pairs(aCustomFilters) do
		rRecord.aCustomValues[kCustomFilter] = DB.getValue(vNode, vCustomFilter.sField, "");
	end
	
	_tRecords[vNode] = rRecord;
end

function getFilterValues(kCustomFilter, vNode)
	local vValues = {};
	
	local vCustomFilter = aCustomFilters[kCustomFilter];
	if vCustomFilter then
		if vCustomFilter.fGetValue then
			vValues = vCustomFilter.fGetValue(vNode);
			if type(vValues) ~= "table" then
				vValues = { vValues };
			end
		elseif vCustomFilter.sType == "boolean" then
			if DB.getValue(vNode, vCustomFilter.sField, 0) ~= 0 then
				vValues = { LibraryData.sFilterValueYes };
			else
				vValues = { LibraryData.sFilterValueNo };
			end
		else
			local vValue = DB.getValue(vNode, vCustomFilter.sField);
			if vCustomFilter.sType == "number" then
				vValues = { tostring(vValue or 0) };
			else
				local sValue;
				if vValue then
					sValue = tostring(vValue) or "";
				else
					sValue = "";
				end
				if sValue == "" then
					vValues = { LibraryData.sFilterValueEmpty };
				else
					vValues = { sValue };
				end
			end
		end
	end
	
	return vValues;
end

function rebuildCustomFilterValues()
	for kCustomFilter,_ in pairs(aCustomFilters) do
		rebuildCustomFilterValueHelper(kCustomFilter);
	end
end
function rebuildCustomFilterValueHelper(kCustomFilter)
	local cFilter = aCustomFilterValueControls[kCustomFilter];
	if not cFilter then
		return;
	end

	local tFilterValues = {};
	for _,vRecord in pairs(_tRecords) do
		if cFilter then
			local vValues = getFilterValues(kCustomFilter, vRecord.vNode);
			for _,v in ipairs(vValues) do
				if (v or "") ~= "" then
					tFilterValues[v] = true;
				end
			end
		end
	end

	cFilter.clear();
	if not tFilterValues[cFilter.getValue()] then
		cFilter.setValue("");
	end

	local tSortedFilterValues = {};
	for k,_ in pairs(tFilterValues) do
		table.insert(tSortedFilterValues, k);
	end
	if aCustomFilters[kCustomFilter].fSort then
		tSortedFilterValues = aCustomFilters[kCustomFilter].fSort(tSortedFilterValues);
	elseif aCustomFilters[kCustomFilter].sType == "number" then
		table.sort(tSortedFilterValues, function(a,b) return (tonumber(a) or 0) < (tonumber(b) or 0); end);
	else
		table.sort(tSortedFilterValues);
	end
	table.insert(tSortedFilterValues, 1, "");
	cFilter.addItems(tSortedFilterValues);
end

function onCustomFilterValueChanged(sFilterType, cFilterValue)
	aCustomFilterValues[sFilterType] = cFilterValue.getValue():lower();
	refreshDisplayList(true);
end

function getRecordIDState(vRecord)
	return LibraryData.getIDState(sInternalRecordType, vRecord.vNode);
end

function onChildCategoryChange(vNode)
	if _tRecords[vNode] then
		_tRecords[vNode].sCategory = UtilityManager.getNodeCategory(vNode);
		if fCategory ~= "*" then
			refreshDisplayList();
		end
	end
end
function onChildObserverUpdate(vNode)
	_tRecords[vNode].nAccess = UtilityManager.getNodeAccessLevel(vNode);
	if fSharedOnly then
		refreshDisplayList();
	end
end
function onChildCustomFilterValueChange(vNode)
	local sNodeName = vNode.getName();
	for kCustomFilter,vCustomFilter in pairs(aCustomFilters) do
		if vCustomFilter.sField == sNodeName then
			rebuildCustomFilterValueHelper(kCustomFilter);
			if aCustomFilterValues[kCustomFilter] ~= "" then
				refreshDisplayList();
			end
			break;
		end
	end
end
function onChildNameChange(vNameNode)
	local vNode = vNameNode.getParent();
	local rRecord = _tRecords[vNode];
	if not rRecord.bIdentifiable or getRecordIDState(rRecord) then
		rRecord.sDisplayName = DB.getValue(vNode, "name", "");
		rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();
		refreshDisplayList();
	end
end
function onChildUnidentifiedNameChange(vNameNode)
	local vNode = vNameNode.getParent();
	local rRecord = _tRecords[vNode];
	if rRecord.bIdentifiable and not getRecordIDState(rRecord) then
		rRecord.sDisplayName = DB.getValue(vNode, "nonid_name", "");
		rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();
		refreshDisplayList();
	end
end
function onChildIdentifiedChange (vIDNode)
	local vNode = vIDNode.getParent();
	local rRecord = _tRecords[vNode];
	if rRecord.bIdentifiable and not Session.IsHost then
		if getRecordIDState(rRecord) then
			rRecord.sDisplayName = DB.getValue(vNode, "name", "");
		else
			rRecord.sDisplayName = DB.getValue(vNode, "nonid_name", "");
		end
		rRecord.sDisplayNameLower = rRecord.sDisplayName:lower();
		refreshDisplayList();
	end
end

function handleCategorySelect(sCategory)
	if not bAllowCategories then
		return;
	end
	
	filter_category.setValue(sCategory);
	fCategory = sCategory;

	if fCategory == "*" then
		filter_category_label.setValue(Interface.getString("masterindex_label_category_all"));
	elseif fCategory == "" then
		filter_category_label.setValue(Interface.getString("masterindex_label_category_empty"));
	else
		filter_category_label.setValue(fCategory);
	end
	
	for _,w in ipairs(list_category.getWindows()) do
		w.setActiveByKey(fCategory);
	end
	
	button_category_detail.setValue(0);
	
	local sDefaultCategory = sCategory;
	if sDefaultCategory == "*" then
		sDefaultCategory = "";
	end
	for _,vMapping in ipairs(LibraryData.getMappings(sInternalRecordType)) do
		DB.setDefaultChildCategory(vMapping, sDefaultCategory);
	end

	setDisplayOffset(0);
	refreshDisplayList(true);
end
function handleCategoryNameChange(sOriginal, sNew)
	if sOriginal == sNew then
		return;
	end
	for _,vMapping in ipairs(LibraryData.getMappings(sInternalRecordType)) do
		DB.updateChildCategory(vMapping, sOriginal, sNew, true);
	end
end
function handleCategoryDelete(sName)
	for _,vMapping in ipairs(LibraryData.getMappings(sInternalRecordType)) do
		DB.removeChildCategory(vMapping, sName, true);
	end
end
function handleCategoryAdd()
	local aMappings = LibraryData.getMappings(sInternalRecordType);
	sDelayedCategoryFocus = DB.addChildCategory(aMappings[1]);
end
function rebuildCategories()
	if not bAllowCategories then
		return;
	end
	
	local aCategories = {};
	for _,vMapping in ipairs(LibraryData.getMappings(sInternalRecordType)) do
		for _,vCategory in ipairs(DB.getChildCategories(vMapping, true)) do
			if type(vCategory) == "string" then
				aCategories[vCategory] = vCategory;
			else
				aCategories[vCategory.name] = vCategory.name;
			end
		end
	end
	aCategories["*"] = Interface.getString("masterindex_label_category_all");
	aCategories[""] = Interface.getString("masterindex_label_category_empty");

	list_category.closeAll();
	for kCategory,vCategory in pairs(aCategories) do
		local w = list_category.createWindow();
		w.setData(kCategory, vCategory, (fCategory == kCategory));
	end
	list_category.applySort();
	
	if not aCategories[fCategory] then
		handleCategorySelect("*");
	end
	
	if button_category_iedit.getValue() == 1 then
		button_category_iedit.setValue(0);
		button_category_iedit.setValue(1);
	end

	if sDelayedCategoryFocus then
		for _,w in ipairs(list_category.getWindows()) do
			if w.getCategory() == sDelayedCategoryFocus then
				w.category_label.setFocus();
				break;
			end
		end
		sDelayedCategoryFocus = nil;
	end
end

function onNameFilterChanged()
	fName = filter_name.getValue():lower();
	refreshDisplayList(true);
end
function onSharedOnlyFilterChanged()
	fSharedOnly = (filter_sharedonly.getValue() == 1);
	refreshDisplayList(true);
end

function onIDChanged()
	for _,w in ipairs(list.getWindows()) do
		w.onIDChanged();
	end
	refreshDisplayList();
end

function addEntry()
	list_iadd.onButtonPress();
end

function getIndexRecord(vNode)
	if bDelayedChildrenChanged then
		onListRecordsChanged(false);
	end

	local sCategory = UtilityManager.getNodeCategory(vNode);
	local sModule = UtilityManager.getNodeModule(vNode);
	
	for _,rRecord in pairs(_tRecords) do
		if sModule == UtilityManager.getNodeModule(rRecord.vNode) and sCategory == rRecord.sCategory then
			local sNameLower = DB.getValue(rRecord.vNode, "name", ""):lower();
			if sNameLower:match("%(contents%)") or sNameLower:match("%(index%)") then
				if vNode == rRecord.vNode then
					return nil;
				end
				return rRecord.vNode;
			end
		end
	end
	
	return nil;
end
function getNextRecord(vNode)
	if bDelayedChildrenChanged then
		onListRecordsChanged(false);
	end

	local sCategory = UtilityManager.getNodeCategory(vNode);
	local sModule = UtilityManager.getNodeModule(vNode);

	aSortedRecords = {};
	for _,rRecord in pairs(_tRecords) do
		if sModule == UtilityManager.getNodeModule(rRecord.vNode) and sCategory == rRecord.sCategory then
			table.insert(aSortedRecords, rRecord);
		end
	end
	table.sort(aSortedRecords, ListManager.defaultSortFunc);
	
	local bGetNext = false;
	for _,rRecord in ipairs(aSortedRecords) do
		if bGetNext then
			return rRecord.vNode;
		end
		if rRecord.vNode == vNode then
			bGetNext = true;
		end
	end
	
	return nil;
end
function getPrevRecord(vNode)	
	if bDelayedChildrenChanged then
		onListRecordsChanged(false);
	end

	local sCategory = UtilityManager.getNodeCategory(vNode);
	local sModule = UtilityManager.getNodeModule(vNode);

	aSortedRecords = {};
	for _,rRecord in pairs(_tRecords) do
		if sModule == UtilityManager.getNodeModule(rRecord.vNode) and sCategory == rRecord.sCategory then
			table.insert(aSortedRecords, rRecord);
		end
	end
	table.sort(aSortedRecords, ListManager.defaultSortFunc);
	
	local nodePrev = nil;
	for _,rRecord in ipairs(aSortedRecords) do
		if rRecord.vNode == vNode then
			return nodePrev;
		end
		nodePrev = rRecord.vNode;
	end
	
	return nil;
end

--
--	LIST HANDLING
--

function refreshDisplayList(bResetScroll)
	saveDisplayListScrollPosition(bResetScroll);
	ListManager.refreshDisplayList(self);
	
	local nListOffset = 40;
	if ListManager.getMaxPages(self) > 1 then
		nListOffset = nListOffset + 24;
	end
	if nCustomFilters > 0 then
		nListOffset = nListOffset + (25 * nCustomFilters);
	end
	list.setAnchor("bottom", "bottomanchor", "top", "relative", -nListOffset);

	restoreDisplayListScrollPosition();
end
function addDisplayListItem(v)
	local wItem = list.createWindow(v.vNode);
	if wItem.category and (fCategory ~= "*") then
		wItem.category.setVisible(false);
	end
	wItem.setRecordType(sInternalRecordType);
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
	refreshDisplayList(true);
end
function getDisplayRecordCount()
	return _nFilteredRecordCount;
end
function setDisplayRecordCount(n)
	_nFilteredRecordCount = n;
end

function isFilteredRecord(v)
	if bAllowCategories and fCategory ~= "*" then
		if v.sCategory ~= fCategory then
			return false;
		end
	end
	if fSharedOnly then
		if v.nAccess == 0 then
			return false;
		end
	end
	for kCustomFilter,sCustomFilterValue in pairs(aCustomFilterValues) do
		if sCustomFilterValue ~= "" then
			local vValues = getFilterValues(kCustomFilter, v.vNode);
			local bMatch = false;
			for _,v in ipairs(vValues) do
				if v:lower() == sCustomFilterValue then
					bMatch = true;
					break;
				end
			end
			if not bMatch then
				return false;
			end
		end
	end
	if fName ~= "" then
		if not string.find(v.sDisplayNameLower, fName, 0, true) then
			return false;
		end
	end
	return true;
end
