-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local tCommonStore = {};

function getVariable(sKey)
	return tCommonStore[sKey];
end

function setVariable(sKey, v)
	if (sKey or "") == "" then
		return;
	end
	tCommonStore[sKey] = v;
end
