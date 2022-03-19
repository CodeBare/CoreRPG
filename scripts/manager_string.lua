-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-----------------------
--  EXISTENCE FUNCTIONS
-----------------------

function startsWith(s, sCheck)
	if not s then
		return false;
	end
	return (s:sub(1,#sCheck) == sCheck);
end

function isWord(sWord, vTarget)
	if not sWord then
		return false;
	end
	if type(vTarget) == "string" then
		if sWord ~= vTarget then
			return false;
		end
	elseif type(vTarget) == "table" then
		if not contains(vTarget, sWord) then
			return false;
		end
	else
		return false;
	end
	return true;
end

function isPhrase(aWords, nIndex, aPhrase)
	if not aPhrase or not aWords then
		return false;
	end
	if #aPhrase == 0 then
		return false;
	end
	
	local i = nIndex - 1;
	for j = 1, #aPhrase do
		if not StringManager.isWord(aWords[i+j], aPhrase[j]) then
			return false;
		end
	end
	return true;
end

function isNumberString(s)
	if s then
		if s:match("^[%+%-]?[%d%.]+$") then
			return true;
		end
	end
	return false;
end

-----------------------
-- SET FUNCTIONS
-----------------------

function contains(set, item)
	if not set or not item then
		return false;
	end
	for i = 1, #set do
		if set[i] == item then
			return true;
		end
	end
	return false;
end

function autoComplete(aSet, sItem, bIgnoreCase)
	if not aSet or not sItem then
		return nil;
	end
	if bIgnoreCase then
		for i = 1, #aSet do
			if sItem:lower() == string.lower(aSet[i]:sub(1, #sItem)) then
				return aSet[i]:sub(#sItem + 1);
			end
		end
	else
		for i = 1, #aSet do
			if sItem == aSet[i]:sub(1, #sItem) then
				return aSet[i]:sub(#sItem + 1);
			end
		end
	end

	return nil;
end

-----------------------
-- MODIFY FUNCTIONS
-----------------------

function capitalize(s)
	if not s then
		return nil;
	end
	local sNew = s:gsub("^%l", string.upper);
	return sNew;
end

function capitalizeAll(s)
	if not s then
		return nil;
	end
	local sNew = s:gsub("^%l", string.upper);
	sNew = sNew:gsub(" %l", string.upper);
	sNew = sNew:gsub(" %(%l", string.upper);
	return sNew;
end

function titleCase(s)
	if not s then
		return nil;
	end
	function titleCaseInternal(sFirst, sRemaining)
		return sFirst:upper() .. sRemaining:lower();
	end
	return s:gsub("(%a)([%w_']*)", titleCaseInternal);
end

function multireplace(s, aPatterns, sReplace)
	if not s or not sReplace then
		return s;
	end
	if type(aPatterns) == "string" then
		s = s:gsub(aPatterns, sReplace);
	elseif type(aPatterns) == "table" then
		for _,v in pairs(aPatterns) do
			s = s:gsub(v, sReplace);
		end
	end

	return s;
end

function addTrailing(s, c)
	if not s then
		return s;
	end
	if s:len() > 0 and s[-1] ~= c then
		s = s .. c;
	end
	return s;
end

function extract(s, nStart, nEnd)
	if not s or not nStart or not nEnd then
		return "", s;
	end
	
	local sExtract = s:sub(nStart, nEnd);
	local sRemainder;
	if nStart == 1 then
		sRemainder = s:sub(nEnd + 1);
	else
		sRemainder = s:sub(1, nStart - 1) .. s:sub(nEnd + 1);
	end

	return sExtract, sRemainder;
end

function extractPattern(s, sPattern)
	if not s or not sPattern then
		return "", s;
	end

	local nStart, nEnd = s:find(sPattern);
	if not nStart then
		return "", s;
	end
	
	local sExtract = s:sub(nStart, nEnd);
	local sRemainder;
	if nStart == 1 then
		sRemainder = s:sub(nEnd + 1);
	else
		sRemainder = s:sub(1, nStart - 1) .. s:sub(nEnd + 1);
	end

	return sExtract, sRemainder;
end

function combine(sSeparator, ...)
	local aCombined = {};

	for i = 1, select("#", ...) do
		local v = select(i, ...);
		if type(v) == "string" and v:len() > 0 then
			table.insert(aCombined, v);
		end
	end

	return table.concat(aCombined, sSeparator);
end

--
-- TRIM STRING
--
-- Strips any spacing characters from the beginning and end of a string.
--
-- The function returns the following parameters:
--   1. The trimmed string
--   2. The starting position of the trimmed string within the original string
--   3. The ending position of the trimmed string within the original string
--

function trim(s)
	if not s then
		return nil;
	end
	
	local pre_starts, pre_ends = s:find("^%s+");
	local post_starts, post_ends = s:find("%s+$");
	
	if pre_ends then
		s = s:gsub("^%s+", "");
	else
		pre_ends = 0;
	end
	if post_starts then
		s = s:gsub("%s+$", "");
	end
	
	return s, pre_ends + 1, pre_ends + #s;
end

function strip(s)
	if not s then
		return nil;
	end

	return trim(s:gsub("%s+", " "));
end

-----------------------
-- PARSE FUNCTIONS
-----------------------

function parseWords(s, extra_delimiters)
	local delim = "^%w%+%-'’";
	if extra_delimiters then
		delim = delim .. extra_delimiters;
	end
	return StringManager.split(s, delim, true); 
end

-- 
-- SPLIT CLAUSES
--
-- The source string is divided into substrings as defined by the delimiters parameter.  
-- Each resulting string is stored in a table along with the start and end position of
-- the result string within the original string.  The result tables are combined into
-- a table which is then returned.
--
-- NOTE: Set trimspace flag to trim any spaces that trail delimiters before next result 
-- string
--

function split(sToSplit, sDelimiters, bTrimSpace)
	if not sToSplit or not sDelimiters then
		return {}, {};
	end
	
	-- SETUP
	local aStrings = {};
	local aStringStats = {};
	
  	-- BUILD DELIMITER PATTERN
  	local sDelimiterPattern = "[" .. sDelimiters .. "]+";
  	if bTrimSpace then
  		sDelimiterPattern = sDelimiterPattern .. "%s*";
  	end
  	
  	-- DEAL WITH LEADING/TRAILING SPACES
  	local nStringStart = 1;
  	local nStringEnd = #sToSplit;
  	if bTrimSpace then
  		_, nStringStart, nStringEnd = StringManager.trim(sToSplit);
  	end
  	
  	-- SPLIT THE STRING, BASED ON THE DELIMITERS
   	local sNextString = "";
 	local nIndex = nStringStart;
  	local nDelimiterStart, nDelimiterEnd = sToSplit:find(sDelimiterPattern, nIndex);
  	while nDelimiterStart do
  		sNextString = sToSplit:sub(nIndex, nDelimiterStart - 1);
  		if sNextString ~= "" then
  			table.insert(aStrings, sNextString);
  			table.insert(aStringStats, {startpos = nIndex, endpos = nDelimiterStart});
  		end
  		
  		nIndex = nDelimiterEnd + 1;
  		nDelimiterStart, nDelimiterEnd = sToSplit:find(sDelimiterPattern, nIndex);
  	end
  	sNextString = sToSplit:sub(nIndex, nStringEnd);
	if sNextString ~= "" then
		table.insert(aStrings, sNextString);
		table.insert(aStringStats, {startpos = nIndex, endpos = nStringEnd + 1});
	end
	
	-- RESULTS
	return aStrings, aStringStats;
end

function splitByPattern(sToSplit, sPattern, bTrimSpace)
	if not sToSplit or not sPattern then
		return {};
	end
	
  	local nStringStart = 1;
  	local nStringEnd = #sToSplit;
  	if bTrimSpace then
  		_, nStringStart, nStringEnd = StringManager.trim(sToSplit);
  	end

	local aStrings = {};
	local sNonGreedyPatternMatch = "(.-)" .. sPattern;
 	local nIndex = nStringStart;
	local nPatternStart, nPatternEnd, sString = sToSplit:find(sNonGreedyPatternMatch, nIndex);
	while nPatternStart do
		table.insert(aStrings, sString);
  		nIndex = nPatternEnd + 1;
		nPatternStart, nPatternEnd, sString = sToSplit:find(sNonGreedyPatternMatch, nIndex);
	end
	local sFinalString = sToSplit:sub(nIndex, nStringEnd);
	if sFinalString ~= "" then
		table.insert(aStrings, sFinalString);
	end

	return aStrings;
end

-----------------------
--  CONVERSION FUNCTIONS
-----------------------

function convertStringToDice(s)
	return DiceManager.convertStringToDice(s);
end
function convertDiceToString(aDice, nMod, bSign)
	return DiceManager.convertDiceToString(aDice, nMod, bSign);
end

--
-- DICE FUNCTIONS
--

function isDiceString(s)
	return DiceManager.isDiceString(s);
end
function isDiceMathString(s)
	return DiceManager.isDiceMathString(s);
end

function evalDiceString(sDice, bAllowDice, bMaxDice)
	return DiceManager.evalDiceString(sDice, bAllowDice, bMaxDice);
end
function evalDice(aDice, nMod, bMax)
	return DiceManager.evalDice(aDice, nMod, bMax);
end
function evalDiceMathExpression(sParam, bMaxDice)
	return DiceManager.evalDiceMathExpression(sParam, bMaxDice);
end

function findDiceMathExpression(s, nStart)
	Debug.console("StringManager.findDiceMathExpression - DEPRECATED - 2022-02-01");
	return nil;
end
