-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _sGmIdDefault = "";
local _tIdentities = {};
local _sCurrentIdentity = nil;

function onInit()
	if Session.IsHost then
		ChatManager.registerSlashCommand("gmid", slashCommandHandlerGmId, "[name]");
		ChatManager.registerSlashCommand("id", slashCommandHandlerId, "[name]");
	end
	
	Interface.onDesktopInit = onDesktopInit;
end

function onDesktopInit()
	if Session.IsHost then
		_sGmIdDefault = Interface.getString("gmid_default");
		GmIdentityManager.activateGMIdentity();
	end

	ChatManager.registerDeliverMessageCallback(GmIdentityManager.onChatDeliverMessage);
end

-- NOTE: Do not return true, since we want standard processing to continue
function onChatDeliverMessage(msg, sMode)
	if sMode == "chat" then
		if Session.IsHost then
			msg.icon = "portrait_gm_token";

			local sIdentity, bMainIdentity = GmIdentityManager.getCurrent()
			if not msg.sender or (msg.sender == "" or msg.sender == User.getUsername()) then
				msg.sender = sIdentity;
				if bMainIdentity then
					msg.font = "chatgmfont";
				else
					msg.font = "chatnpcfont";
				end
			else
				msg.font = "chatnpcfont";
			end
		else
			local sCurrentId = User.getCurrentIdentity();
			if sCurrentId then
				msg.icon = "portrait_" .. sCurrentId .. "_chat";
			end
		end
	elseif sMode == "emote" then
		if Session.IsHost then
			local sIdentity, bMainIdentity = GmIdentityManager.getCurrent()
			if not bMainIdentity then
				msg.sender = "";
				msg.text = sIdentity .. " " .. msg.text;
			end
		end
	end
end

function slashCommandHandlerId(sCommand, sParams)
    local sGMID = GmIdentityManager.getGMIdentity();
    local sNewID = StringManager.trim(sParams);
    
    if sNewID:upper() == sGMID:upper() then
        GmIdentityManager.activateGMIdentity();
    else
        GmIdentityManager.addIdentity(sParams, false);
    end
end
function slashCommandHandlerGmId(sCommand, sParams)
	local sOldGMID = GmIdentityManager.getGMIdentity();
	local sNewGMID = StringManager.trim(sParams);

	if sOldGMID ~= sNewGMID then
		for k,_ in pairs(_tIdentities) do
			_tIdentities[k] = false;
		end
		_tIdentities[sOldGMID] = nil;
		_tIdentities[sNewGMID] = true;

		local w = ChatManager.getChatWindow();
		if w then
			w.speaker.replace(1, sNewGMID, nil, false);
		end

		CampaignRegistry.gmidentity = sNewGMID;
	end
	
	GmIdentityManager.setCurrent(sNewGMID);
end

function setCurrent(sName)
	_sCurrentIdentity = sName;

	local w = ChatManager.getChatWindow();
	if w then
		w.speaker.setListValue(sName);
	end
end
function getCurrent()
	if _sCurrentIdentity then
		return _sCurrentIdentity, _tIdentities[_sCurrentIdentity];
	end
	return nil, nil;
end

function getGMIdentity()
    local sGMID = CampaignRegistry.gmidentity or _sGmIdDefault;
    if sGMID == "" then
    	sGMID = User.getUsername();
    end
    sGMID = StringManager.trim(sGMID);
    return sGMID;
end
function activateGMIdentity()
	GmIdentityManager.addIdentity(getGMIdentity(), true);
end

function existsIdentity(name)
	if _tIdentities[name] ~= nil then
		return true;
	end
	
	return false;
end
function addIdentity(sName, bIsGM)
	if not _tIdentities[sName] then
		local w = ChatManager.getChatWindow();
		if w then
			w.speaker.add(sName, nil, not bIsGM);
		end
	end

	_tIdentities[sName] = bIsGM;
	GmIdentityManager.setCurrent(sName);
end
function removeIdentity(sName)
	-- Preserve the first entry
	if _tIdentities[sName] then
		return;
	end

	-- In case the identity being deleted is active, activate the root identity
	if _sCurrentIdentity == sName then
		GmIdentityManager.activateGMIdentity();
	end

	-- Remove from list	
	local w = ChatManager.getChatWindow();
	if w then
		w.speaker.remove(sName);
	end

	-- Remove from table
	_tIdentities[sName] = nil;
end
