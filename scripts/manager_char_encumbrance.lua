-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _tStandardSupportedRulesets =
{
	"CoreRPG",
	"3.5E",
	"4E",
	"5E",
	"13th_Age",
	"AFF2",
	"Basic Roleplaying",
	"BoL",
	"CallOfCthulhu",
	"CallOfCthulhu7E",
	"d20 Modern",
	"DCC RPG",
	"Fate Core",
	"ICONS",
	"MCC RPG",
	"PFRPG",
	"Symbaroum",
	"WOIN",
};

-- Known Custom Overrides
--		2E
--		Alien
--		Castles and Crusades (Legacy)
--		Conan
--		MGT1
--		MGT2
--		SFRPG
--		SavageWorlds
--		SWD
--		SWPF
--		Vaesen

-- Known Lack of Currency and/or Encumbrance
--		Cypher System
--		Index Card RPG
--		Mutants and Masterminds 3rd
--		Numenera (Cypher)
--		The Strange (Cypher)

-- Unknown at this time
--		PFRPG2
--		RMC

--
--	Initialization and Cleanup
--

local _bInitComplete = false;
local _bDesktopInitComplete = false;
function onInit()
	if StringManager.contains(_tStandardSupportedRulesets, Interface.getRuleset()) then
		CharEncumbranceManager.addStandardCalc();
	end
	Interface.onDesktopInit = onDesktopInit;
	_bInitComplete = true;
end
function onDesktopInit()
	performInit();
	_bDesktopInitComplete = true;
end
function onClose()
	if Session.IsHost and CharEncumbranceManager.isEnabled() then
		OptionsManager.unregisterCallback("CURR", CharEncumbranceManager.onCurrencyOptionUpdate);
		CurrencyManager.unregisterCallback(CharEncumbranceManager.onCurrencyUpdate);
		CharEncumbranceManager.disableCharCurrencyHandlers();
	end
end

local _bInitialized = false;
function performInit()
	if not _bInitComplete then
		return;
	end

	if CharEncumbranceManager.isEnabled() then
		if _bInitialized then
			return;
		end

		OptionsManager.registerOption2("CURR", false, "option_header_houserule", "option_label_CURR", "option_entry_cycler", 
				{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });

		if Session.IsHost then
			OptionsManager.registerCallback("CURR", CharEncumbranceManager.onCurrencyOptionUpdate);
			CurrencyManager.registerCallback(CharEncumbranceManager.onCurrencyUpdate);
			CharEncumbranceManager.enableCharCurrencyHandlers();

			CharEncumbranceManager.updateAllCharacters();
		end

		_bInitialized = true;
	end
end

--
--	Settings
--

local _fnEncumbranceCalc = nil;
function addCustomCalc(fnEncumbranceCalc)
	if _bInitialized then
		ChatManager.SystemMessage("CharEncumbranceManager.addDefaultEncumbranceCalc can only be called once.")
		return;
	end
	_fnEncumbranceCalc = fnEncumbranceCalc;
	performInit();
end
function addStandardCalc()
	CharEncumbranceManager.addCustomCalc(CharEncumbranceManager.calcDefaultEncumbrance);
end
function isEnabled()
	return (_fnEncumbranceCalc ~= nil);
end

local _sEncumbranceField = "encumbrance.load";
function setEncumbranceField(sFieldName)
	_sEncumbranceField = sFieldName;
end
function getEncumbranceField()
	return _sEncumbranceField;
end

local _tCustomCurrencyFields = nil;
function setCurrencyUpdateFields(tCustomCurrencyFields)
	_tCustomCurrencyFields = tCustomCurrencyFields;
end
function getCurrencyUpdateFields()
	return _tCustomCurrencyFields or _tDefaultCurrencyFields;
end

--
-- 	Database behaviors
--

function enableCharCurrencyHandlers()
	local tItemLists = ItemManager.getInventoryPaths("charsheet");
	local tItemFields = ItemManager.getEncumbranceFields("charsheet");
	for _,sList in ipairs(tItemLists) do
		local sListPath = "charsheet.*." .. sList;
		for _,sField in ipairs(tItemFields) do
			DB.addHandler(sListPath .. ".*." .. sField, "onUpdate", CharEncumbranceManager.onCharItemFieldUpdate);
		end
		DB.addHandler(sListPath, "onChildDeleted", CharEncumbranceManager.onCharItemDelete);
	end

	local tCurrencyPaths = CurrencyManager.getCurrencyPaths("charsheet");
	local tCurrencyFields = CurrencyManager.getEncumbranceFields("charsheet");
	for _,sList in ipairs(tCurrencyPaths) do
		local sListPath = "charsheet.*." .. sList;
		for _,sField in ipairs(tCurrencyFields) do
			DB.addHandler(sListPath .. ".*." .. sField, "onUpdate", CharEncumbranceManager.onCharItemFieldUpdate);
		end
		DB.addHandler(sListPath, "onChildDeleted", CharEncumbranceManager.onCharItemDelete);
	end
end
function disableCharCurrencyHandlers()
	local tItemLists = ItemManager.getInventoryPaths("charsheet");
	local tItemFields = ItemManager.getEncumbranceFields("charsheet");
	for _,sList in ipairs(tItemLists) do
		local sListPath = "charsheet.*." .. sList;
		for _,sField in ipairs(tItemFields) do
			DB.removeHandler(sListPath .. ".*." .. sField, "onUpdate", CharEncumbranceManager.onCharItemFieldUpdate);
		end
		DB.removeHandler(sListPath, "onChildDeleted", CharEncumbranceManager.onCharItemDelete);
	end

	local tCurrencyPaths = CurrencyManager.getCurrencyPaths("charsheet");
	local tCurrencyFields = CurrencyManager.getEncumbranceFields("charsheet");
	for _,sList in ipairs(tCurrencyPaths) do
		local sListPath = "charsheet.*." .. sList;
		for _,sField in ipairs(tCurrencyFields) do
			DB.removeHandler(sListPath .. ".*." .. sField, "onUpdate", CharEncumbranceManager.onCharItemFieldUpdate);
		end
		DB.removeHandler(sListPath, "onChildDeleted", CharEncumbranceManager.onCharItemDelete);
	end
end

function onCurrencyOptionUpdate()
	CharEncumbranceManager.updateAllCharacters();
end
function onCurrencyUpdate()
	CharEncumbranceManager.updateAllCharacters();
end
function onCharItemFieldUpdate(nodeItem)
	local nodeChar = DB.getChild(nodeItem, "....");
	CharEncumbranceManager.updateEncumbrance(nodeChar);
end
function onCharItemDelete(nodeInventory)
	local nodeChar = DB.getChild(nodeInventory, "..");
	CharEncumbranceManager.updateEncumbrance(nodeChar);
end

function updateAllCharacters()
	local aMappings = LibraryData.getMappings("charsheet");
	for _,vMapping in ipairs(aMappings) do
		for _,vNode in pairs(DB.getChildren(vMapping)) do
			CharEncumbranceManager.updateEncumbrance(vNode);
		end
	end
end
function updateEncumbrance(nodeChar)
	if _fnEncumbranceCalc then
		_fnEncumbranceCalc(nodeChar);
	end
end

--
--	Default calculations
--

function calcDefaultEncumbrance(nodeChar)
	local nEncumbrance = CharEncumbranceManager.calcDefaultInventoryEncumbrance(nodeChar);
	nEncumbrance = nEncumbrance + CharEncumbranceManager.calcDefaultCurrencyEncumbrance(nodeChar);
	CharEncumbranceManager.setDefaultEncumbranceValue(nodeChar, nEncumbrance);
end

function calcDefaultInventoryEncumbrance(nodeChar)
	local nInvTotal = 0;
	
	local nCount, nWeight;

	local tInventoryPaths = ItemManager.getInventoryPaths("charsheet");
	for _,sList in ipairs(tInventoryPaths) do
		for _,nodeItem in pairs(DB.getChildren(nodeChar, sList)) do
			if DB.getValue(nodeItem, "carried", 0) ~= 0 then
				nCount = DB.getValue(nodeItem, "count", 0);
				nWeight = DB.getValue(nodeItem, "weight", 0);
				
				nInvTotal = nInvTotal + (nCount * nWeight);
			end
		end
	end

	return nInvTotal;
end

function calcDefaultCurrencyEncumbrance(nodeChar)
	local nCurrTotal = 0;

	if OptionsManager.isOption("CURR", "on") then
		local sCurrency;
		local nCurrencyWeight;
		local tCurrencyPaths = CurrencyManager.getCurrencyPaths("charsheet");
		for _,sList in ipairs(tCurrencyPaths) do
			for _,vNode in pairs(DB.getChildren(nodeChar, sList)) do
				sCurrency = DB.getValue(vNode, "name", "");

				if (CurrencyManager.getCurrencyMatch(sCurrency) or "") ~= "" then
					nCurrencyWeight = DB.getValue(vNode, "amount", 0) * CurrencyManager.getCurrencyWeight(sCurrency);
					nCurrTotal = nCurrTotal + nCurrencyWeight;
				end
			end
		end
	end

	return nCurrTotal;
end

function setDefaultEncumbranceValue(nodeChar, nEncumbrance)
	local sField = CharEncumbranceManager.getEncumbranceField();
	DB.setValue(nodeChar, sField, "number", math.floor(nEncumbrance));
end
