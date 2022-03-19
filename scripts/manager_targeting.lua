-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_TOGGLETARGET = "toggletarget";
OOB_MSGTYPE_REMOVETARGET = "removetarget";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_TOGGLETARGET, handleToggleTarget);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_REMOVETARGET, handleRemoveTarget);
	CombatManager.setCustomDeleteCombatantHandler(onCTEntryDeleted);
end

function onCTEntryDeleted(nodeEntry)
	local sEntry = nodeEntry.getPath();
	
	for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
		for _,vTarget in pairs(DB.getChildren(nodeCT, "targets")) do
			if DB.getValue(vTarget, "noderef", "") == sEntry then
				vTarget.delete();
			end
		end
		for _,vEffect in pairs(DB.getChildren(nodeCT, "effects")) do
			if DB.getChildCount(vEffect, "targets") > 0 then
				for _,vEffectTarget in pairs(DB.getChildren(vEffect, "targets")) do
					if DB.getValue(vEffectTarget, "noderef", "") == sEntry then
						vEffectTarget.delete();
					end
				end
				if DB.getChildCount(vEffect, "targets") == 0 then
					vEffect.delete();
				end
			end
		end
	end
end

function getFullTargets(rActor)
	local aTargets = {};

	if rActor then
		local nodeCT = ActorManager.getCTNode(rActor);
		if nodeCT then
			for _,vTarget in pairs(DB.getChildren(nodeCT, "targets")) do
				local rTarget = ActorManager.resolveActor(DB.getValue(vTarget, "noderef", ""));
				table.insert(aTargets, rTarget);
			end
		end
	end
	
	return aTargets;
end

function getActiveToken(vImage)
	local nodeCurrentCT = CombatManager.getCurrentUserCT();
	if nodeCurrentCT then
		local tokenCT = CombatManager.getTokenFromCT(nodeCurrentCT);
		if tokenCT then
			local nodeContainer = tokenCT.getContainerNode();
			if nodeContainer then
				if nodeContainer.getPath() == vImage.getDatabaseNode().getPath() then
					return tokenCT;
				end
			end
		end
	end
	
	return nil;
end

function getSelectionHelper(vImage)
	local aSelected = vImage.getSelectedTokens();
	if #aSelected > 0 then
		return aSelected;
	end
	
	local tokenCT = TargetingManager.getActiveToken(vImage);
	if tokenCT then
		return { tokenCT };
	end
	
	return {};
end

function clearTargets(vImage)
	local aSelected = TargetingManager.getSelectionHelper(vImage);

	for _,vToken in ipairs(aSelected) do
		local nodeCT = CombatManager.getCTFromToken(vToken);
		if nodeCT then
			TargetingManager.clearCTTargets(nodeCT, vToken);
		else
			vToken.clearTargets();
		end
	end
end

function setFactionTargets(vImage, bNegated)
	-- Get selection or active CT
	local aSelected = TargetingManager.getSelectionHelper(vImage);

	-- Determine faction of selection, and clear previous targets
	local sFaction = "friend";
	local sSelectedFaction = nil;
	for _,vToken in ipairs(aSelected) do
		local nodeCT = CombatManager.getCTFromToken(vToken);
		if not nodeCT then
			vToken.clearTargets();
			break;
		end
		
		TargetingManager.clearCTTargets(nodeCT, vToken);
		
		local sCTFaction = DB.getValue(nodeCT, "friendfoe", "");
		if sCTFaction == "" then
			break;
		end
		if sSelectedFaction then
			if sSelectedFaction ~= sCTFaction then
				sSelectedFaction = nil;
				break;
			end
		else
			sSelectedFaction = sCTFaction;
		end
	end
	if sSelectedFaction then
		sFaction = sSelectedFaction;
	end
	
	-- Iterate through tracker to target correct faction
	local bHost = Session.IsHost;
	local sContainer = vImage.getDatabaseNode().getPath();
	for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
		if DB.getValue(nodeCT, "tokenrefnode", "") == sContainer then
			if bHost or not CombatManager.isCTHidden(nodeCT) then
				if bNegated then
					if DB.getValue(nodeCT, "friendfoe", "") ~= sFaction then
						for _,vToken in ipairs(aSelected) do
							vToken.setTarget(true, DB.getValue(nodeCT, "tokenrefid", 0));
						end
					end
				else
					if DB.getValue(nodeCT, "friendfoe", "") == sFaction then
						for _,vToken in ipairs(aSelected) do
							vToken.setTarget(true, DB.getValue(nodeCT, "tokenrefid", 0));
						end
					end
				end
			end
		end
	end
end

function removeTarget(sSourceNode, sTargetNode)
	local tokenSource = CombatManager.getTokenFromCT(sSourceNode);
	local tokenTarget = CombatManager.getTokenFromCT(sTargetNode);
	
	if tokenSource and tokenTarget then
		if tokenSource.getContainerNode() == tokenTarget.getContainerNode() then
			tokenSource.setTarget(false, tokenTarget.getId());
			return;
		end
	end
	
	local nodeSourceCT = CombatManager.getCTFromNode(sSourceNode);
	local nodeTargetCT = CombatManager.getCTFromNode(sTargetNode);
	if nodeSourceCT and nodeTargetCT then
		TargetingManager.notifyRemoveTarget(nodeSourceCT, nodeTargetCT);
	end
end

function handleToggleTarget(msgOOB)
	local nodeSourceCT = DB.findNode(msgOOB.sSourceNode);
	local nodeTargetCT = DB.findNode(msgOOB.sTargetNode);
	
	TargetingManager.toggleCTTarget(nodeSourceCT, nodeTargetCT);
end

function handleRemoveTarget(msgOOB)
	local nodeSourceCT = DB.findNode(msgOOB.sSourceNode);
	local nodeTargetCT = DB.findNode(msgOOB.sTargetNode);
	
	TargetingManager.removeCTTarget(nodeSourceCT, nodeTargetCT);
end

function notifyToggleTarget(nodeSourceCT, nodeTargetCT)
	-- Build OOB message to pass toggle request to host
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_TOGGLETARGET;
	if Session.IsHost then
		msgOOB.user = "";
	else
		msgOOB.user = User.getUsername();
	end
	msgOOB.identity = User.getIdentityLabel();

	msgOOB.sSourceNode = nodeSourceCT.getPath();
	msgOOB.sTargetNode = nodeTargetCT.getPath();

	Comm.deliverOOBMessage(msgOOB, "");
end

function notifyRemoveTarget(nodeSourceCT, nodeTargetCT)
	-- Build OOB message to pass toggle request to host
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_REMOVETARGET;
	if Session.IsHost then
		msgOOB.user = "";
	else
		msgOOB.user = User.getUsername();
	end
	msgOOB.identity = User.getIdentityLabel();

	msgOOB.sSourceNode = nodeSourceCT.getPath();
	msgOOB.sTargetNode = nodeTargetCT.getPath();

	Comm.deliverOOBMessage(msgOOB, "");
end

function toggleClientCTTarget(nodeTargetCT)
	if not nodeTargetCT then
		return;
	end
	
	local nodeSourceCT = CombatManager.getCurrentUserCT();
	if not nodeSourceCT then
		ChatManager.SystemMessage(Interface.getString("ct_error_targetingpcmissingfromct"));
		return;
	end

	TargetingManager.notifyToggleTarget(nodeSourceCT, nodeTargetCT);
end

function toggleCTTarget(nodeSourceCT, nodeTargetCT)
	if not nodeSourceCT or not nodeTargetCT then
		return;
	end
	
	-- Determine whether CT
	local vTargetEntry = nil;
	local sNodeTargetCT = nodeTargetCT.getPath();
	for _,vTarget in pairs(DB.getChildren(nodeSourceCT, "targets")) do
		if DB.getValue(vTarget, "noderef", "") == sNodeTargetCT then
			vTargetEntry = vTarget;
			break;
		end
	end
	
	if vTargetEntry then
		TargetingManager.removeCTTargetEntry(nodeSourceCT, vTargetEntry);
	else
		TargetingManager.addCTTarget(nodeSourceCT, nodeTargetCT);
	end
end

function addCTTarget(nodeSourceCT, nodeTargetCT)
	if not nodeSourceCT or not nodeTargetCT then
		return;
	end
	
	-- Get linked tokens (if any) and targets for source CT entry
	local tokenSource = CombatManager.getTokenFromCT(nodeSourceCT);
	local tokenTarget = CombatManager.getTokenFromCT(nodeTargetCT);
	
	-- Check for duplicates
	local sNodeTargetCT = nodeTargetCT.getPath();
	for _,vTarget in pairs(DB.getChildren(nodeSourceCT, "targets")) do
		if DB.getValue(vTarget, "noderef", "") == sNodeTargetCT then
			return;
		end
	end

	-- Create new target entry
	local vNew = DB.createChild(nodeSourceCT, "targets").createChild();
	DB.setValue(vNew, "noderef", "string", sNodeTargetCT);
	
	-- If source linked token is actually targeting target linked token, then remove targeting on map
	if tokenSource and tokenTarget and (tokenSource.getContainerNode().getPath() == tokenTarget.getContainerNode().getPath()) then
		tokenSource.setTarget(true, tokenTarget);
	end
end

function removeCTTarget(nodeSourceCT, nodeTargetCT)
	if not nodeSourceCT or not nodeTargetCT then
		return;
	end
	
	-- Determine whether CT
	local vTargetEntry = nil;
	local sNodeTargetCT = nodeTargetCT.getPath();
	for _,vTarget in pairs(DB.getChildren(nodeSourceCT, "targets")) do
		if DB.getValue(vTarget, "noderef", "") == sNodeTargetCT then
			vTargetEntry = vTarget;
			break;
		end
	end
	
	if vTargetEntry then
		TargetingManager.removeCTTargetEntry(nodeSourceCT, vTargetEntry);
	end
end

function removeCTTargetEntry(nodeSourceCT, nodeSourceCTTarget)
	-- Get linked tokens (if any)
	local tokenSource = CombatManager.getTokenFromCT(nodeSourceCT);
	local tokenTarget = CombatManager.getTokenFromCT(DB.getValue(nodeSourceCTTarget, "noderef", ""));
	
	-- Delete CT target record
	nodeSourceCTTarget.delete();
	
	-- If source linked token is actually targeting target linked token, then remove targeting on map
	if tokenSource and tokenTarget and (tokenSource.getContainerNode().getPath() == tokenTarget.getContainerNode().getPath()) then
		tokenSource.setTarget(false, tokenTarget);
	end
end

function removeCTTargeted(nodeTarget)
	if not nodeTarget then
		return;
	end
	
	local sTargetCT = nodeTarget.getPath();
	
	for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
		for _,vTarget in pairs(DB.getChildren(nodeCT, "targets")) do
			if DB.getValue(vTarget, "noderef", "") == sTargetCT then
				TargetingManager.removeCTTargetEntry(nodeCT, vTarget);
				break;
			end
		end
	end
end

function clearCTTargets(nodeSourceCT, tokenCT)
	TargetingManager.lockTargetUpdate();

	-- Delete CT target records
	for _,vTarget in pairs(DB.getChildren(nodeSourceCT, "targets")) do
		vTarget.delete();
	end
	
	-- If linked token, then clear targets on map
	if not tokenCT then
		tokenCT = CombatManager.getTokenFromCT(nodeSourceCT);
	end
	if tokenCT then
		tokenCT.clearTargets();
	end

	TargetingManager.unlockTargetUpdate();
end

function setCTFactionTargets(nodeSourceCT, bNegated)
	-- Clear current targets
	TargetingManager.clearCTTargets(nodeSourceCT);

	-- Lock updates from token objects to reduce overhead
	TargetingManager.lockTargetUpdate();
	
	-- Get the faction and targets for this CT entry
	local sFaction = DB.getValue(nodeSourceCT, "friendfoe", "");

	-- Get the linked token for this CT entry (if any)
	local tokenSource = CombatManager.getTokenFromCT(nodeSourceCT);
	local sContainer = "";
	if tokenSource then
		sContainer = tokenSource.getContainerNode().getPath();
	end
	
	-- Check each actor in combat tracker for faction match
	local nodeTargets = DB.createChild(nodeSourceCT, "targets");
	for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
		local bAdd = false;
		if bNegated then
			if DB.getValue(nodeCT, "friendfoe", "") ~= sFaction then
				bAdd = true;
			end
		else
			if DB.getValue(nodeCT, "friendfoe", "") == sFaction then
				bAdd = true;
			end
		end

		-- If faction match, then add CT target (and token target if target has a linked token on the same map)
		if bAdd then
			local vNew = nodeTargets.createChild();
			DB.setValue(vNew, "noderef", "string", nodeCT.getPath());
			
			if (sContainer ~= "") and (DB.getValue(nodeCT, "tokenrefnode", "") == sContainer) then
				tokenSource.setTarget(true, DB.getValue(nodeCT, "tokenrefid", 0));
			end
		end
	end
	
	-- Restore updates from token objects
	TargetingManager.unlockTargetUpdate();
end

function updateTargetsFromCT(nodeSourceCT, newTokenInstance)
	if not nodeSourceCT or not newTokenInstance then
		return;
	end
	
	-- Lock updates from token objects to reduce overhead
	TargetingManager.lockTargetUpdate();
	
	-- Look up all tokens in CT
	local aTokens = {};
	for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			aTokens[nodeCT.getPath()] = tokenCT;
		end
	end
	
	-- Check if any CT targets for the new token are on the same map, and set the target lines
	local sContainer = newTokenInstance.getContainerNode().getPath();
	for _,vTarget in pairs(DB.getChildren(nodeSourceCT, "targets")) do
		local tokenCT = aTokens[DB.getValue(vTarget, "noderef", "")];
		if tokenCT and (sContainer == tokenCT.getContainerNode().getPath()) then
			newTokenInstance.setTarget(true, tokenCT);
		end
	end
	
	-- Check if the new token should be targeted by any tokens on the map already
	local sNodeSourceCT = nodeSourceCT.getPath();
	for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
		for _,vTarget in pairs(DB.getChildren(nodeCT, "targets")) do
			if DB.getValue(vTarget, "noderef", "") == sNodeSourceCT then
				local tokenCT = aTokens[nodeCT.getPath()];
				if tokenCT and (sContainer == tokenCT.getContainerNode().getPath()) then
					tokenCT.setTarget(true, newTokenInstance);
				end
			end
		end
	end
	
	-- Restore updates from token objects
	TargetingManager.unlockTargetUpdate();
end

local bTargetUpdateLock = false;
function lockTargetUpdate()
	bTargetUpdateLock = true;
end
function unlockTargetUpdate()
	bTargetUpdateLock = false;
end
function onTargetUpdate(tokenMap)
	if bTargetUpdateLock then
		return;
	end
	
	local nodeCT = CombatManager.getCTFromToken(tokenMap);
	if not nodeCT then
		return;
	end
	
	local nodeTargets = DB.createChild(nodeCT, "targets");

	local sTokenContainer = tokenMap.getContainerNode().getPath();
	local nTokenID = tokenMap.getId();
	local aTargets = tokenMap.getTargets();
	
	-- Figure out which targets in the CT are on the same map
	local aCTMapTargets = {};
	for _,vTarget in pairs(nodeTargets.getChildren()) do
		local sTargetCT = DB.getValue(vTarget, "noderef", "");
		if sTargetCT ~= "" then
			local nodeTargetCT = DB.findNode(sTargetCT);
			if DB.getValue(nodeTargetCT, "tokenrefnode", "") == sTokenContainer then
				aCTMapTargets[DB.getValue(nodeTargetCT, "tokenrefid", 0)] = vTarget;
			end
		end
	end
	
	-- Remove CT targets which are not part of current token target set
	for k,v in pairs(aCTMapTargets) do
		if not StringManager.contains(aTargets, k) then
			v.delete();
		end
	end
	
	-- Add CT targets for any token targets not already accounted for
	for _,v in ipairs(aTargets) do
		if not aCTMapTargets[v] then
			local nodeTargetCT = CombatManager.getCTFromToken(Token.getToken(sTokenContainer, v));
			if nodeTargetCT then
				local nodeNewTarget = nodeTargets.createChild();
				DB.setValue(nodeNewTarget, "noderef", "string", nodeTargetCT.getPath());
			end
		end
	end
end
