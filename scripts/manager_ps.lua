-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aEntryMap = {};
local aFieldMap = {};

function onInit()
	if Session.IsHost then
		for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
			linkPCFields(v);
		end

		DB.addHandler("partysheet.*.name", "onUpdate", updateName);
		DB.addHandler("charsheet.*", "onDelete", onCharDelete);
	end
end

function getPartyCount()
	return DB.getChildCount("partysheet.partyinformation");
end

function mapChartoPS(nodeChar)
	if not nodeChar then return nil; end
	
	local sChar = nodeChar.getPath();
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sClass, sRecord = DB.getValue(v, "link", "", "");
		if sRecord == sChar then
			return v;
		end
	end
	return nil;
end

function mapPStoChar(nodePS)
	if not nodePS then return nil; end
	
	local sClass, sRecord = DB.getValue(nodePS, "link", "", "");
	if sRecord == "" then return nil; end
	return DB.findNode(sRecord);
end

function onCharDelete(nodeChar)
	local nodePS = mapChartoPS(nodeChar);
	if nodePS then
		nodePS.delete();
	end
end

function onLinkUpdated(nodeField)
	DB.setValue(aFieldMap[nodeField.getPath()], nodeField.getType(), nodeField.getValue());
end

function onLinkDeleted(nodeField)
	local sFieldName = nodeField.getPath();
	aFieldMap[sFieldName] = nil;
	DB.removeHandler(sFieldName, 'onUpdate', onLinkUpdated);
	DB.removeHandler(sFieldName, 'onDelete', onLinkDeleted);
end

function onEntryDeleted(nodePS)
	local sRecordName = nodePS.getPath();
	if aEntryMap[sRecordName] then
		DB.removeHandler(sRecordName, "onDelete", onEntryDeleted);
		aEntryMap[sRecordName] = nil;
		
		for k,v in pairs(aFieldMap) do
			if string.sub(v, 1, sRecordName:len()) == sRecordName then
				aFieldMap[k] = nil;
				DB.removeHandler(k, 'onUpdate', onLinkUpdated);
				DB.removeHandler(k, 'onDelete', onLinkDeleted);
			end
		end
	end
end

function linkRecordField(nodeRecord, nodePS, sField, sType, sPSField)
	if not nodeRecord then return; end
	
	if not sPSField then
		sPSField = sField;
	end

	if not aEntryMap[nodePS.getPath()] then
		DB.addHandler(nodePS.getPath(), "onDelete", onEntryDeleted);
		aEntryMap[nodePS.getPath()] = true;
	end
	
	local nodeField = nodeRecord.createChild(sField, sType);
	DB.addHandler(nodeField.getPath(), 'onUpdate', onLinkUpdated);
	DB.addHandler(nodeField.getPath(), 'onDelete', onLinkDeleted);
	
	aFieldMap[nodeField.getPath()] = DB.getPath(nodePS, sPSField);
	onLinkUpdated(nodeField);
end

function linkPCFields(nodePS)
	if PartyManager2 and PartyManager2.linkPCFields then
		PartyManager2.linkPCFields(nodePS);
		return;
	end
	
	local nodeChar = mapPStoChar(nodePS);
	linkRecordField(nodeChar, nodePS, "name", "string");
	linkRecordField(nodeChar, nodePS, "token", "token", "token");
end

function getNodeFromTokenRef(nodeContainer, nId)
	if not nodeContainer then
		return nil;
	end
	local sContainerNode = nodeContainer.getPath();
	
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sChildContainerName = DB.getValue(v, "tokenrefnode", "");
		local nChildId = tonumber(DB.getValue(v, "tokenrefid", "")) or 0;
		if (sChildContainerName == sContainerNode) and (nChildId == nId) then
			return v;
		end
	end
	return nil;
end

function getNodeFromToken(token)
	local nodeContainer = token.getContainerNode();
	local nID = token.getId();

	return getNodeFromTokenRef(nodeContainer, nID);
end

function linkToken(nodePS, newTokenInstance)
	TokenManager.linkToken(nodePS, newTokenInstance);
	
	if newTokenInstance then
		newTokenInstance.setTargetable(false);
		newTokenInstance.setActivable(true);
		newTokenInstance.setActive(false);
		newTokenInstance.setVisible(true);

		newTokenInstance.setName(DB.getValue(nodePS, "name", ""));
	end

	return true;
end

function onTokenDelete(tokenMap)
	local nodePS = getNodeFromToken(tokenMap);
	if nodePS then
		DB.setValue(nodePS, "tokenrefnode", "string", "");
		DB.setValue(nodePS, "tokenrefid", "string", "");
	end
end

function updateName(nodeName)
	local nodeEntry = nodeName.getParent();
	local tokeninstance = Token.getToken(DB.getValue(nodeEntry, "tokenrefnode", ""), DB.getValue(nodeEntry, "tokenrefid", ""));
	if tokeninstance then
		tokeninstance.setName(DB.getValue(nodeEntry, "name", ""));
	end
end

--
-- DROP HANDLING
--

function addChar(nodeChar)
	local nodePS = mapChartoPS(nodeChar)
	if nodePS then
		return;
	end
	
	nodePS = DB.createChild("partysheet.partyinformation");
	DB.setValue(nodePS, "link", "windowreference", "charsheet", nodeChar.getPath());
	linkPCFields(nodePS);
end

--
-- PARTY SHEET SUPPORT
--

function replacePartyToken(nodePS, newTokenInstance)
	local oldTokenInstance = CombatManager.getTokenFromCT(nodePS);
	if oldTokenInstance and oldTokenInstance ~= newTokenInstance then
		if not newTokenInstance then
			local nodeContainerOld = oldTokenInstance.getContainerNode();
			if nodeContainerOld then
				local x,y = oldTokenInstance.getPosition();
				newTokenInstance = Token.addToken(nodeContainerOld.getPath(), DB.getValue(nodePS, "token", ""), x, y);
			end
		end
		oldTokenInstance.delete();
	end

	PartyManager.linkToken(nodePS, newTokenInstance);
end
