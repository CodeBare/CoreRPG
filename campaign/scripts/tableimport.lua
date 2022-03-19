-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onDataTypeChanged();
end

function onDataTypeChanged()
	local sDataType = datatype.getStringValue();
	
	local bShowDelimitedFields = (sDataType == "delimited");
	delimiter_label.setVisible(bShowDelimitedFields);
	delimiter.setVisible(bShowDelimitedFields);
	headerrow_label.setVisible(bShowDelimitedFields);
	headerrow.setVisible(bShowDelimitedFields);
	rangecol_label.setVisible(bShowDelimitedFields);
	rangecol.setVisible(bShowDelimitedFields);
end

function onImport()
	local sDataType = datatype.getStringValue();
	if sDataType == "delimited" then
		onImportDelimited();
	else
		onImportSimple();
	end
end

function onImportSimple()
	local sName = name.getValue();
	local sText = text.getValue();
	
	local vTable = parseSimple(sText);
	local nodeTable = createTable(sName, vTable);
	LibraryData.openRecordWindow("table", nodeTable);
	close();
end

function cleanImportStringForMatching(s)
	-- Things get complicated, since we support UTF-8 strings internally
	-- Pattern matching doesn't work well on UTF-8 strings
	-- Convert special characters to ASCII characters before pattern matching
	s = s:gsub("–", "-"); -- &ndash (0xE2-0x80-0x93)
	s = s:gsub("—", "-"); -- &mdash (0xE2-0x80-0x94)

	return s;
end

function parseSimple(sText)
	local vTable = {};
	vTable.headerdata = {};
	vTable.data = {};

	local tLines = StringManager.split(sText, "\r\n", true);
	for kLine,vLine in ipairs(tLines) do
		local tResults, nRangeFrom, nRangeTo = parseSimpleTextLine(vLine, true);

		local vTableLine = {};
		vTableLine.nFrom = nRangeFrom or kLine;
		vTableLine.nTo = nRangeTo or vTableLine.nFrom;
		for _,vResult in ipairs(tResults) do
			table.insert(vTableLine, vResult);
		end

		table.insert(vTable.data, vTableLine);
	end

	return vTable;
end

function parseSimpleTextLine(s, bCheckRange)
	local sStringToMatch = cleanImportStringForMatching(s);
	local sRangeFrom, sRangeTo, sResults = sStringToMatch:match("^%s*(%d+)%.?%s*-%s*(%d+)%.?%s+(.*)");
	if not sRangeFrom then
		sRangeFrom, sResults = sStringToMatch:match("^%s*(%d+)%.?%s+(.*)");
		if not sRangeFrom then
			sResults = s;
		end
	end
	local nRangeFrom = tonumber(sRangeFrom) or nil;
	local nRangeTo = tonumber(sRangeTo) or nRangeFrom;

	local tResults = StringManager.splitByPattern(sResults, "%s%s+", true);

	return tResults, nRangeFrom, nRangeTo;
end

function onImportDelimited()
	local sName = name.getValue();
	local sText = text.getValue();
	local bHeaderRow = (headerrow.getValue() == 1);
	local bRangeCol = (rangecol.getValue() == 1);
	
	local sDelimiter = delimiter.getStringValue();
	local cDelimiter = ',';
	if sDelimiter == "pipe" then
		cDelimiter = '|';
	elseif sDelimiter == "colon" then
		cDelimiter = ':';
	elseif sDelimiter == "semicolon" then
		cDelimiter = ';';
	end

	local vTable = parseDelimited(sText, cDelimiter, bHeaderRow, bRangeCol);
	local nodeTable = createTable(sName, vTable);
	openTable(nodeTable);
	close();
end

function parseDelimited(sText, cDelimiter, bHeaderRow, bRangeCol)
	local vTable = {};
	vTable.headerdata = {};
	vTable.data = {};

	local tLines = StringManager.split(sText, "\r\n", true);
	local nLineCount = 1;
	for kLine,vLine in ipairs(tLines) do
		if bHeaderRow and (kLine == 1) then
			local tResults = parseDelimitedLine(vLine, cDelimiter, bRangeCol);
			for _,vResult in ipairs(tResults) do
				table.insert(vTable.headerdata, vResult);
			end
		else
			local tResults, nRangeFrom, nRangeTo = parseDelimitedLine(vLine, cDelimiter, bRangeCol);

			local vTableLine = {};
			vTableLine.nFrom = nRangeFrom or nLineCount;
			vTableLine.nTo = nRangeTo or vTableLine.nFrom;
			for _,vResult in ipairs(tResults) do
				table.insert(vTableLine, vResult);
			end

			table.insert(vTable.data, vTableLine);

			nLineCount = nLineCount + 1;
		end
	end

	return vTable;
end

function parseDelimitedLine(s, cDelimiter, bRangeCol)
	local tDelimiterResults = StringManager.splitByPattern(s, cDelimiter, true);
	local tResults = {};
	local i = 1;
	while i <= #tDelimiterResults do
		table.insert(tResults, tDelimiterResults[i]);
		if tDelimiterResults[i]:match("^%s*\"") then
			while (i + 1 <= #tDelimiterResults) and not tDelimiterResults[i]:match("\"%s*$") do
				tResults[#tResults] = tResults[#tResults] .. cDelimiter .. tDelimiterResults[i + 1];
				i = i + 1;
			end
		end
		i = i + 1;
	end

	for kResult,vResult in ipairs(tResults) do
		local sData = vResult:match("^%s*\"(.*)\"%s*$");
		if sData then
			tResults[kResult] = StringManager.trim(sData);
		else
			tResults[kResult] = StringManager.trim(vResult);
		end
	end

	local nRangeFrom = nil;
	local nRangeTo = nil;
	if bRangeCol and (#tResults > 0) then
		local sRangeCol = tResults[1];
		table.remove(tResults, 1);

		local sStringToMatch = cleanImportStringForMatching(sRangeCol);

		local sRangeFrom, sRangeTo = sStringToMatch:match("^%s*(%d+)%.?%s*-%s*(%d+)%.?%s*$");
		if not sRangeFrom then
			sRangeFrom = sStringToMatch:match("^%s*(%d+)%.?%s*$");
		end
		nRangeFrom = tonumber(sRangeFrom) or nil;
		nRangeTo = tonumber(sRangeTo) or nRangeFrom;
	end
	return tResults, nRangeFrom, nRangeTo;
end

function createTable(sName, vTable)
	local sRootMapping = LibraryData.getRootMapping("table");
    local nodeTable = DB.createChild(sRootMapping);
    local nodeTableRows = nodeTable.createChild("tablerows");
    
    DB.setValue(nodeTable, "name", "string", sName);

    local nColumns = 1;
    for kHeader,vHeader in ipairs(vTable.headerdata) do
    	DB.setValue(nodeTable, "labelcol" .. kHeader, "string", vHeader);
    end
    if #(vTable.headerdata) > nColumns then
    	nColumnes = #(vTable.headerdata);
    end

	for _,vRow in ipairs(vTable.data) do
        local nodeRow = nodeTableRows.createChild();
	    DB.setValue(nodeRow, "fromrange", "number", vRow.nFrom);
	    DB.setValue(nodeRow, "torange", "number", vRow.nTo);

        local nodeRowResults = nodeRow.createChild("results");
        for _,vResult in ipairs(vRow) do
			local nodeResult = nodeRowResults.createChild();
			DB.setValue(nodeResult, "result", "string", StringManager.trim(vResult));
       	end

       	if #vRow > nColumns then
       		nColumns = #vRow;
       	end
	end
    DB.setValue(nodeTable, "resultscols", "number", nColumns);

    return nodeTable;
end

function openTable(nodeTable)
	if not nodeTable then
		return;
	end

	local sClass = LibraryData.getRecordDisplayClass("table");
	local w = Interface.openWindow(sClass, nodeTable);
	w.header.subwindow.name.setFocus();
end
