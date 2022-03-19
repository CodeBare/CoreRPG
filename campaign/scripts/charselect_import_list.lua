-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local sLabelLocal = Interface.getString("charselect_label_local");
	local sLabelCampaign = Interface.getString("charselect_label_campaign");
	
	local localIdentities = User.getLocalIdentities();
	for _, v in ipairs(localIdentities) do
		local w = createWindow(v.databasenode);
		if (v.session or "") == "" then
			w.source_label.setValue(sLabelLocal);
			w.source.setVisible(false);
		else
			w.source_label.setValue(sLabelCampaign);
			w.source.setValue(v.session);
		end
	end
	
	if Session.IsHost then
		for _,v in pairs(DB.getChildrenGlobal("pregencharsheet")) do
			addPregen(v);
		end
		Module.onModuleLoad = onModuleLoad;
	end
end

function onClose()
	Module.onModuleLoad = function() end;
end

function onModuleLoad(sModule)
	local nodeRoot = DB.getRoot(sModule);
	if nodeRoot then
		for _,v in pairs(DB.getChildren(nodeRoot, "pregencharsheet")) do
			addPregen(v);
		end
	end
end

function addPregen(node)
	local w = createWindow(node);
	if w then
		w.source_label.setValue(Interface.getString("charselect_label_pregen"));
		local aModuleInfo = Module.getModuleInfo(node.getModule());
		if aModuleInfo then
			w.source.setValue(aModuleInfo.displayname);
		end
	end
end
