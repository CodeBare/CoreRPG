-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aSources = {};

function onInit()
	setReadOnly(true);
end

function onClose()
	for _,sSource in ipairs(aSources) do
		DB.removeHandler(sSource, "onUpdate", onSourceUpdated);
	end
end

function addSource(sAddSource, bDelayUpdate)
	if (sAddSource or "") == "" then
		return;
	end
	
	DB.addHandler(sAddSource, "onUpdate", onSourceUpdated);
	table.insert(aSources, sAddSource);
	if not bDelayUpdate then
		self.onSourceUpdated();
	end
end

function removeSource(sRemoveSource)
	if (sRemoveSource or "") == "" then
		return;
	end
	
	for kSource,sSource in ipairs(aSources) do
		if sSource == sRemoveSource then
			DB.removeHandler(sSource, "onUpdate", onSourceUpdated);
			table.remove(aSources, kSource);
			self.onSourceUpdated();
			break;
		end
	end
end

function onSourceValue(sSource)
	return DB.getValue(sSource, "");
end

function onSourceUpdated()
	local aSourceValues = {};
	
	for _,sSource in ipairs(aSources) do
		local sSourceValue = self.onSourceValue(sSource);
		if (sSourceValue or "") ~= "" then
			table.insert(aSourceValues, sSourceValue);
		end
	end
	
	setValue(table.concat(aSourceValues, " "));
end

