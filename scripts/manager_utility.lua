-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _bClientFGU;
function isClientFGU()
	if _bClientFGU == nil then
		_bClientFGU = (Session.VersionMajor >= 4);
	end
	return _bClientFGU;
end

-- NOTE: Converts table into numerically indexed table, based on sort order of original keys. Original keys are not included in new table.
function getSortedTable(aOriginal)
	local aSorter = {};
	for k,_ in pairs(aOriginal) do
		table.insert(aSorter, k);
	end
	table.sort(aSorter);
	
	local aSorted = {};
	for _,v in ipairs(aSorter) do
		table.insert(aSorted, aOriginal[v]);
	end
	return aSorted;
end

-- NOTE: Performs a structure deep copy. Does not copy meta table information.
function copyDeep(v)
	if type(v) == "table" then
		local v2 = {};
		for kTable, vTable in next, v, nil do
			v2[copyDeep(kTable)] = copyDeep(vTable);
		end
		return v2;
	end
	
	return v;
end

function encodeXML(s)
	if not s then
		return "";
	end
	return s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("\"", "&quot;"):gsub("'", "&apos;");
end

function getDataBaseNodePathSplit(vNode)
	local aPath = {};
	local sPath = "";
	if type(vNode) == "databasenode" then
		sPath = vNode.getPath();
	elseif type(vNode) == "string" then
		sPath = vNode;
	end
	
	-- Remove module data
	sPath = sPath:gsub("@.*$", "");
	
	-- Pull first string before period
	for s in sPath:gmatch("([^%.]+)") do
		table.insert(aPath, s);
	end

	if #aPath == 0 then
		return "";
	end
	return unpack(aPath);
end

function getNodeAccessLevel(vNode)
	if vNode then
		if vNode.isPublic() then
			return 2;
		else
			if Session.IsHost then
				local sOwner = vNode.getOwner();
				local aHolderNames = {};
				local aHolders = vNode.getHolders();
				for _,sHolder in pairs(aHolders) do
					if sOwner then
						if sOwner ~= sHolder then
							table.insert(aHolderNames, sHolder);
						end
					else
						table.insert(aHolderNames, sHolder);
					end
				end
				
				if #aHolderNames > 0 then
					return 1, aHolderNames;
				end
			end
		end
	end
	return 0;
end

function getNodeCategory(vNode)
	local vCategory = vNode.getCategory();
	if type(vCategory) == "table" then
		return vCategory.name;
	end
	return vCategory;
end

function getNodeModule(vNode)
	return vNode.getModule() or "";
end

function getRootNodeName(vNode)
	local nodeResult = nil;
	if type(vNode) == "databasenode" then
		nodeTemp = vNode;
	elseif type(vNode) == "string" then
		nodeTemp = DB.findNode(vNode);
	end
	while nodeTemp do
		nodeResult = nodeTemp;
		nodeTemp = nodeTemp.getParent();
	end
	if nodeResult then 
		return nodeResult.getName(); 
	end
	return "";
end

--
--	Window/control helper functions
--

function getTopWindow(w)
	local wTop = w;
	while wTop and (wTop.windowlist or wTop.parentcontrol) do
		if wTop.windowlist then
			wTop = wTop.windowlist.window;
		else
			wTop = wTop.parentcontrol.window;
		end
	end
	return wTop;
end

function setStackedWindowVisibility(w, bShow)
	local wTop = w;
	while wTop and (wTop.windowlist or wTop.parentcontrol) do
		if wTop.windowlist then
			wTop.windowlist.setVisible(bShow);
			wTop = wTop.windowlist.window;
		else
			wTop.parentcontrol.setVisible(bShow);
			wTop = wTop.parentcontrol.window;
		end
	end
end

function callStackedWindowFunction(w, sFunction, ...)
	local wTop = w;
	while wTop and (wTop.windowlist or wTop.parentcontrol) do
		if wTop[sFunction] then
			wTop[sFunction](...);
		end
		if wTop.windowlist then
			wTop = wTop.windowlist.window;
		else
			wTop = wTop.parentcontrol.window;
		end
	end
end