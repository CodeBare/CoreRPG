-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	Desktop.registerPublicNodes();
	
	Interface.onDesktopInit = onDesktopInit;
	User.onLogin = onUserLogin;
end

function onDesktopInit()
	if not Session.IsHost then
		Interface.openWindow("charselect_client", "");
	end
	
	Desktop.registerModuleSets();
	if not CampaignRegistry or not CampaignRegistry.setup then
		Interface.openWindow("setup", "");
	end
end

function onUserLogin(sUser, bActivated)
	if bActivated then
		local sMOTD = StringManager.trim(DB.getText("motd.text", ""));
		if sMOTD ~= "" then
			local bAlreadyOpen = true;
			local w = Interface.findWindow("motd", "motd");
			if not w then
				bAlreadyOpen = false;
				w = Interface.openWindow("motd", "motd");
			end
			if w then
				w.share(sUser);
			end
			if not bAlreadyOpen then
				w.close();
			end
		end
	end
end

function registerPublicNodes()
	if Session.IsHost then
		DB.createNode("motd").setPublic(true);
		DB.createNode("options").setPublic(true);
		DB.createNode("partysheet").setPublic(true);
		DB.createNode("calendar").setPublic(true);
		DB.createNode("combattracker").setPublic(true);
		DB.createNode("modifiers").setPublic(true);
		DB.createNode("effects").setPublic(true);
	end
end

function addDataModuleSet(sMode, vDataModuleSet)
	if not aDataModuleSet[sMode] then
		return;
	end
	table.insert(aDataModuleSet[sMode], vDataModuleSet);
end

function addTokenPackSet(sMode, vTokenModuleSet)
	Debug.console("Desktop.addTokenPackSet - DEPRECATED - 2021-10-15");
end

function registerModuleSets()
	if Session.IsHost then
		DesktopManager.addDataModuleSets(aDataModuleSet["host"]);
	else
		DesktopManager.addDataModuleSets(aDataModuleSet["client"]);
	end
end

aCoreDesktopStack = 
{
	["host"] =
	{
		{
			sIcon = "sidebar_icon_link_ct",
			tooltipres="sidebar_tooltip_ct",
			class="combattracker_host",
			path="combattracker",
		},
		{
			sIcon = "sidebar_icon_link_ps",
			tooltipres="sidebar_tooltip_ps",
			class="partysheet_host",
			path="partysheet",
		},
		{
			class="calendar",
			path="calendar",
		},
		{
			class="pointerselection",
		},
		{
			class="modifiers",
			path="modifiers",
		},
		{
			class="effectlist",
			path="effects",
		},
		{
			class="options",
		},
	},
	["client"] =
	{
		{
			sIcon = "sidebar_icon_link_ct",
			tooltipres="sidebar_tooltip_ct",
			class="combattracker_client",
			path="combattracker",
		},
		{
			sIcon = "sidebar_icon_link_ps",
			tooltipres="sidebar_tooltip_ps",
			class="partysheet_client",
			path="partysheet",
		},
		{
			class="calendar",
			path="calendar",
		},
		{
			class="pointerselection",
		},
		{
			class="modifiers",
			path="modifiers",
		},
		{
			class="effectlist",
			path="effects",
		},
		{
			class="options",
		},
	},
};

aCoreDesktopDockV4 = 
{
	["live"] =
	{
		{
			tooltipres="sidebar_tooltip_assets",
			class="tokenbag",
		},
		{
			class="library",
		},
	},
};

aDataModuleSet = 
{
	["host"] =
	{
	},
	["client"] =
	{
	},
};
