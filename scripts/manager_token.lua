-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local nTokenDragUnits = nil;

local bDisplayDefaultHealth = false;
local fGetHealthInfo = nil;

local bDisplayDefaultEffects = false;
local fGetEffectInfo = nil;
local fParseEffectComp = nil;
local aParseEffectTagConditional = {};
local aParseEffectBonusTag = {};
local aParseEffectSimpleTag = {};
local aParseEffectCondition = {};

function onInit()
	if Session.IsHost then
		Token.onContainerChanged = onContainerChanged;
		Token.onTargetUpdate = onTargetUpdate;
		User.onIdentityStateChange = onIdentityStateChange;

		CombatManager.setCustomDeleteCombatantHandler(onCombatantDelete);
		CombatManager.addCombatantFieldChangeHandler("active", "onUpdate", updateActive);
		CombatManager.addCombatantFieldChangeHandler("space", "onUpdate", updateSpaceReach);
		CombatManager.addCombatantFieldChangeHandler("reach", "onUpdate", updateSpaceReach);
	end
	DB.addHandler("charsheet.*", "onDelete", deleteOwner);
	DB.addHandler("charsheet.*", "onObserverUpdate", updateOwner);

	Token.onAdd = onTokenAdd;
	Token.onDelete = onTokenDelete;
	Token.onDrop = onDrop;
	Token.onHover = onHover;
	Token.onDoubleClick = onDoubleClick;

	CombatManager.addCombatantFieldChangeHandler("tokenrefid", "onUpdate", updateAttributes);
	CombatManager.addCombatantFieldChangeHandler("friendfoe", "onUpdate", updateFaction);
	CombatManager.addCombatantFieldChangeHandler("name", "onUpdate", updateName);
	CombatManager.addCombatantFieldChangeHandler("nonid_name", "onUpdate", updateName);
	CombatManager.addCombatantFieldChangeHandler("isidentified", "onUpdate", updateName);
	
	TokenManager.initEffectTracking();
	TokenManager.initOptionTracking();
end

function linkToken(nodeCT, newTokenInstance)
	local nodeContainer = nil;
	if newTokenInstance then
		nodeContainer = newTokenInstance.getContainerNode();
	end
	
	if nodeContainer then
		DB.setValue(nodeCT, "tokenrefnode", "string", nodeContainer.getPath());
		DB.setValue(nodeCT, "tokenrefid", "string", newTokenInstance.getId());
	else
		DB.setValue(nodeCT, "tokenrefnode", "string", "");
		DB.setValue(nodeCT, "tokenrefid", "string", "");
	end

	return true;
end

function initOptionTracking()
	if Session.IsHost then
		DB.addHandler("options.TFAC", "onUpdate", onOptionChanged);
	end
	DB.addHandler("options.TPTY", "onUpdate", onOptionChanged);
	DB.addHandler("options.TNAM", "onUpdate", onOptionChanged);
end
function onOptionChanged(nodeOption)
	for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			TokenManager.updateAttributesHelper(tokenCT, nodeCT);
		end
	end
end

function onCombatantDelete(nodeCT)
	if TokenManager2 and TokenManager2.onCombatantDelete then
		if TokenManager2.onCombatantDelete(nodeCT) then
			return;
		end
	end
	
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
		if sClass ~= "charsheet" then
			tokenCT.delete();
		else
			local aWidgets = getWidgetList(tokenCT);
			for _, vWidget in pairs(aWidgets) do
				vWidget.destroy();
			end

			tokenCT.setActivable(true);
			tokenCT.setActive(false);
			tokenCT.setActivable(false);
			tokenCT.setModifiable(true);
			tokenCT.setVisible(nil);

			tokenCT.setName();
			tokenCT.setGridSize(0);
			tokenCT.removeAllUnderlays();
		end
	end
end
function onTokenAdd(tokenMap)
	ImageManager.onTokenAdd(tokenMap);
end
function onTokenDelete(tokenMap)
	ImageManager.onTokenDelete(tokenMap);

	if Session.IsHost then
		CombatManager.onTokenDelete(tokenMap);
		PartyManager.onTokenDelete(tokenMap);
	end
end
function onContainerChanged(tokenCT, nodeOldContainer, nOldId)
	if nodeOldContainer then
		local nodeCT = CombatManager.getCTFromTokenRef(nodeOldContainer, nOldId);
		if nodeCT then
			local nodeNewContainer = tokenCT.getContainerNode();
			if nodeNewContainer then
				DB.setValue(nodeCT, "tokenrefnode", "string", nodeNewContainer.getPath());
				DB.setValue(nodeCT, "tokenrefid", "string", tokenCT.getId());
			else
				DB.setValue(nodeCT, "tokenrefnode", "string", "");
				DB.setValue(nodeCT, "tokenrefid", "string", "");
			end
		end
	end
	local nodePS = PartyManager.getNodeFromTokenRef(nodeOldContainer, nOldId);
	if nodePS then
		local nodeNewContainer = tokenCT.getContainerNode();
		if nodeNewContainer then
			DB.setValue(nodePS, "tokenrefnode", "string", nodeNewContainer.getPath());
			DB.setValue(nodePS, "tokenrefid", "string", tokenCT.getId());
		else
			DB.setValue(nodePS, "tokenrefnode", "string", "");
			DB.setValue(nodePS, "tokenrefid", "string", "");
		end
	end
end
function onTargetUpdate(tokenMap)
	TargetingManager.onTargetUpdate(tokenMap);
end

function onWheelHelper(tokenCT, notches)
	if not tokenCT then
		return;
	end
	
	local newscale = tokenCT.getScale();
	local adj = notches * 0.1;
	if adj < 0 then
		newscale = newscale * (1 + adj);
	else
		newscale = newscale * (1 / (1 - adj));
	end
	tokenCT.setScale(newscale);
end
function onWheelCT(nodeCT, notches)
	if not Input.isControlPressed() then
		return false;
	end
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		TokenManager.onWheelHelper(tokenCT, notches);
	end
end
function onDrop(tokenCT, draginfo)
	local nodeCT = CombatManager.getCTFromToken(tokenCT);
	if nodeCT then
		return CombatManager.onDrop("ct", nodeCT.getPath(), draginfo);
	else
		if draginfo.getType() == "targeting" then
			ChatManager.SystemMessage(Interface.getString("ct_error_targetingunlinkedtoken"));
			return true;
		end
	end
end
function onHover(tokenMap, bOver)
	local nodeCT = CombatManager.getCTFromToken(tokenMap);
	if nodeCT then
		if OptionsManager.isOption("TNAM", "hover") then
			for _, vWidget in pairs(getWidgetList(tokenMap, "name")) do
				vWidget.setVisible(bOver);
			end
		end
		if bDisplayDefaultHealth then
			local sOption;
			if Session.IsHost then
				sOption = OptionsManager.getOption("TGMH");
			elseif DB.getValue(nodeCT, "friendfoe", "") == "friend" then
				sOption = OptionsManager.getOption("TPCH");
			else
				sOption = OptionsManager.getOption("TNPCH");
			end
			if (sOption == "barhover") or (sOption == "dothover") then
				for _, vWidget in pairs(getWidgetList(tokenMap, "health")) do
					vWidget.setVisible(bOver);
				end
			end
		end
		if bDisplayDefaultEffects then
			local sOption;
			if Session.IsHost then
				sOption = OptionsManager.getOption("TGME");
			elseif DB.getValue(nodeCT, "friendfoe", "") == "friend" then
				sOption = OptionsManager.getOption("TPCE");
			else
				sOption = OptionsManager.getOption("TNPCE");
			end
			if (sOption == "hover") or (sOption == "markhover") then
				for _, vWidget in pairs(getWidgetList(tokenMap, "effect")) do
					vWidget.setVisible(bOver);
				end
			end
		end
		if TokenManager2 and TokenManager2.onHover then
			TokenManager2.onHover(tokenMap, nodeCT, bOver);
		end
	end
end
function onDoubleClick(tokenMap, vImage)
	local nodeCT = CombatManager.getCTFromToken(tokenMap);
	if nodeCT then
		if Session.IsHost then
			local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
			if sRecord ~= "" then
				Interface.openWindow(sClass, sRecord);
			else
				Interface.openWindow(sClass, nodeCT);
			end
		else
			if (DB.getValue(nodeCT, "friendfoe", "") == "friend") then
				local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
				if sClass == "charsheet" then
					if sRecord ~= "" and DB.isOwner(sRecord) then
						Interface.openWindow(sClass, sRecord);
					else
						ChatManager.SystemMessage(Interface.getString("ct_error_openpclinkedtokenwithoutaccess"));
					end
				else
					local nodeActor;
					if sRecord ~= "" then
						nodeActor = DB.findNode(sRecord);
					else
						nodeActor = nodeCT;
					end
					if nodeActor then
						Interface.openWindow(sClass, nodeActor);
					else
						ChatManager.SystemMessage(Interface.getString("ct_error_openotherlinkedtokenwithoutaccess"));
					end
				end
				vImage.clearSelectedTokens();
			end
		end
	end
end
function onIdentityStateChange(sIdentity, sUser, sStateName, vState)
	if sStateName == "color" and sUser ~= "" then
		for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
			local token = CombatManager.getTokenFromCT(nodeCT);
			if token then
				local rActor = ActorManager.resolveActor(nodeCT);
				if rActor and ActorManager.isPC(rActor) then
					local nodeCreature = ActorManager.getCreatureNode(rActor);
					if nodeCreature then
						local sTokenIdentity = nodeCreature.getName();
						if sTokenIdentity == sIdentity then
							TokenManager.updateTokenColor(token);
						end
					end
				end
			end
		end
	end
end

function updateAttributesFromToken(tokenMap)
	local nodeCT = CombatManager.getCTFromToken(tokenMap);
	if nodeCT then
		TokenManager.updateAttributesHelper(tokenMap, nodeCT);
	end
	
	if Session.IsHost then
		local nodePS = PartyManager.getNodeFromToken(tokenMap);
		if nodePS then
			tokenMap.setTargetable(false);
			tokenMap.setActivable(true);
			tokenMap.setActive(false);
			tokenMap.setVisible(true);
			
			tokenMap.setName(DB.getValue(nodePS, "name", ""));
		end
	end
end
function updateAttributes(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		TokenManager.updateAttributesHelper(tokenCT, nodeCT);
	end
end
function updateAttributesHelper(tokenCT, nodeCT)
	if Session.IsHost then
		tokenCT.setTargetable(true);
		tokenCT.setActivable(true);
		
		if OptionsManager.isOption("TFAC", "on") then
			tokenCT.setOrientationMode("facing");
		else
			tokenCT.setOrientationMode();
		end
		
		TokenManager.updateActiveHelper(tokenCT, nodeCT);
		TokenManager.updateFactionHelper(tokenCT, nodeCT);
		TokenManager.updateSizeHelper(tokenCT, nodeCT);

		VisionManager.updateTokenVisionHelper(tokenCT, nodeCT);
		VisionManager.updateTokenLightingHelper(tokenCT, nodeCT);
	end
	TokenManager.updateOwnerHelper(tokenCT, nodeCT);
	
	TokenManager.updateNameHelper(tokenCT, nodeCT);
	TokenManager.updateTooltip(tokenCT, nodeCT);
	if bDisplayDefaultHealth then 
		TokenManager.updateHealthHelper(tokenCT, nodeCT); 
	end
	if bDisplayDefaultEffects then
		TokenManager.updateEffectsHelper(tokenCT, nodeCT);
	end
	if TokenManager2 and TokenManager2.updateAttributesHelper then
		TokenManager2.updateAttributesHelper(tokenCT, nodeCT);
	end
end
function updateTooltip(tokenCT, nodeCT)
	if TokenManager2 and TokenManager2.updateTooltip then
		TokenManager2.updateTooltip(tokenCT, nodeCT);
		return;
	end
	
	if Session.IsHost then
		local aTooltip = {};
		local sFaction = DB.getValue(nodeCT, "friendfoe", "");
		
		local sOptTNAM = OptionsManager.getOption("TNAM");
		if sOptTNAM == "tooltip" then
			local sName = ActorManager.getDisplayName(nodeCT);
			table.insert(aTooltip, sName);
		end
		
		tokenCT.setName(table.concat(aTooltip, "\r"));
	end
end

function updateName(nodeName)
	local nodeCT = nodeName.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		TokenManager.updateNameHelper(tokenCT, nodeCT);
		TokenManager.updateTooltip(tokenCT, nodeCT);
	end
end
function updateNameHelper(tokenCT, nodeCT)
	local sOptTNAM = OptionsManager.getOption("TNAM");
	local aWidgets = TokenManager.getWidgetList(tokenCT, "name");
	
	if sOptTNAM == "off" or sOptTNAM == "tooltip" then
		for _, vWidget in pairs(aWidgets) do
			vWidget.destroy();
		end
	else
		local sOptTASG = OptionsManager.getOption("TASG");
		local sName = ActorManager.getDisplayName(nodeCT);
		local nStarts, _, sNumber = string.find(sName, " ?(%d+)$");
		if nStarts then
			sName = string.sub(sName, 1, nStarts - 1);
		end
		local bWidgetsVisible = (sOptTNAM == "on");

		local widgetName = aWidgets["name"];
		if not widgetName then
			widgetName = tokenCT.addTextWidget("mini_name", "");
			if sOptTASG == "80" then
				widgetName.setPosition("top", 0, -5);
			else
				widgetName.setPosition("top", 0, 0);
			end
			widgetName.setFrame("mini_name", 5, 1, 5, 1);
			widgetName.setName("name");
		end
		if widgetName then
			widgetName.setVisible(bWidgetsVisible);
			widgetName.setText(sName);
			widgetName.setTooltipText(sName);

			local nDU = GameSystem.getDistanceUnitsPerGrid();
			local nSpace = math.max(math.ceil(DB.getValue(nodeCT, "space", nDU) / nDU), 1);
			widgetName.setMaxWidth((100 * nSpace) - 30);
		end

		if sNumber then
			local widgetOrdinal = aWidgets["ordinal"];
			if not widgetOrdinal then
				widgetOrdinal = tokenCT.addTextWidget("sheetlabel", "");
				if sOptTASG == "80" then
					widgetOrdinal.setPosition("topright", 5, -5);
				else
					widgetOrdinal.setPosition("topright", 0, 0);
				end
				widgetOrdinal.setFrame("tokennumber", 7, 1, 7, 1);
				widgetOrdinal.setName("ordinal");
			end
			if widgetOrdinal then
				widgetOrdinal.setVisible(bWidgetsVisible);
				widgetOrdinal.setText(sNumber);
			end
		else
			if aWidgets["ordinal"] then
				aWidgets["ordinal"].destroy();
			end
		end
	end
end

function updateVisibility(nodeCT)
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		TokenManager.updateVisibilityHelper(tokenCT, nodeCT);

		local _,bVisibleSetting = tokenCT.isVisible();
		if bVisibleSetting == false then
			TargetingManager.removeCTTargeted(nodeCT);
		end
	else
		if DB.getValue(nodeCT, "friendfoe", "") ~= "friend" then
			if DB.getValue(nodeCT, "tokenvis", 0) ~= 1 then
				TargetingManager.removeCTTargeted(nodeCT);
			end
		end
	end
end
function updateVisibilityHelper(tokenCT, nodeCT)
	if DB.getValue(nodeCT, "friendfoe", "") == "friend" then
		if OptionsManager.isOption("TPTY", "on") then
			tokenCT.setVisible(true);
		elseif not Session.IsHost and DB.isOwner(ActorManager.getCreatureNode(nodeCT)) then
			tokenCT.setVisible(true);
		else
			tokenCT.setVisible(nil);
		end
	else
		if DB.getValue(nodeCT, "tokenvis", 0) == 1 then
			if tokenCT.isVisible() ~= true then
				tokenCT.setVisible(nil);
			end
		else
			tokenCT.setVisible(false);
		end
	end
end

function deleteOwner(nodePC)
	local nodeCT = CombatManager.getCTFromNode(nodePC);
	if nodeCT then
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			if Session.IsHost then
				tokenCT.setOwner();
				TokenManager.updateTokenColor(tokenCT);
			end
		end
	end
end
-- NOTE: Assume registered on host; Only called for PC (charsheet) node owner changes
function updateOwner(nodePC)
	local nodeCT = CombatManager.getCTFromNode(nodePC);
	if nodeCT then
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			TokenManager.updateOwnerHelper(tokenCT, nodeCT);
		end
	end
end
function updateOwnerHelper(tokenCT, nodeCT)
	if Session.IsHost then
		local nodeCreature = ActorManager.getCreatureNode(nodeCT);
		tokenCT.setOwner(DB.getOwner(nodeCreature));
		TokenManager.updateTokenColor(tokenCT);
	end
end

function updateActive(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		TokenManager.updateActiveHelper(tokenCT, nodeCT);
	end
end
function updateActiveHelper(tokenCT, nodeCT)
	if Session.IsHost then
		if tokenCT.isActivable() then
			local bActive = (DB.getValue(nodeCT, "active", 0) == 1);
			if bActive then
				tokenCT.setActive(true);
			else
				tokenCT.setActive(false);
			end
		end
	end
end

function updateFaction(nodeFaction)
	local nodeCT = nodeFaction.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		if Session.IsHost then
			TokenManager.updateFactionHelper(tokenCT, nodeCT);
		end
		TokenManager.updateTooltip(tokenCT, nodeCT);
		if bDisplayDefaultHealth then 
			TokenManager.updateHealthHelper(tokenCT, nodeCT); 
		end
		if bDisplayDefaultEffects then
			TokenManager.updateEffectsHelper(tokenCT, nodeCT);
		end
		if TokenManager2 and TokenManager2.updateFaction then
			TokenManager2.updateFaction(tokenCT, nodeCT);
		end
	end
end
function updateFactionHelper(tokenCT, nodeCT)
	local bAllowPublicAccess = false;
	if DB.getValue(nodeCT, "friendfoe", "") == "friend" then
		if OptionsManager.isOption("TPTY", "on") then
			bAllowPublicAccess = true;
		end
	end

	tokenCT.setPublicEdit(bAllowPublicAccess);
	tokenCT.setPublicVision(bAllowPublicAccess);
	TokenManager.updateTokenColor(tokenCT);

	TokenManager.updateVisibilityHelper(tokenCT, nodeCT);
	TokenManager.updateSizeHelper(tokenCT, nodeCT);
end

function updateSpaceReach(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		TokenManager.updateSizeHelper(tokenCT, nodeCT);
	end
end

function updateSizeHelper(tokenCT, nodeCT)
	local nDU = GameSystem.getDistanceUnitsPerGrid();
	
	local nSpace = math.ceil(DB.getValue(nodeCT, "space", nDU) / nDU);
	local nHalfSpace = nSpace / 2;
	local nReach = math.ceil(DB.getValue(nodeCT, "reach", nDU) / nDU) + nHalfSpace;

	-- Clear underlays
	tokenCT.removeAllUnderlays();

	-- Reach underlay
	local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
	if sClass == "charsheet" then
		tokenCT.addUnderlay(nReach, "4f000000", "hover");
	else
		tokenCT.addUnderlay(nReach, "4f000000", "hover,gmonly");
	end

	-- Faction/space underlay
	local sFaction = DB.getValue(nodeCT, "friendfoe", "");
	if sFaction == "friend" then
		tokenCT.addUnderlay(nHalfSpace, "2F" .. ColorManager.COLOR_TOKEN_FACTION_FRIEND);
	elseif sFaction == "foe" then
		tokenCT.addUnderlay(nHalfSpace, "2F" .. ColorManager.COLOR_TOKEN_FACTION_FOE);
	elseif sFaction == "neutral" then
		tokenCT.addUnderlay(nHalfSpace, "2F" .. ColorManager.COLOR_TOKEN_FACTION_NEUTRAL);
	end
	
	-- Set grid spacing
	tokenCT.setGridSize(nSpace);

	-- Update name widget size
	TokenManager.updateNameHelper(tokenCT, nodeCT);

	-- Update health bar size
	if bDisplayDefaultHealth then
		TokenManager.updateHealthHelper(tokenCT, nodeCT);
	end
end

function updateTokenColor(token)
	-- Only update custom color if token exists and only on host
	if not token then
		return;
	end
	if not token.setColor then
		return;
	end
	if not Session.IsHost then
		return;
	end

	-- If valid CT actor, then check for custom color based on token linking
	local nodeCT = CombatManager.getCTFromToken(token);
	local rActor = ActorManager.resolveActor(nodeCT);
	if rActor then
		-- If PC, check to see if identity has owner and is active
		if ActorManager.isPC(rActor) then
			local nodeCreature = ActorManager.getCreatureNode(rActor);
			if nodeCreature then
				local nodeIdentity = nodeCreature.getName();
				local bMatch = false;
				for _, sIdentity in pairs(User.getAllActiveIdentities()) do
					if sIdentity == nodeIdentity then
						bMatch = true;
					end
				end
				if bMatch then
					local color = User.getIdentityColor(nodeCreature.getName());
					if color then
						token.setColor(color);
						return;
					end
				end
			end
		end

		-- Otherwise, use faction coloring
		local sFaction = DB.getValue(nodeCT, "friendfoe", "");
		if sFaction == "friend" then
			token.setColor(ColorManager.COLOR_TOKEN_FACTION_FRIEND);
			return;
		elseif sFaction == "foe" then
			token.setColor(ColorManager.COLOR_TOKEN_FACTION_FOE);
			return;
		elseif sFaction == "neutral" then
			token.setColor(ColorManager.COLOR_TOKEN_FACTION_NEUTRAL);
			return;
		end
	end

	-- Set to neutral faction color if all of our custom color checks fail
	token.setColor(ColorManager.COLOR_TOKEN_FACTION_NEUTRAL);
end

--
-- Widget Management
--

local aWidgetSets = { ["name"] = { "name", "ordinal" } };
function registerWidgetSet(sKey, aSet)
	aWidgetSets[sKey] = aSet;
end
function getWidgetList(tokenCT, sSet)
	local aWidgets = {};

	if (sSet or "") == "" then
		for _,aSet in pairs(aWidgetSets) do
			for _,sWidget in pairs(aSet) do
				local w = tokenCT.findWidget(sWidget);
				if w then
					aWidgets[sWidget] = w;
				end
			end
		end
	else
		if aWidgetSets[sSet] then
			for _,sWidget in pairs(aWidgetSets[sSet]) do
				local w = tokenCT.findWidget(sWidget);
				if w then
					aWidgets[sWidget] = w;
				end
			end
		end
	end
	
	return aWidgets;
end

function setDragTokenUnits(nUnits)
	nTokenDragUnits = nUnits;
end
function endDragTokenWithUnits()
	nTokenDragUnits = nil;
end
function getTokenSpace(tokenMap)
	local nSpace = 1;
	if nTokenDragUnits then
		local nDU = GameSystem.getDistanceUnitsPerGrid();
		nSpace = math.max(math.ceil(nTokenDragUnits / nDU), 1);
	else
		local nodeCT = CombatManager.getCTFromToken(tokenMap);
		if nodeCT then
			nSpace = DB.getValue(nodeCT, "space", 1);
			local nDU = GameSystem.getDistanceUnitsPerGrid();
			nSpace = math.max(math.ceil(nSpace / nDU), 1);
		end
	end
	return nSpace;
end
function autoTokenScale(tokenMap)
	local aImage = tokenMap.getContainerNode().getValue();
	if not aImage or (aImage.gridsizex <= 0) or (aImage.gridsizey <= 0) then
		return;
	end
	
	local nGridScale = TokenManager.getTokenSpace(tokenMap);
	if aImage.gridtype == 1 then
		nGridScale = nGridScale / 1.414;
	end
	local sOptTASG = OptionsManager.getOption("TASG");
	if sOptTASG == "80" then
		nGridScale = nGridScale * 0.8;
	end
	tokenMap.setScale(nGridScale);
end

--
-- Effects Management
--

function initEffectTracking()
	CombatManager.setCustomAddCombatantEffectHandler(updateEffects);
	CombatManager.setCustomDeleteCombatantEffectHandler(updateEffects);
	CombatManager.addCombatantEffectFieldChangeHandler("isactive", "onAdd", updateEffectsField);
	CombatManager.addCombatantEffectFieldChangeHandler("isactive", "onUpdate", updateEffectsField);
	CombatManager.addCombatantEffectFieldChangeHandler("isgmonly", "onAdd", updateEffectsField);
	CombatManager.addCombatantEffectFieldChangeHandler("isgmonly", "onUpdate", updateEffectsField);
	CombatManager.addCombatantEffectFieldChangeHandler("label", "onAdd", updateEffectsField);
	CombatManager.addCombatantEffectFieldChangeHandler("label", "onUpdate", updateEffectsField);
end

function updateEffectsField(nodeEffectField)
	TokenManager.updateEffects(nodeEffectField.getChild("...."));
end

function updateEffects(nodeCT)
	if Session.IsHost then
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			VisionManager.updateTokenVisionHelper(tokenCT, nodeCT);
			VisionManager.updateTokenLightingHelper(tokenCT, nodeCT);
		end
	end
	if bDisplayDefaultEffects then
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			TokenManager.updateEffectsHelper(tokenCT, nodeCT);
			TokenManager.updateTooltip(tokenCT, nodeCT);
		end
	end
end

--
-- Common token manager add-on health bar/dot functionality
--
-- Callback assumed input of:
--		* nodeCT
-- Assume callback function provided returns 3 parameters
--		* percent wounded (number), 
--		* status text (string), 
--		* status color (string, hex color)
--

TOKEN_HEALTHBAR_GRAPHIC_WIDTH = 20;
TOKEN_HEALTHBAR_GRAPHIC_HEIGHT = 200;

TOKEN_HEALTHBAR_HOFFSET = 0;
TOKEN_HEALTHBAR_WIDTH = 10;
TOKEN_HEALTHBAR_HEIGHT = 100;
TOKEN_HEALTHDOT_HOFFSET = 0;
TOKEN_HEALTHDOT_VOFFSET = 0;
TOKEN_HEALTHDOT_SIZE = 10;

function addDefaultHealthFeatures(f, aHealthFields)
	if not f then 
		return; 
	end
	bDisplayDefaultHealth = true;
	fGetHealthInfo = f;
	TokenManager.registerWidgetSet("health", {"healthbar", "healthdot"});

	for _,sField in ipairs(aHealthFields) do
		CombatManager.addCombatantFieldChangeHandler(sField, "onUpdate", updateHealth);
	end

	OptionsManager.registerOption2("TGMH", false, "option_header_token", "option_label_TGMH", "option_entry_cycler", 
			{ labels = "option_val_bar|option_val_barhover|option_val_dot|option_val_dothover", values = "bar|barhover|dot|dothover", baselabel = "option_val_off", baseval = "off", default = "dot" });
	OptionsManager.registerOption2("TNPCH", false, "option_header_token", "option_label_TNPCH", "option_entry_cycler", 
			{ labels = "option_val_bar|option_val_barhover|option_val_dot|option_val_dothover", values = "bar|barhover|dot|dothover", baselabel = "option_val_off", baseval = "off", default = "dot" });
	OptionsManager.registerOption2("TPCH", false, "option_header_token", "option_label_TPCH", "option_entry_cycler", 
			{ labels = "option_val_bar|option_val_barhover|option_val_dot|option_val_dothover", values = "bar|barhover|dot|dothover", baselabel = "option_val_off", baseval = "off", default = "dot" });
	OptionsManager.registerOption2("WNDC", false, "option_header_combat", "option_label_WNDC", "option_entry_cycler", 
			{ labels = "option_val_detailed", values = "detailed", baselabel = "option_val_simple", baseval = "off", default = "off" });
	DB.addHandler("options.TGMH", "onUpdate", onOptionChanged);
	DB.addHandler("options.TNPCH", "onUpdate", onOptionChanged);
	DB.addHandler("options.TPCH", "onUpdate", onOptionChanged);
	DB.addHandler("options.WNDC", "onUpdate", onOptionChanged);
end
function updateHealth(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		TokenManager.updateHealthHelper(tokenCT, nodeCT);
		TokenManager.updateTooltip(tokenCT, nodeCT);
	end
end
function updateHealthHelper(tokenCT, nodeCT)
	local sOptTH;
	if Session.IsHost then
		sOptTH = OptionsManager.getOption("TGMH");
	elseif DB.getValue(nodeCT, "friendfoe", "") == "friend" then
		sOptTH = OptionsManager.getOption("TPCH");
	else
		sOptTH = OptionsManager.getOption("TNPCH");
	end
	local aWidgets = TokenManager.getWidgetList(tokenCT, "health");

	if sOptTH == "off" then
		for _,vWidget in pairs(aWidgets) do
			vWidget.destroy();
		end
	else
		local nPercentWounded,sStatus,sColor = fGetHealthInfo(nodeCT);
		
		if sOptTH == "bar" or sOptTH == "barhover" then
			local w, h = tokenCT.getSize();
		
			local bAddBar = false;
			if h > 0 then
				bAddBar = true; 
			end
			
			if bAddBar then
				local widgetHealthBar = aWidgets["healthbar"];
				if not widgetHealthBar then
					widgetHealthBar = tokenCT.addBitmapWidget("healthbar");
					widgetHealthBar.sendToBack();
					widgetHealthBar.setName("healthbar");
				end
				if widgetHealthBar then
					widgetHealthBar.sendToBack();
					widgetHealthBar.setColor(sColor);
					widgetHealthBar.setTooltipText(sStatus);
					widgetHealthBar.setVisible(sOptTH == "bar");
					TokenManager.updateHealthBarScale(tokenCT, nodeCT, nPercentWounded);
				end
			end
			
			if aWidgets["healthdot"] then
				aWidgets["healthdot"].destroy();
			end
		elseif sOptTH == "dot" or sOptTH == "dothover" then
			local widgetHealthDot = aWidgets["healthdot"];
			if not widgetHealthDot then
				widgetHealthDot = tokenCT.addBitmapWidget("healthdot");
				widgetHealthDot.setPosition("bottomright", TOKEN_HEALTHDOT_HOFFSET, TOKEN_HEALTHDOT_VOFFSET);
				widgetHealthDot.setName("healthdot");

				local nDU = GameSystem.getDistanceUnitsPerGrid();
				local nSpace = math.ceil(DB.getValue(nodeCT, "space", nDU) / nDU);
				widgetHealthDot.setSize(TOKEN_HEALTHDOT_SIZE * nSpace, TOKEN_HEALTHDOT_SIZE * nSpace);
			end
			if widgetHealthDot then
				widgetHealthDot.setColor(sColor);
				widgetHealthDot.setTooltipText(sStatus);
				widgetHealthDot.setVisible(sOptTH == "dot");
			end

			if aWidgets["healthbar"] then
				aWidgets["healthbar"].destroy();
			end
		end
	end
end
function updateHealthBarScale(tokenCT, nodeCT, nPercentWounded)
	local widgetHealthBar = tokenCT.findWidget("healthbar");
	if widgetHealthBar then
		local nDU = GameSystem.getDistanceUnitsPerGrid();
		local nSpace = math.ceil(DB.getValue(nodeCT, "space", nDU) / nDU);
		local sOptTASG = OptionsManager.getOption("TASG");

		local barw = TOKEN_HEALTHBAR_WIDTH;
		local barh = TOKEN_HEALTHBAR_HEIGHT;
		if sOptTASG == "80" then
			barw = barw * 0.8;
			barh = barh * 0.8;
		end

		widgetHealthBar.setClipRegion(0, nPercentWounded * 100, 100, 100);
		widgetHealthBar.setSize(barw * nSpace, barh * nSpace);
		widgetHealthBar.setPosition("right", TOKEN_HEALTHBAR_HOFFSET, 0);
	end
end

--
-- Common token manager add-on effect functionality
--
-- Callback assumed input of: 
--		* nodeCT
--		* bSkipGMOnlyEffects
-- Callback assumed output of: 
--		* integer-based array of tables with following format
-- 			{ 
--				sName = "<Effect name to display>", (Currently, as effect icon tooltips when each displayed)
--				sIcon = "<Effect icon asset to display on token>",
--				sEffect = "<Original effect string>" (Currently used for large tooltips (multiple effects))
--			}
--

TOKEN_MAX_EFFECTS = 6;
TOKEN_EFFECT_MARGIN = 0;
TOKEN_EFFECT_OFFSETMAXX = 14; -- Prevent overlap with health bar

TOKEN_EFFECT_FGC_SIZE_SMALL = 18;
TOKEN_EFFECT_FGC_SIZE_STANDARD = 24;
TOKEN_EFFECT_FGC_SIZE_LARGE = 30;

TOKEN_EFFECT_SIZE_SMALL = 10;
TOKEN_EFFECT_SIZE_STANDARD = 15;
TOKEN_EFFECT_SIZE_LARGE = 20;

function addDefaultEffectFeatures(f, f2)
	bDisplayDefaultEffects = true;
	fGetEffectInfo = f or getEffectInfoDefault;
	fParseEffectComp = f2 or EffectManager.parseEffectCompSimple;

	local aEffectSet = {}; for i = 1, TOKEN_MAX_EFFECTS do table.insert(aEffectSet, "effect" .. i); end
	TokenManager.registerWidgetSet("effect", aEffectSet);

	OptionsManager.registerOption2("TGME", false, "option_header_token", "option_label_TGME", "option_entry_cycler", 
			{ labels = "option_val_icons|option_val_iconshover|option_val_mark|option_val_markhover", values = "on|hover|mark|markhover", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("TNPCE", false, "option_header_token", "option_label_TNPCE", "option_entry_cycler", 
			{ labels = "option_val_icons|option_val_iconshover|option_val_mark|option_val_markhover", values = "on|hover|mark|markhover", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("TPCE", false, "option_header_token", "option_label_TPCE", "option_entry_cycler", 
			{ labels = "option_val_icons|option_val_iconshover|option_val_mark|option_val_markhover", values = "on|hover|mark|markhover", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("TESZ", false, "option_header_token", "option_label_TESZ", "option_entry_cycler", 
			{ labels = "option_val_small|option_val_large", values = "small|large", baselabel = "option_val_standard", baseval = "", default = "" });

	DB.addHandler("options.TGME", "onUpdate", onOptionChanged);
	DB.addHandler("options.TNPCE", "onUpdate", onOptionChanged);
	DB.addHandler("options.TPCE", "onUpdate", onOptionChanged);
	DB.addHandler("options.TESZ", "onUpdate", onOptionChanged);
end

function updateEffectsHelper(tokenCT, nodeCT)
	local sOptTE;
	if Session.IsHost then
		sOptTE = OptionsManager.getOption("TGME");
	elseif DB.getValue(nodeCT, "friendfoe", "") == "friend" then
		sOptTE = OptionsManager.getOption("TPCE");
	else
		sOptTE = OptionsManager.getOption("TNPCE");
	end

	local sOptTASG = OptionsManager.getOption("TASG");
	local sOptTESZ = OptionsManager.getOption("TESZ");
	local nEffectSize = TOKEN_EFFECT_SIZE_STANDARD;
	if sOptTESZ == "small" then
		nEffectSize = TOKEN_EFFECT_SIZE_SMALL;
	elseif sOptTESZ == "large" then
		nEffectSize = TOKEN_EFFECT_SIZE_LARGE;
	end
	if sOptTASG == "80" then
		nEffectSize = nEffectSize * 0.8;
	end
	
	local aWidgets = TokenManager.getWidgetList(tokenCT, "effect");
	
	if sOptTE == "off" then
		for _, vWidget in pairs(aWidgets) do
			vWidget.destroy();
		end
	elseif sOptTE == "mark" or sOptTE == "markhover" then
		local bWidgetsVisible = (sOptTE == "mark");
		
		local aTooltip = {};
		local aCondList = fGetEffectInfo(nodeCT);
		for _,v in ipairs(aCondList) do
			table.insert(aTooltip, v.sEffect);
		end
		
		if #aTooltip > 0 then
			local w = aWidgets["effect1"];
			if not w then
				w = tokenCT.addBitmapWidget();
				if w then
					w.setName("effect1");
				end
			end
			if w then
				w.setBitmap("cond_generic");
				w.setTooltipText(table.concat(aTooltip, "\r"));
				w.setPosition("bottomleft", (nEffectSize / 2), -(nEffectSize / 2));
				w.setSize(nEffectSize, nEffectSize);
				w.setVisible(bWidgetsVisible);
			end
			for i = 2, TOKEN_MAX_EFFECTS do
				local w = aWidgets["effect" .. i];
				if w then
					w.destroy();
				end
			end
		else
			for i = 1, TOKEN_MAX_EFFECTS do
				local w = aWidgets["effect" .. i];
				if w then
					w.destroy();
				end
			end
		end
	else
		local bWidgetsVisible = (sOptTE == "on");
		
		local aCondList = fGetEffectInfo(nodeCT);
		local nConds = #aCondList;
		
		local wTokenEffectMax;
		if sOptTASG == "80" then
			wTokenEffectMax = 60;
		else
			wTokenEffectMax = 80;
		end
		
		local wLast = nil;
		local lastposx = 0;
		local posx = 0;
		local i = 1;
		local nMaxLoop = math.min(nConds, TOKEN_MAX_EFFECTS);
		while i <= nMaxLoop do
			local w = aWidgets["effect" .. i];
			if not w then
				w = tokenCT.addBitmapWidget();
				if w then
					w.setName("effect" .. i);
				end
			end
			if w then
				w.setBitmap(aCondList[i].sIcon);
				w.setTooltipText(aCondList[i].sName);
				if wLast and posx + nEffectSize > wTokenEffectMax then
					w.destroy();
					wLast.setBitmap("cond_more");
					wLast.setPosition("bottomleft", lastposx + (nEffectSize / 2), -(nEffectSize / 2));
					wLast.setSize(nEffectSize, nEffectSize);
					local aTooltip = {};
					table.insert(aTooltip, wLast.getTooltipText());
					for j = i, nConds do
						table.insert(aTooltip, aCondList[j].sEffect);
					end
					wLast.setTooltipText(table.concat(aTooltip, "\r"));
					i = i + 1;
					break;
				end
				if i == nMaxLoop and nConds > nMaxLoop then
					w.setBitmap("cond_more");
					local aTooltip = {};
					for j = i, nConds do
						table.insert(aTooltip, aCondList[j].sEffect);
					end
					w.setTooltipText(table.concat(aTooltip, "\r"));
				end
				w.setPosition("bottomleft", posx + (nEffectSize / 2), -(nEffectSize / 2));
				w.setSize(nEffectSize, nEffectSize);
				lastposx = posx;
				posx = posx + nEffectSize + TOKEN_EFFECT_MARGIN;
				w.setVisible(bWidgetsVisible);
				wLast = w;
			end
			i = i + 1;
		end
		while i <= TOKEN_MAX_EFFECTS do
			local w = aWidgets["effect" .. i];
			if w then
				w.destroy();
			end
			i = i + 1;
		end
	end
end

function addEffectTagIconConditional(sType, f)
	aParseEffectTagConditional[sType] = f;
end
function addEffectTagIconBonus(vType)
	if type(vType) == "table" then
		for _,v in pairs(vType) do
			aParseEffectBonusTag[v] = true;
		end
	elseif type(vType) == "string" then
		aParseEffectBonusTag[vType] = true;
	end
end
function addEffectTagIconSimple(vType, sIcon)
	if type(vType) == "table" then
		for kTag,vTag in pairs(vType) do
			aParseEffectSimpleTag[kTag] = vTag;
		end
	elseif type(vType) == "string" then
		if not sIcon then return; end
		aParseEffectSimpleTag[vType] = sIcon;
	end
end
function addEffectConditionIcon(vType, sIcon)
	if type(vType) == "table" then
		for kCond,vCond in pairs(vType) do
			aParseEffectCondition[kCond:lower()] = vCond;
		end
	elseif type(vType) == "string" then
		if not sIcon then return; end
		aParseEffectCondition[vType] = sIcon;
	end
end
function getEffectInfoDefault(nodeCT, bSkipGMOnly)
	local aIconList = {};

	local rActor = ActorManager.resolveActor(nodeCT);
	
	-- Iterate through effects
	local aSorted = {};
	for _,nodeChild in pairs(DB.getChildren(nodeCT, "effects")) do
		table.insert(aSorted, nodeChild);
	end
	table.sort(aSorted, function (a, b) return a.getName() < b.getName() end);

	for k,v in pairs(aSorted) do
		if DB.getValue(v, "isactive", 0) == 1 then
			if (not bSkipGMOnly and Session.IsHost) or (DB.getValue(v, "isgmonly", 0) == 0) then
				local sLabel = DB.getValue(v, "label", "");
				
				local aEffectIcons = {};
				local aEffectComps = EffectManager.parseEffect(sLabel);
				for kComp,sEffectComp in ipairs(aEffectComps) do
					local vComp = fParseEffectComp(sEffectComp);
					local sTag = vComp.type;
					
					local sNewIcon = nil;
					local bContinue = true;
					local bBonusEffectMatch = false;
					
					for kCustom,_ in pairs(aParseEffectTagConditional) do
						if kCustom == sTag then
							bContinue = aParseEffectTagConditional[kCustom](rActor, v, vComp);
							sNewIcon = "";
							break;
						end
					end
					if not bContinue then
						break;
					end
					
					if not sNewIcon then
						for kBonus,_ in pairs(aParseEffectBonusTag) do
							if kBonus == sTag then
								bBonusEffectMatch = true;
								if #(vComp.dice) > 0 or vComp.mod > 0 then
									sNewIcon = "cond_bonus";
								elseif vComp.mod < 0 then
									sNewIcon = "cond_penalty";
								else
									sNewIcon = "";
								end
								break;
							end
						end
					end
					if not sNewIcon then
						sNewIcon = aParseEffectSimpleTag[sTag];
					end
					if not sNewIcon then
						sTag = vComp.original:lower();
						sNewIcon = aParseEffectCondition[sTag];
					end
					
					aEffectIcons[kComp] = sNewIcon;
				end
				
				if #aEffectComps > 0 then
					-- If the first effect component didn't match anything, use it as a name
					local sFinalName = nil;
					if not aEffectIcons[1] then
						sFinalName = aEffectComps[1].original;
					end
					
					-- If all icons match, then use the matching icon, otherwise, use the generic icon
					local sFinalIcon = nil;
					local bSame = true;
					for _,vIcon in pairs(aEffectIcons) do
						if (vIcon or "") ~= "" then
							if sFinalIcon then
								if sFinalIcon ~= vIcon then
									sFinalIcon = nil;
									break;
								end
							else
								sFinalIcon = vIcon;
							end
						end
					end
					
					table.insert(aIconList, { sName = sFinalName or sLabel, sIcon = sFinalIcon or "cond_generic", sEffect = sLabel } );
				end
			end
		end
	end
	
	return aIconList;
end
