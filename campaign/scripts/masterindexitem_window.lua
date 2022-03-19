-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local m_vNode = nil;
local m_sRecordType = "";
local m_bShared = false;
local m_bDirty = false;
local m_bIdentifiable = false;

function onInit()
	m_vNode = getDatabaseNode();
	if not m_vNode then
		return;
	end
	
	local sModule = m_vNode.getModule();
	if modified and sModule then
		modified.setVisible(true);
		modified.setTooltipText(sModule);
		if not m_vNode.isReadOnly() then
			m_vNode.onIntegrityChange = onIntegrityChange;
			onIntegrityChange(m_vNode);
		end
	end

	m_vNode.onObserverUpdate = onObserverUpdate;
	onObserverUpdate(m_vNode);
	
	if category then
		m_vNode.onCategoryChange = onCategoryChange;
		onCategoryChange(m_vNode);
	end
end

function setRecordType(sNewRecordType)
	if m_sRecordType == sNewRecordType then
		return;
	end
		
	m_sRecordType = sNewRecordType
	
	local sRecordDisplayClass = LibraryData.getRecordDisplayClass(m_sRecordType, m_vNode);
	local sPath = "";
	if m_vNode then
		sPath = m_vNode.getPath();
	end
	link.setValue(sRecordDisplayClass, sPath);
	
	local sEmptyNameText = LibraryData.getEmptyNameText(m_sRecordType);
	name.setEmptyText(sEmptyNameText);
	
	if isidentified and nonid_name then
		m_bIdentifiable = LibraryData.isIdentifiable(m_sRecordType, m_vNode);
		
		if m_bIdentifiable then
			local sEmptyUnidentifiedNameText = LibraryData.getEmptyUnidentifiedNameText(m_sRecordType);
			nonid_name.setEmptyText(sEmptyUnidentifiedNameText);

			onIDChanged();
		end
	end
end

function onMenuSelection(selection)
	if selection == 7 then
		toggleRecordSharing();
	elseif selection == 8 then
		getDatabaseNode().revert();
	end
end

function buildMenu()
	resetMenuItems();
	
	if modified and m_bDirty then
		registerMenuItem(Interface.getString("menu_revert"), "shuffle", 8);
	end
	if m_bShared then
		registerMenuItem(Interface.getString("windowunshare"), "windowunshare", 7);
	else
		registerMenuItem(Interface.getString("windowshare"), "windowshare", 7);
	end
end

function onIDChanged()
	local bID = LibraryData.getIDState(m_sRecordType, m_vNode);
	name.setVisible(bID);
	nonid_name.setVisible(not bID);
end

function onIntegrityChange()
	m_bDirty = not m_vNode.isIntact();
	
	if m_bDirty then
		modified.setIcon("record_dirty");
	else
		modified.setIcon("record_intact");
	end

	buildMenu();
end

function onObserverUpdate()
	if owner then
		owner.setValue(m_vNode.getOwner());
	end
	
	local nAccess, aHolderNames = UtilityManager.getNodeAccessLevel(m_vNode);
	access.setValue(nAccess);
	if Session.IsHost then
		if nAccess == 2 then
			m_bShared = true;
		elseif nAccess == 1 then
			local sShared = Interface.getString("tooltip_shared") .. " " .. table.concat(aHolderNames, ", ");
			access.setStateTooltipText(1, sShared);
			m_bShared = true;
		else
			m_bShared = false;
		end
		buildMenu();
	end
end

function onCategoryChange()
	local vCategory = m_vNode.getCategory();
	if type(vCategory) ~= "string" then
		vCategory = vCategory.name;
	end
	category.setValue(vCategory);
	category.setTooltipText(vCategory);
end

function toggleRecordSharing()
	if m_bShared then
		unshareRecord();
	else
		shareRecord();
	end
end

function unshareRecord()
	if not Session.IsHost then return; end
	
	if m_vNode.isPublic() then
		m_vNode.setPublic(false);
	else
		m_vNode.removeAllHolders(true);
	end
end

function shareRecord()
	if not Session.IsHost then return; end

	m_vNode.setPublic(true);
end

