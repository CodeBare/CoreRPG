-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local rsname = "CoreRPG";
local rsmajorversion = 5;

function onInit()
	if Session.IsHost then
		VersionManager.updateCampaign();
	end
	Module.onModuleLoad = onModuleLoad;
end

function onModuleLoad(sModule)
	local _, _, aMajor, _ = DB.getRulesetVersion(sModule);
	VersionManager.updateModule(sModule, aMajor[rsname]);
end

function updateCampaign()
	local _, _, aMajor, aMinor = DB.getRulesetVersion();
	local major = aMajor[rsname];
	if not major then
		return;
	end
	
	if major > 0 and major < rsmajorversion then
		print("Migrating campaign database to latest data version. (" .. rsname ..")");
		DB.backup();
		
		if major < 2 then
			VersionManager.convertNotes2();
		end
		if major < 4 then
			VersionManager.convertImages4();
			VersionManager.convertItems4();
			VersionManager.convertPartyItems4();
		end
		if major < 5 then
			VersionManager.convertCurrency5();
		end
	end
end

function updateModule(sModule, nVersion)
	if not nVersion then nVersion = 0; end
	if nVersion > 0 and nVersion < rsmajorversion then
		local nodeRoot = DB.getRoot(sModule);
		if not nodeRoot then return; end
		if nVersion < 4 then
			VersionManager.convertImages4(nodeRoot);
			VersionManager.convertItems4(nodeRoot);
		end
	end
end

function convertNotes2()
	for _,vNote in pairs(DB.getChildren("notes")) do
		local vText = DB.getChild(vNote, "text");
		if DB.getType(vText) == "string" then
			local sText = vText.getValue();
			sText = "<p>" .. sText:gsub("\n", "</p><p>") .. "</p>";
			DB.deleteChild(vNote, "text");
			DB.setValue(vNote, "text", "formattedtext", sText);
		end
	end
end

function convertImages4(nodeRoot)
	local sValue = DB.getValue("options.IMID", "");
	if sValue == "on" then return; end
	
	local aMappings = LibraryData.getMappings("image");
	for _,vMapping in ipairs(aMappings) do
		for _,vNode in pairs(DB.getChildren(DB.getPath(nodeRoot, vMapping))) do
			DB.deleteChild(vNode, "isidentified");
		end
	end
end

function convertItems4(nodeRoot)
	local sValue = DB.getValue("options.MIID", "");
	if sValue == "on" then return; end
	
	local aMappings = LibraryData.getMappings("item");
	for _,vMapping in ipairs(aMappings) do
		for _,vNode in pairs(DB.getChildren(DB.getPath(nodeRoot, vMapping))) do
			DB.deleteChild(vNode, "isidentified");
		end
	end

	local aMappings = LibraryData.getMappings("treasureparcel");
	for _,vMapping in ipairs(aMappings) do
		for _,vNode in pairs(DB.getChildren(DB.getPath(nodeRoot, vMapping))) do
			for _,vParcelItem in pairs(DB.getChildren(vNode, "itemlist")) do
				DB.deleteChild(vNode, "isidentified");
			end
		end
	end
end

function convertPartyItems4()
	local sValue = DB.getValue("options.MIID", "");
	if sValue == "on" then return; end
	
	for _,vParcelItem in pairs(DB.getChildren("partysheet.treasureparcelitemlist")) do
		DB.deleteChild(vNode, "isidentified");
	end
end

function convertCurrency5()
	if not GameSystem.currencies then
		return;
	end

	local tGameCurrencies = {};
	for _,tGameCurrency in ipairs(GameSystem.currencies) do
		local tNew = {
			sName = tGameCurrency["name"] or tGameCurrency,
			nWeight = tGameCurrency["weight"] or 0,
			nValue = tGameCurrency["value"] or 0,
		};
		if type(tNew.sName) == "string" then
			tNew.sNameLower = tNew.sName:lower();
		else
			tNew.sNameLower = "";
		end
		table.insert(tGameCurrencies, tNew);
	end

	for _,nodeCurrency in pairs(DB.getChildren("currencies")) do
		local nWeight = DB.getValue(nodeCurrency, "weight", 0);
		local nValue = DB.getValue(nodeCurrency, "value", 0);
		if (nWeight == 0) and (nValue == 0) then
			local sNameLower = StringManager.trim(DB.getValue(nodeCurrency, "name", "")):lower();
			if sNameLower ~= "" then
				for _,tGameCurrency in ipairs(tGameCurrencies) do
					if sNameLower == tGameCurrency.sNameLower then
						DB.setValue(nodeCurrency, "weight", "number", tGameCurrency.nWeight);
						DB.setValue(nodeCurrency, "value", "number", tGameCurrency.nValue);
						break;
					end
				end
			end
		end
	end
end
