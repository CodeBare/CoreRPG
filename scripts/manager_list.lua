--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _nDefaultListPageSize = 50;

--
--  SETTING FUNCTIONS
--

function getDefaultPageSize()
	return _nDefaultListPageSize;
end
function setDefaultPageSize(n)
	_nDefaultListPageSize = n;
end

--
-- LIST HELPERS
--

function refreshDisplayList(w)
	-- Filter records available in list
	local tFilteredRecords = {};
	for _,v in pairs(w.getAllRecords()) do
		if w.isFilteredRecord(v) then
			table.insert(tFilteredRecords, v);
		end
	end
	w.setDisplayRecordCount(#tFilteredRecords);

	-- Sort filtered records
	local fSort = nil;
	if w.getSortFunction then
		fSort = w.getSortFunction();
	end
	table.sort(tFilteredRecords, fSort or ListManager.defaultSortFunc);
	
	-- Ensure display offset is valid
	local nDisplayOffset = w.getDisplayOffset();
	if (nDisplayOffset < 0) or (nDisplayOffset >= #tFilteredRecords) then
		nDisplayOffset = 0;
	end
	local nDisplayOffsetMax = nDisplayOffset + ListManager.getPageSize(w);
	
	-- Clear current windows
	if w.clearDisplayList then
		w.clearDisplayList();
	else
		w.list.closeAll();
	end

	-- Create windows for current page
	for kRecord,vRecord in ipairs(tFilteredRecords) do
		if kRecord > nDisplayOffset and kRecord <= nDisplayOffsetMax then
			w.addDisplayListItem(vRecord);
		end
	end

	-- Show/hide page info/buttons based on number of pages and current page
	ListManager.updatePageControls(w);
end
function defaultSortFunc(a, b)
	if a.sDisplayNameLower ~= b.sDisplayNameLower then
		return a.sDisplayNameLower < b.sDisplayNameLower;
	end
	return DB.getPath(a.vNode) < DB.getPath(b.vNode);
end

--
--  PAGE BUTTON HELPERS
--

function getPageSize(w)
	if w and w.getPageSize then
		return w.getPageSize();
	end
	return _nDefaultListPageSize;
end
function getCurrentPage(w)
	return math.max(math.ceil(w.getDisplayOffset() / ListManager.getPageSize(w)), 0) + 1;
end
function getMaxPages(w)
	local nCurrentPage = ListManager.getCurrentPage(w);
	local nPages = (nCurrentPage - 1) + math.max(math.ceil((w.getDisplayRecordCount() - w.getDisplayOffset()) / ListManager.getPageSize(w)), 0);
	return nPages;
end
function updatePageControls(w)
	local nPages = ListManager.getMaxPages(w);
	if nPages > 1 then
		local nCurrentPage = ListManager.getCurrentPage(w);
		local sPageText = string.format(Interface.getString("label_page_info"), nCurrentPage, nPages)

		w.pageanchor.setVisible(true);
		w.page_info.setValue(sPageText);
		w.page_info.setVisible(true);
		w.page_start.setVisible(nCurrentPage > 1);
		w.page_prev.setVisible(nCurrentPage > 1);
		w.page_next.setVisible(nCurrentPage < nPages);
		w.page_end.setVisible(nCurrentPage < nPages);
	else
		w.pageanchor.setVisible(false);
		w.page_info.setVisible(false);
		w.page_start.setVisible(false);
		w.page_prev.setVisible(false);
		w.page_next.setVisible(false);
		w.page_end.setVisible(false);
	end
end

function handlePageStart(w)
	w.setDisplayOffset(0);
end
function handlePagePrev(w)
	w.setDisplayOffset(w.getDisplayOffset() - ListManager.getPageSize(w));
end
function handlePageNext(w)
	w.setDisplayOffset(w.getDisplayOffset() + ListManager.getPageSize(w));
end
function handlePageEnd(w)
	local nPages = ListManager.getMaxPages(w);
	if nPages > 1 then
		w.setDisplayOffset((nPages - 1) * ListManager.getPageSize(w));
	else
		w.setDisplayOffset(0);
	end
end
