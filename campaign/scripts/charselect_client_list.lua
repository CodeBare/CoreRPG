-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bInitialized = false;

function onInit()
	activeidentities = User.getAllActiveIdentities();
	
	User.getRemoteIdentities("charsheet", GameSystem.requestCharSelectDetailClient(), addIdentity);
	
	bInitialized = true;
end

function onClose()
	bInitialized = false;
end

function addIdentity(id, vDetails, nodeLocal)
	if not bInitialized then
		return;
	end
	
	for _, v in ipairs(activeidentities) do
		if v == id then
			return;
		end
	end

	local w = createWindow();
	if w then
		w.setData(id, nodeLocal);
		
		local sName, sDetails = GameSystem.receiveCharSelectDetailClient(vDetails);
		w.name.setValue(sName);
		w.details.setValue(sDetails);
		if DB.isOwner("charsheet." .. id) then
			w.campaign.setValue(Interface.getString("charselect_label_server") .. " (" .. Interface.getString("charselect_label_owned") .. ")");
		end

		if id then
			w.portrait.setIcon("portrait_" .. id .. "_charlist", true);
		end
		
		applySort();
	end
end
