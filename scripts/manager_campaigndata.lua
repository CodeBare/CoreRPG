-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	DB.onImport = onImport;
	DB.onExport = onExport;
end

--
-- Drop handling
--

function handleFileDrop(sTarget, draginfo)
	if not Session.IsHost then 
		return; 
	end
	
	if sTarget == "image" then
		Interface.addImageFile(draginfo.getStringData());
		return true;
	end
end

function createImageRecordFromAsset(sAsset, bOpen)
	local bAllowEdit = LibraryData.allowEdit("image");
	if not bAllowEdit then
		return;
	end

	local sName;
	local tSplit = StringManager.split(sAsset, "/");
	if #tSplit > 0 then
		local sFileName = tSplit[#tSplit];
		local tNameSplit = StringManager.split(sFileName, ".");
		if #tNameSplit > 1 and StringManager.contains({"png", "PNG", "jpg", "JPG", "jpeg", "JPEG"}, tNameSplit[#tNameSplit]) then
			tNameSplit[#tNameSplit] = nil;
			sName = table.concat(tNameSplit, ".");
		else
			sName = sFileName;
		end
	else
		sName = sAsset;
	end

	local nodeTarget = nil;
	local sRootMapping = LibraryData.getRootMapping("image");
	for _,vNode in pairs(DB.getChildren(sRootMapping)) do
		local sExistingName = DB.getValue(vNode, "name", "");
		if sName == sExistingName then
			ChatManager.SystemMessage(Interface.getString("image_message_exists") .. "\r(" .. sName .. ")");
			nodeTarget = vNode;
		end
	end

	if not nodeTarget then
		nodeTarget = DB.createChild(sRootMapping);
		DB.setValue(nodeTarget, "name", "string", sName);
		DB.setValue(nodeTarget, "image", "image", sAsset);
	end

	if nodeTarget and bOpen then
		local sDisplayClass = LibraryData.getRecordDisplayClass("image");
		Interface.openWindow(sDisplayClass, nodeTarget);
	end
end

function handleImageAssetDrop(sTarget, draginfo)
	if not Session.IsHost then 
		return; 
	end
	
	if sTarget == "image" then
		local sAsset = draginfo.getTokenData();
		CampaignDataManager.createImageRecordFromAsset(sAsset, true);
	end
end

function importCampaignImageAssets()
	local tAssets = Interface.getAssets("image", "campaign/images");
	for _,v in ipairs(tAssets) do
		CampaignDataManager.createImageRecordFromAsset(v, false);
	end
end

function handleDrop(sTarget, draginfo)
	if CampaignDataManager2 and CampaignDataManager2.handleDrop then
		if CampaignDataManager2.handleDrop(sTarget, draginfo) then
			return true;
		end
	end
	
	if not Session.IsHost then
		return;
	end
	
	if sTarget == "item" then
		ItemManager.handleAnyDrop(DB.createNode("item"), draginfo);
		return true;
	elseif sTarget == "combattracker" then
		local sClass, sRecord = draginfo.getShortcutData();
		if sClass == "charsheet" then
			CombatManager.addPC(draginfo.getDatabaseNode());
			return true;
		elseif sClass == "npc" then
			CombatManager.addNPC(sClass, draginfo.getDatabaseNode());
			return true;
		elseif sClass == "battle" then
			CombatManager.addBattle(draginfo.getDatabaseNode());
			return true;
		end
	else
		local sClass, sRecord = draginfo.getShortcutData();

		local bAllowEdit = LibraryData.allowEdit(sTarget);
		if bAllowEdit then
			local sDisplayClass = LibraryData.getRecordDisplayClass(sTarget);
			local sRootMapping = LibraryData.getRootMapping(sTarget);

			local bCopy = false;
			if ((sRootMapping or "") ~= "") then
				if ((sDisplayClass or "") == sClass) then
					bCopy = true;
				elseif ((sTarget == "story") and (sClass == "note")) then
					bCopy = true;
				elseif ((sTarget == "note") and (sClass == "encounter")) then
					bCopy = true;
				end
			end
			if bCopy then
				local nodeSource = DB.findNode(sRecord);
				local nodeTarget = DB.createChild(sRootMapping);
				DB.copyNode(nodeSource, nodeTarget);
				local sName = DB.getValue(nodeTarget, "name", "");
				if sName ~= "" and UtilityManager.getNodeCategory(nodeSource) == UtilityManager.getNodeCategory(nodeTarget) then
					DB.setValue(nodeTarget, "name", "string", sName .. " " .. Interface.getString("masterindex_suffix_duplicate"));
				end
				DB.setValue(nodeTarget, "locked", "number", 1);
				return true;
			end
		end
	end
end

--
-- Character manaagement
--

local sImportRecordType = "";
function importChar()
	sImportRecordType = "charsheet";
	Interface.dialogFileOpen(CampaignDataManager.onImportFileSelection, nil, nil, true);
end
function importNPC()
	sImportRecordType = "npc";
	Interface.dialogFileOpen(CampaignDataManager.onImportFileSelection, nil, nil, true);
end
function onImportFileSelection(result, vPath)
	if result ~= "ok" then return; end
	
	if sImportRecordType == "charsheet" then
		local sRootMapping = LibraryData.getRootMapping(sImportRecordType);
		if sRootMapping then
			if type(vPath) == "table" then
				for _,v in ipairs(vPath) do
					DB.import(v, sRootMapping, "character");
					ChatManager.SystemMessage(Interface.getString("message_slashimportsuccess") .. ": " .. v);
				end
			else
				DB.import(vPath, sRootMapping, "character");
				ChatManager.SystemMessage(Interface.getString("message_slashimportsuccess") .. ": " .. vPath);
			end
		end
	elseif sImportRecordType == "npc" then
		local sRootMapping = LibraryData.getRootMapping(sImportRecordType);
		if sRootMapping then
			if type(vPath) == "table" then
				for _,v in ipairs(vPath) do
					DB.import(v, sRootMapping, "npc");
					ChatManager.SystemMessage(Interface.getString("message_slashimportsuccess") .. ": " .. v);
				end
			else
				DB.import(vPath, sRootMapping, "npc");
				ChatManager.SystemMessage(Interface.getString("message_slashimportsuccess") .. ": " .. vPath);
			end
		end
	end
end
function onImport(node)
	local aPath = StringManager.split(node.getPath(), ".");
	if #aPath == 2 and aPath[1] == "charsheet" then
		if DB.getValue(node, "token", ""):sub(1,9) == "portrait_" then
			DB.setValue(node, "token", "token", "portrait_" .. node.getName() .. "_token");
		end
	end
end

local sExportRecordType = "";
local sExportRecordPath = "";
function exportChar(nodeChar)
	sExportRecordType = "charsheet";
	if nodeChar then
		sExportRecordPath = DB.getPath(nodeChar);
	else
		sExportRecordPath = "";
	end
	Interface.dialogFileSave(CampaignDataManager.onExportFileSelection);
end
function exportNPC(nodeNPC)
	sExportRecordType = "npc";
	if nodeNPC then
		sExportRecordPath = DB.getPath(nodeNPC);
	else
		sExportRecordPath = "";
	end
	Interface.dialogFileSave(CampaignDataManager.onExportFileSelection);
end
function onExportFileSelection(result, path)
	if result ~= "ok" then 
		return; 
	end

	if sExportRecordType == "charsheet" then
		if (sExportRecordPath or "") ~= "" then
			DB.export(path, sExportRecordPath, "character");
		else
			local sRootMapping = LibraryData.getRootMapping(sExportRecordType);
			if sRootMapping then
				DB.export(path, sRootMapping, "character", true);
			end
		end
	elseif sExportRecordType == "npc" then
		if (sExportRecordPath or "") ~= "" then
			DB.export(path, sExportRecordPath, "npc");
		else
			local sRootMapping = LibraryData.getRootMapping(sExportRecordType);
			if sRootMapping then
				DB.export(path, sRootMapping, "npc", true);
			end
		end
	end
end
function onExport(node, sFile, sTag, bList)
	if sTag == "character" then
		if bList then
			ChatManager.SystemMessage(Interface.getString("message_slashexportsuccess"));
		else
			ChatManager.SystemMessage(Interface.getString("message_slashexportsuccess") .. ": " .. DB.getValue(node, "name", ""));
		end
	elseif sTag == "npc" then
		if bList then
			ChatManager.SystemMessage(Interface.getString("message_slashexportsuccess"));
		else
			ChatManager.SystemMessage(Interface.getString("message_slashexportsuccess") .. ": " .. DB.getValue(node, "name", ""));
		end
	end
end

function setCharPortrait(nodeChar, sPortrait)
	if not nodeChar or not sPortrait then
		return;
	end
	
	User.setPortrait(nodeChar, sPortrait);
	
	local sToken = DB.getValue(nodeChar, "token", "");
	if nodeChar and ((sToken == "") or (sToken:sub(1,9) == "portrait_")) then
		DB.setValue(nodeChar, "token", "token", "portrait_" .. nodeChar.getName() .. "_token");
	end
	
	local wnd = Interface.findWindow("charsheet", nodeChar)
	if wnd then
		if wnd.portrait then
			wnd.portrait.setIcon("portrait_" .. nodeChar.getName() .. "_charlist", true);
		end
	end
	
	wnd = Interface.findWindow("charselect_client", "charsheet");
	if wnd then
		for _, v in pairs(wnd.list.getWindows()) do
			if v.localdatabasenode then
				if v.localdatabasenode == nodeChar then
					if v.portrait then
						v.portrait.setFile(sPortrait);
					end
				end
			end
		end
	end
end

function addPregenChar(nodeSource)
	if CampaignDataManager2 and CampaignDataManager2.addPregenChar then
		return CampaignDataManager2.addPregenChar(nodeSource);
	end
	
	local nodeTarget = DB.createChild("charsheet");
	DB.copyNode(nodeSource, nodeTarget);

	local sToken = DB.getValue(nodeTarget, "token", "");
	if sToken:match("^portrait_.*_token$") then
		DB.setValue(nodeTarget, "token", "token", "portrait_" .. nodeTarget.getName() .. "_token");
	end

	ChatManager.SystemMessage(Interface.getString("pregenchar_message_add"));
	return nodeTarget;
end

--
-- Encounter management
--

function convertRndEncExprToEncCount(nodeNPC)
	local sExpr = DB.getValue(nodeNPC, "expr", "");
	DB.deleteChild(nodeNPC, "expr");
	
	sExpr = sExpr:gsub("$PC", tostring(PartyManager.getPartyCount()));
	
	local nCount = DiceManager.evalDiceMathExpression(sExpr);
	DB.setValue(nodeNPC, "count", "number", nCount);
	return nCount;
end

function generateEncounterFromRandom(nodeSource)
	if not nodeSource then
		return;
	end
	
	local sDisplayClass = LibraryData.getRecordDisplayClass("battle");
	local sRootMapping = LibraryData.getRootMapping("battle");
	if ((sRootMapping or "") == "") then
		return;
	end
	
	local nodeTarget = DB.createChild(sRootMapping);
	DB.copyNode(nodeSource, nodeTarget);
	
	local aDelete = {};
	local sTargetNPCList = LibraryData.getCustomData("battle", "npclist") or "npclist";
	for _,nodeNPC in pairs(DB.getChildren(nodeTarget, sTargetNPCList)) do
		local nCount = CampaignDataManager.convertRndEncExprToEncCount(nodeNPC);
		if nCount <= 0 then
			table.insert(aDelete, nodeNPC);
		end
	end
	for _,nodeDelete in ipairs(aDelete) do
		nodeDelete.delete();
	end
	DB.setValue(nodeTarget, "locked", "number", 1);

	if CampaignDataManager2 and CampaignDataManager2.onEncounterGenerated then
		CampaignDataManager2.onEncounterGenerated(nodeTarget);
	end
	
	Interface.openWindow(sDisplayClass, nodeTarget);
end
