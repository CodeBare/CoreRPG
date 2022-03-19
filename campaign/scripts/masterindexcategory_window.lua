-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function delete()
	windowlist.window.handleCategoryDelete(category.getValue());
end

function handleDrop(draginfo)
	if draginfo.isType("shortcut") then
		local sCategory = category.getValue();
		if sCategory ~= "*" then
			local _,sRecord = draginfo.getShortcutData();
			DB.setCategory(sRecord, sCategory);
		end
		return true;
	end
end

function handleSelect()
	windowlist.window.handleCategorySelect(category.getValue());
end

function handleCategoryNameChange(sOriginal, sNew)
	windowlist.window.handleCategoryNameChange(sOriginal, sNew);
end

function getCategory()
	return category.getValue();
end

function setData(sCategoryKey, sCategoryText, bActive)
	category.setValue(sCategoryKey);
	category_label.initialize(sCategoryText);
	if sCategoryKey ~= "*" then
		category_label.setStateFrame("drophover", "fieldfocusplus", 7, 3, 7, 3);
		category_label.setStateFrame("drophilight", "fieldfocus", 7, 3, 7, 3);
	end
	if bActive then
		setFrame("rowshade");
	end
end

function setActiveByKey(sActiveKey)
	if category.getValue() == sActiveKey then
		setFrame("rowshade");
	else
		setFrame(nil);
	end
end

