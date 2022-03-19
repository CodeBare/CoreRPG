--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

FT_COL_DEFAULT_LENGTH = 100;

function setItemRecordType(sRecordType)
	local sDisplayClass = LibraryData.getRecordDisplayClass(sRecordType, getDatabaseNode());
	setItemClass(sDisplayClass);
end

function setItemClass(sDisplayClass)
	local node = getDatabaseNode();
	if node and sDisplayClass ~= "" then
		link.setValue(sDisplayClass, node.getPath());
	else
		link.setVisible(false);
		link.setEnabled(false);
	end
end

function setColumnInfo(aColumns, nDefaultColumnWidth)
	for kColumn,rColumn in ipairs(aColumns) do
		local sControlClass;
		if rColumn.sTemplate or "" ~= "" then
			sControlClass = rColumn.sTemplate;
		else
			-- Determine column base control type
			if rColumn.sType == "number" then
				sControlClass = "number_refgroupedlistgroupitem";
			elseif rColumn.sType == "formattedtext" then
				sControlClass = "string_refgroupedlistgroupitem_ft";
			elseif rColumn.sType == "custom" then
				sControlClass = "string_refgroupedlistgroupitem_custom";
			else
				sControlClass = "string_refgroupedlistgroupitem";
			end

			-- Adjust template based on base control type and column attributes
			if sControlClass == "string_refgroupedlistgroupitem" then
				if kColumn == 1 then
					if rColumn.bWrapped then
						sControlClass = "string_refgroupedlistgroupitem_link_wrap";
					else
						sControlClass = "string_refgroupedlistgroupitem_link";
					end
				elseif rColumn.bCentered then
					if rColumn.bWrapped then
						sControlClass = "string_refgroupedlistgroupitem_center";
					else
						sControlClass = "string_refgroupedlistgroupitem_center_wrap";
					end
				else
					if rColumn.bWrapped then
						sControlClass = "string_refgroupedlistgroupitem_wrap";
					end
				end
			elseif sControlClass == "number_refgroupedlistgroupitem" then
				if rColumn.bDisplaySign then
					sControlClass = "number_signed_refgroupedlistgroupitem";
				end
			elseif sControlClass == "string_refgroupedlistgroupitem_ft" then
				if rColumn.bWrapped then
					sControlClass = "string_refgroupedlistgroupitem_ft_wrap";
				end
			elseif sControlClass == "string_refgroupedlistgroupitem_custom" then
				if rColumn.bCentered then
					if rColumn.bWrapped then
						sControlClass = "string_refgroupedlistgroupitem_custom_center";
					else
						sControlClass = "string_refgroupedlistgroupitem_custom_center_wrap";
					end
				else
					if rColumn.bWrapped then
						sControlClass = "string_refgroupedlistgroupitem_custom_wrap";
					end
				end
			end
		end

		local cField = createControl(sControlClass, rColumn.sName);
		if rColumn.sType == "formattedtext" then
			cField.setValue(getFTColumnValue(rColumn.sName) or "");
		elseif rColumn.sType == "custom" then
			cField.setValue(LibraryData.getCustomColumnValue(rColumn.sName, getDatabaseNode()) or "");
		end
		cField.setAnchoredWidth(rColumn.nWidth or nDefaultColumnWidth)
	end
end

function getFTColumnValue(sColumnName, nLength)
	local sText = DB.getText(getDatabaseNode(), sColumnName)
	if (sText or "") == "" then
		return "";
	end
	
	local sTemp = sText:sub(1, math.min(sText:find("\n") or #sText, nLength or FT_COL_DEFAULT_LENGTH));
	if #sTemp < #sText then
		local nSpaceBreak = sTemp:reverse():find("%s");
		if nSpaceBreak then
			sTemp = sTemp:sub(1, #sTemp - nSpaceBreak - 1);
		end
		sTemp = sTemp .. "...";
	end
	return sTemp;
end
