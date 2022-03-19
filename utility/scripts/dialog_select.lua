-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aQueue = {};
local bHandleSelections = false;
local bFinalizingSelection = false;
local nMinSelections = 1;
local nMaxSelections = nil;

function requestSelection(sTitle, sMsg, aSelections, fnCallback, vCustom, nMinimum, nMaximum, bFront)
	local nCurrentStack = #aQueue;
	
	local rRequest = { title = sTitle, msg = sMsg, options = aSelections, min = nMinimum, max = nMaximum, callback = fnCallback, custom = vCustom };
	if bFront then
		if bFinalizingSelection or (#aQueue == 0) then
			table.insert(aQueue, 1, rRequest);
		else
			table.insert(aQueue, 2, rRequest);
		end
	else
		table.insert(aQueue, rRequest);
	end

	if nCurrentStack == 0 then
		activateNextSelection();
	end
end

function activateNextSelection()
	if #aQueue > 0 then
		bHandleSelections = false;
		
		title.setValue (aQueue[1].title);
		message.setValue (aQueue[1].msg);
		
		list.closeAll();
		for _,v in ipairs(aQueue[1].options) do
			if type(v) == "string" then
				local w = list.createWindow();
				w.text.setValue(v);
			elseif type(v) == "table" then
				local w = list.createWindow();
				w.text.setValue(v.text);
				if v.linkclass and v.linkrecord then
					w.shortcut.setValue(v.linkclass, v.linkrecord);
					w.shortcut.setVisible(true);
				end
				if v.selected then
					w.selected.setValue(1);
				end
			end
		end
		
		nMinSelections = aQueue[1].min or 1;
		nMaxSelections = aQueue[1].max or nMinSelections;
		bHandleSelections = true;
		onSelectionChanged();
	else
		close();
	end
end

function onSelectionChanged()
	if not bHandleSelections then
		return;
	end
	
	local nSelections = 0;
	for _,w in pairs(list.getWindows()) do
		if w.selected.getValue() == 1 then
			nSelections = nSelections + 1;
		end
	end
	
	if nSelections >= nMinSelections and ((nMaxSelections <= 0) or (nSelections <= nMaxSelections)) then
		button_ok.setVisible(true);
	else
		button_ok.setVisible(false);
	end
end

function processOK()
	if #aQueue > 0 then
		bFinalizingSelection = true;
		local rSelect = aQueue[1];
		table.remove(aQueue, 1);

		if rSelect.callback then
			local aSelections = {};
			for _,w in pairs(list.getWindows()) do
				if w.selected.getValue() == 1 then
					table.insert(aSelections, w.text.getValue());
				end
			end

			rSelect.callback(aSelections, rSelect.custom);
		end
		bFinalizingSelection = false;
	end
	
	activateNextSelection();
end

function processCancel()
	close();
end
