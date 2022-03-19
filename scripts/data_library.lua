-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- RECORD TYPE FORMAT
-- 		["recordtype"] = { 
-- 			aDataMap = <table of strings>, (required)
--
--			bExport = <bool>, (optional)
--			nExport = <number>, (optional; overriden by bExport)
--			bExportNoReadOnly = <bool>, (optional; overrides bExport)
--			sExportPath = <string>, (optional)
--			bExportListSkip = <bool>, (optional)
--			sExportListDisplayClass = <string>, (optional)
--
-- 			bHidden = <bool>, (optional)
-- 			bID = <bool>, (optional)
--			bNoCategories = <bool>, (optional)
--
-- 			sListDisplayClass = <string>, (optional)
-- 			sRecordDisplayClass = <string>, (optional)
--			aRecordDisplayCLasses = <table of strings>, (optional; overrides sRecordDisplayClass)
--			fRecordDisplayClass = <function>, (optional; overrides sRecordDisplayClass)
--			fGetLink = <function>, (optional)
--
--			aGMListButtons = <table of template names>, (optional)
--			aPlayerListButtons = <table of template names>, (optional)
--
--			aCustomFilters = <table of custom filter table records>, (optional)
-- 		},
--

-- FIELDS ADDED FROM STRING DATA
-- 		sDisplayText = Interface.getString(library_recordtype_label_ .. sRecordType)
--		sSingleDisplayText = Interface.getString(library_recordtype_single_ .. sRecordType)
-- 		sEmptyNameText = Interface.getString(library_recordtype_empty_ .. sRecordType)
--		sExportDisplayText = Interface.getString(library_recordtype_export_ .. sRecordType)
-- FIELDS ADDED FROM STRING DATA (only when bID set)
-- 		sEmptyUnidentifiedNameText = Interface.getString(library_recordtype_empty_nonid_ .. sRecordType)
--

-- RECORD TYPE LEGEND
--		aDataMap = Required. Table of strings. defining the valid data paths for records of this type
--			NOTE: For bExport/nExport, that number of data paths from the beginning of the data map list will be used as the source for exporting 
--				and the target data paths will be the same in the module. (i.e. default campaign data paths, editable).
--				The next nExport data paths in the data map list will be used as the export target data paths for read-only data paths for the 
--				matching source data path.
--			EX: { "item", "armor", "weapon", "reference.items", "reference.armors", "reference.weapons" } with a nExport of 3 would mean that
--				the "item", "armor" and "weapon" data paths would be exported to the matching "item", "armor" and "weapon" data paths in the module by default.
--				If the reference data path option is selected, then "item", "armor" and "weapon" data paths would be exported to 
--				"reference.items", "reference.armors", and "reference.weapons", respectively.
--
--		bExport = Optional. Same as nExport = 1. Boolean indicating whether record should be exportable in the library export window for the record type.
--		nExport = Optional. Overriden by bExport. Number indicating number of data paths which are exportable in the library export window for the record type.
--			NOTE: See aDataMap for bExport/nExport are handled for target campaign data paths vs. reference data paths (editable vs. read-only)
--		bExportNoReadOnly = Optional. Similar to bExport. Boolean indicating whether record should be exportable in the library export window for the record type, but read only option in export is ignored.
--		sExportPath = Optional. When exporting records to a module, use this alternate data path when storing into a module, instead of the base data path for this record.
--		sExportListDisplayClass = Optional. When exporting records, the list link created for records to be accessed from the library will use this display class. (Default is reference_list)
--		bExportListSkip = Optional. When exporting records, a list link is normally created for the records to be accessed from the library. This option skips creation of the list and link.
--
--		bHidden = Optional. Boolean indicating whether record should be displayed in library, and sidebar options.
-- 		bID = Optional. Boolean indicating whether record is identifiable or not (currently only items and images)
--		bNoCategories = Optional. Disable display and usage of category information.
--		sEditMode = Optional. Valid values are "play" or "none".  If "play" specified, then both players and GMs can add/remove records of this record type. Note, players can only remove records they have created. If "none" specified, then neither player nor GM can add/remove records. If not specified, then only GM can add/remove records.
--			NOTE: The character selection dialog handles this in the custom character selection window class historically, so does not use this option.
--
--		sListDisplayClass = Optional. String. Class to use when displaying this record in a list. If not defined, a default class will be used.
--		sRecordDisplayClass = Optional. String. Class to use when displaying this record in detail. (Defaults to record type key string) 
--		aRecordDisplayClasses = Optional. Table of strings. List of valid display classes for records of this type. Use fRecordDisplayClass to specify which one to use for a given path.
--		fRecordDisplayClass = Optional. Function. Function called when requesting to display this record in detail.
--		fGetLink = Optional. Function. Function called to determine window class and data path to use when pressing or dragging sidebar button.
--
--		aGMListButtons = Optional. Table of template names. A list of control templates created and added to the master list window for this record type in GM mode.
--		aPlayerListButtons = Optional. Table of template names. A list of control templates created and added to the master list window for this record type in Player mode.
--
--		aCustomFilters = Optional. Table of custom filter table records.  Key = Label string to display for filter; 
--			Filter table record format is:
--				sField = Required. String. Child data node that contains data to use to build filter value list; and to apply filter to.
--				fGetValue = Optional. Function. Returns string or table of strings containing filter value(s) for the record passed as parameter to the function.
--				sType = Optional. String. Valid values are: "boolean", "number".  
--					NOTE: If no type specified, string is assumed. If empty string value returned, then the string resource (library_recordtype_filter_empty) will be used for display if available.
--					NOTE 2: For boolean type, these string resources will be used for labels (library_recordtype_filter_yes, library_recordtype_filter_no).
--
--		sDisplayText = Required. String Resource. Text displayed in library and tooltips to identify record type textually.
--		sEmptyNameText = Optional. String Resource. Text displayed in name field of record list and detail classes, when name is empty.
--		sEmptyUnidentifiedNameText = Optional. String Resource. Text displayed in nonid_name field of record list and detail classes, when nonid_name is empty. Only used if bID flag set.
--

function getCharListLink()
	if Session.IsHost then
		return "charselect_host", "charsheet";
	end
	return "charselect_client", "charsheet";
end

aRecords = {
	["effect"] = {
		bExport = true,
		bExportListSkip = true,
		bHidden = true,
		aDataMap = { "effects" },
	},
	["modifier"] = {
		bExport = true,
		bExportListSkip = true,
		bHidden = true,
		aDataMap = { "modifiers" },
	},
	["referencemanualpage"] = {
		bExport = true,
		bHidden = true,
		aDataMap = { "reference.refmanualdata" },
		sExportPath = "reference.refmanualdata",
		aExportAuxSource = { "reference.refmanualindex" },
		aExportAuxTarget = { "reference.refmanualindex" },
		sExportListClass = "reference_manual",
		sExportListPath = "reference.refmanualindex",
	},
	
	["charsheet"] = { 
		sExportPath = "pregencharsheet",
		sExportListClass = "pregencharselect",
		aDataMap = { "charsheet" },
		fGetLink = getCharListLink,
		-- sRecordDisplayClass = "charsheet", 
	},
	["note"] = { 
		bNoCategories = true,
		sEditMode = "play",
		aDataMap = { "notes" }, 
		sListDisplayClass = "masterindexitem_note",
		-- sRecordDisplayClass = "note", 
	},

	["story"] = { 
		bExport = true,
		aDataMap = { "encounter", "reference.encounters" }, 
		sRecordDisplayClass = "encounter", 
		aGMListButtons = { "button_storytemplate" },
		},
	["storytemplate"] = { 
		bExport = true,
		bHidden = true,
		aDataMap = { "storytemplate", "reference.storytemplates" }, 
		-- sRecordDisplayClass = "storytemplate", 
		},
	["quest"] = { 
		bExport = true,
		aDataMap = { "quest", "reference.quests" }, 
		-- sRecordDisplayClass = "quest", 
	},
	["image"] = { 
		bExportNoReadOnly = true,
		bID = true,
		aDataMap = { "image", "reference.images" }, 
		sListDisplayClass = "masterindexitem_id",
		sRecordDisplayClass = "imagewindow",
		aGMListButtons = { "button_folder_image", "button_store_image" },
		aGMListButtonsV4 = { "button_folder_import_image_files", "button_folder_import_image_assets", "button_store_image" },
	},
	["npc"] = { 
		bExport = true,
		bID = true,
		aDataMap = { "npc", "reference.npcs" }, 
		sListDisplayClass = "masterindexitem_id",
		-- sRecordDisplayClass = "npc", 
		aGMEditButtons = { "button_add_npc_import" },
	},
	["battle"] = { 
		bExport = true,
		aDataMap = { "battle", "reference.battles" }, 
		-- sRecordDisplayClass = "battle", 
		aGMListButtons = { "button_battlerandom" },
	},
	["battlerandom"] = { 
		bExport = true,
		bHidden = true,
		aDataMap = { "battlerandom", "reference.battlerandoms" }, 
		-- sRecordDisplayClass = "battlerandom", 
	},
	["item"] = { 
		bExport = true,
		bID = true,
		aDataMap = { "item", "reference.items" }, 
		sListDisplayClass = "masterindexitem_id",
		-- sRecordDisplayClass = "item",
		},
	["treasureparcel"] = { 
		bExport = true,
		aDataMap = { "treasureparcels", "reference.treasureparcels" }, 
		-- sRecordDisplayClass = "treasureparcel", 
	},
	["table"] = { 
		bExport = true,
		aDataMap = { "tables", "reference.tables" }, 
		-- sRecordDisplayClass = "table", 
		aGMEditButtons = { "button_add_table_guided", "button_add_table_import_text" },
	},
	["vehicle"] = { 
		bExport = true,
		aDataMap = { "vehicle", "reference.vehicles" }, 
		-- sRecordDisplayClass = "vehicle", 
		aGMListButtons = { "button_vehicle_type" },
		aCustomFilters = {
			["Type"] = { sField = "type" },
		},
	},
};

aListViews = {
	["vehicle"] = {
		["bytype"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "vehicle_grouped_label_name", nWidth=200 },
				{ sName = "cost", sType = "string", sHeadingRes = "vehicle_grouped_label_cost", nWidth=80, bCentered=true },
				{ sName = "weight", sType = "number", sHeadingRes = "vehicle_grouped_label_weight", sTooltipRes="vehicle_grouped_tooltip_weight", bCentered=true },
				{ sName = "speed", sType = "string", sHeadingRes = "vehicle_grouped_label_speed", sTooltipRes="vehicle_grouped_tooltip_speed", nWidth=100, bCentered=true },
			},
			aFilters = {},
			aGroups = { { sDBField = "type" } },
			aGroupValueOrder = {},
		},
	},
};

local _bInitialized = false;
function initialize()
	sFilterValueYes = Interface.getString("library_recordtype_filter_yes");
	sFilterValueNo = Interface.getString("library_recordtype_filter_no");
	sFilterValueEmpty = Interface.getString("library_recordtype_filter_empty");
	
	for kRecordType,_ in pairs(aRecords) do
		LibraryData.initRecordType(kRecordType);
	end

	for kRecordType,tRecordTypeViews in pairs(aListViews) do
		for kRecordView,_ in pairs(tRecordTypeViews) do
			LibraryData.initRecordView(kRecordType, kRecordView);
		end
	end

	_bInitialized = true;
end

function initRecordType(sRecordType)
	local tRecordTypeInfo = LibraryData.getRecordTypeInfo(sRecordType);
	if not tRecordTypeInfo then
		return;
	end

	tRecordTypeInfo.sDisplayText = Interface.getString("library_recordtype_label_" .. sRecordType);
	tRecordTypeInfo.sEmptyNameText = Interface.getString("library_recordtype_empty_" .. sRecordType);
	if tRecordTypeInfo.bID then
		tRecordTypeInfo.sEmptyUnidentifiedNameText = Interface.getString("library_recordtype_empty_nonid_" .. sRecordType);
	end
	tRecordTypeInfo.sExportDisplayText = Interface.getString("library_recordtype_export_" .. sRecordType);
	if tRecordTypeInfo.sExportDisplayText == "" then 
		tRecordTypeInfo.sExportDisplayText = tRecordTypeInfo.sDisplayText; 
	end
	tRecordTypeInfo.sSingleDisplayText = Interface.getString("library_recordtype_single_" .. sRecordType);
	if tRecordTypeInfo.sSingleDisplayText == "" then 
		tRecordTypeInfo.sSingleDisplayText = tRecordTypeInfo.sDisplayText:gsub("s$", ""); 
	end
	
	local aMappings = LibraryData.getMappings(sRecordType);
	if aMappings and (#aMappings > 0) then
		local rExport = {};
		rExport.name = sRecordType;
		rExport.label = tRecordTypeInfo.sExportDisplayText;
		if tRecordTypeInfo.sExportListClass then
			rExport.listclass = tRecordTypeInfo.sExportListClass;
			rExport.listpath = tRecordTypeInfo.sExportListPath;
		elseif not tRecordTypeInfo.bExportListSkip then
			rExport.listclass = "reference_list";
		end

		local sDisplayClass = LibraryData.getRecordDisplayClass(sRecordType);
		if tRecordTypeInfo.sExportPath then
			rExport.source = aMappings[1];
			rExport.export = tRecordTypeInfo.sExportPath;
			rExport.exportref = tRecordTypeInfo.sExportPath;
		elseif tRecordTypeInfo.bExportNoReadOnly then
			rExport.source = aMappings[1];
			rExport.export = aMappings[1];
			rExport.exportref = aMappings[1];
		elseif tRecordTypeInfo.bExport then
			rExport.source = aMappings[1];
			rExport.export = aMappings[1];
			rExport.exportref = aMappings[2];
		elseif tRecordTypeInfo.nExport then
			local aExportMappings = {};
			local aExportRefMappings = {};
			for i = 1, tRecordTypeInfo.nExport do
				if aMappings[i] then
					table.insert(aExportMappings, aMappings[i]);
				end
				if aMappings[tRecordTypeInfo.nExport + i] then
					table.insert(aExportRefMappings, aMappings[tRecordTypeInfo.nExport + i]);
				end
			end
			if #aExportMappings > 0 then
				rExport.source = aExportMappings;
				rExport.export = aExportMappings;
				if #aExportRefMappings > 0 then
					rExport.exportref = aExportRefMappings;
				end
			end
		end

		if tRecordTypeInfo.aExportAuxSource and tRecordTypeInfo.aExportAuxTarget and (#(tRecordTypeInfo.aExportAuxSource) == #(tRecordTypeInfo.aExportAuxTarget)) then
			if type(rExport.source) ~= "table" then
				rExport.source = { rExport.source };
			end
			if type(rExport.export) ~= "table" then
				rExport.export = { rExport.export };
			end
			if rExport.exportref and (type(rExport.exportref) ~= "table") then
				rExport.exportref = { rExport.exportref };
			end

			for _,v in ipairs(tRecordTypeInfo.aExportAuxSource) do
				table.insert(rExport.source, v);
			end
			for _,v in ipairs(tRecordTypeInfo.aExportAuxTarget) do
				table.insert(rExport.export, v);
			end
			if rExport.exportref then
				for _,v in ipairs(tRecordTypeInfo.aExportAuxRefTarget or tRecordTypeInfo.aExportAuxTarget) do
					table.insert(rExport.exportref, v);
				end
			end
		end
		
		if rExport.source then
			ExportManager.registerExportNode(rExport);
		end
	end
end
function getRecordTypes()
	local aRecordTypes = {};
	for kRecordType,vRecord in pairs(aRecords) do
		table.insert(aRecordTypes, kRecordType);
	end
	table.sort(aRecordTypes);
	return aRecordTypes;
end
function getRecordTypeInfo(sRecordType)
	return aRecords[sRecordType];
end
function setRecordTypeInfo(sRecordType, rRecordType)
	aRecords[sRecordType] = rRecordType;
end
function overrideRecordTypes(tRecordTypes)
	for kRecordType,vRecordType in pairs(tRecordTypes) do
		LibraryData.overrideRecordTypeInfo(kRecordType, vRecordType);
	end
end
function overrideRecordTypeInfo(sRecordType, rRecordType)
	if aRecords[sRecordType] then
		for k,v in pairs(rRecordType) do
			aRecords[sRecordType][k] = v;
		end
	else
		aRecords[sRecordType] = rRecordType;
	end
end
function getRecordTypeFromPath(sPath)
	for kRecordType,vRecord in pairs(aRecords) do
		if vRecord.aDataMap and vRecord.aDataMap[1] and vRecord.aDataMap[1] == sPath then
			return kRecordType;
		end
	end
	return "";
end
function getRecordTypeFromRecordPath(sRecord)
	local sRecordSansModule = StringManager.split(sRecord, "@")[1];
	local aRecordPathSansModule = StringManager.split(sRecordSansModule, ".");
	if #aRecordPathSansModule > 0 then aRecordPathSansModule[#aRecordPathSansModule] = nil; end
	local sRecordListSansModule = table.concat(aRecordPathSansModule, ".");
	for kRecordType,vRecord in pairs(aRecords) do
		if vRecord.aDataMap then
			for _,vMapping in ipairs(vRecord.aDataMap) do
				if vMapping == sRecordListSansModule then
					return kRecordType;
				end
			end
		end
	end
	return "";
end

function isHidden(sRecordType)
	if aRecords[sRecordType] then
		if aRecords[sRecordType].bHidden then
			return true;
		end
	end
	return false;
end
function getDisplayText(sRecordType)
	if aRecords[sRecordType] then
		return aRecords[sRecordType].sDisplayText;
	end
	return "";
end
function getSingleDisplayText(sRecordType)
	if aRecords[sRecordType] then
		return aRecords[sRecordType].sSingleDisplayText;
	end
	return "";
end
function getCategoryDisplayText(sCategory)
	return Interface.getString("library_category_label_" .. sCategory);
end

function getRootMapping(sRecordType)
	if aRecords[sRecordType] then
		local sType = type(aRecords[sRecordType].aDataMap);
		if sType == "table" then
			return aRecords[sRecordType].aDataMap[1];
		elseif sType == "string" then
			return aRecords[sRecordType].aDataMap;
		end
	end
end
function getMappings(sRecordType)
	if aRecords[sRecordType] then
		local sType = type(aRecords[sRecordType].aDataMap);
		if sType == "table" then
			return aRecords[sRecordType].aDataMap;
		elseif sType == "string" then
			return { aRecords[sRecordType].aDataMap };
		end
	end
	return {};
end
function getIndexDisplayClass(sRecordType)
	if aRecords[sRecordType] then
		return (aRecords[sRecordType].sListDisplayClass or "");
	end
	return "";
end
function getIndexButtons(sRecordType)
	if aRecords[sRecordType] then
		if Session.IsHost then
			return (aRecords[sRecordType].aGMListButtonsV4 or aRecords[sRecordType].aGMListButtons or {});
		else
			return (aRecords[sRecordType].aPlayerListButtonsV4 or aRecords[sRecordType].aPlayerListButtons or {});
		end
	end
	return {};
end
function addIndexButton(sRecordType, sButtonTemplate)
	if (sButtonTemplate or "") == "" then
		return;
	end
	if aRecords[sRecordType] then
		if Session.IsHost then
			if aRecords[sRecordType].aGMListButtonsV4 then
				if not StringManager.contains(aRecords[sRecordType].aGMListButtonsV4, sButtonTemplate) then
					table.insert(aRecords[sRecordType].aGMListButtonsV4, sButtonTemplate);
				end
			else
				if not aRecords[sRecordType].aGMListButtons then
					aRecords[sRecordType].aGMListButtons = {};
				end
				if not StringManager.contains(aRecords[sRecordType].aGMListButtons, sButtonTemplate) then
					table.insert(aRecords[sRecordType].aGMListButtons, sButtonTemplate);
				end
			end
		else
			if aRecords[sRecordType].aPlayerListButtonsV4 then
				if not StringManager.contains(aRecords[sRecordType].aPlayerListButtonsV4, sButtonTemplate) then
					table.insert(aRecords[sRecordType].aPlayerListButtonsV4, sButtonTemplate);
				end
			else
				if not aRecords[sRecordType].aPlayerListButtons then
					aRecords[sRecordType].aPlayerListButtons = {};
				end
				if not StringManager.contains(aRecords[sRecordType].aPlayerListButtons, sButtonTemplate) then
					table.insert(aRecords[sRecordType].aPlayerListButtons, sButtonTemplate);
				end
			end
		end
	end
end
function removeIndexButton(sRecordType, sButtonTemplate)
	if (sButtonTemplate or "") == "" then return; end
	if not aRecords[sRecordType] then return; end
	if Session.IsHost then
		if aRecords[sRecordType].aGMListButtonsV4 then
			for kButton, sButton in pairs(aRecords[sRecordType].aGMListButtonsV4) do
				if sButton == sButtonTemplate then
					table.remove(aRecords[sRecordType].aGMListButtonsV4, kButton);
					return;
				end
			end
		elseif aRecords[sRecordType].aGMListButtons then
			for kButton, sButton in pairs(aRecords[sRecordType].aGMListButtons) do
				if sButton == sButtonTemplate then
					table.remove(aRecords[sRecordType].aGMListButtons, kButton);
					return;
				end
			end
		end
	else
		if aRecords[sRecordType].aPlayerListButtonsV4 then
			for kButton, sButton in pairs(aRecords[sRecordType].aPlayerListButtonsV4) do
				if sButton == sButtonTemplate then
					table.remove(aRecords[sRecordType].aPlayerListButtonsV4, kButton);
					return;
				end
			end
		elseif aRecords[sRecordType].aPlayerListButtons then
			for kButton, sButton in pairs(aRecords[sRecordType].aPlayerListButtons) do
				if sButton == sButtonTemplate then
					table.remove(aRecords[sRecordType].aPlayerListButtons, kButton);
					return;
				end
			end
		end
	end
end
function getEditButtons(sRecordType)
	if aRecords[sRecordType] then
		if Session.IsHost then
			return (aRecords[sRecordType].aGMEditButtons or {});
		else
			return (aRecords[sRecordType].aPlayerEditButtons or {});
		end
	end
	return {};
end
function getCustomFilters(sRecordType)
	if aRecords[sRecordType] then
		return (aRecords[sRecordType].aCustomFilters or {});
	end
	return {};
end
function getEmptyNameText(sRecordType)
	if aRecords[sRecordType] then
		return aRecords[sRecordType].sEmptyNameText;
	end
	return "";
end
function getEmptyUnidentifiedNameText(sRecordType)
	if aRecords[sRecordType] then
		return aRecords[sRecordType].sEmptyUnidentifiedNameText;
	end
	return "";
end

function getRecordDisplayClass(sRecordType, sPath)
	if aRecords[sRecordType] then
		if aRecords[sRecordType].fRecordDisplayClass then
			return aRecords[sRecordType].fRecordDisplayClass(sPath);
		elseif aRecords[sRecordType].aRecordDisplayClasses then
			return aRecords[sRecordType].aRecordDisplayClasses[1];
		elseif aRecords[sRecordType].sRecordDisplayClass then
			return aRecords[sRecordType].sRecordDisplayClass;
		else
			return sRecordType;
		end
	end
	return "";
end
function isRecordDisplayClass(sRecordType, sClass)
	if aRecords[sRecordType] then
		if aRecords[sRecordType].fIsRecordDisplayClass then
			return aRecords[sRecordType].fIsRecordDisplayClass(sClass);
		elseif aRecords[sRecordType].aRecordDisplayClasses then
			return StringManager.contains(aRecords[sRecordType].aRecordDisplayClasses, sClass);
		elseif aRecords[sRecordType].sRecordDisplayClass then
			return (aRecords[sRecordType].sRecordDisplayClass == sClass);
		else
			return (sRecordType == sClass);
		end
	end
	return false;
end
function getRecordTypeFromDisplayClass(sClass)
	for kRecordType,vRecordType in pairs(aRecords) do
		if LibraryData.isRecordDisplayClass(kRecordType, sClass) then
			return kRecordType;
		end
	end
	return "";
end

function getIDMode(sRecordType)
	if aRecords[sRecordType] then
		if aRecords[sRecordType].bID then
			return aRecords[sRecordType].bID;
		end
	end
	return false;
end
function isIdentifiable(sRecordType, vNode)
	if aRecords[sRecordType] then
		if aRecords[sRecordType].bID then
			if aRecords[sRecordType].fIsIdentifiable then
				return aRecords[sRecordType].fIsIdentifiable(vNode);
			else
				return true;
			end
		end
	end
	return false;
end
function getIDOption(sRecordType)
	if aRecords[sRecordType] and aRecords[sRecordType].sIDOption then
		return aRecords[sRecordType].sIDOption;
	end
	return "";
end
function getIDState(sRecordType, vNode, bIgnoreHost)
	local bID = true;
	
	if LibraryData.isIdentifiable(sRecordType, vNode) then
		if aRecords[sRecordType].fGetIDState then
			bID = aRecords[sRecordType].fGetIDState(vNode, bIgnoreHost);
		else
			if (bIgnoreHost or not Session.IsHost) then
				bID = (DB.getValue(vNode, "isidentified", 1) == 1);
			end
		end
	end
	
	return bID;
end

function getCustomData(sRecordType, sKey)
	if aRecords[sRecordType] and aRecords[sRecordType].aCustom then
		return aRecords[sRecordType].aCustom[sKey];
	end
	return nil;
end
function setCustomData(sRecordType, sKey, v)
	if aRecords[sRecordType] then
		if not aRecords[sRecordType].aCustom then
			aRecords[sRecordType].aCustom = {};
		end
		aRecords[sRecordType].aCustom[sKey] = v;
	end
end

function allowCategories(sRecordType)
	if aRecords[sRecordType] then
		if aRecords[sRecordType].bNoCategories then
			return false;
		end
	end
	return true;
end
function allowEdit(sRecordType)
	if aRecords[sRecordType] then
		local vEditMode = aRecords[sRecordType].sEditMode;
		if vEditMode then
			if vEditMode == "play" then
				return true;
			elseif vEditMode == "none" then
				return false;
			end
		end

		-- Default behavior (host only editing, no local or player)
		if Session.IsHost then
			return true;
		end
	end
	return false;
end

--
--	RECORD VIEW FUNCTIONS
--

function setListView(sRecordType, sRecordView, tRecordViewData)
	LibraryData.setRecordView(sRecordType, sRecordView, tRecordViewData);
end
function getListView(sRecordType, sRecordView)
	return LibraryData.getRecordView(sRecordType, sRecordView);
end

function initRecordView(sRecordType, sRecordView)
	local tRecordType = LibraryData.getRecordTypeInfo(sRecordType);
	local tRecordView = LibraryData.getListView(sRecordType, sRecordView);
	if not tRecordType or not tRecordView then
		return;
	end
	
	local sRecordViewLabelRes = string.format("library_recordview_label_%s_%s", sRecordType, sRecordView);
	local sRecordViewLabel = Interface.getString(sRecordViewLabelRes);
	if (sRecordViewLabel or "") ~= "" then
		tRecordView.sDisplayText = string.format("%s - %s", tRecordType.sDisplayText, sRecordViewLabel);
		tRecordView.sExportDisplayText = string.format("%s - %s", tRecordType.sExportDisplayText, sRecordViewLabel);
	else
		tRecordView.sDisplayText = Interface.getString(tRecordView.sTitleRes);
		if (tRecordView.sDisplayText or "") == "" then
			tRecordView.sDisplayText = tRecordView.sTitle or "";
		end
		tRecordView.sExportDisplayText = tRecordView.sDisplayText;
	end
end
function getRecordViews(sRecordType)
	if not aListViews[sRecordType] then
		return nil;
	end
	return aListViews[sRecordType];
end
function getRecordView(sRecordType, sRecordView)
	if not aListViews[sRecordType] or not aListViews[sRecordType][sRecordView] then
		return nil;
	end
	return aListViews[sRecordType][sRecordView];
end
function setRecordViews(tRecordViews)
	for kRecordType,tRecordTypeViews in pairs(tRecordViews) do
		for kRecordView,tRecordView in pairs(tRecordTypeViews) do
			LibraryData.setRecordView(kRecordType, kRecordView, tRecordView);
		end
	end
end
function setRecordView(sRecordType, sRecordView, tRecordViewData)
	if not aListViews[sRecordType] then
		aListViews[sRecordType] = {};
	end
	aListViews[sRecordType][sRecordView] = tRecordViewData;

	if _bInitialized then
		LibraryData.initRecordView(sRecordType, sRecordView);
	end
end

--
--	GROUPED VIEW FUNCTIONS
--

local aCustomFilterHandlers = {};
function setCustomFilterHandler(sKey, f)
	aCustomFilterHandlers[sKey] = f;
end
function getCustomFilterValue(sKey, vRecord, vDefault)
	if aCustomFilterHandlers[sKey] then
		return aCustomFilterHandlers[sKey](vRecord, vDefault);
	end
	return vDefault;
end

local aCustomColumnHandlers = {};
function setCustomColumnHandler(sKey, f)
	aCustomFilterHandlers[sKey] = f;
end
function getCustomColumnValue(sKey, vRecord, vDefault)
	if aCustomFilterHandlers[sKey] then
		return aCustomFilterHandlers[sKey](vRecord, vDefault);
	end
	return vDefault;
end

--
--	FILTER VIEW FUNCTIONS
--

local aCustomGroupOutputHandlers = {};
function setCustomGroupOutputHandler(sKey, f)
	aCustomGroupOutputHandlers[sKey] = f;
end
function getCustomGroupOutput(sKey, vGroupValue)
	if aCustomGroupOutputHandlers[sKey] then
		return aCustomGroupOutputHandlers[sKey](vGroupValue);
	end
	return vGroupValue;
end

--
--	MISC
--

function openRecordWindow(sRecordType, node)
	if not node then
		return;
	end

	local sClass = LibraryData.getRecordDisplayClass(sRecordType);
	local w = Interface.openWindow(sClass, node);
	if w.header and w.header.subwindow and w.header.subwindow.name then
		w.header.subwindow.name.setFocus();
	end
end
