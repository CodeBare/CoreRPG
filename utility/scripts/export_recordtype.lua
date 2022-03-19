-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onSelectValueChanged();
end

function onSelectValueChanged()
	local bState = (select.getValue() == 1);
	entries.setVisible(not bState);
end

function onHover(bOnWindow)
	if bOnWindow then
		setFrame("rowshade");
	else
		setFrame(nil);
	end
end

local _tData = nil;

function setData(tExport)
	_tData = tExport;
	label.setValue(_tData.label);
end

function getExportType()
	return _tData.name;
end
function getExportListClass()
	return _tData.listclass;
end
function getExportListPath()
	return _tData.listpath;
end

function getSources()
	local vExportSource = _tData.source or _tData.name;

	local tExportSources = {};
	if type(vExportSource) == "table" then
		tExportSources = vExportSource;
	elseif vExportSource ~= "" then
		tExportSources = { vExportSource };
	end
	return tExportSources;
end
function getTargets()
	local vExportTarget = _tData.export or _tData.name;

	local tExportTargets = {};
	if type(vExportTarget) == "table" then
		tExportTargets = vExportTarget;
	elseif vExportTarget ~= "" then
		tExportTargets = { vExportTarget };
	end
	return tExportTargets;
end
function getRefTargets()
	local vExportRefTarget = _tData.exportref or _tData.export or _tData.name;

	local tExportRefTargets = {};
	if type(vExportRefTarget) == "table" then
		tExportRefTargets = vExportRefTarget;
	elseif vExportRefTarget ~= "" then
		tExportRefTargets = { vExportRefTarget };
	end
	return tExportRefTargets;
end
