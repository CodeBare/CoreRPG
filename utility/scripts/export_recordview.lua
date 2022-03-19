-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _tData;

function setData(tData)
	_tData = tData;

	label.setValue(_tData.sLabel);
end

function getData()
	return _tData;
end
