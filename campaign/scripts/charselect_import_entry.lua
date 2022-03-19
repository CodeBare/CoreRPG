-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local node = getDatabaseNode();
	
	local portraitfile = User.getLocalIdentityPortrait(node);
	if portraitfile then
		portrait.setFile(portraitfile);
	end
	
	name.setValue(DB.getValue(node, "name", ""));
	details.setValue(GameSystem.getCharSelectDetailHost(node));
end

local bRequested = false;
function importCharacter()
	if Session.IsHost then
		local nodeTarget = CampaignDataManager.addPregenChar(getDatabaseNode());
		if (portrait.getFile() or "") ~= "" then
		 	portrait.activate(nodeTarget);
		end
	else
		if not bRequested then
			User.requestIdentity("", "charsheet", "name", getDatabaseNode(), requestResponse);
			bRequested = true;
		end
	end
end

function requestResponse(result, identity)
	if result and identity then
		local colortable = {};
		if CampaignRegistry and CampaignRegistry.colortables and CampaignRegistry.colortables[identity] then
			colortable = CampaignRegistry.colortables[identity];
		end
		User.setCurrentIdentityColors(colortable.color or "000000", colortable.blacktext or false);

		windowlist.window.close();
	else
		error.setVisible(true);
	end
end

function exportCharacter()
	CampaignDataManager.exportChar(getDatabaseNode());
end

