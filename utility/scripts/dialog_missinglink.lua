-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local m_aModules = nil;
local m_fCallback = nil;
local m_aCustom = nil;
local m_bFoundWildcard = false;

function initialize(vModule, fCallback, aCustom)
	if type(vModule) == "table" then
		m_aModules = vModule;
	else
		m_aModules = { vModule };
	end
	m_fCallback = fCallback;
	m_aCustom = aCustom;
	
	activateNextModuleLoad();
end

function activateNextModuleLoad()
	while #m_aModules > 0 and m_aModules[1] == "*" do
		table.remove(m_aModules, 1);
		m_bFoundWildcard = true;
	end
	
	if #m_aModules > 0 then
		local sMessage = string.format(Interface.getString("module_message_missinglink"), m_aModules[1]);
		message.setValue(sMessage);
	else
		if m_fCallback then
			m_fCallback(m_aCustom, m_bFoundWildcard);
		end
		close();
	end
end

function processOK()
	if #m_aModules > 0 then
		Module.activate(m_aModules[1]);
		table.remove(m_aModules, 1);
	end
	activateNextModuleLoad();
end

function processCancel()
	close();
end
