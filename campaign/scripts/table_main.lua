-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aTableColumnLabels = {};
local nColumnsLeftMargin = 70;
local nColumnsRightMargin = 30;
local nLabelLeftMargin = 5;
local nLabelRightMargin = 5;
local bInitPhase = true;

function onInit()
	if Session.IsHost then
		OptionsManager.registerCallback("REVL", onOptionUpdate);
		
		if not tablerows.getNextWindow(nil) then
			addRow();
			addRow();
		end
	end
	
	self.onSizeChanged = handleSizeChanged;
	onColumnsChanged();
	
	updateDieHeader();
	onOptionUpdate();
	update();
	
	local node = getDatabaseNode();
	DB.addHandler(DB.getPath(node, "tablerows.*.fromrange"), "onUpdate", updateDieHeader);
	DB.addHandler(DB.getPath(node, "tablerows.*.torange"), "onUpdate", updateDieHeader);
	DB.addHandler(DB.getPath(node, "tablerows"), "onChildDeleted", updateDieHeader);
	DB.addHandler(DB.getPath(node, "dice"), "onUpdate", updateDieHeader);
	DB.addHandler(DB.getPath(node, "mod"), "onUpdate", updateDieHeader);
end

function onSubwindowInstantiated()
	bInitPhase = false;
	updateColumns();
end

function onClose()
	if Session.IsHost then
		OptionsManager.unregisterCallback("REVL", onOptionUpdate);
	end
		
	local node = getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "tablerows.*.fromrange"), "onUpdate", updateDieHeader);
	DB.removeHandler(DB.getPath(node, "tablerows.*.torange"), "onUpdate", updateDieHeader);
	DB.removeHandler(DB.getPath(node, "tablerows"), "onChildDeleted", updateDieHeader);
	DB.removeHandler(DB.getPath(node, "dice"), "onUpdate", updateDieHeader);
	DB.removeHandler(DB.getPath(node, "mod"), "onUpdate", updateDieHeader);
end

function onOptionUpdate()
	local bShow = false;
	if Session.IsHost then
		bShow = OptionsManager.isOption("REVL", "on");
	end
	
	hiderollresults.setVisible(bShow);
	label_showroll.setVisible(bShow);
end

function update()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	
	if bReadOnly then
		table_iedit.setValue(0);
	end
	table_iedit.setVisible(not bReadOnly);

	description.setReadOnly(bReadOnly);
	local bShowDesc = not bReadOnly or not description.isEmpty();
	description.setVisible(bShowDesc);
	divider.setVisible(bShowDesc);
	
	for _,ctrlLabel in pairs(aTableColumnLabels) do
		ctrlLabel.setReadOnly(bReadOnly);
	end
	
	tablerows.setReadOnly(bReadOnly);
	for _,w in ipairs(tablerows.getWindows()) do
		w.fromrange.setReadOnly(bReadOnly);
		w.torange.setReadOnly(bReadOnly);
		for _,w2 in ipairs(w.results.getWindows()) do
			w2.result.setReadOnly(bReadOnly);
		end
	end
end

function handleSizeChanged()
	updateColumns();
end

function updateDieHeader()
	local aDice, nMod = TableManager.getTableDice(getDatabaseNode());
	sDice = DiceManager.convertDiceToString(aDice, nMod);
	tablecolumnheaders.subwindow.header_die.setValue(sDice);
end

function getColumns()
	return resultscols.getValue();
end

function setColumns(nColumns)
	local nCurrentColumns = getColumns();
	if nColumns < 1 then
		nColumns = 1;
	elseif nColumns > TableManager.MAX_COLUMNS then
		nColumns = TableManager.MAX_COLUMNS;
	end
	if nColumns ~= nCurrentColumns then
		resultscols.setValue(nColumns);
	end
end

function calcColumnWidths()
	local w,h = tablerows.getSize();
	return math.floor(((w - nColumnsLeftMargin - nColumnsRightMargin) / getColumns()) + 0.5) - 1;
end

function onColumnsChanged()
	local nColumns = getColumns();
	for i = 1, nColumns do
		addColumnLabel(i);
	end
	for i = nColumns + 1, TableManager.MAX_COLUMNS do
		removeColumnLabel(i);
	end

	if Session.IsHost then
		for _,v in ipairs(tablerows.getWindows()) do
			setRowColumns(v, nColumns);
		end
	end
	
	updateColumns();
end

function addRow()
	local winRow = tablerows.createWindow();
	
	setRowColumns(winRow, getColumns());
	winRow.results.setColumnWidth(calcColumnWidths());

	return winRow;
end

function setRowColumns(winRow, nColumns)
	local nCount = 0;
	
	for _,v in ipairs(winRow.results.getWindows()) do
		nCount = nCount + 1;
		if nCount > nColumns then
			v.getDatabaseNode().delete();
		end
	end
	
	while nCount < nColumns do
		nCount = nCount + 1;
		winRow.results.createWindow();
	end
end

function addColumnLabel(index)
	local ctrlLabel = tablecolumnheaders.subwindow["labelcol" .. index];
	if not ctrlLabel then
		ctrlLabel = tablecolumnheaders.subwindow.createControl("label_tablecolumn", "labelcol" .. index);
		if ctrlLabel then
			table.insert(aTableColumnLabels, index, ctrlLabel);
		end
	end
end

function removeColumnLabel(index)
	local ctrlLabel = tablecolumnheaders.subwindow["labelcol" .. index];
	if ctrlLabel then
		ctrlLabel.destroy();
		table.remove(aTableColumnLabels, index);
	end
end

function updateColumns()
	if bInitPhase then
		return;
	end
	
	local nColumns = getColumns();
	local nWidth = calcColumnWidths();

	for _,v in ipairs(tablerows.getWindows()) do
		v.results.setColumnWidth(nWidth);
	end

	local x = nColumnsLeftMargin + 10;
	local w,h;
	local nLabelWidth = nWidth - nLabelLeftMargin - nLabelRightMargin;
	
	for k,v in pairs(aTableColumnLabels) do
		if k <= nColumns then
			v.setAnchor("left", "", "left", "absolute", x + nLabelLeftMargin);
			v.setVisible(true);
			v.setAnchoredWidth(nLabelWidth);
			x = x + nWidth;
		elseif k > nColumns then
			v.setVisible(false);
		end
	end
end

function onDrop(x, y, draginfo)
	-- If no dice, then nothing to do
	local sDragType = draginfo.getType();
	if sDragType ~= "dice" and sDragType ~= "table" then
		return false;
	end
	local aDropDiceList = draginfo.getDieList();
	if not aDropDiceList then
		return false;
	end
	
	-- Set up table roll structure
	local rTableRoll = {};
	rTableRoll.nodeTable = getDatabaseNode();

	-- Get dice and mod
	rTableRoll.aDice = {};
	for _,v in ipairs(aDropDiceList) do
		table.insert(rTableRoll.aDice, v.type);
	end
	rTableRoll.nMod = draginfo.getNumberData();

	-- Determine column dropped on (if any)
	rTableRoll.nColumn = 0;
	local nColumns = getColumns();
	if nColumns > 1 then
		local nWidth = calcColumnWidths();
		if x > nColumnsLeftMargin then
			rTableRoll.nColumn = math.floor((x - nColumnsLeftMargin) / nWidth) + 1;
			if (rTableRoll.nColumn < 1) or (rTableRoll.nColumn > nColumns) then
				rTableRoll.nColumn = 0;
			end
		end
	end
	
	-- Perform the roll
	TableManager.performRoll(nil, nil, rTableRoll, true);
	return true;
end

function actionRoll(draginfo)
	local rTableRoll = {};
	rTableRoll.nodeTable = getDatabaseNode();
	
	TableManager.performRoll(draginfo, nil, rTableRoll, true);
	return true;
end
