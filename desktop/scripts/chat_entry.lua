-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	self.onSlashCommand = ChatManager.onSlashCommand;
end

function onDeliverMessage(msg, mode)
	if ChatManager.onDeliverMessage(msg, mode) then
		return false;
	end
	return msg;
end

function onTab()
	ChatManager.doUserAutoComplete(self);
	return true;
end
