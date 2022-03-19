-- Copyright SmiteWorks USA, LLC., 2011

PORTRAIT_SIZE = 75;
PORTRAIT_PADDING = 3;
LEFT_MARGIN = 20;
RIGHT_MARGIN = 20;
TOP_MARGIN = 5;
BOTTOM_MARGIN = 10;

OOB_MSGTYPE_SETAFK = "setafk";

local _wCharList = nil;
local _bDoingWindowResize = false;
local _sCharEntryClass = "characterlist_entry"
local _tCharEntryDecorators = {}
local _tCharEntries = {};

local _tDropHandlers = {};

local _tUserStates = {};

function onInit()
	if Session.IsHost then
		CharacterListManager.registerDropHandler("number", onNumberDrop)
	end
	CharacterListManager.registerDropHandler("string", onStringDrop)
	CharacterListManager.registerDropHandler("shortcut", onShortcutDrop)
	if Session.IsHost then
		CharacterListManager.registerDropHandler("", onDefaultDrop);
	end

	ChatManager.registerSlashCommand("afk", processAFK);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_SETAFK, handleAFK);

	User.onUserStateChange = onUserStateChange;
	User.onIdentityActivation = onIdentityActivation;
	User.onIdentityStateChange = onIdentityStateChange;
end

function registerWindow(w)
	_wCharList = w;
	if _wCharList and _wCharList then
		_wCharList.anchor.setStaticBounds(LEFT_MARGIN - PORTRAIT_PADDING, TOP_MARGIN, 0, 0);
	end
	if _wCharList then
		_wCharList.onSizeChanged = handleSizeChanged;
	end
end

function onUserStateChange(sUser, sStateName, nState)
	if sUser ~= "" then
		if not _tUserStates[sUser] then
			_tUserStates[sUser] = "active";
		end
		
		if sStateName == "active" or sStateName == "idle" then
			if _tUserStates[sUser] ~= "afk" then
				_tUserStates[sUser] = sStateName;
			end
		elseif sStateName == "typing" then
			if _tUserStates[sUser] == "afk" and sUser == User.getUsername() then
				_tUserStates[sUser] = "typing"
				CharacterListManager.messageAFK(sUser);
			else
				_tUserStates[sUser] = "typing"
			end
		end
		
		local sIdentity = User.getCurrentIdentity(sUser);
		if sIdentity then
			local ctrl = CharacterListManager.findControlForIdentity(sIdentity);
			if ctrl then
				ctrl.setActiveState(_tUserStates[sUser]);
			end
		end
	end
end

function onIdentityActivation(sIdentity, sUser, bActivated)
	if not _wCharList then
		return;
	end

	if bActivated then
		local ctrl = CharacterListManager.findControlForIdentity(sIdentity);
		if not ctrl or not ctrl.getName then
			CharacterListManager.createEntry(sIdentity);
			CharacterListManager.layoutControls();
			
			if not Session.IsHost then
				if (User.getIdentityOwner(sIdentity) == User.getUsername()) then
					Interface.openWindow("charsheet", "charsheet." .. sIdentity);
				end
			end
		end
	else
		local ctrl = CharacterListManager.findControlForIdentity(sIdentity);
		if ctrl then
			CharacterListManager.destroyEntry(ctrl, sIdentity);
			CharacterListManager.layoutControls();
			
			if not Session.IsHost then
				local w = Interface.findWindow("charsheet", "charsheet." .. sIdentity);
				if w then 
					w.close(); 
				end
			end
		end
	end
end

function onIdentityStateChange(sIdentity, sUser, sStateName, vState)
	local ctrl = CharacterListManager.findControlForIdentity(sIdentity);
	if ctrl then
		if sStateName == "current" then
			ctrl.setCurrent(vState, sUserState);
		elseif sStateName == "label" then
			ctrl.setName(vState);
		elseif sStateName == "color" then
			ctrl.updateColor();
		end
	end
end

function findControlForIdentity(sIdentity)
	if not _wCharList then
		return nil;
	end
	return _wCharList["ctrl_" .. sIdentity];
end

function controlSortCmp(t1, t2)
	return t1.name < t2.name;
end

function layoutControls()
	if not _wCharList then
		return;
	end

	local tIdentityList = {};
	for k, v in pairs(User.getAllActiveIdentities()) do
		table.insert(tIdentityList, { name = v, control = findControlForIdentity(v) });
	end
	table.sort(tIdentityList, controlSortCmp);
	for k, v in pairs(tIdentityList) do
		v.control.sendToBack();
	end
	_wCharList.anchor.sendToBack();
end

function resizeWindow()
	if not _wCharList then
		return;
	end

	local x = LEFT_MARGIN + RIGHT_MARGIN;
	local y = TOP_MARGIN + PORTRAIT_SIZE + BOTTOM_MARGIN;
	local count = CharacterListManager.getEntryCount();
	if count > 0 then
		x = x + (count * PORTRAIT_SIZE) + ((count - 1) * PORTRAIT_PADDING);
	end
	_bDoingWindowResize = true;
	_wCharList.setSize(x, y);
	_bDoingWindowResize = false;
end

-- Handle Reset Position menu in panel object, since no event generated
function handleSizeChanged()
	if not _wCharList then
		return;
	end
	if _bDoingWindowResize then
		return;
	end
	CharacterListManager.resizeWindow();
end


--
-- Character list management
--

function addDecorator(sName, fDecorator)
	_tCharEntryDecorators[sName] = fDecorator
end

function removeDecorator(sName)
	_tCharEntryDecorators[sName] = nil
end

function setEntryClass(sWindowClass)
	_sCharEntryClass = sWindowClass
end

function createEntry(sIdentity)
	if not _wCharList then
		return;
	end

	-- Create control
	local ctrlChar = _wCharList.createControl(_sCharEntryClass, "ctrl_" .. sIdentity)

	-- Configure control
	ctrlChar.setAnchor("top", nil, "top", "absolute", TOP_MARGIN);
	ctrlChar.setAnchor("left", "anchor", "right", "relative", PORTRAIT_PADDING);
	ctrlChar.setAnchoredWidth(PORTRAIT_SIZE);
	ctrlChar.setAnchoredHeight(PORTRAIT_SIZE);

	-- Track control
	_tCharEntries[sIdentity] = ctrlChar;
	
	-- Setup widgets and decorators
	ctrlChar.createWidgets(sIdentity)
	for _,fDecorator in pairs(_tCharEntryDecorators) do
		fDecorator(ctrlChar, sIdentity)
	end

	-- Setup menus
	ctrlChar.setMenuItems(sIdentity);

	-- Resize character list window
	CharacterListManager.resizeWindow();
end

function destroyEntry(ctrlChar, sIdentity)
	-- Destory control
	ctrlChar.destroy();
	
	-- Track entries
	_tCharEntries[sIdentity] = nil;
	
	CharacterListManager.resizeWindow();
end

function getAllEntries()
	return _tCharEntries;
end

function getEntry(sIdentity)
	return _tCharEntries[sIdentity];
end

function getEntryCount()
	local count = 0;
	for _ in pairs(_tCharEntries) do 
		count = count + 1; 
	end
	return count;
end

--
-- Drop handling
--

function registerDropHandler(sDropType, fHandler)
	_tDropHandlers[sDropType] = fHandler;
end

function unregisterDropHandler(sDropType)
	_tDropHandlers[sDropType] = nil;
end

function processDrop(sIdentity, draginfo)
	-- CHECK REGISTERED DROP HANDLERS
	local sDropType = draginfo.getType();
	
	for sKey, fHandler in pairs(_tDropHandlers) do
		if sKey == sDropType then
			return fHandler(sIdentity, draginfo);
		end
	end

	if _tDropHandlers[""] then
		return _tDropHandlers[""](sIdentity, draginfo);
	end
	
	-- NO DROP HANDLER FOUND
	return nil;
end

--
-- Default drop handlers
--

function onNumberDrop(sIdentity, draginfo)
	local msg = {};
	msg.text = draginfo.getDescription();
	msg.font = "systemfont";
	msg.icon = "";
	msg.dice = {};
	msg.diemodifier = draginfo.getNumberData();
	msg.secret = false;
	
	Comm.deliverChatMessage(msg);
	return true
end

function onStringDrop(sIdentity, draginfo)
	ChatManager.processWhisperHelper(User.getIdentityLabel(sIdentity), draginfo.getStringData());
	return true;
end

function onShortcutDrop(sIdentity, draginfo)
	local sClass, sRecord = draginfo.getShortcutData();
	local nodeSource = draginfo.getDatabaseNode();
	
	if Session.IsHost then
		local bProcessed = false;
		if Input.isAltPressed() then
			bProcessed = CharacterListManager.processClassDrop(sClass, sIdentity, draginfo);
		end
		if not bProcessed then
			local w = Interface.openWindow(draginfo.getShortcutData());
			if w then
				w.share(User.getIdentityOwner(sIdentity));
			end
		end
		return true;
	else
		CharacterListManager.processClassDrop(sClass, sIdentity, draginfo);
	end
end

function processClassDrop(sClass, sIdentity, draginfo)
	return ItemManager.handleAnyDrop("charsheet." .. sIdentity, draginfo);
end

function onDefaultDrop(sIdentity, draginfo)
	return CombatManager.onDrop(nil, "charsheet." .. sIdentity, draginfo);
end

--
--	Features
--

function processAFK(sCommand, sParams)
	CharacterListManager.toggleAFK();
end

function toggleAFK()
	local sUser = User.getUsername();
	
	if _tUserStates[sUser] == "afk" then
		_tUserStates[sUser] = "active";
	else
		_tUserStates[sUser] = "afk";
	end
	
	local sIdentity = User.getCurrentIdentity();
	 if sIdentity then
		local ctrl = CharacterListManager.findControlForIdentity(sIdentity);
		 if ctrl then
			ctrl.setActiveState(_tUserStates[sUser]);
		end
	end
	
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_SETAFK;
	msgOOB.user = sUser;
	if _tUserStates[sUser] == "afk" then
		msgOOB.nState = 1;
	else
		msgOOB.nState = 0;
	end

	Comm.deliverOOBMessage(msgOOB);
end

function handleAFK(msgOOB)
	if not _tUserStates[msgOOB.user] then
		_tUserStates[msgOOB.user] = "active";
	end
	
	local sIdentity = User.getCurrentIdentity(msgOOB.user);
	if sIdentity then
		local ctrl = CharacterListManager.findControlForIdentity(sIdentity);
		if ctrl then
			if msgOOB.nState == "0" then
				_tUserStates[msgOOB.user] = "active";
			else
				_tUserStates[msgOOB.user] = "afk";
			end
			
			ctrl.setActiveState(_tUserStates[msgOOB.user]);
		end
		
		CharacterListManager.messageAFK(msgOOB.user);
	end
end

function messageAFK(sUser)
	local msg = {font = "systemfont"};
	if _tUserStates[sUser] == "afk" then
		msg.text = Interface.getString("charlist_message_afkon") .. " (" .. sUser .. ")";
	else
		msg.text = Interface.getString("charlist_message_afkoff") .. " (" .. sUser .. ")";
	end
	Comm.addChatMessage(msg);
end
