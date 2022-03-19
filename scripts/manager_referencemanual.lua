-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

MANUAL_DEFAULT_INDEX = "reference.refmanualindex";
MANUAL_DEFAULT_CONTENT = "reference.refmanualdata";

MANUAL_DEFAULT_CHAPTER_LIST_NAME = "chapters";
MANUAL_DEFAULT_SUBCHAPTER_LIST_NAME = "subchapters";
MANUAL_DEFAULT_PAGE_LIST_NAME = "refpages";

MANUAL_DEFAULT_INDEX_MATCH = "%(index%)";
MANUAL_DEFAULT_INDEX_MATCH_2 = "%(contents%)";

-- NOTE: Assume that only one manual exists per module
-- NOTE: Assume that the reference manual exists in a specific location in each module

--
--	Theming
--

local _nTextFrameOffsetX = 25;
local _nTextFrameOffsetY = 35;
local _nTextWithFrameOffsetX = 35;
local _nTextSansFrameOffsetX = 20;

local _nHeaderFrameOffsetX = 20;
local _nHeaderFrameOffsetY = 20;
local _nHeaderWithFrameOffsetY = 20;
local _nHeaderWithFrameOffsetX = 30;
local _nHeaderSansFrameOffsetX = 20;
local _nHeaderSansFrameOffsetY = 0;

local _nGraphicOffsetX = 35;

local _nMinImageWidth = 100;
local _nMaxSingleImageWidth = 600;
local _nMaxColumnImageWidth = 300;

local _sBlockTextEditBackColor = "18000000";

local _sBlockIconColor = "000000";
function setBlockButtonIconColor(s)
	_sBlockIconColor = s;
end
function getBlockButtonIconColor()
	return _sBlockIconColor;
end

local _tBlockFrames = {
	"sidebar",
	"text1",
	"text2",
	"text3",
	"text4",
	"text5",
	"book",
	"page",
	"picture",
	"pink",
	"blue",
	"brown",
	"green",
	"yellow",
};

function getBlockFrames()
	return _tBlockFrames;
end
function addBlockFrame(sName)
	if (sName or "") == "" then
		return;
	end
	for _,s in ipairs(_tBlockFrames) do
		if sName == s then
			return;
		end
	end
	table.insert(_tBlockFrames, sName);
end
function removeBlockFrame(sName)
	if (sName or "") == "" then
		return;
	end
	for k,s in ipairs(_tBlockFrames) do
		if sName == s then
			table.remove(_tBlockFrames, k);
			return;
		end
	end
end

--
--	Index/Next/Prev Tracking
--

_tManualIndexPath = {};
_tManualPages = {};
_tManualIndex = {};
function init(sModule, sPath)
	sModule = sModule or "";

	if not _tManualIndexPath[sModule] then
		local sManualPath;
		local _,nChapterEnd = sPath:find("%." .. ReferenceManualManager.MANUAL_DEFAULT_CHAPTER_LIST_NAME .. "%.");
		if nChapterEnd then
			sManualPath = sPath:sub(1, nChapterEnd - 1);
		else
			sManualPath = ReferenceManualManager.MANUAL_DEFAULT_INDEX .. "." .. ReferenceManualManager.MANUAL_DEFAULT_CHAPTER_LIST_NAME;
		end

		_tManualIndexPath[sModule] = sManualPath;
	end

	rebuildIndex(sModule);
end

function getOrderedRecords(tDefaultRecords)
	local tSorter = {};
	for k,v in pairs(tDefaultRecords) do
		table.insert(tSorter, { nIndex = k, nOrder = DB.getValue(v, "order", 0), sPath = v.getPath() });
	end
	table.sort(tSorter, ReferenceManualManager.sortfuncOrderedRecords);
	
	local tSorted = {};
	for _,v in ipairs(tSorter) do
		table.insert(tSorted, tDefaultRecords[v.nIndex]);
	end
	return tSorted;
end
function sortfuncOrderedRecords(a, b)
	if a.nOrder ~= b.nOrder then
		return a.nOrder < b.nOrder;
	end
	return a.sPath < b.sPath;
end

function rebuildIndex(sModule)
	sModule = sModule or "";
	if not _tManualIndexPath[sModule] then
		return;
	end

	_tManualPages[sModule] = {};
	_tManualIndex[sModule] = nil;

	for _,nodeChapter in ipairs(ReferenceManualManager.getOrderedRecords(DB.getChildren(_tManualIndexPath[sModule] .. "@" .. sModule))) do
		for _,nodeSubchapter in ipairs(ReferenceManualManager.getOrderedRecords(DB.getChildren(nodeChapter, ReferenceManualManager.MANUAL_DEFAULT_SUBCHAPTER_LIST_NAME))) do
			for _,nodePage in ipairs(ReferenceManualManager.getOrderedRecords(DB.getChildren(nodeSubchapter, ReferenceManualManager.MANUAL_DEFAULT_PAGE_LIST_NAME))) do
				local sClass, sRecord = DB.getValue(nodePage, "listlink", "", "");
				if sRecord ~= "" then
					table.insert(_tManualPages[sModule], sRecord);
					local sNameLower = DB.getValue(nodePage, "name", ""):lower();
					if sNameLower:match(ReferenceManualManager.MANUAL_DEFAULT_INDEX_MATCH) or sNameLower:match(ReferenceManualManager.MANUAL_DEFAULT_INDEX_MATCH_2) then
						_tManualIndex[sModule] = sRecord;
					end
				end
			end
		end
	end
end

function getIndexRecord(sModule)
	rebuildIndex(sModule);
	return _tManualIndex[sModule or ""];
end
function getPrevRecord(sModule, sCurrent)
	rebuildIndex(sModule);
	for kRecord,sRecord in ipairs(_tManualPages[sModule or ""]) do
		if sRecord == sCurrent then
			return _tManualPages[sModule or ""][kRecord - 1];
		end
	end
	return nil;
end
function getNextRecord(sModule, sCurrent)
	rebuildIndex(sModule);
	for kRecord,sRecord in ipairs(_tManualPages[sModule or ""]) do
		if sRecord == sCurrent then
			return _tManualPages[sModule or ""][kRecord + 1];
		end
	end
	return nil;
end

--
--  General Helper Functions
--

function updateOrderValues(cList)
	local tChildWinRecords = {};
	for _,wChild in ipairs(cList.getWindows()) do
		local nOrder = wChild.order.getValue();
		local sName = wChild.getDatabaseNode().getName();
		table.insert(tChildWinRecords, { win = wChild, sName = sName, nOrder = nOrder });
	end
 	table.sort(tChildWinRecords, function (a, b) if a.nOrder ~= b.nOrder then return a.nOrder < b.nOrder; end return a.sName < b.sName end);

 	local tReturnList = {};
 	for kChildWinRecord,tChildWinRecord in ipairs(tChildWinRecords) do
 		if tChildWinRecord.nOrder ~= kChildNodeRecord then
 			tChildWinRecord.win.order.setValue(kChildWinRecord);
 		end
 		tReturnList[kChildWinRecord] = tChildWinRecord.win;
 	end
 	return tReturnList;
end

--
--	Index Management (Add/Delete/Move Up/Move Down)
--

function onIndexAdd(w)
	local nodeList = w.list.getDatabaseNode();
	if not nodeList or nodeList.isStatic() then
		return;
	end

	local wPage = nil;
	local bSetPageNameFocus = false;
	local sClass = w.getClass();
	if sClass == "reference_manual_index" then
		local wChapter = ReferenceManualManager.onIndexAddHelper(w.list);
		local wSection;
		if wChapter then
			wChapter.name.setFocus();
			wSection = ReferenceManualManager.onIndexAddHelper(wChapter.list);
		end
		if wSection then
			wPage = ReferenceManualManager.onIndexAddHelper(wSection.list);
		end
	end
	if sClass == "reference_manual_index_chapter" then
		local wSection = ReferenceManualManager.onIndexAddHelper(w.list);
		if wSection then
			wSection.name.setFocus();
			wPage = ReferenceManualManager.onIndexAddHelper(wSection.list);
		end
	end
	if sClass == "reference_manual_index_section" then
		wPage = ReferenceManualManager.onIndexAddHelper(w.list);
		bSetPageNameFocus = true;
	end

	if wPage then
		local sContentPath = ReferenceManualManager.MANUAL_DEFAULT_CONTENT;
		local sModule = nodeList.getModule();
		if (sModule or "") ~= "" then
			sContentPath = sContentPath .. "@" .. sModule;
		end
		local nodePageData = DB.createChild(sContentPath);
		wPage.setLink("reference_manualtextwide", DB.getPath(nodePageData));
		if bSetPageNameFocus then
			wPage.name.setFocus();
		end
	end
end
function onIndexAddHelper(cList)
	local nCount = #(ReferenceManualManager.updateOrderValues(cList));
	local wAdd = cList.createWindow();
	wAdd.order.setValue(nCount + 1);

	return wAdd;
end

function onIndexDelete(w)
	local node = w.getDatabaseNode();
	if not node or node.isStatic() then
		return;
	end

	local tDataRecords = {};
	local sClass = w.getClass();
	if sClass == "reference_manual_index_chapter" then
		for _,wSection in pairs(w.list.getWindows()) do
			for _,wPage in pairs(wSection.list.getWindows()) do
				ReferenceManualManager.onIndexDeleteHelper(tDataRecords, wPage);
			end
		end
	end
	if sClass == "reference_manual_index_section" then
		for _,wPage in pairs(w.list.getWindows()) do
			ReferenceManualManager.onIndexDeleteHelper(tDataRecords, wPage);
		end
	end
	if sClass == "reference_manual_index_page" then
		ReferenceManualManager.onIndexDeleteHelper(tDataRecords, w);
	end

	node.delete();

	for _,sRecord in ipairs(tDataRecords) do
		local nodeToDelete = DB.findNode(sRecord);
		if nodeToDelete then
			nodeToDelete.delete();
		end
	end
end
function onIndexDeleteHelper(tDataRecords, wPage)
	local _,sRecord = wPage.listlink.getValue();
	if (sRecord or "") ~= "" then
		table.insert(tDataRecords, sRecord);
	end
end

function onIndexMoveUp(w)
	local cParentList = w.windowlist;
	local nodeList = cParentList.getDatabaseNode();
	if not nodeList or nodeList.isStatic() then
		return;
	end
	local tOrderedChildren = ReferenceManualManager.updateOrderValues(cParentList);

	local sClass = w.getClass();
	if sClass == "reference_manual_index_chapter" then
		local nOrder = w.order.getValue();
		if nOrder > 1 then
			tOrderedChildren[nOrder - 1].order.setValue(nOrder);
			tOrderedChildren[nOrder].order.setValue(nOrder - 1);
			cParentList.applySort();
		end
	end
	if sClass == "reference_manual_index_section" then
		local nOrder = w.order.getValue();
		if nOrder > 1 then
			tOrderedChildren[nOrder - 1].order.setValue(nOrder);
			tOrderedChildren[nOrder].order.setValue(nOrder - 1);
			cParentList.applySort();
		elseif nOrder == 1 then
			local wChapter = w.windowlist.window;
			local cChapterParentList = wChapter.windowlist;
			local tChapterOrderedChildren = ReferenceManualManager.updateOrderValues(cChapterParentList);
			local nChapterOrder = wChapter.order.getValue();
			local wPrevChapter = nil;
			if nChapterOrder > 1 then
				wPrevChapter = tChapterOrderedChildren[nChapterOrder - 1];
			end
			if wPrevChapter then
				ReferenceManualManager.onIndexMoveHelper(w, wPrevChapter.list, false);
			end
		end
	end
	if sClass == "reference_manual_index_page" then
		local nOrder = w.order.getValue();
		if nOrder > 1 then
			tOrderedChildren[nOrder - 1].order.setValue(nOrder);
			tOrderedChildren[nOrder].order.setValue(nOrder - 1);
			cParentList.applySort();
		elseif nOrder == 1 then
			local wSection = w.windowlist.window;
			local cSectionParentList = wSection.windowlist;
			local tSectionOrderedChildren = ReferenceManualManager.updateOrderValues(cSectionParentList);
			local nSectionOrder = wSection.order.getValue();
			local wPrevSection = nil;
			if nSectionOrder > 1 then
				wPrevSection = tSectionOrderedChildren[nSectionOrder - 1];
			elseif nSectionOrder == 1 then
				local wChapter = wSection.windowlist.window;
				local cChapterParentList = wChapter.windowlist;
				local tChapterOrderedChildren = ReferenceManualManager.updateOrderValues(cChapterParentList);
				local nChapterOrder = wChapter.order.getValue();
				if nChapterOrder > 1 then
					local wPrevChapter = tChapterOrderedChildren[nChapterOrder - 1];
					local tPrevChapterOrderedChildren = ReferenceManualManager.updateOrderValues(wPrevChapter.list);
					if #tPrevChapterOrderedChildren > 0 then
						wPrevSection = tPrevChapterOrderedChildren[#tPrevChapterOrderedChildren];
					else
						wPrevSection = wPrevChapter.list.createWindow();
						wPrevSection.order.setValue(1);
					end
				end
			end
			if wPrevSection then
				ReferenceManualManager.onIndexMoveHelper(w, wPrevSection.list, false);
			end
		end
	end
end
function onIndexMoveDown(w)
	local cParentList = w.windowlist;
	local nodeList = cParentList.getDatabaseNode();
	if not nodeList or nodeList.isStatic() then
		return;
	end
	local tOrderedChildren = ReferenceManualManager.updateOrderValues(cParentList);

	local sClass = w.getClass();
	if sClass == "reference_manual_index_chapter" then
		local nOrder = w.order.getValue();
		if nOrder < #tOrderedChildren then
			tOrderedChildren[nOrder + 1].order.setValue(nOrder);
			tOrderedChildren[nOrder].order.setValue(nOrder + 1);
			cParentList.applySort();
		end
	end
	if sClass == "reference_manual_index_section" then
		local nOrder = w.order.getValue();
		if nOrder < #tOrderedChildren then
			tOrderedChildren[nOrder + 1].order.setValue(nOrder);
			tOrderedChildren[nOrder].order.setValue(nOrder + 1);
			cParentList.applySort();
		elseif nOrder == #tOrderedChildren then
			local wChapter = w.windowlist.window;
			local cChapterParentList = wChapter.windowlist;
			local tChapterOrderedChildren = ReferenceManualManager.updateOrderValues(cChapterParentList);
			local nChapterOrder = wChapter.order.getValue();
			local wNextChapter = nil;
			if nChapterOrder < #tChapterOrderedChildren then
				wNextChapter = tChapterOrderedChildren[nChapterOrder + 1];
			end
			if wNextChapter then
				ReferenceManualManager.onIndexMoveHelper(w, wNextChapter.list, true);
			end
		end
	end
	if sClass == "reference_manual_index_page" then
		local nOrder = w.order.getValue();
		if nOrder < #tOrderedChildren then
			tOrderedChildren[nOrder + 1].order.setValue(nOrder);
			tOrderedChildren[nOrder].order.setValue(nOrder + 1);
			cParentList.applySort();
		elseif nOrder == #tOrderedChildren then
			local wSection = w.windowlist.window;
			local cSectionParentList = wSection.windowlist;
			local tSectionOrderedChildren = ReferenceManualManager.updateOrderValues(cSectionParentList);
			local nSectionOrder = wSection.order.getValue();
			local wNextSection = nil;
			if nSectionOrder < #tSectionOrderedChildren then
				wNextSection = tSectionOrderedChildren[nSectionOrder + 1];
			elseif nSectionOrder == #tSectionOrderedChildren then
				local wChapter = wSection.windowlist.window;
				local cChapterParentList = wChapter.windowlist;
				local tChapterOrderedChildren = ReferenceManualManager.updateOrderValues(cChapterParentList);
				local nChapterOrder = wChapter.order.getValue();
				if nChapterOrder < #tChapterOrderedChildren then
					local wNextChapter = tChapterOrderedChildren[nChapterOrder + 1];
					local tNextChapterOrderedChildren = ReferenceManualManager.updateOrderValues(wNextChapter.list);
					if #tNextChapterOrderedChildren > 0 then
						wNextSection = tNextChapterOrderedChildren[1];
					else
						wNextSection = wNextChapter.list.createWindow();
						wNextSection.order.setValue(1);
					end
				end
			end
			if wNextSection then
				ReferenceManualManager.onIndexMoveHelper(w, wNextSection.list, true);
			end
		end
	end
end
function onIndexMoveHelper(w, cList, bDown)
	local tOrderedChildren = ReferenceManualManager.updateOrderValues(cList);
	if bDown then
		for kChild,wChild in ipairs(tOrderedChildren) do
			wChild.order.setValue(kChild + 1);
		end
	end

	local wNew = cList.createWindow();
	local nodeOld = w.getDatabaseNode();
	DB.copyNode(nodeOld, wNew.getDatabaseNode());
	nodeOld.delete();

	if bDown then
		wNew.order.setValue(1);
	else
		wNew.order.setValue(#tOrderedChildren + 1);
	end
end

-- 
--	Index Keyword Generation
--

local tKeywordIgnore = {
	["a"] = true,
	["about"] = true,
	["above"] = true,
	["after"] = true,
	["again"] = true,
	["against"] = true,
	["all"] = true,
	["am"] = true,
	["an"] = true,
	["and"] = true,
	["any"] = true,
	["are"] = true,
	["aren't"] = true,
	["as"] = true,
	["at"] = true,
	["be"] = true,
	["because"] = true,
	["been"] = true,
	["before"] = true,
	["being"] = true,
	["below"] = true,
	["between"] = true,
	["both"] = true,
	["but"] = true,
	["by"] = true,
	["can't"] = true,
	["cannot"] = true,
	["could"] = true,
	["couldn't"] = true,
	["did"] = true,
	["didn't"] = true,
	["do"] = true,
	["does"] = true,
	["doesn't"] = true,
	["doing"] = true,
	["don't"] = true,
	["down"] = true,
	["during"] = true,
	["each"] = true,
	["few"] = true,
	["for"] = true,
	["from"] = true,
	["further"] = true,
	["got"] = true,
	["had"] = true,
	["hadn't"] = true,
	["has"] = true,
	["hasn't"] = true,
	["have"] = true,
	["haven't"] = true,
	["having"] = true,
	["he"] = true,
	["he'd"] = true,
	["he'll"] = true,
	["he's"] = true,
	["her"] = true,
	["here"] = true,
	["here's"] = true,
	["hers"] = true,
	["herself"] = true,
	["him"] = true,
	["himself"] = true,
	["his"] = true,
	["how"] = true,
	["how's"] = true,
	["i"] = true,
	["i'd"] = true,
	["i'll"] = true,
	["i'm"] = true,
	["i've"] = true,
	["if"] = true,
	["in"] = true,
	["into"] = true,
	["is"] = true,
	["isn't"] = true,
	["it"] = true,
	["it's"] = true,
	["its"] = true,
	["itself"] = true,
	["let's"] = true,
	["like"] = true,
	["me"] = true,
	["more"] = true,
	["most"] = true,
	["mustn't"] = true,
	["my"] = true,
	["myself"] = true,
	["no"] = true,
	["nor"] = true,
	["not"] = true,
	["of"] = true,
	["off"] = true,
	["on"] = true,
	["once"] = true,
	["only"] = true,
	["or"] = true,
	["other"] = true,
	["ought"] = true,
	["our"] = true,
	["ours"] = true,
	["ourselves"] = true,
	["out"] = true,
	["over"] = true,
	["own"] = true,
	["same"] = true,
	["shan't"] = true,
	["she"] = true,
	["she'd"] = true,
	["she'll"] = true,
	["she's"] = true,
	["should"] = true,
	["shouldn't"] = true,
	["so"] = true,
	["some"] = true,
	["such"] = true,
	["than"] = true,
	["that"] = true,
	["that's"] = true,
	["the"] = true,
	["their"] = true,
	["theirs"] = true,
	["them"] = true,
	["themselves"] = true,
	["then"] = true,
	["there"] = true,
	["there's"] = true,
	["these"] = true,
	["they"] = true,
	["they'd"] = true,
	["they'll"] = true,
	["they're"] = true,
	["they've"] = true,
	["this"] = true,
	["those"] = true,
	["through"] = true,
	["to"] = true,
	["too"] = true,
	["under"] = true,
	["until"] = true,
	["up"] = true,
	["very"] = true,
	["was"] = true,
	["wasn't"] = true,
	["we"] = true,
	["we'd"] = true,
	["we'll"] = true,
	["we're"] = true,
	["we've"] = true,
	["were"] = true,
	["weren't"] = true,
	["what"] = true,
	["what's"] = true,
	["when"] = true,
	["when's"] = true,
	["where"] = true,
	["where's"] = true,
	["which"] = true,
	["while"] = true,
	["who"] = true,
	["who's"] = true,
	["whom"] = true,
	["why"] = true,
	["why'd"] = true,
	["why's"] = true,
	["with"] = true,
	["won't"] = true,
	["would"] = true,
	["wouldn't"] = true,
	["you"] = true,
	["you'd"] = true,
	["you'll"] = true,
	["you're"] = true,
	["you've"] = true,
	["your"] = true,
	["yours"] = true,
	["yourself"] = true,
	["yourselves"] = true,
}

function onCampaignKeywordGen()
	for _,nodeChapter in pairs(DB.getChildren(DB.getPath(ReferenceManualManager.MANUAL_DEFAULT_INDEX, ReferenceManualManager.MANUAL_DEFAULT_CHAPTER_LIST_NAME))) do
		for _,nodeSubchapter in pairs(DB.getChildren(nodeChapter, ReferenceManualManager.MANUAL_DEFAULT_SUBCHAPTER_LIST_NAME)) do
			for _,nodePage in pairs(DB.getChildren(nodeSubchapter, ReferenceManualManager.MANUAL_DEFAULT_PAGE_LIST_NAME)) do
				ReferenceManualManager.onCampaignKeywordGenPage(nodePage);
			end
		end
	end
end

function onCampaignKeywordGenPage(nodePage)
	local tKeywords = {};

	ReferenceManualManager.getKeywordsFromText(DB.getValue(nodePage, "name", ""), tKeywords);

	local _,sRecord = DB.getValue(nodePage, "listlink", "", "");
	local nodeRefPage = DB.findNode(sRecord);
	if nodeRefPage then
		for _,nodeBlock in pairs(DB.getChildren(nodeRefPage, "blocks")) do
			ReferenceManualManager.getKeywordsFromText(DB.getText(nodeBlock, "text", ""), tKeywords);
			ReferenceManualManager.getKeywordsFromText(DB.getText(nodeBlock, "text2", ""), tKeywords);
		end
	end

	local tKeywords2 = {};
	for sWord,_ in pairs(tKeywords) do
		table.insert(tKeywords2, sWord);
	end
	DB.setValue(nodePage, "keywords", "string", table.concat(tKeywords2, " "));
end

function getKeywordsFromText(sText, tKeywords)
	local tWords = StringManager.parseWords(sText);
	for _,sWord in pairs(tWords) do
		local sWordLower = sWord:lower();
		if not tKeywordIgnore[sWordLower] and not sWord:match("^%d+$") then
			tKeywords[sWordLower] = true;
		end
	end
end

--
--	Block Management (Add/Delete/Move Up/Move Down) plus Drop events
--

function onBlockAdd(w, sBlockType)
	local nodeList = w.blocks.getDatabaseNode();
	if not nodeList or nodeList.isStatic() then
		return;
	end
	local nCount = #(ReferenceManualManager.updateOrderValues(w.blocks));

	local wNew = w.blocks.createWindow();
	wNew.order.setValue(nCount + 1);

	local nodeBlock = wNew.getDatabaseNode()
	if sBlockType == "textrimagel" then
		DB.setValue(nodeBlock, "blocktype", "string", "imageleft");
		DB.setValue(nodeBlock, "align", "string", "right,left");
		DB.setValue(nodeBlock, "imagelink", "windowreference", "", "");
	elseif sBlockType == "textlimager" then
		DB.setValue(nodeBlock, "blocktype", "string", "imageright");
		DB.setValue(nodeBlock, "align", "string", "left,right");
		DB.setValue(nodeBlock, "imagelink", "windowreference", "", "");
	elseif sBlockType == "image" then
		DB.setValue(nodeBlock, "blocktype", "string", "image");
		DB.setValue(nodeBlock, "frame", "string", "picture");
		DB.setValue(nodeBlock, "imagelink", "windowreference", "", "");
	elseif sBlockType == "header" then
		DB.setValue(nodeBlock, "blocktype", "string", "header");
	elseif sBlockType == "dualtext" then
		DB.setValue(nodeBlock, "blocktype", "string", "dualtext");
		DB.setValue(nodeBlock, "align", "string", "left,right");
	elseif sBlockType == "text" then
		DB.setValue(nodeBlock, "blocktype", "string", "singletext");
	end

	ReferenceManualManager.onBlockRebuild(wNew);
end
function onBlockDelete(w)
	w.getDatabaseNode().delete();
end

function onBlockMoveUp(w)
	local cParentList = w.windowlist;
	local nodeList = cParentList.getDatabaseNode();
	if not nodeList or nodeList.isStatic() then
		return;
	end
	local tOrderedChildren = ReferenceManualManager.updateOrderValues(cParentList);

	local nOrder = w.order.getValue();
	if nOrder > 1 then
		tOrderedChildren[nOrder - 1].order.setValue(nOrder);
		tOrderedChildren[nOrder].order.setValue(nOrder - 1);
		cParentList.applySort();
	end
end
function onBlockMoveDown(w)
	local cParentList = w.windowlist;
	local nodeList = cParentList.getDatabaseNode();
	if not nodeList or nodeList.isStatic() then
		return;
	end
	local tOrderedChildren = ReferenceManualManager.updateOrderValues(cParentList);

	local nOrder = w.order.getValue();
	if nOrder < #tOrderedChildren then
		tOrderedChildren[nOrder + 1].order.setValue(nOrder);
		tOrderedChildren[nOrder].order.setValue(nOrder + 1);
		cParentList.applySort();
	end
end

function onBlockDrop(w, draginfo)
	if not w then
		return false;
	end

	local bReadOnly = WindowManager.getReadOnlyState(w.windowlist.window.getDatabaseNode());
	if bReadOnly then
		return false;
	end

	local sDragType = draginfo.getType();
	if sDragType == "shortcut" then
    	local sClass,sRecord = draginfo.getShortcutData();
    	if sClass == "imagewindow" then
	        local nodeDrag = draginfo.getDatabaseNode();
	        local sAsset = DB.getText(nodeDrag, "image", "");
    		local sName = DB.getValue(nodeDrag, "name", "");

    		ReferenceManualManager.onBlockImageDropHelper(w, sAsset, sName, sClass, sRecord);
    		return true;
        end
    elseif (sDragType == "image") or (sDragType == "token") then
    	local sAsset = draginfo.getTokenData();
    	ReferenceManualManager.onBlockImageDropHelper(w, sAsset);
		return true;
    end

	return false;
end
function onBlockImageDropHelper(w, sAsset, sName, sClass, sRecord)
	if sAsset == "" then
		return;
	end

    local nodeWin = w.getDatabaseNode();
    DB.setValue(nodeWin, "image", "image", sAsset);
	DB.setValue(nodeWin, "caption", "string", sName or "");
	DB.setValue(nodeWin, "imagelink", "windowreference", sClass or "", sRecord or "");

	-- Remove any old scaling/size information from previous images
	DB.deleteChild(nodeWin, "scale");
	DB.deleteChild(nodeWin, "size");

	ReferenceManualManager.onBlockRebuild(w);
end

function onBlockScaleUp(w)
	local nScale = ReferenceManualManager.getBlockImageScale(w);
	if nScale < 100 then
		local nodeWin = w.getDatabaseNode();
		nScale = math.min(nScale + 10, 100);
		DB.setValue(nodeWin, "scale", "number", nScale);
		DB.deleteChild(nodeWin, "size");

		ReferenceManualManager.onBlockRebuild(w);
	end
end
function onBlockScaleDown(w)
	local nScale = ReferenceManualManager.getBlockImageScale(w);
	if nScale > 10 then
		local nodeWin = w.getDatabaseNode();
		nScale = math.max(nScale - 10, 10);
		DB.setValue(nodeWin, "scale", "number", nScale);
		DB.deleteChild(nodeWin, "size");

		ReferenceManualManager.onBlockRebuild(w);
	end
end
function onBlockSizeClear(w)
	local nodeWin = w.getDatabaseNode();
	DB.deleteChild(nodeWin, "size");

	ReferenceManualManager.onBlockRebuild(w);
end

--
--	Block Display
--

function onBlockUpdate(w, bReadOnly)
	ReferenceManualManager.updateBlockControls(w, bReadOnly);
end

function updateBlockControls(w, bReadOnly)
	ReferenceManualManager.updateBlockTextControls(w, bReadOnly);
	ReferenceManualManager.updateBlockImageControls(w, bReadOnly);
	ReferenceManualManager.updateBlockEditControls(w, bReadOnly);
end
function updateBlockTextControls(w, bReadOnly)
	updateBlockTextControlHelper(w.header, bReadOnly);
	updateBlockTextControlHelper(w.text, bReadOnly);
	updateBlockTextControlHelper(w.text_left, bReadOnly);
	updateBlockTextControlHelper(w.text_right, bReadOnly);

	if bReadOnly then
		if w.button_frameselect then
			w.button_frameselect.destroy();
		end
		if w.button_frameselect_right then
			w.button_frameselect_right.destroy();
		end
	else
		if w.header or w.text or w.text_left then
			if not w.button_frameselect then
				if w.text_left then
					w.createControl("button_refmanual_block_frameselect_left", "button_frameselect");
				else
					w.createControl("button_refmanual_block_frameselect", "button_frameselect");
				end
			end
		else
			if w.button_frameselect then
				w.button_frameselect.destroy();
			end
		end
		if w.text_right then
			if not w.button_frameselect_right then
				local cFrame = w.createControl("button_refmanual_block_frameselect", "button_frameselect_right");
				cFrame.setAnchor("left", "text_right", "left", "absolute", -20);
			end
		else
			if w.button_frameselect_right then
				w.button_frameselect_right.destroy();
			end
		end
	end
end
function updateBlockTextControlHelper(c, bReadOnly)
	if c then
		c.setReadOnly(bReadOnly);
		if bReadOnly then
			c.setBackColor();
		else
			c.setBackColor(_sBlockTextEditBackColor);
		end
	end
end
function updateBlockImageControls(w, bReadOnly)
	if w.image then
		local bHasImageLink = ReferenceManualManager.getBlockImageLinkBool(w);

		if bHasImageLink then
			if not w.imagelink then
				w.createControl("linkc_refblock_image_clickcapture", "imagelink");
			end
		else
			if w.imagelink then
				w.imagelink.destroy();
			end
		end

		if w.caption then
			local bCaptionEmpty = (w.caption.getValue() == "");
			local bUseCaptionLink = (bReadOnly and not CaptionEmpty and bHasImageLink);

			w.caption.setVisible(not bReadOnly or not bCaptionEmpty);
			w.caption.setReadOnly(bReadOnly);
			w.caption.setUnderline(bHasImageLink);
			if bReadOnly then
				w.caption.setBackColor();
			else
				w.caption.setBackColor(_sBlockTextEditBackColor);
			end

			if bUseCaptionLink then
				if not w.captionlink then
	            	w.createControl("linkc_refblock_image_caption_clickcapture", "captionlink", "imagelink");
				end
			else
				if w.captionlink then
	            	w.captionlink.destroy();
				end
			end
		end

		if bReadOnly or not bHasImageLink then
			if w.button_image_linkclear then
				w.button_image_linkclear.destroy();
			end
		else
			if not w.button_image_linkclear then
	    		w.createControl("button_refmanual_block_image_linkclear", "button_image_linkclear");
			end
		end

		if bReadOnly then
			if w.button_image_sizeclear then
				w.button_image_sizeclear.destroy();
			end
			if w.button_image_scaleup then
				w.button_image_scaleup.destroy();
			end
			if w.button_image_scaledown then
				w.button_image_scaledown.destroy();
			end
		else
			local tLegacySize = ReferenceManualManager.getBlockImageLegacySize(w);
			if tLegacySize then
				if not w.button_image_sizeclear then
		    		w.createControl("button_refmanual_block_image_sizeclear", "button_image_sizeclear");
				end
				if w.button_image_scaleup then
					w.button_image_scaleup.destroy();
				end
				if w.button_image_scaledown then
					w.button_image_scaledown.destroy();
				end
			else
				if w.button_image_sizeclear then
					w.button_image_sizeclear.destroy();
				end
				local nScale = ReferenceManualManager.getBlockImageScale(w);
				if nScale < 100 then
					if not w.button_image_scaleup then
			    		w.createControl("button_refmanual_block_image_scaleup", "button_image_scaleup");
					end
				else
					if w.button_image_scaleup then
						w.button_image_scaleup.destroy();
					end
				end
				if nScale > 10 then
					if not w.button_image_scaledown then
			    		w.createControl("button_refmanual_block_image_scaledown", "button_image_scaledown");
					end
				else
					if w.button_image_scaledown then
						w.button_image_scaledown.destroy();
					end
				end
			end
		end
	else
		if w.imagelink then
        	w.imagelink.destroy();
		end
		if w.captionlink then
        	w.captionlink.destroy();
		end
		if w.button_image_linkclear then
        	w.button_image_linkclear.destroy();
		end
		if w.button_image_scaleup then
        	w.button_image_scaleup.destroy();
		end
		if w.button_image_scaledown then
        	w.button_image_scaledown.destroy();
		end
		if w.button_image_sizeclear then
			w.button_image_sizeclear.destroy();
		end
	end
end
function updateBlockEditControls(w, bReadOnly)
	if bReadOnly then
		if w.imovedown then
			w.imovedown.destroy();
		end
		if w.imoveup then
			w.imoveup.destroy();
		end
		if w.idelete then
			w.idelete.destroy();
		end
	else
		if not w.idelete then
			w.createControl("button_refmanual_block_idelete", "idelete");
		end
		if not w.imoveup then
			w.createControl("button_refmanual_block_imoveup", "imoveup");
		end
		if not w.imovedown then
			w.createControl("button_refmanual_block_imovedown", "imovedown");
		end
	end
end

function onBlockRebuild(w)
	ReferenceManualManager.clearBlockControls(w);

	local sBlockType = w.blocktype.getValue();
	if sBlockType == "header" then
		ReferenceManualManager.addBlockHeader(w);
	else
		local sAlign = DB.getValue(w.getDatabaseNode(), "align", "");
		local tAlign = StringManager.split(sAlign, ",");

		-- Single column
		if #tAlign <= 1 then
			if sBlockType:match("image") or sBlockType:match("picture") then
				ReferenceManualManager.addBlockImage(w);
			elseif sBlockType:match("icon") then
				ReferenceManualManager.addBlockIcon(w);
			else
				ReferenceManualManager.addBlockText(w);
			end
		-- Dual columns
		elseif #tAlign >= 2 then
			ReferenceManualManager.addBlockText(w, tAlign[1]);
			
			if sBlockType:match("image") or sBlockType:match("picture") then
				ReferenceManualManager.addBlockImage(w, tAlign[2]);
			elseif sBlockType:match("icon") then
				ReferenceManualManager.addBlockIcon(w, tAlign[2]);
			else
				ReferenceManualManager.addBlockText(w, tAlign[2], true);
			end
		end
	end

	ReferenceManualManager.adjustBlockToImageSize(w);

	local bReadOnly = WindowManager.getReadOnlyState(w.windowlist.window.getDatabaseNode());
	ReferenceManualManager.updateBlockControls(w, bReadOnly);
end

function clearBlockControls(w)
	ReferenceManualManager.clearBlockTextControls(w);
	ReferenceManualManager.clearBlockImageControls(w);
	ReferenceManualManager.clearBlockEditControls(w);
end
function clearBlockTextControls(w)
	if w.button_frameselect_right then
		w.button_frameselect_right.destroy();
	end
	if w.button_frameselect then
		w.button_frameselect.destroy();
	end
	if w.spacer_left then
		w.spacer_left.destroy();
	end
	if w.spacer then
		w.spacer.destroy();
	end
	if w.text_right then
		w.text_right.destroy();
	end
	if w.text_left then
		w.text_left.destroy();
	end
	if w.text then
		w.text.destroy();
	end
	if w.header then
		w.header.destroy();
	end
end
function clearBlockImageControls(w)
	if w.button_image_scaledown then
    	w.button_image_scaledown.destroy();
	end
	if w.button_image_scaleup then
    	w.button_image_scaleup.destroy();
	end
	if w.button_image_sizeclear then
		w.button_image_sizeclear.destroy();
	end
	if w.button_image_linkclear then
		w.button_image_linkclear.destroy();
	end
	if w.captionlink then
    	w.captionlink.destroy();
	end
	if w.caption then
		w.caption.destroy();
	end
	if w.imagelink then
    	w.imagelink.destroy();
	end
	if w.image then
		w.image.destroy();
	end
end
function clearBlockEditControls(w)
	if w.imovedown then
		w.imovedown.destroy();
	end
	if w.imoveup then
		w.imoveup.destroy();
	end
	if w.idelete then
		w.idelete.destroy();
	end
end

function getBlockFrame(w, sAlign)
	local sFrame;
	if sAlign == "left" then
	 	sFrame = DB.getValue(w.getDatabaseNode(), "frameleft", "");
	else
	 	sFrame = DB.getValue(w.getDatabaseNode(), "frame", "");
	end
	if sFrame == "noframe" then
		sFrame = "";
	end
	return sFrame;
end
function getBlockImageData(w, sAlign)
	local node = w.getDatabaseNode();
	local sAsset = DB.getText(node, "image", "");
	if sAsset == "" then
		sAsset = DB.getText(node, "picture", "")
	end

	local tImageSize = {};
	tImageSize.w, tImageSize.h = Interface.getAssetSize(sAsset);

 	local tLegacySize = ReferenceManualManager.getBlockImageLegacySize(w);
 	if tLegacySize then
 		ReferenceManualManager.applyBlockGraphicSizeMaxHelper(tImageSize, tLegacySize.w, tLegacySize.h);
 	end

	if (sAlign == "left") or (sAlign == "right") then
		applyBlockGraphicSizeMaxHelper(tImageSize, _nMaxColumnImageWidth);
	else
		applyBlockGraphicSizeMaxHelper(tImageSize, _nMaxSingleImageWidth);
	end

	local nScale = tonumber(DB.getValue(node, "scale")) or 100;
	if (nScale < 10) or (nScale > 100) then
		nScale = 100;
	end
	if nScale < 100 then
		tImageSize.w = math.ceil((tImageSize.w * nScale) / 100);
		tImageSize.h = math.ceil((tImageSize.h * nScale) / 100);
	end
	
	if tImageSize.w == 0 then
		tImageSize.w = _nMinImageWidth;
		tImageSize.h = tImageSize.w;
	elseif tImageSize.w < _nMinImageWidth then
		local nScale = tImageSize.w / _nMinImageWidth;
		tImageSize.w = _nMinImageWidth;
		tImageSize.h = math.ceil(tImageSize.h / nScale);
	end

    return sAsset, tImageSize.w, tImageSize.h;
end
function getBlockImageLinkBool(w)
	local sLinkClass, sLinkRecord = DB.getValue(w.getDatabaseNode(), "imagelink", "", "");
	return (sLinkClass ~= "") and (sLinkRecord ~= "");
end
function getBlockImageScale(w)
	local nScale = tonumber(DB.getValue(w.getDatabaseNode(), "scale")) or 100;
	if (nScale < 10) or (nScale > 100) then
		nScale = 100;
	end
	return nScale;
end
function getBlockImageLegacySize(w)
	local tLegacySize = nil;
	local sLegacySize = DB.getValue(w.getDatabaseNode(), "size", "");
	if (sLegacySize ~= "") then
		local sSizeDataW, sSizeDataH = sLegacySize:match("(%d+),(%d+)");
		if sSizeDataW and sSizeDataH then
			tLegacySize = {};
			tLegacySize.w = tonumber(sSizeDataW) or 100;
			tLegacySize.h = tonumber(sSizeDataH) or 100;
		end
	end
	return tLegacySize;
end
function getBlockIconData(w, sAlign)
	local node = w.getDatabaseNode();
	local sAsset = DB.getText(node, "icon", "");

	local tImageSize = { w = 100, h = 100 };

 	local tLegacySize = ReferenceManualManager.getBlockImageLegacySize(w);
 	if tLegacySize then
 		tImageSize.w = tLegacySize.w;
 		tImageSize.h = tLegacySize.h;
 	end

	if (sAlign == "left") or (sAlign == "right") then
		applyBlockGraphicSizeMaxHelper(tImageSize, _nMaxColumnImageWidth);
	else
		applyBlockGraphicSizeMaxHelper(tImageSize, _nMaxSingleImageWidth);
	end
	
    return sAsset, tImageSize.w, tImageSize.h;
end
function applyBlockGraphicSizeMaxHelper(tImageSize, nMaxW, nMaxH)
	if nMaxW and (tImageSize.w > nMaxW) then
		local nScale = tImageSize.w / nMaxW;
		tImageSize.w = nMaxW;
		tImageSize.h = math.ceil(tImageSize.h / nScale);
	end
	if nMaxH and (tImageSize.h > nMaxH) then
		local nScale = tImageSize.h / nMaxH;
		tImageSize.h = nMaxH;
		tImageSize.w = math.ceil(tImageSize.w / nScale);
	end
end

function addBlockHeader(w)
	local sFrame = ReferenceManualManager.getBlockFrame(w);

	local cHeader = w.header;
	if not cHeader then
		cHeader = w.createControl("header_refblock", "header", "text");
	end
	if sFrame ~= "" and Interface.isFrame("referenceblock-" .. sFrame) then
		cHeader.setAnchor("left", "", "left", "absolute", _nHeaderWithFrameOffsetX);
		cHeader.setAnchor("right", "", "right", "absolute", -_nHeaderWithFrameOffsetX);
		cHeader.setAnchor("top", "", "top", "absolute", _nHeaderWithFrameOffsetY);
		cHeader.setFrame("referenceblock-" .. sFrame, _nHeaderFrameOffsetX, _nHeaderFrameOffsetY, _nHeaderFrameOffsetX, _nHeaderFrameOffsetY);
		if not w.spacer then
			local cSpacer = w.createControl("spacer_refblock", "spacer");
			cSpacer.setAnchor("top", "header", "bottom", "absolute", 0);
			cSpacer.setAnchoredHeight(_nHeaderWithFrameOffsetY);
		end
	else
		cHeader.setAnchor("left", "", "left", "absolute", _nHeaderSansFrameOffsetX);
		cHeader.setAnchor("right", "", "right", "absolute", -_nHeaderSansFrameOffsetX);
		cHeader.setAnchor("top", "", "top", "absolute", _nHeaderSansFrameOffsetY);
		cHeader.setFrame("");
		if w.spacer then
			w.spacer.destroy();
		end
	end
end
function addBlockText(w, sAlign, bUseSecondField)
	local sFrame = ReferenceManualManager.getBlockFrame(w, sAlign);

    local sSource;
    if bUseSecondField then
    	sSource = "text2";
    else
    	sSource = "text";
    end

    local sControlName;
    if sAlign == "left" then
    	sControlName = "text_left";
    elseif sAlign == "right" then
    	sControlName = "text_right";
    else
    	sControlName = "text";
    end

    local cText = w[sControlName];
    if not cText then
    	cText = w.createControl("ft_refblock", sControlName, sSource);
    end

    if sFrame ~= "" and Interface.isFrame("referenceblock-" .. sFrame) then
		if sAlign == "left" then
			cText.setAnchor("left", "", "left", "absolute", _nTextWithFrameOffsetX);
			cText.setAnchor("right", "", "center", "absolute", -_nTextWithFrameOffsetX);
		elseif sAlign == "right" then
			cText.setAnchor("left", "", "center", "absolute", _nTextWithFrameOffsetX);
			cText.setAnchor("right", "", "right", "absolute", -_nTextWithFrameOffsetX);
		else
			cText.setAnchor("left", "", "left", "absolute", _nTextWithFrameOffsetX);
			cText.setAnchor("right", "", "right", "absolute", -_nTextWithFrameOffsetX);
		end
		cText.setAnchor("top", "", "top", "absolute", _nTextFrameOffsetY);
		cText.setFrame("referenceblock-" .. sFrame, _nTextFrameOffsetX, _nTextFrameOffsetY, _nTextFrameOffsetX, _nTextFrameOffsetY);

		if sAlign == "left" then
			if not w.spacer_left then
				local cSpacer = w.createControl("spacer_refblock", "spacer_left");
				cSpacer.setAnchor("top", sControlName, "bottom", "absolute", 0);
				cSpacer.setAnchoredHeight(_nTextFrameOffsetY);
			end
		else
			if not w.spacer then
				local cSpacer = w.createControl("spacer_refblock", "spacer");
				cSpacer.setAnchor("top", sControlName, "bottom", "absolute", 0);
				cSpacer.setAnchoredHeight(_nTextFrameOffsetY);
			end
		end
    else
		cText.setAnchor("top", "", "top", "absolute", 0);
		if sAlign == "left" then
			cText.setAnchor("left", "", "left", "absolute", _nTextSansFrameOffsetX);
			cText.setAnchor("right", "", "center", "absolute", -_nTextSansFrameOffsetX);
		elseif sAlign == "right" then
			cText.setAnchor("left", "", "center", "absolute", _nTextSansFrameOffsetX);
			cText.setAnchor("right", "", "right", "absolute", -_nTextSansFrameOffsetX);
		else
			cText.setAnchor("left", "", "left", "absolute", _nTextSansFrameOffsetX);
			cText.setAnchor("right", "", "right", "absolute", -_nTextSansFrameOffsetX);
		end
		cText.setFrame("");
		if sAlign == "left" then
			if w.spacer_left then
				w.spacer_left.destroy();
			end
		else
			if w.spacer then
				w.spacer.destroy();
			end
		end
    end
end
function addBlockImage(w, sAlign)
	local node = w.getDatabaseNode();
	local sAsset, wImage, hImage = ReferenceManualManager.getBlockImageData(w, sAlign);

	local cImage = w.image;
    if not cImage then
    	cImage = w.createControl("image_refblock", "image");
    end

	if sAsset == "" then
		cImage.setIcon("button_ref_block_image");
		cImage.setColor(ReferenceManualManager.getBlockButtonIconColor());
		cImage.setFrame("border");
	else
		cImage.setData(sAsset);
		cImage.setColor("");
		cImage.setFrame("");
	end

    if not w.caption then
    	w.createControl("string_refblock_image_caption", "caption");
    end
end
function addBlockIcon(w, sAlign)
	local node = w.getDatabaseNode();
	local sIcon, wImage, hImage = ReferenceManualManager.getBlockIconData(w, sAlign);

	local cIcon = w.icon;
    if not cIcon then
    	cIcon = w.createControl("icon_refblock", "icon");
    end
	cIcon.setIcon(sIcon);
end

function adjustBlockToImageSize(w)
	if w.image or w.icon then
		local sAlign = DB.getValue(w.getDatabaseNode(), "align", "");
		local tAlign = StringManager.split(sAlign, ",");
		local sGraphicAlign;
		if #tAlign >= 2 then
			sGraphicAlign = tAlign[2];
		end

		local c;
		local tSize = {};
		if w.image then
			c = w.image;
			_, tSize.w, tSize.h = ReferenceManualManager.getBlockImageData(w, sGraphicAlign);
		elseif w.icon then
			c = w.icon;
			_, tSize.w, tSize.h = ReferenceManualManager.getBlockIconData(w, sGraphicAlign);
		end

		c.setAnchoredWidth(tSize.w);
		c.setAnchoredHeight(tSize.h);
		if sGraphicAlign == "left" then
			c.setAnchor("left", "", "left", "absolute", _nGraphicOffsetX);
		elseif sGraphicAlign == "right" then
			c.setAnchor("right", "", "right", "absolute", -_nGraphicOffsetX);
			c.resetAnchor("left");
		else
			c.setAnchor("left", "", "center", "absolute", tonumber("-" .. (tSize.w / 2)));
		end

		if #tAlign >= 2 then
			local nOffset = tSize.w + (2 * _nGraphicOffsetX);
			local sFrame = ReferenceManualManager.getBlockFrame(w, tAlign[1]);
			if sFrame ~= "" then
				nOffset = nOffset + (_nTextWithFrameOffsetX - _nTextSansFrameOffsetX);
			end
			local cText = w.text_left or w.text_right or w.text;
			if tAlign[1] == "left" then
				cText.setAnchor("right", "", "right", "absolute", -nOffset);
			elseif tAlign[1] == "right" then
				cText.setAnchor("left", "", "left", "absolute", nOffset);
			end
		end
	end
end

--
--	Backward compatibility
--

function initPageLegacyText(wPage)
	local node = wPage.getDatabaseNode(); 
	local sOldText = DB.getValue(node, "text");
	if (sOldText or "") == "" then
		return;
	end

    local cText = wPage.text_legacy;
	if not cText then
		cText = wPage.createControl("ft_referencemanualpage_text_legacy", "text_legacy");
	end
end

function migratePageLegacyTextToBlock(wPage)
	local node = wPage.getDatabaseNode(); 
	local sOldText = DB.getValue(node, "text");
	if (sOldText or "") == "" then
		return;
	end

	local bStatic = node.isStatic();
	if bStatic then
		node.setStatic(false);
		wPage.blocks.getDatabaseNode().setStatic(false);
		for _,wChild in ipairs(wPage.blocks.getWindows()) do
			local nodeChild = wChild.getDatabaseNode();
			nodeChild.setStatic(false);
			nodeChild.createChild("order").setStatic(false);
		end
	end

	local tOrderedChildren = ReferenceManualManager.updateOrderValues(wPage.blocks);
	for kChild,wChild in ipairs(tOrderedChildren) do
		wChild.order.setValue(kChild + 1);
	end

	local wNew = wPage.blocks.createWindow();
	wNew.order.setValue(1);
	local nodeBlock = wNew.getDatabaseNode();
	DB.setValue(nodeBlock, "blocktype", "string", "singletext");
	DB.setValue(nodeBlock, "text", "formattedtext", sOldText);
	DB.deleteChild(node, "text");

	if bStatic then
		node.setStatic(true);
		wPage.blocks.getDatabaseNode().setStatic(true);
		for _,wChild in ipairs(wPage.blocks.getWindows()) do
			local nodeChild = wChild.getDatabaseNode();
			nodeChild.setStatic(true);
			nodeChild.createChild("order").setStatic(true);
		end
	end

	ReferenceManualManager.onBlockRebuild(wNew);
	if wPage.text_legacy then
		wPage.text_legacy.destroy();
	end
	wPage.blocks.applySort();
end
