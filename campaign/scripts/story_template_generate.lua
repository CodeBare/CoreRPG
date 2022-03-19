-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
local aLiteralReplacements = {};

local tableNameArray = {};
local columnincrementor = 1;
local tablenamekeeper = "PLACEHOLDERNAME";
local RetrievedDataTable = {};
local RetrievedDataTable = { [tablenamekeeper] = {[columnincrementor] = "" } };

--
-- CROSS-TEMPLATE STORAGE VARIABLES
--

local aLiteralReplacementsStore = {};
local columnincrementorStore = 1
local tablenamekeeperStore = "PLACEHOLDERNAME"
local RetrievedDataTableStore = {};
local RetrievedDataTableStore = { [tablenamekeeperStore] = {[columnincrementorStore] = ""} }

--
-- LINK TEXT COLUMN REFERENCE STORAGE VARIABLES
--

local actualLinkText = ""
local linkTextLevelIncrementor = 1
local linkTableNameArray = {}
local linkTextArray = {};
local linkTextArray = { [actualLinkText] = { [linkTextLevelIncrementor] = ""} };
local linkTableNameInstance = 1


local stopIncrementing = false

function onButtonPress()
	local node = window.getDatabaseNode();
	
	aLiteralReplacements = {};

	tableNameArray = {}                               
	columnincrementor = 1 
	tablenamekeeper = "PLACEHOLDERNAME"
	RetrievedDataTable = {}
	RetrievedDataTable = { [tablenamekeeper] = {[columnincrementor] = ""} };

	-- CROSS-TEMPLATE STORAGE VARIABLE RESETS
	aLiteralReplacementsStore = {};
	columnincrementorStore = 1;
	tablenamekeeperStore = "PLACEHOLDERNAME";
	RetrievedDataTableStore = {};
	RetrievedDataTableStore = { [tablenamekeeperStore] = {[columnincrementorStore] = ""} };

    -- LINK TEXT COLUMN REFERENCE STORAGE VARIABLE RESETS
    actualLinkText = ""
    linkTextLevelIncrementor = 1
    linkTableNameArray = {}
    linkTextArray = {};
    linkTextArray = { [actualLinkText] = { [linkTextLevelIncrementor] = ""} };
    stopIncrementing = false
    linkTableNameInstance = 1
	
	sName = DB.getValue(node, "name", "");
	sText = DB.getValue(node, "text", "");

	sName = CrossTemplateWrite(sName);
	sText = CrossTemplateWrite(sText);

	sName = performCalloutStorageReferences(sName);
	sText = performCalloutStorageReferences(sText);

	sName = replaceDateFG(sName);
	sText = replaceDateFG(sText);

	sName = replaceDate(sName);
	sText = replaceDate(sText);

	sName = performInternalCallouts(sName);  
	sText = performInternalCallouts(sText);

	sName = performInternalReferences(sName);
	sText = performInternalReferences(sText);

	sName = performTableLookups(sName); 
	sText = performTableLookups(sText);

	sName = CrossTemplateWrite(sName);
	sText = CrossTemplateWrite(sText);

	sName = performCalloutStorageReferences(sName);
	sText = performCalloutStorageReferences(sText);

	sName = performColumnReferenceLinks(sName)
	sText = performColumnReferenceLinks(sText)

	sName = performLiteralReplacements(sName);              
	sText = performLiteralReplacements(sText);

	sName = resolveInternalReferences(sName);
	sText = resolveInternalReferences(sText);

    sText = performCalloutStorageReferences(sText);  -- Recurse once, standard.
	sText = performCalloutStorageReferences(sText);  -- Done again here on purpose, now that I have received a couple requests for the added functionality.  Please leave both.

    sText = performLinkReplacements(sText);

    sName = performIndefiniteArticles(sName);
	sText = performIndefiniteArticles(sText);

	sName = performCapitalize(sName);
	sText = performCapitalize(sText);

    -- NOTE: Second call to same function is by design
    --		This allows cross-template results to be pulled from within table results retrieved above.
    sText = performCalloutStorageReferences(sText); 

	nodeTarget = DB.createChild("encounter");
	DB.setValue(nodeTarget, "name", "string", sName);
	DB.setValue(nodeTarget, "text", "formattedtext", sText);

	Interface.openWindow("encounter", nodeTarget);
end

function CrossTemplateWrite(sOriginal)
    -- Allows storage of rolled results across/between story templates using
    -- {:TableA:StorageName} Hidden feature: {:?TableA:StorageName} 
    local sOutput = sOriginal
    local internaltext = ""
    local textToReplace = ""
    local hidden = false
        
    for sTableTag, internaltext, seperator, storageName, eTableTag in sOutput:gmatch("()%{%:([^%:]+)(%:)([^%}]+)%}()") do 

        local storageNameNew = storageName
        hidden = false
                            
        if internaltext:match("%?") then
            internaltext = internaltext:gsub("%?", "")
            hidden = true

            textToReplace = "{:?"..internaltext..seperator..storageName.."}"
            textToReplace = textToReplace:gsub("%{", "%%{")
            textToReplace = textToReplace:gsub("%}", "%%}")
            textToReplace = textToReplace:gsub("%?", "%%?")
            textToReplace = textToReplace:gsub("%:", "%%:")
			textToReplace = textToReplace:gsub("%-", "%%%-")
        else
            textToReplace = "{:"..internaltext..seperator..storageName.."}"
            textToReplace = textToReplace:gsub("%{", "%%{")
            textToReplace = textToReplace:gsub("%}", "%%}")
            textToReplace = textToReplace:gsub("%:", "%%:")
			textToReplace = textToReplace:gsub("%-", "%%%-")

        end

        internaltext = "["..internaltext.."]"

        internaltext = performTableLookupsStorage(internaltext, storageNameNew)
        internaltext = internaltext:gsub("(.-)%s*$", "%1")
        StoryTemplateManager.setVariable(storageNameNew, internaltext);
        
        if hidden == true then
            sOutput = sOutput:gsub(textToReplace, " ")
        elseif hidden == false then
            sOutput = sOutput:gsub(textToReplace, internaltext)
        end

        sOutput = sOutput:gsub("&#60;"..storageName.."&#62;", internaltext)
    end

    return sOutput    
end

function performTableLookupsStorage(sOriginal, storageName)
	-- A special version of performtablelookups that stores the column data in a way other
	-- templates can access it via cross-template referencing
	local sOutput = sOriginal;
    local internalRefStorageNM = storageName
    local columnincrementorStore = 1
	
	local sResult = sOutput;
	local aMathResults = {};
	for nStartTag, sTag, nEndTag in sOutput:gmatch("()%[([^%]]+)%]()") do
		local sDiceExpr;
		if sTag:match("x$") then
			sDiceExpr = sTag:sub(1, -2);
		else
			sDiceExpr = sTag;
		end
		if DiceManager.isDiceMathString(sDiceExpr) then
			local nMathResult = DiceManager.evalDiceMathExpression(sDiceExpr);
			if sTag:match("x$") then
				table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = "[" .. nMathResult .. "x]" });
			else
				table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = nMathResult });
			end
		end
	end
	for i = #aMathResults,1,-1 do
		sOutput = sOutput:sub(1, aMathResults[i].nStart - 1) .. aMathResults[i].vResult .. sOutput:sub(aMathResults[i].nEnd);
	end
    	
	local nMult = 1;
	local aLookupResults = {};
	for nStartTag, sTag, nEndTag in sOutput:gmatch("()%[([^%]]+)%]()") do
		local sMult = sTag:match("^(%d+)x$");
		if sMult then
			nMult = math.max(tonumber(sMult), 1);
			table.insert(aLookupResults, { nStart = nStartTag, nEnd = nEndTag, vResult = "" });
		else
			local sTable = sTag;
            local nCol = 0;

            local resultText = ""
            local tablecolumnconcat
            
			local sColumn = sTable:match("|(%d+)$");
			if sColumn then
				sTable = sTable:sub(1, -(#sColumn + 2));
				nCol = tonumber(sColumn) or 0;
			end
			local nodeTable = TableManager.findTable(sTable);

			local aMultLookupResults = {};
			local aMultLookupLinks = {};
			for nCount = 1,nMult do
				local sLocalReplace = "";
				local aLocalLinks = {};
				if nodeTable then
                    bContinue = true;
                
					if internalRefStorageNM ~= nil then
						tablenamekeeperStore = internalRefStorageNM
					end

                    RetrievedDataTableStore[tablenamekeeperStore] = {[columnincrementorStore] = ""}

					local aDice, nMod = TableManager.getTableDice(nodeTable);
					local nRollResults = DiceManager.evalDice(aDice, nMod);
                    local aTableResults = TableManager.getResults(nodeTable, nRollResults, nCol);  
                    local tableNameColumnNumberConcated = ""  
                    
                    local hideAll = false					
					local aOutputResults = {};

					if aTableResults then
						for _,v in ipairs(aTableResults) do
							if (v.sClass or "") ~= "" then
								if v.sClass == "table" then
									local sTableName = DB.getValue(DB.getPath(v.sRecord, "name"), "");
	                                local orderedLinkText = v.sText

	                                if sTableName ~= "" then     
	                                    
	                                    stopIncrementing = false
	                                    local linkTableName = sTableName .. linkTableNameInstance -- THIS ENSURES LINK TEXT IS STORED IN SEPERATE ARRAYS, EVEN IF THEY SHOULD HAVE THE EXACT SAME NAME AS ANOTHER LINK TEXT STRING
	                                    linkTextArray = { [linkTableName] = { [linkTextLevelIncrementor] = ""} };    
	        
	                                    linkTextArray[linkTableName][linkTextLevelIncrementor] = orderedLinkText
	                                    linkTextLevelNumberConcated = linkTableName .. linkTextLevelIncrementor
	                                    linkTableNameArray[linkTextLevelNumberConcated] = linkTextArray[linkTableName][linkTextLevelIncrementor] 
	    
										sTableName = "[" .. sTableName .. "]";
										local sMultTag, nEndMultTag = v.sText:match("%[(%d+x)%]()");
										if nEndMultTag then
	                                        v.sText = v.sText:sub(1, nEndMultTag - 1) .. sTableName .. " " .. v.sText:sub(nEndMultTag);
	                                    else
	                                        local checkHidePhrase = string.upper(v.sText)

	                                        if checkHidePhrase:match("|HIDE AFTER|") or checkHidePhrase:match("|HIDEAFTER|") then  -- HIDE LATTER TEXT PHRASE 
	                                            sTableName = performTableLookupsLinkText(sTableName)
	                                            v.sText = sTableName;

	                                        elseif checkHidePhrase:match("|HIDE BEFORE|") or checkHidePhrase:match("|HIDEBEFORE|") then
	                                            stopIncrementing = true
	                                            sTableName, hideAll = performTableLookupsOG(sTableName)

	                                            if hideAll == true then
	                                                hideAll = false
	                                            else
	                                                linkTextLevelNumberConcated = linkTableName .. linkTextLevelIncrementor
	                                                local subOut = linkTableNameArray[linkTextLevelNumberConcated]

	                                                subOut = subOut:gsub("%[", "%%[")
	                                                subOut = subOut:gsub("%]", "%%]")
	                                                subOut = subOut:gsub("%/", "%%/")
	                                                subOut = subOut:gsub("%,", "%%,")
	                                                subOut = subOut:gsub("%:", "%%:")
	                                                subOut = subOut:gsub("%-", "%%%-")

	                                                v.sText = sTableName:gsub(subOut, "")
	                                            end
	                                        else
	                                            sTableName, hideAll = performTableLookupsOG(sTableName, linkTableName)

	                                            if hideAll == true then
	                                                v.sText = sTableName
	                                                hideAll = false
	                                            else
	                                                v.sText = sTableName .. " " .. v.sText; 

	                                                if stopIncrementing == true then

	                                                    while linkTextLevelIncrementor >= 1 do
	                                                        linkTextLevelNumberConcated = linkTableName .. linkTextLevelIncrementor

	                                                        if linkTableNameArray[linkTextLevelNumberConcated] == nil then -- Check to make sure there isn't a value in the previous position
	                                                            linkTextLevelIncrementor = linkTextLevelIncrementor -1
	                                                            linkTextLevelNumberConcated = linkTableName .. linkTextLevelIncrementor

	                                                            if linkTableNameArray[linkTextLevelNumberConcated] ~= nil then
	                                                                local subOut = linkTableNameArray[linkTextLevelNumberConcated]

	                                                                v.sText = v.sText:gsub(subOut, "")
	                                                                linkTextLevelIncrementor = linkTextLevelIncrementor -1
	                                                            end

	                                                        else
	                                                            local subOut = linkTableNameArray[linkTextLevelNumberConcated]
	            
	                                                            subOut = subOut:gsub("([%-%+%.%?%,%/%:%*%(%)%[%]%^%$%%])", "%%%1") --prep the string/pattern for gsub

	                                                            v.sText = v.sText:gsub(subOut, "")
	                                                            linkTextLevelIncrementor = linkTextLevelIncrementor -1
	                                                        end
	                                                
	                                                    end 

	                                                    linkTextLevelIncrementor = 1
	                                                    stopIncrementing = false
	                                                end
	                                            end
	                                        end

	                                        local linkStorage = v.sText
	    
	                                        RetrievedDataTableStore[tablenamekeeperStore][columnincrementorStore] = linkStorage
	                                        tableNameColumnNumberConcated = tablenamekeeperStore .. columnincrementorStore
	                                        StoryTemplateManager.setVariable(tableNameColumnNumberConcated, RetrievedDataTableStore[tablenamekeeperStore][columnincrementorStore]);
	                                        columnincrementorStore = columnincrementorStore + 1

										end
									end

	                                table.insert(aOutputResults, v.sText);  

								else
	                                local hasAtableInTheRecordName = v.sText:match("%[")

	                                while hasAtableInTheRecordName ~= nil do
	                                    v.sText = performTableLookupsOG(v.sText)
	                                    hasAtableInTheRecordName = v.sText:match("%[")
	                                end 
	                                table.insert(aLocalLinks, { sClass = v.sClass, sRecord = v.sRecord, sText = v.sText}); 

	                                -- THE SECTION BELOW ENABLES STORING LINKS FOR LATER COLUMN REFERENCE
	                                local nClass = v.sClass
	                                local nRecord = v.sRecord
	                                local nText = v.sText
	                                local linkStorage = "||" .. nClass .. "|" .. nRecord .. "|" .. nText .. "||"

	                                RetrievedDataTableStore[tablenamekeeperStore][columnincrementorStore] = linkStorage
	                                tableNameColumnNumberConcated = tablenamekeeperStore .. columnincrementorStore
	                                StoryTemplateManager.setVariable(tableNameColumnNumberConcated, RetrievedDataTableStore[tablenamekeeperStore][columnincrementorStore]);
	                                columnincrementorStore = columnincrementorStore + 1

								end

	                        else

	                            local hasAtableinit = v.sText:match("%[")
	                            while hasAtableinit ~= nil do
	                                v.sText = performTableLookupsOG(v.sText)
	                                hasAtableinit = v.sText:match("%[")
	                            end 

	                            table.insert(aOutputResults, v.sText);

	                            resultText = v.sText

	                            RetrievedDataTableStore[tablenamekeeperStore][columnincrementorStore] = resultText
	                            tableNameColumnNumberConcated = tablenamekeeperStore .. columnincrementorStore
	                            StoryTemplateManager.setVariable(tableNameColumnNumberConcated, RetrievedDataTableStore[tablenamekeeperStore][columnincrementorStore]);
	                            columnincrementorStore = columnincrementorStore + 1

							end

						end
					end
					
					sLocalReplace = table.concat(aOutputResults, " ");
										
				else
					sLocalReplace = sTag;
				end
                               
				-- Recurse to address any new math/table lookups
				sLocalReplace = performTableLookupsOG(sLocalReplace);
				
				table.insert(aMultLookupResults, sLocalReplace);
				for _,vLink in ipairs(aLocalLinks) do
					table.insert(aMultLookupLinks, vLink);
				end

			end

			local sReplace = table.concat(aMultLookupResults, " ");
			if aLiteralReplacementsStore[sTable] then
				table.insert(aLiteralReplacementsStore[sTable], sReplace);
			else
				aLiteralReplacementsStore[sTable] = { sReplace };
			end

			for _,vLink in ipairs(aMultLookupLinks) do
				sReplace = sReplace .. "||" .. vLink.sClass .. "|" .. vLink.sRecord .. "|" .. vLink.sText .. "||";
			end
			
			table.insert(aLookupResults, { nStart = nStartTag, nEnd = nEndTag, vResult = sReplace });
			nMult = 1;
		end
		
	end
    
	for i = #aLookupResults,1,-1 do
		sOutput = sOutput:sub(1, aLookupResults[i].nStart - 1) .. aLookupResults[i].vResult .. sOutput:sub(aLookupResults[i].nEnd);
	end
	
	return sOutput;
end

function performCalloutStorageReferences(sOriginal)
    -- Allows column referencing of Cross-Template Stored Data with
    -- {#StorageName|3#} and complete result referencing with {StorageName}
    local sOutput = sOriginal
    local columnreferencetag = ""
	local columnerrormessage = "NO COLUMN NUMBER INPUT"

    for startag, secondTag, actualTableName, colnumber, thirdTag, endtag in string.gmatch(sOutput, "(%{)(%#)([^%|]+)%|(%d+)%#(%})") do
        columnreferencetag = "{#"..actualTableName.."|"..colnumber.."#}"
        actualTableName = actualTableName..colnumber

        columnreferencetag = columnreferencetag:gsub("%|", "%%|")
        columnreferencetag = columnreferencetag:gsub("%{", "%%{")
        columnreferencetag = columnreferencetag:gsub("%}", "%%}")
        columnreferencetag = columnreferencetag:gsub("%#", "%%#")
		columnreferencetag = columnreferencetag:gsub("%-", "%%%-") -- added for hyphen support

        if not colnumber or (colnumber == 0) then
            sOutput = sOutput:gsub(columnreferencetag, columnerrormessage);
        else
            local v = StoryTemplateManager.getVariable(actualTableName);
            if v then
                sOutput = sOutput:gsub(columnreferencetag, v);
            else
                ChatManager.SystemMessage("There was no data stored inside the StoryTemplateManager variable for "..actualTableName)
            end
        end
    end

    for sTag, internaltext, eTag in sOutput:gmatch("()%{([^%}]+)%}()") do

        local replaceText = "%{"..internaltext.."%}"

        internaltext = internaltext

        local v = StoryTemplateManager.getVariable(internaltext);
        if v then 
            sOutput = sOutput:gsub(replaceText, v);
        else
            sOutput = sOutput:gsub(replaceText, "No Stored Data");
        end
    end
    
    return sOutput
end

function replaceDateFG(sOriginal)
    -- Replace [FGDate:FORMAT] with the current date from the game.
    -- Ex: Sunday, Nov 2nd
    local sOutput = sOriginal
    local date = ""
    local correctFormat = false

	for stag, internalText, seperator, format, endTag, etag in sOriginal:gmatch("()(%[FGDate)(%:)([^%]]+)(%])()") do
       
        local internalText = internalText..seperator..format..endTag

		internalText = internalText:gsub("([%-%+%.%?%,%/%:%*%(%)%[%]%^%$%%])", "%%%1") -- updated for hyphen support
        
        local nDays = DB.getValue("calendar.current.day");
        local nMonths = DB.getValue("calendar.current.month");
        local nYears = DB.getValue("calendar.current.year");
        local nEpoch = DB.getValue("calendar.current.epoch");

        if nDays == nil or nMonths == nil or nYears == nil then
            ChatManager.SystemMessage("You NEED to load a calendar module before trying to use a date from Fantasy Grounds!")
            date = "No Calendar Mod Loaded"
        else
            local monthName = CalendarManager.getMonthName(nMonths);
            local nWeekDay = CalendarManager.getLunarDay(nYears, nMonths, nDays);
            local sWeekDay = CalendarManager.getLunarDayName(nWeekDay);
            local sSuffix = Interface.getString("message_calendardaysuffix" .. (nDays % 10));
            
            local dayWithSuffix = tostring(nDays) .. (sSuffix or "");
            local dayName = sWeekDay
            local fullmonth = monthName
            local smallmonth = nMonths -- mmm (smallmonth, ie: Jan, Feb, etc) only works with the Gregorian Calendar
            local shortYear = 0
            local sYears = tonumber(nYears)
    
            if sYears >= 1000 then
                shortYear = string.sub(sYears, 3)
            elseif sYears >= 100 then
                shortYear = string.sub(sYears, 2)
            else 
                shortYear = sYears
            end

            if nMonths == 1 then -- This allows the smallmonth function "mmm" to still work if the Gregorian Calendar is in use
                smallmonth = "Jan"
            elseif nMonths == 2 then
                smallmonth = "Feb"
            elseif nMonths == 3 then
                smallmonth = "Mar"
            elseif nMonths == 4 then
                smallmonth = "Apr"
            elseif nMonths == 5 then
                smallmonth = "May"
            elseif nMonths == 6 then
                smallmonth = "Jun"
            elseif nMonths == 7 then
                smallmonth = "Jul"
            elseif nMonths == 8 then
                smallmonth = "Aug"
            elseif nMonths == 9 then
                smallmonth = "Sep"
            elseif nMonths == 10 then
                smallmonth = "Oct"
            elseif nMonths == 11 then
                smallmonth = "Nov"
            elseif nMonths == 12 then
                smallmonth = "Dec"
            end


            if format:find("mm", 1, true) or format:find("month", 1, true) or format:find("dd", 1, true) or format:find("day", 1, true) or format:find("yy", 1, true) or format:find("epoch", 1, true) then 
                correctFormat = true 
            end

            if correctFormat == false then
                date = "Date format incorrect, see console for correct formats"
                ChatManager.SystemMessage("Proper date call syntax:  [FGDate:FORMAT] Correct Date format examples:  \"yyyy\", \"yy\", \"month\", \"mm\", \"mmm\", \"day\", \"dd\", \"ddd\" (adds a day suffix ie 1st, 2nd, 3rd etc.), or \"epoch\". Use in any combination!  NOTE: \"mmm\" only works with the Gregorian Calendar")
            else
                format = format:gsub("mmm", smallmonth)
                format = format:gsub("mm", nMonths)
                format = format:gsub("month", fullmonth)  
                format = format:gsub("ddd", dayWithSuffix)
                format = format:gsub("dd", nDays)
                format = format:gsub("day", dayName)
                format = format:gsub("yyyy", nYears)
                format = format:gsub("yy", shortYear)

                if nEpoch ~= nil then
                    format = format:gsub("epoch", nEpoch)
                end

                date = format
            end
            
        end

		sOutput = sOutput:gsub(internalText, date)
	end

	return sOutput
end

function replaceDate(sOriginal)
    -- Replace [Date:FORMAT] with the current date from the PC clock.
    -- Ex: Sunday, Nov 2nd
    local sOutput = sOriginal
    local date = ""
    local correctFormat = false
    local numericalmonth = os.date("%m")
    local smallmonth = os.date("%b")
    local fullmonth = os.date("%B")
    local day = os.date("%d")
    local fullday = os.date("%A")
    local year = os.date("%Y")
    local shortYear    
    local sYear = tonumber(year)

    if sYear >= 1000 then
        shortYear = string.sub(sYear, 3)
    elseif year >= 100 then
        shortYear = string.sub(sYear, 2)
    else 
        shortYear = sYear
    end

	for stag, internalText, seperator, format, endTag, etag in sOriginal:gmatch("()(%[Date)(%:)([^%]]+)(%])()") do
        
        local internalText = internalText..seperator..format..endTag

		internalText = internalText:gsub("([%-%+%.%?%,%/%:%*%(%)%[%]%^%$%%])", "%%%1") -- updated for hyphen support

        if format:find("mm", 1, true) or format:find("mmm", 1, true) or format:find("month", 1, true) or format:find("dd", 1, true) or format:find("day", 1, true) or format:find("yyyy", 1, true) or format:find("year", 1, true) or format:find("oldschool", 1, true) then 
            correctFormat = true 
        end

        if correctFormat == false then
            date = "Date format incorrect, see console for correct formats"
            ChatManager.SystemMessage("Proper date call syntax:  [Date:FORMAT] Correct Date format examples:   \"yyyy\", \"yy\", \"month\", \"mm\", \"mmm\", \"day\", \"dd\", \"ddd\" (adds a day suffix ie 1st, 2nd, 3rd etc.), \"epoch\", or \"oldschool\". Use in any combination!")
        else

            if format == "oldschool" then
                date = os.date("%A, the %dof %B, in the year of our Lord: Two-Thousand and %y")
                local stags, words, changedays, words2, changeyear, etags = date:match("()([^%d]+)([^%a]+)([^%d]+)([%d]+)()") 
    
                local swapdays = changedays
                swapdays = datehelper(swapdays)
    
                if changeyear == "20" then
                    changeyear = "Twenty"
                elseif changeyear == "21" then
                    changeyear = "Twenty One"
                elseif changeyear == "22" then
                    changeyear = "Twenty Two"
                elseif changeyear == "23" then
                    changeyear = "Twenty Three"
                elseif changeyear == "24" then
                    changeyear = "Twenty Four"
                elseif changeyear == "25" then
                    changeyear = "Twenty Five"
                elseif changeyear == "26" then
                    changeyear = "Twenty Six"
                elseif changeyear == "27" then
                    changeyear = "Twenty Seven"
                elseif changeyear == "28" then
                    changeyear = "Twenty Eight"
                elseif changeyear == "29" then
                    changeyear = "Twenty Nine"
                end

                date = words..swapdays..words2..changeyear  
            else
                date = format

                date = date:gsub("mmm", smallmonth)
                date = date:gsub("mm", numericalmonth)
                date = date:gsub("month", fullmonth)
                date = date:gsub("ddd", datehelper(day))
                date = date:gsub("dd", day)
                date = date:gsub("day", fullday)
                date = date:gsub("yyyy", year)
                date = date:gsub("yy", shortYear)
                date = date:gsub("epoch", "AD")

            end

		sOutput = sOutput:gsub(internalText, date)
        end
        
	end

	return sOutput
end

function datehelper(sOriginal)
    -- This helps make the results in the [Date:FORMAT] and [FGDate:FORMAT] look right
    local date = sOriginal

    if date:match(10) or date:match(20) or date:match(30) then
        -- then do nothing.  Unless:
    elseif date:match(0) then
        date = date:gsub(0, "")
    end

    for day in date:gmatch("%d+") do
        day = tonumber(day)
        if day == 21 or day == 31 then
            date = date.."st "
        elseif day == 22 or day == 32 then
            date = date.."nd "
        elseif day == 23 then
            date = date.."rd "
        elseif day > 3 then
            date = date.."th "
        elseif  day > 2 then
            date = date.."rd "
        elseif day > 1 then
            date = date.."nd "
        elseif day == 1 then
            date = date.."st "
        end
    end

    return date
end

function performInternalCallouts(sOriginal)
    -- This rolls table callouts inside of table callouts.
    -- ie: [:a [tableA] and [tableB] inside a parent:StorageName]
    -- Hidden feature = [:?[TableA] TableB:StorageName]
	-- Also handles internal callouts alongside internal references now ie: [<Reference> [Callout]]
	-- Also handles custom named internal callouts alongside internal references now ie: [:<Reference> [Callout]:Custom Name]

	local sOutput = sOriginal
	local internaltext = ""
    local textToReplace = ""
    local hidden = false

	local internaltabletext = ""
	local textInReference = ""
	
    for sTableTag, internaltext, seperator, storageName, eTableTag in sOutput:gmatch("()%[%:([^%:]+)(%:)([^%]]+)%]()") do 
        -- Correct usage: [:Text [tableA] text:StorageName] add a "?" after the first ":" to hide the result
        -- the StorageName can be used for <StorageName> references and even #StorageName|1# column references!

        if internaltext:match("%<") or internaltext:match("&#60;") or internaltext:match("&LT;") or internaltext:match("&lt;") or internaltext:match("&#35;")  or internaltext:match("%#") then --This was beefed up because it was missing internal references sometimes (rarely, but now never.  Works with FGC now too)
            -- If matched here, then quickly resolve internal callouts and skip the rest since there is a <reference> in here
            -- We will resolve internal REFERENCES later, in a pair of totally seperate functions

			if internaltext:match("%[") then -- This checks to see if there were internal callouts alongside an internal reference, and resolves those ahead of time if so
				for sTextTag, internaltabletext, eTextTag in internaltext:gmatch("()%[([^%]]+)%]()") do 
					local textInternalToReplace = internaltext
					textInternalToReplace = textInternalToReplace:gsub("([%-%+%.%?%,%/%:%<%>%#%*%(%)%[%]%^%$%%])", "%%%1") -- updated for hyphen support

					textToReplace = "%[" .. internaltabletext .. "%]"
					textInReference = internaltabletext
					internaltabletext = "[" .. internaltabletext .. "]"

					internaltabletext = performTableLookupsOG(internaltabletext)
					sOutput = sOutput:gsub(textToReplace, internaltabletext)
					sOutput = sOutput:gsub("&#60;"..textInReference.."&#62;", internaltabletext)
				end
			end

        else
            local storageNameNew = storageName
            hidden = false
			
            textToReplace = "[:"..internaltext..seperator..storageNameNew.."]"
            textToReplace = textToReplace:gsub("%[", "%%[")
            textToReplace = textToReplace:gsub("%]", "%%]")
			textToReplace = textToReplace:gsub("%-", "%%%-")
                    
            if internaltext:match("%?") then
                internaltext = internaltext:gsub("%?", "")  
                hidden = true

                textToReplace = "[:?"..internaltext..seperator..storageNameNew.."]" 
                textToReplace = textToReplace:gsub("%[", "%%[")
                textToReplace = textToReplace:gsub("%]", "%%]")
                textToReplace = textToReplace:gsub("%?", "%%?") 
				textToReplace = textToReplace:gsub("%-", "%%%-")
            end

            internaltext = performTableLookupsOG(internaltext)
            internaltext = "["..internaltext.."]"
            internaltext = performTableLookups(internaltext, storageNameNew)
            
            if hidden == true then
                sOutput = sOutput:gsub(textToReplace, " ")
            elseif hidden == false then
                sOutput = sOutput:gsub(textToReplace, internaltext)
            end

            sOutput = sOutput:gsub("&#60;"..storageNameNew.."&#62;", internaltext)
        end
	end

	return sOutput
end

function performInternalReferences(sOriginal)
    -- This allows table <references> inside of table callouts. 
    -- ie: [a <tableA> and <tableB> inside a parent] (now supports Custom Naming and the Hidden feature) 
    -- This is part one of a two-part process.

	local sOutput = sOriginal
	local internaltext = ""
    local textToReplace = ""
    local frontag = "|!!|!|" -- The pattern matching was a little finnicky until I placed these in variables, now it works just fine.
    local backtag = "|!|!!|"

    for sTableTag, internaltext, eTableTag in sOutput:gmatch("()%[([^%]]+)%]()") do 
        -- Correct usage: [Text <reference> text]
        -- This can be used with <references> and even #storagename|1# column references!

        if internaltext:match("&lt;") or internaltext:match("%#") or internaltext:match("&#60;") or internaltext:match("&LT;") or internaltext:match("&#35;") or internaltext:match("%<") then  -- Made more robust to not miss a beat.  This line works with FGC now too.

            textToReplace = "["..internaltext.."]"
		    textToReplace = textToReplace:gsub("([%-%+%.%?%,%/%:%<%>%#%*%(%)%[%]%^%$%%])", "%%%1") -- Updated for hyphen support
            
            internaltext = frontag..internaltext..backtag  -- Changed to reflect the new variables added above, which makes the patterns stable
            -- In this way, the other functions will resolve the internal
            -- references as normal, and later we will swap out our unique
            -- tags with [brackets] again for the final roll
			
		    sOutput = sOutput:gsub(textToReplace, internaltext)
		end		
	end

	return sOutput
end

function performTableLookups(sOriginal, storageName)
    -- Look for table roll expressions.
    -- This Has been Extensively moddified to do the column data storage as well as link storage and adding link text display options

	local sOutput = sOriginal;
    local internalCallStorageNM = storageName
    local hidden = false		
	local sResult = sOutput;
	local aMathResults = {};

	for nStartTag, sTag, nEndTag in sOutput:gmatch("()%[([^%]]+)%]()") do
		local sDiceExpr;
		if sTag:match("x$") then
			sDiceExpr = sTag:sub(1, -2);
		else
			sDiceExpr = sTag;
		end
		if DiceManager.isDiceMathString(sDiceExpr) then
			local nMathResult = DiceManager.evalDiceMathExpression(sDiceExpr);
			if sTag:match("x$") then
				table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = "[" .. nMathResult .. "x]" });
			else
				table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = nMathResult });
			end
		end
	end

	for i = #aMathResults,1,-1 do
		sOutput = sOutput:sub(1, aMathResults[i].nStart - 1) .. aMathResults[i].vResult .. sOutput:sub(aMathResults[i].nEnd);
	end
    
    local tablefinished = true
	local nMult = 1;
	local aLookupResults = {};

	for nStartTag, sTag, nEndTag in sOutput:gmatch("()%[([^%]]+)%]()") do
		local sMult = sTag:match("^(%d+)x$");
		if sMult then
			nMult = math.max(tonumber(sMult), 1);
			table.insert(aLookupResults, { nStart = nStartTag, nEnd = nEndTag, vResult = "" });
		else
            local sTable = sTag;            
            hidden = false
                        
            if sTable:match("%?") then
                sTable = sTable:gsub("%?", "")
                hidden = true
            end

            local nCol = 0;
            local resultText = ""
            local tablecolumnconcat            
			local sColumn = sTable:match("|(%d+)$");

			if sColumn then
				sTable = sTable:sub(1, -(#sColumn + 2));
				nCol = tonumber(sColumn) or 0;
			end

			local nodeTable = TableManager.findTable(sTable);
			local aMultLookupResults = {};
			local aMultLookupLinks = {};

			for nCount = 1,nMult do
				local sLocalReplace = "";
				local aLocalLinks = {};

				if nodeTable then
                    bContinue = true;
                
                    if tablefinished == true then
						tablenamekeeper = sTable
						tablefinished = false
					end

					if internalCallStorageNM ~= nil then
						tablenamekeeper = internalCallStorageNM
						tablefinished = false
					end

                    if tablenamekeeper == sTable then
                        tablecolumnconcat = tablenamekeeper .. 1
                        if tableNameArray[tablecolumnconcat] ~= nil then
                            local i = 1
                            while tableNameArray[tablecolumnconcat] ~= nil do
                                tablecolumnconcat = tablenamekeeper .. i
                                if tableNameArray[tablecolumnconcat] == nil then
                                    columnincrementor = i
                                    RetrievedDataTable[tablenamekeeper] = {[columnincrementor] = ""}
                                    else
                                    i = i + 1
                                end
                            end
                        else
                            columnincrementor = 1
                            RetrievedDataTable[tablenamekeeper] = {[columnincrementor] = ""}
                        end
                    elseif tablenamekeeper ~= sTable then
                        if tablefinished == true then
                            tablenamekeeper = sTable
                            tablefinished = false
                        end

                        tablecolumnconcat = tablenamekeeper .. 1
                        -- NOTE: tableNameArray[tablecolumnconcat] is a facsimile
                        -- of our final storage array.  With it, we can peek at
                        -- already stored column data

                        if tableNameArray[tablecolumnconcat] ~= nil then
                            local i = 1
                            while tableNameArray[tablecolumnconcat] ~= nil do
                                tablecolumnconcat = tablenamekeeper .. i
                                if tableNameArray[tablecolumnconcat] == nil then
                                    columnincrementor = i
                                    RetrievedDataTable[tablenamekeeper] = {[columnincrementor] = ""}
                                else
                                    i = i + 1
                                end
                            end
                        else
                            columnincrementor = 1
                            RetrievedDataTable[tablenamekeeper] = {[columnincrementor] = ""}
                        end
                    end

					local aDice, nMod = TableManager.getTableDice(nodeTable);
					local nRollResults = DiceManager.evalDice(aDice, nMod);
                    local aTableResults = TableManager.getResults(nodeTable, nRollResults, nCol);
					
					local aOutputResults = {};
                    local hideAll = false

					if aTableResults then
						for _,v in ipairs(aTableResults) do
	                        local tableNameColumnNumberConcated = ""

							if (v.sClass or "") ~= "" then -- This Section now modified to allow column referencing of link records/tables
								if v.sClass == "table" then
									local sTableName = DB.getValue(DB.getPath(v.sRecord, "name"), "");
	                                local orderedLinkText = v.sText

	                                if sTableName ~= "" then

	                                    stopIncrementing = false
	                                    local linkTableName = sTableName .. linkTableNameInstance -- THIS ENSURES LINK TEXT IS STORED IN SEPERATE ARRAYS, EVEN IF THEY SHOULD HAVE THE EXACT SAME NAME AS ANOTHER LINK TEXT STRING
	                                    linkTextArray = { [linkTableName] = { [linkTextLevelIncrementor] = ""} };    
	        
	                                    linkTextArray[linkTableName][linkTextLevelIncrementor] = orderedLinkText
	                                    linkTextLevelNumberConcated = linkTableName .. linkTextLevelIncrementor
	                                    linkTableNameArray[linkTextLevelNumberConcated] = linkTextArray[linkTableName][linkTextLevelIncrementor] 
	    
										sTableName = "[" .. sTableName .. "]";
										local sMultTag, nEndMultTag = v.sText:match("%[(%d+x)%]()");
										if nEndMultTag then
	                                        v.sText = v.sText:sub(1, nEndMultTag - 1) .. sTableName .. " " .. v.sText:sub(nEndMultTag);
	                                    else
	                                        local checkHidePhrase = string.upper(v.sText)

	                                        if checkHidePhrase:match("|HIDE AFTER|") or checkHidePhrase:match("|HIDEAFTER|") then  -- HIDE LATTER TEXT PHRASE 
	                                            sTableName = performTableLookupsLinkText(sTableName)
	                                            v.sText = sTableName;

	                                        elseif checkHidePhrase:match("|HIDE BEFORE|") or checkHidePhrase:match("|HIDEBEFORE|") then
	                                            stopIncrementing = true
	                                            sTableName, hideAll = performTableLookupsOG(sTableName)

	                                            if hideAll == true then
	                                                hideAll = false
	                                            else
	                                                linkTextLevelNumberConcated = linkTableName .. linkTextLevelIncrementor
	                                                local subOut = linkTableNameArray[linkTextLevelNumberConcated]

	                                                subOut = subOut:gsub("([%-%+%.%?%,%/%:%*%(%)%[%]%^%$%%])", "%%%1") -- Updated for hyphen support

	                                                v.sText = sTableName:gsub(subOut, "")
	                                            end
	                                        else
	                                            sTableName, hideAll = performTableLookupsOG(sTableName, linkTableName)

	                                            if hideAll == true then
	                                                v.sText = sTableName
	                                                hideAll = false
	                                            else
	                                                v.sText = sTableName .. " " .. v.sText; 

	                                                if stopIncrementing == true then

	                                                    while linkTextLevelIncrementor >= 1 do
	                                                        linkTextLevelNumberConcated = linkTableName .. linkTextLevelIncrementor

	                                                        if linkTableNameArray[linkTextLevelNumberConcated] == nil then
	                                                            linkTextLevelIncrementor = linkTextLevelIncrementor -1
	                                                            linkTextLevelNumberConcated = linkTableName .. linkTextLevelIncrementor
	                                                            if linkTableNameArray[linkTextLevelNumberConcated] ~= nil then
	                                                                local subOut = linkTableNameArray[linkTextLevelNumberConcated]

	                                                                v.sText = v.sText:gsub(subOut, "")
	                                                                linkTextLevelIncrementor = linkTextLevelIncrementor -1
	                                                            end

	                                                        else
	                                                            local subOut = linkTableNameArray[linkTextLevelNumberConcated]
	            
	                                                            subOut = subOut:gsub("([%-%+%.%?%,%/%:%*%(%)%[%]%^%$%%])", "%%%1") -- Updated for hyphen support

	                                                            v.sText = v.sText:gsub(subOut, "")
	                                                            linkTextLevelIncrementor = linkTextLevelIncrementor -1
	                                                        end
	                                                    end 

	                                                    linkTextLevelIncrementor = 1
	                                                    stopIncrementing = false
	                                                end
	                                            end
	                                        end

	                                        local linkStorage = v.sText
	    
	                                        RetrievedDataTable[tablenamekeeper][columnincrementor] = linkStorage
	                                        tableNameColumnNumberConcated = tablenamekeeper .. columnincrementor
	                                        tableNameArray[tableNameColumnNumberConcated] = RetrievedDataTable[tablenamekeeper][columnincrementor]
	                                        columnincrementor = columnincrementor + 1
										end
									end

	                                table.insert(aOutputResults, v.sText);         
	                        
								else
	                                local hasAtableInTheRecordName = v.sText:match("%[")

	                                while hasAtableInTheRecordName ~= nil do
	                                    v.sText = performTableLookupsOG(v.sText)
	                                    hasAtableInTheRecordName = v.sText:match("%[")
	                                end 

	                                table.insert(aLocalLinks, { sClass = v.sClass, sRecord = v.sRecord, sText = v.sText});
	                                
	                                -- THE SECTION BELOW ALLOWS STORAGE OF LINKS FOR COLUMN REFERENCE
	                                local nClass = v.sClass
	                                local nRecord = v.sRecord
	                                local nText = v.sText
	                                local linkStorage = "||" .. nClass .. "|" .. nRecord .. "|" .. nText .. "||"

	                                RetrievedDataTable[tablenamekeeper][columnincrementor] = linkStorage
	                                tableNameColumnNumberConcated = tablenamekeeper .. columnincrementor
	                                tableNameArray[tableNameColumnNumberConcated] = RetrievedDataTable[tablenamekeeper][columnincrementor]
	                                columnincrementor = columnincrementor + 1
								end

	                            linkTableNameInstance = linkTableNameInstance + 1
	                        else

	                            local hasAtableinit = v.sText:match("%[")
	                            while hasAtableinit ~= nil do
	                                v.sText = performTableLookupsOG(v.sText)
	                                hasAtableinit = v.sText:match("%[")
	                            end 

	                            if hidden == false then
	                                table.insert(aOutputResults, v.sText);
	                            end

	                            resultText = v.sText
	                            RetrievedDataTable[tablenamekeeper][columnincrementor] = resultText
	                            tableNameColumnNumberConcated = tablenamekeeper .. columnincrementor
	                            tableNameArray[tableNameColumnNumberConcated] = RetrievedDataTable[tablenamekeeper][columnincrementor]

	                            columnincrementor = columnincrementor + 1
							end

						end
					end
					
					sLocalReplace = table.concat(aOutputResults, " ");
                    tablefinished = true
										
				else
					sLocalReplace = sTag;
				end
                               
				-- Recurse to address any new math/table lookups
				sLocalReplace = performTableLookupsOG(sLocalReplace);
				
				table.insert(aMultLookupResults, sLocalReplace);
				for _,vLink in ipairs(aLocalLinks) do
					table.insert(aMultLookupLinks, vLink);
				end

			end

			local sReplace = table.concat(aMultLookupResults, " ");
			if aLiteralReplacements[sTable] then
				table.insert(aLiteralReplacements[sTable], sReplace);
			else
				aLiteralReplacements[sTable] = { sReplace };
			end

			for _,vLink in ipairs(aMultLookupLinks) do
				sReplace = sReplace .. "||" .. vLink.sClass .. "|" .. vLink.sRecord .. "|" .. vLink.sText .. "||";
			end
			
			table.insert(aLookupResults, { nStart = nStartTag, nEnd = nEndTag, vResult = sReplace });
			nMult = 1;
		end
		
	end

	for i = #aLookupResults,1,-1 do
		sOutput = sOutput:sub(1, aLookupResults[i].nStart - 1) .. aLookupResults[i].vResult .. sOutput:sub(aLookupResults[i].nEnd);
	end
	
	return sOutput;
end

function performTableLookupsOG(sOriginal, priorLinkTableName)
    -- Look for table roll expressions.  
    -- Added functionality for column referencing with links.  
    -- Now returns multiple arguments.

    local sOutput = sOriginal;
    local hideAll = false
	local sResult = sOutput;
	local aMathResults = {};
    local linkTableName = ""

    if priorLinkTableName ~= nil then
        linkTableName = priorLinkTableName
    else linkTableName = ""
    end

	for nStartTag, sTag, nEndTag in sOutput:gmatch("()%[([^%]]+)%]()") do
		local sDiceExpr;
		if sTag:match("x$") then
			sDiceExpr = sTag:sub(1, -2);
		else
			sDiceExpr = sTag;
		end
		if DiceManager.isDiceMathString(sDiceExpr) then
			local nMathResult = DiceManager.evalDiceMathExpression(sDiceExpr);
			if sTag:match("x$") then
				table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = "[" .. nMathResult .. "x]" });
			else
				table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = nMathResult });
			end
		end
	end
	for i = #aMathResults,1,-1 do
		sOutput = sOutput:sub(1, aMathResults[i].nStart - 1) .. aMathResults[i].vResult .. sOutput:sub(aMathResults[i].nEnd);
	end
	
	local nMult = 1;
	local aLookupResults = {};
	for nStartTag, sTag, nEndTag in sOutput:gmatch("()%[([^%]]+)%]()") do
		local sMult = sTag:match("^(%d+)x$");
		if sMult then
			nMult = math.max(tonumber(sMult), 1);
			table.insert(aLookupResults, { nStart = nStartTag, nEnd = nEndTag, vResult = "" });
		else
			local sTable = sTag;
			local nCol = 0;
			
			local sColumn = sTable:match("|(%d+)$");
			if sColumn then
				sTable = sTable:sub(1, -(#sColumn + 2));
				nCol = tonumber(sColumn) or 0;
			end
			local nodeTable = TableManager.findTable(sTable);

			local aMultLookupResults = {};
			local aMultLookupLinks = {};
			for nCount = 1,nMult do
				local sLocalReplace = "";
				local aLocalLinks = {};
				if nodeTable then
					bContinue = true;
					
					local aDice, nMod = TableManager.getTableDice(nodeTable);
					local nRollResults = DiceManager.evalDice(aDice, nMod);
					local aTableResults = TableManager.getResults(nodeTable, nRollResults, nCol);
					
					local aOutputResults = {};
					if aTableResults then
						for _,v in ipairs(aTableResults) do

							if (v.sClass or "") ~= "" then -- This Section now modified to allow column referencing of link records/tables
								if v.sClass == "table" then
									local sTableName = DB.getValue(DB.getPath(v.sRecord, "name"), "");
									if sTableName ~= "" then
										sTableName = "[" .. sTableName .. "]";
										local sMultTag, nEndMultTag = v.sText:match("%[(%d+x)%]()");
										if nEndMultTag then
											v.sText = v.sText:sub(1, nEndMultTag - 1) .. sTableName .. " " .. v.sText:sub(nEndMultTag);
	                                    else 
	                                        local checkHidePhrase = string.upper(v.sText)

	                                            if stopIncrementing == true then
	                                                orderedLinkTextOG = ""
	                                            else
	                                                orderedLinkTextOG = v.sText

	                                                linkTextLevelIncrementor = linkTextLevelIncrementor +1
	                                                linkTextArray = { [linkTableName] = { [linkTextLevelIncrementor] = ""} };
	                                                linkTextArray[linkTableName][linkTextLevelIncrementor] = orderedLinkTextOG
	                                                linkTextLevelNumberConcated = linkTableName .. linkTextLevelIncrementor
	                                                linkTableNameArray[linkTextLevelNumberConcated] = linkTextArray[linkTableName][linkTextLevelIncrementor] 
	                                            end          

	                                        if checkHidePhrase:match("|HIDE ALL|") or checkHidePhrase:match("|HIDEALL|") then  -- HERE IS THE HIDE ALL TEXT PHRASE  
	                                            hideAll = true
	                                            sTableName = performTableLookupsLinkText(sTableName)
	                                            v.sText = sTableName;

	                                        elseif checkHidePhrase:match("|HIDE BEFORE|") or checkHidePhrase:match("|HIDEBEFORE|") then  -- HERE IS THE HIDE PRIOR TEXT PHRASE  
	                                            stopIncrementing = true
	                                            sTableName, hideAll = performTableLookupsOG(sTableName, linkTableName)

	                                            if hideAll == true then
	                                                v.sText = sTableName
	                                            else
	                                                v.sText = sTableName .. " " .. v.sText;                                            
	                                            end
	                                        
	                                        elseif checkHidePhrase:match("|HIDE AFTER|") or checkHidePhrase:match("|HIDEAFTER|") then-- HERE IS THE HIDE LATTER TEXT PHRASE
	                                            sTableName = performTableLookupsLinkText(sTableName)
	                                            v.sText = sTableName;
	                                        else
	                                            local isHidden = false
	                                            sTableName, hideAll = performTableLookupsOG(sTableName, linkTableName)

	                                            if hideAll == true then
	                                                v.sText = sTableName
	                                            else
	                                                v.sText = sTableName .. " " .. v.sText;
	                                            end

	                                        end

										end
	                                end
									table.insert(aOutputResults, v.sText);
								else
									table.insert(aLocalLinks, { sClass = v.sClass, sRecord = v.sRecord, sText = v.sText });
								end
	                        else

								table.insert(aOutputResults, v.sText);
							end
						end
					end
                    
                    sLocalReplace = table.concat(aOutputResults, " ");
                    
				else
					sLocalReplace = sTag;
				end
				
				-- Recurse to address any new math/table lookups
				sLocalReplace = performTableLookupsOG(sLocalReplace, linkTableName);
				
				table.insert(aMultLookupResults, sLocalReplace);
				for _,vLink in ipairs(aLocalLinks) do
					table.insert(aMultLookupLinks, vLink);
				end
			end

			local sReplace = table.concat(aMultLookupResults, " ");
			if aLiteralReplacements[sTable] then
				table.insert(aLiteralReplacements[sTable], sReplace);
			else
				aLiteralReplacements[sTable] = { sReplace };
			end

			for _,vLink in ipairs(aMultLookupLinks) do
				sReplace = sReplace .. "||" .. vLink.sClass .. "|" .. vLink.sRecord .. "|" .. vLink.sText .. "||";
			end
			
			table.insert(aLookupResults, { nStart = nStartTag, nEnd = nEndTag, vResult = sReplace });
			nMult = 1;
		end
		
	end
	for i = #aLookupResults,1,-1 do
		sOutput = sOutput:sub(1, aLookupResults[i].nStart - 1) .. aLookupResults[i].vResult .. sOutput:sub(aLookupResults[i].nEnd);
	end
	
	return sOutput, hideAll, orderedLinkTextOG;
end

function performTableLookupsLinkText(sOriginal)
    -- Look for table roll expressions specifically involving link records that wish to not display further column text

    local sOutput = sOriginal;
	local sResult = sOutput;
	local aMathResults = {};

	for nStartTag, sTag, nEndTag in sOutput:gmatch("()%[([^%]]+)%]()") do
		local sDiceExpr;
		if sTag:match("x$") then
			sDiceExpr = sTag:sub(1, -2);
		else
			sDiceExpr = sTag;
		end
		if DiceManager.isDiceMathString(sDiceExpr) then
			local nMathResult = DiceManager.evalDiceMathExpression(sDiceExpr);
			if sTag:match("x$") then
				table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = "[" .. nMathResult .. "x]" });
			else
				table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = nMathResult });
			end
		end
	end
	for i = #aMathResults,1,-1 do
		sOutput = sOutput:sub(1, aMathResults[i].nStart - 1) .. aMathResults[i].vResult .. sOutput:sub(aMathResults[i].nEnd);
	end
	
	local nMult = 1;
	local aLookupResults = {};
	for nStartTag, sTag, nEndTag in sOutput:gmatch("()%[([^%]]+)%]()") do
		local sMult = sTag:match("^(%d+)x$");
		if sMult then
			nMult = math.max(tonumber(sMult), 1);
			table.insert(aLookupResults, { nStart = nStartTag, nEnd = nEndTag, vResult = "" });
		else
			local sTable = sTag;
			local nCol = 0;
			
			local sColumn = sTable:match("|(%d+)$");
			if sColumn then
				sTable = sTable:sub(1, -(#sColumn + 2));
				nCol = tonumber(sColumn) or 0;
			end
			local nodeTable = TableManager.findTable(sTable);

			local aMultLookupResults = {};
			local aMultLookupLinks = {};
			for nCount = 1,nMult do
				local sLocalReplace = "";
				local aLocalLinks = {};
				if nodeTable then
					bContinue = true;
					
					local aDice, nMod = TableManager.getTableDice(nodeTable);
					local nRollResults = DiceManager.evalDice(aDice, nMod);
					local aTableResults = TableManager.getResults(nodeTable, nRollResults, nCol);
					
					local aOutputResults = {};
					if aTableResults then
						for _,v in ipairs(aTableResults) do
							if (v.sClass or "") ~= "" then
								if v.sClass == "table" then
									local sTableName = DB.getValue(DB.getPath(v.sRecord, "name"), "");
									if sTableName ~= "" then
										sTableName = "[" .. sTableName .. "]";
										local sMultTag, nEndMultTag = v.sText:match("%[(%d+x)%]()");
										if nEndMultTag then
											v.sText = v.sText:sub(1, nEndMultTag - 1) .. sTableName .. " " .. v.sText:sub(nEndMultTag);
	                                    else
	                                        sTableName = performTableLookupsLinkText(sTableName) -- A change here ensures the final results include no further column text alongside links
											v.sText = sTableName;
										end
	                                end
									table.insert(aOutputResults, v.sText);
								else
									table.insert(aLocalLinks, { sClass = v.sClass, sRecord = v.sRecord, sText = v.sText });
								end
	                        else

								table.insert(aOutputResults, v.sText);
							end
						end
					end
                    
                    sLocalReplace = table.concat(aOutputResults, " ");
                    
				else
					sLocalReplace = sTag;
				end
				
				-- Recurse to address any new math/table lookups
				sLocalReplace = performTableLookupsOG(sLocalReplace);
				
				table.insert(aMultLookupResults, sLocalReplace);
				for _,vLink in ipairs(aLocalLinks) do
					table.insert(aMultLookupLinks, vLink);
				end
			end

			local sReplace = table.concat(aMultLookupResults, " ");
			if aLiteralReplacements[sTable] then
				table.insert(aLiteralReplacements[sTable], sReplace);
			else
				aLiteralReplacements[sTable] = { sReplace };
			end

			for _,vLink in ipairs(aMultLookupLinks) do
				sReplace = sReplace .. "||" .. vLink.sClass .. "|" .. vLink.sRecord .. "|" .. vLink.sText .. "||";
			end
			
			table.insert(aLookupResults, { nStart = nStartTag, nEnd = nEndTag, vResult = sReplace });
			nMult = 1;
		end
		
	end
	for i = #aLookupResults,1,-1 do
		sOutput = sOutput:sub(1, aLookupResults[i].nStart - 1) .. aLookupResults[i].vResult .. sOutput:sub(aLookupResults[i].nEnd);
	end
	
	return sOutput;
end

function performLiteralReplacements(sOriginal)
	local sOutput = sOriginal;
	for k,v in pairs(aLiteralReplacements) do			
		-- Now replace any variable replacement values from the table. Replace < with
		-- xml encoded values. You can't use the encodeXML function because it escapes &amp;
		local sLiteral = "&#60;" .. k:gsub("([%-%+%.%?%*%(%)%[%]%^%$%%])", "%%%1") .."&#62;";
		sOutput = sOutput:gsub(sLiteral, table.concat(v, " "));	
	end
	return sOutput;
end

function performColumnReferenceLinks(sOriginal)
    local sOutput = sOriginal
    local columnreferencetag = ""
    local replacementData = ""
	local tableNameLitterals = ""
	local columnerrormessage = "NO COLUMN NUMBER INPUT"
    local tableerrormessage = "NO DATA IN COLUMN "


    for startag, actualTableName, colnumber, endtag in string.gmatch(sOutput, "(%#)([^%#]+)%|(%d+)(%#)") do
		tableNameLitterals = actualTableName
		tableNameLitterals = tableNameLitterals:gsub("([%-%+%.%?%,%/%:%*%(%)%[%]%^%$%%])", "%%%1")  -- Added to catch odd characters in table names
        columnreferencetag = startag..tableNameLitterals.."|"..colnumber..endtag
        actualTableName = actualTableName..colnumber

        if not colnumber or (colnumber == 0) then
            replacementData = columnreferencetag 
            sOutput = sOutput:gsub(replacementData, columnerrormessage);
        elseif tableNameArray[actualTableName] == nil then 
            replacementData = columnreferencetag 
            sOutput = sOutput:gsub(replacementData, tableerrormessage .. colnumber);
        else
            replacementData = columnreferencetag 
            sOutput = sOutput:gsub(replacementData, tableNameArray[actualTableName]);

        end
        
    end
	
    return sOutput
end

function resolveInternalReferences(sOriginal)
    -- This allows table <references> inside of table callouts.
    -- ie: [a <TableA> and <TableB> inside a parent].  
    -- Now works with Custom Naming and Hidden Features
    -- Correct usage: [Text <Table Reference> text] -OR- [:Text <Table Reference> text:Custom Name] -OR- [:?Text <Table Reference> text:Custom Name]
    -- This will also work for referenced column data ie: [Text #reference|2# text]
    -- This is part two of a two-part process.

	local sOutput = sOriginal
	local internaltext = ""
    local textToReplace = ""
    local finalTextToReplace = ""
	local internalTextLitterals = ""
    local internaltexttwo = ""
    local hidden = false

    for sTableTag, frontag, internaltext, backtag, eTableTag in sOutput:gmatch("()(|!!|!|)([^%|]+)(|!|!!|)()") do 

		internalTextLitterals = internaltext
		internalTextLitterals = internalTextLitterals:gsub("([%-%+%.%?%,%/%:%*%(%)%[%]%^%$%%])", "%%%1")  -- Added to catch odd characters in table names

        finalTextToReplace = frontag..internalTextLitterals..backtag -- Due to the new custom naming and hidden features, a new version of textToRelpace had to be added for instances where there are no custom names or hidden tags

        internaltext = "["..internaltext.."]"
        internaltext = internaltext:gsub("\\s+", "\\s")  -- removing the double space caused by the hashtag replacement, and swapping for single spaces

        if internaltext:match("%:") then     -- Adding custom naming to Internal Callout References
            for sTableTag, internaltexttwo, seperator, storageName, eTableTag in internaltext:gmatch("()%[%:[%?]?([^%:]+)(%:)([^%]]+)%]()") do 
                
                    local storageNameNew = storageName

                    if internaltext:match("?") then -- Adding a hidden function to Internal Callout References
                        hidden = true
                        textToReplace = frontag..":".."?"..internaltexttwo..seperator..storageName..backtag -- seperating the strings here via concatenation makes them behave better when being run through gsub later
                    else
                        hidden = false
                        textToReplace = frontag..":"..internaltexttwo..seperator..storageName..backtag
                    end

                    textToReplace = textToReplace:gsub("%:", "%%:") -- Added for custom naming
                    textToReplace = textToReplace:gsub("%?", "%%?") -- Added for hidden feature
					textToReplace = textToReplace:gsub("%-", "%%%-") -- Added for hyphen support
					textToReplace = textToReplace:gsub("%>", "%%%>") -- Added for hyphen support
					textToReplace = textToReplace:gsub("%<", "%%%<") -- Added for hyphen support
                    
                    internaltexttwo = "["..internaltexttwo.."]"
                    internaltexttwo = performTableLookups(internaltexttwo, storageNameNew)  -- Important to use the Non-OG version of this function here, to enable the custom naming feature
            
                    if hidden == true then
                        sOutput = sOutput:gsub(textToReplace, " ")
                    elseif hidden == false then
                        sOutput = sOutput:gsub(textToReplace, internaltexttwo)
                    end
                    
                    sOutput = sOutput:gsub("&#60;"..storageNameNew.."&#62;", internaltexttwo)
            end

        else -- If there was no custom storage name given, just look it up and replace as normal. 
            internaltext = performTableLookupsOG(internaltext)
		    sOutput = sOutput:gsub(finalTextToReplace, internaltext)
        end
    end
    
    
	return sOutput
end

function performLinkReplacements(sOriginal)
    -- Puts in table links and formatting
	local sOutput = sOriginal;

	local aLinkResults = {};
	for nLinkStart, sLinkClass, sLinkRecord, sLinkText, nLinkEnd in sOutput:gmatch("()||([^|]*)|([^|]*)|([^|]*)||()") do
		local nSectionTagStart, sSectionTag, nSectionTagEnd;
		for nTempTagStart, sTempTag, nTempTagEnd in sOutput:gmatch("()<([^>]+)>()") do
			if nTempTagEnd > nLinkStart then
				break;
			end
			if (sTempTag == "p") or (sTempTag == "h") or
                (sTempTag == "table") or (sTempTag == "frame") or
                (sTempTag == "frameid") or (sTempTag == "li") or
                (sTempTag == "linklist") then

				nSectionTagStart = nTempTagStart;
				sSectionTag = sTempTag;
				nSectionTagEnd = nTempTagEnd;
			end
		end
		
		local sLinkReplace = "<linklist><link class=\"" .. 
            UtilityManager.encodeXML(sLinkClass) .. "\" recordname=\"" .. 
            UtilityManager.encodeXML(sLinkRecord) .. "\">" .. sLinkText .. 
            "</link></linklist>";
		
		if sSectionTag == "table" then
			sLinkReplace = "!TABLE LINK NOT ALLOWED!";
		elseif sSectionTag == "frameid" then
			sLinkReplace = "!SPEAKER LINK NOT ALLOWED!";
		elseif sSectionTag == "li" then
			sLinkReplace = "</li></list>" .. sLinkReplace .. "<list><li>";
		elseif sSectionTag == "linklist" then
			sLinkReplace = "</link>" .. sLinkReplace .. "<link>";
		elseif sSectionTag == "frame" then
			sLinkReplace = "</frame>" .. sLinkReplace .. "<frame>";
		elseif sSectionTag == "h" then
			sLinkReplace = "</h>" .. sLinkReplace .. "<h>";
		elseif sSectionTag == "p" then
			sLinkReplace = "</p>" .. sLinkReplace .. "<p>";
		else
			sLinkReplace = "!MISSING SECTION!";
		end
		
		table.insert(aLinkResults, { nStart = nLinkStart, nEnd = nLinkEnd, vResult = sLinkReplace });
	end
	for i = #aLinkResults,1,-1 do
		sOutput = sOutput:sub(1, aLinkResults[i].nStart - 1) .. aLinkResults[i].vResult .. sOutput:sub(aLinkResults[i].nEnd);
	end
	
	sOutput = sOutput:gsub("<p></p>", "");
	sOutput = sOutput:gsub("<h></h>", "");
	sOutput = sOutput:gsub("<list>%s*<li></li>%s*</list>", "");
	sOutput = sOutput:gsub("<link></link>", "");
	sOutput = sOutput:gsub("<frame></frame>", "");
	
	sOutput = sOutput:gsub("</linklist>%s*<linklist>", "");
	
	return sOutput;
end

function performIndefiniteArticles(sOriginal)
    -- Look for (a) or (A) callouts, and replace them with the correct
    -- indefinite article.  ie: (a) might stay "a" or be changed to "an"
    -- if the text following requires it.
    local textToReplace
    local replacementText
    local sOutput = sOriginal

	for i, gmatchpat in ipairs{ "[phbu]", "frame", "/frameid", "td", "li" } do

        for sTag, formatTag, frontTag, letterToCap, backTag, eTag in sOutput:gmatch("()(<" .. gmatchpat .. ">)(%()(a)(%))()") do  -- Adds auto-caps to the beginning of newlines and other format tags.  Big improvement!
            formatTag = formatTag:gsub("[<>]", "%%%0")    
            sOutput = sOutput:gsub(formatTag .. "%(" .. letterToCap .. "%)", formatTag .. "%(" .. letterToCap:upper() .. "%)")
        end
    end

    for sTag, frontTag, article, backTag, space, nextWord, eTag in sOutput:gmatch("()(%()([aA])(%))(%s)([%a]+)()") do
		
        textToReplace = "%" .. frontTag .. article .. "%" .. backTag .. space .. nextWord

        local nextWordLower = string.lower(nextWord) -- case insensitive nextword
           
		if nextWordLower:match("^[u]ni[nm]") then -- Had to be put in front, or else "^[u]ni" would pick it up next

			if article == "a" then
				article = "an"
			elseif article == "A" then
				article ="An"
			end

		elseif nextWordLower:match("^[u]ni") or nextWordLower:match("unanimous") or  --Vastly expanded list with pattern matching
			nextWordLower:match("uranium") or nextWordLower:match("^[u]rin") or 
			nextWordLower:match("^[u]re") or nextWordLower:match("^[u]se") or 
			nextWordLower:match("^[u]su") or nextWordLower:match("^[u]bi") or 
			nextWordLower:match("^[e]we") or nextWordLower:match("^[u]rl") or
			nextWordLower:match("^[u]fo") or nextWordLower:match("uganda") or 
			nextWordLower:match("ukrain") or nextWordLower:match("ukulele") or 
			nextWordLower:match("^[u]ke") or nextWordLower:match("^[u]lo") or
			nextWordLower:match("^[u]te") or nextWordLower:match("^[u]ti") or 
			nextWordLower:match("utopia") or nextWordLower:match("uvula") or 
			nextWordLower:match("^[e]u") or nextWordLower:match("^[o]ne") or 
			nextWordLower:match("^[o]nce") or nextWordLower:match("usable") or 
			nextWordLower:match("uranus") then

		elseif nextWordLower:match("^[aeiou]") then
			if article == "a" then
				article = "an"
			elseif article == "A" then
				article ="An"
			end

		elseif nextWordLower:match("heir") or nextWordLower:match("hour") or nextWordLower:match("honest") or nextWordLower:match("honor") then
			if article == "a" then
				article = "an"
			elseif article == "A" then
				article ="An"
			end

		else -- everything else should abide by the consonant rule

		end

        replacementText = article .. space .. nextWord
        sOutput = sOutput:gsub(textToReplace, replacementText)
    end

    return sOutput
end

function performCapitalize(sOriginal)
    -- Look for (t) syntax within rolled results, where "t" is any
    -- starting letter of a word, and capitalize it if it 
	-- begins a sentence, a bolded or underlined area, a header, table, chat dialoge, or a new line.
    local textToReplace
    local replacementText
    local sOutput = sOriginal
	
    for sTag, punctuation, spaces, frontTag, letterToCap, backTag, eTag in sOutput:gmatch("()([%%.%?%!])(%s+)(%()(%a)(%))()") do -- This handles punctuation and new sentances.
        local punctuation, r = punctuation:gsub("[?.!]","%%%0")
    
        if r>0 then
        sOutput = sOutput:gsub(punctuation .. spaces .. "%(" .. letterToCap .. "%)", punctuation .. spaces .. letterToCap:upper())
        end
    end

    for i, gmatchpat in ipairs{ "[phbu]", "frame", "/frameid", "td", "li" } do

        for sTag, formatTag, frontTag, letterToCap, backTag, eTag in sOutput:gmatch("()(<" .. gmatchpat .. ">)(%()(%a)(%))()") do  -- Adds auto-caps to the beginning of newlines and other format tags.  Big improvement!
            formatTag = formatTag:gsub("[<>]", "%%%0")    
            sOutput = sOutput:gsub(formatTag .. "%(" .. letterToCap .. "%)", formatTag .. letterToCap:upper())
        end
    end

    for sTag, frontTag, letterToCap, backTag, eTag in sOutput:gmatch("()(%()(%a)(%))()") do -- Removes the parenthesis around letters that should not be capitalized, leaving them lowercase
        textToReplace = "%(" .. letterToCap .. "%)"
        replacementText = letterToCap:lower() -- makes the input letter non-case sensitive now
        sOutput = sOutput:gsub(textToReplace, replacementText)
    end

    return sOutput
end


