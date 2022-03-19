-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- NOTE: All valid dice assets supported by all the script functions must start with "d"

function onInit()
	Interface.onDesktopInit = onDesktopInit;
end

local _tRulesetDice;
function onDesktopInit()
	_tRulesetDice = Interface.getDice();
end

-----------------------
-- CUSTOM DIE EVALUATION FUNCTIONS
-----------------------

local _tCustomDieEvalHandler = {
	["F"] = {
		nMinValue = -1,
		nMaxValue = 1,
		fnRandomValue = function () return math.random(-1, 1); end,
	},
};

function registerCustomDieEvalHandler(sDie, fnDie)
	if ((sDie or "") == "") or (#sDie < 2) then
		return;
	end
	if sDie:sub(1,1) ~= "d" then
		return;
	end
	_tCustomDieEvalHandler[sDie] = fnDie;
end
function unregisterCustomDieEvalHandler(sDie)
	if ((sDie or "") == "") or (#sDie < 2) then
		return;
	end
	if sDie:sub(1,1) ~= "d" then
		return;
	end
	_tCustomDieEvalHandler[sDie] = nil;
end

function getCustomDieMinValue(sDie)
	if not _tCustomDieEvalHandler[sDie] then
		return nil;
	end
	return _tCustomDieEvalHandler[sDie].nMinValue;
end
function getCustomDieMaxValue(sDie)
	if not _tCustomDieEvalHandler[sDie] then
		return nil;
	end
	return _tCustomDieEvalHandler[sDie].nMaxValue;
end
function getCustomDieRandomValue(sDie)
	if not _tCustomDieEvalHandler[sDie] then
		return nil;
	end
	if not _tCustomDieEvalHandler[sDie].fnRandomValue then
		return nil;
	end
	return _tCustomDieEvalHandler[sDie].fnRandomValue();
end

local _tCustomPreEncodeRollHandler = {};
function registerCustomPreEncodeRollHandler(fCallback)
	for _,v in pairs(_tCustomPreEncodeRollHandler) do
		if v == fCallback then
			return;
		end
	end
	table.insert(_tCustomPreEncodeRollHandler, fCallback);
end
function unregisterCustomPreEncodeRollHandler(fCallback)
	for k, v in pairs(_tCustomPreEncodeRollHandler) do
		if v == fCallback then
			table.remove(_tCustomPreEncodeRollHandler, k);
			break;
		end
	end
end

local _tCustomPostDecodeRollHandler = {};
function registerCustomPostDecodeRollHandler(fCallback)
	for _,v in pairs(_tCustomPostDecodeRollHandler) do
		if v == fCallback then
			return;
		end
	end
	table.insert(_tCustomPostDecodeRollHandler, fCallback);
end
function unregisterCustomPostDecodeRollHandler(fCallback)
	for k, v in pairs(_tCustomPostDecodeRollHandler) do
		if v == fCallback then
			table.remove(_tCustomPostDecodeRollHandler, k);
			break;
		end
	end
end

function onPreEncodeRoll(vRoll)
	for _,fCallback in ipairs(_tCustomPreEncodeRollHandler) do
		fCallback(vRoll);
	end
end
function onPostDecodeRoll(vRoll, bFinal)
	for _,fCallback in ipairs(_tCustomPostDecodeRollHandler) do
		fCallback(vRoll, bFinal);
	end
end

-----------------------
--  INTERNAL ONLY HELPER FUNCTIONS
-----------------------

function isValidDie(s)
	if not s then
		return false;
	end

	if StringManager.contains(_tRulesetDice, s) then
		return true;
	elseif _tCustomDieEvalHandler[s] then
		return true;
	elseif s:match("^d%d+$") then
		return true;
	end
end
function isValidTerm(s)
	if not s then
		return false;
	end
	if s == "" then
		return true;
	end

	if not StringManager.isNumberString(s) then
		local _,sDieType = DiceManager.parseDiceTerm(s);
		if not sDieType then
			return false;
		end
	end
	return true;
end

function convertDiceStringToTerms(s)
	local tTerms = {};
	if s then
		s = s:gsub("[ %(%)]", "");
		local tPlusTerms = StringManager.split(s, "%+");
		for _,vPlusTerm in ipairs(tPlusTerms) do
			local tMinusTerms = StringManager.split(vPlusTerm, "%-");
			for kMinusTerm,vMinusTerm in ipairs(tMinusTerms) do
				if vMinusTerm ~= "" then
					if kMinusTerm == 1 and not vPlusTerm:match("^%-") then
						table.insert(tTerms, vMinusTerm);
					else
						table.insert(tTerms, "-" .. vMinusTerm);
					end
				end
			end
		end
	end
	return tTerms;
end
function parseDiceTerm(s)
	if not s then
		return nil;
	end
	local sSign, sDieCount, sDieType = s:match("^([%-%+]?)([%d%.]*)([dD].+)");
	if sDieType and sDieType:sub(1,1) == "D" then
		sDieType = 'd' .. sDieType:sub(2);
	end
	if not DiceManager.isValidDie(sDieType) then
		return nil;
	end
	if sSign == "-" then
		sDieType = "-" .. sDieType;
	end
	local nDieCount = math.floor(tonumber(sDieCount) or 1);
	return nDieCount, sDieType;
end

-----------------------
--  IDENTIFICATION FUNCTIONS
-----------------------

function isDiceString(s)
	if not s then
		return false;
	end
	local tTerms = StringManager.split(s, "%+%-");
	for _,vTerm in ipairs(tTerms) do
		if not DiceManager.isValidTerm(vTerm) then
			return false;
		end
	end
	return true;
end
function isDiceMathString(s)
	if not s then
		return false;
	end
	local tTerms = StringManager.split(s, "*/%+%-%(%)");
	for _,vTerm in ipairs(tTerms) do
		if not DiceManager.isValidTerm(vTerm) then
			return false;
		end
	end
	return true;
end

-----------------------
--  CONVERSION FUNCTIONS
-----------------------

function convertStringToDice(s)
	local tDice = {};
	local nMod = 0;
	
	local tTerms = DiceManager.convertDiceStringToTerms(s);
	for _,vTerm in ipairs(tTerms) do
		if StringManager.isNumberString(vTerm) then
			nMod = nMod + (tonumber(vTerm) or 0);
		else
			local nDieCount, sDieType = DiceManager.parseDiceTerm(vTerm);
			if sDieType then
				for i = 1, nDieCount do
					table.insert(tDice, sDieType);
				end
			end
		end
	end

	return tDice, nMod;
end
function convertDiceToString(tDice, nMod, bSign)
	local tResult = {};

	if tDice then
		local tDieCount = {};

		for _,v in ipairs(tDice) do
			-- Draginfo die data is two levels deep
			if type(v) == "table" then
				tDieCount[v.type] = (tDieCount[v.type] or 0) + 1;

			-- Database value die data is one level deep
			else
				tDieCount[v] = (tDieCount[v] or 0) + 1;
			end
		end

		-- Build string
		for k,v in pairs(tDieCount) do
			if v == 1 then
				if #tResult == 0 then
					table.insert(tResult, k);
				else
					table.insert(tResult, "+" .. k);
				end
			else
				if k:sub(1,1) == "-" then
					table.insert(tResult, "-" .. v .. k:sub(2));
				else
					if #tResult == 0 then
						table.insert(tResult, v .. k);
					else
						table.insert(tResult, "+" .. v .. k);
					end
				end
			end
		end
	end
	
	-- ADD OPTIONAL MODIFIER
	if nMod then
		if nMod > 0 then
			if (#tResult == 0) and not bSign then
				table.insert(tResult, tostring(nMod));
			else
				table.insert(tResult, "+" .. nMod);
			end
		elseif nMod < 0 then
			table.insert(tResult, tostring(nMod));
		end
	end
	
	-- RESULTS
	return table.concat(tResult);
end

-----------------------
-- EVALUATION FUNCTIONS
-----------------------

--
-- 	EVAL DICE STRING
--
-- 	Evaluates a string that contains an arbitrary number of simple
--		numerical terms and dice expressions (i.e. 2d6-3+2d4+7...)
-- 
-- 	NOTE: Dice expressions are automatically evaluated randomly without rolling the 
-- 		physical dice on-screen, or ignored if the bAllowDice flag not set.
--

function evalDiceString(s, bAllowDice, bMax)
	local nTotal = 0;
	
	local tTerms = DiceManager.convertDiceStringToTerms(s);
	for _,vTerm in ipairs(tTerms) do
		if StringManager.isNumberString(vTerm) then
			nTotal = nTotal + (tonumber(vTerm) or 0);
		else
			local nDieCount, sDieType = DiceManager.parseDiceTerm(vTerm);
			if sDieType then
				for i = 1, nDieCount do
					nTotal = nTotal + DiceManager.evalDie(sDieType, bMax);
				end
			end
		end
	end
	
	return nTotal;
end
function evalDice(tDice, nMod, bMax)
	local nTotal = 0;
	for _,sDie in pairs(tDice) do
		local sDieType = sDie:match("(%-?d.+)");
		nTotal = nTotal + DiceManager.evalDie(sDieType, bMax);
	end
	if nMod then
		nTotal = nTotal + nMod;
	end
	return nTotal;
end
function evalDie(sDieType, bMax)
	if (sDieType or "") == "" then
		return 0;
	end

	local bNegative;
	if sDieType:match("^%-") then
		bNegative = true;
		sDieType = sDieType:sub(2);
	else
		bNegative = false;
	end

	local nDie = nil;
	if bMax then
		nDie = DiceManager.getCustomDieMaxValue(sDieType);
	else
		nDie = DiceManager.getCustomDieRandomValue(sDieType);
	end
	if not nDie then
		local nDieSides = tonumber(sDieType:sub(2)) or 0;
		if nDieSides > 0 then
			if bMax then
				nDie = nDieSides;
			else
				nDie = math.random(nDieSides);
			end
		end
	end

	if bNegative then
		nDie = 0 - (nDie or 0);
	end

	return nDie or 0;
end

function evalDiceMathExpression(sParam, bMaxDice)
	if not sParam then
		return 0;
	end
	
	local s = sParam:gsub(" ", "");
	
	-- Convert to post-fix array
	-- Note: Based on Shunting-Yard algorithm (modified for dice operator)
	local sOps = "-+*/";
	local aOpStack = {};
	local aPFArray = {};
	local sNonOp = "";
	
	for i = 1,#s do
		local c = s:sub(i, i);
		local nFind = sOps:find(c, 1, true);
		if nFind then
			if sNonOp ~= "" then
				table.insert(aPFArray, sNonOp);
				sNonOp = "";
			end
			while #aOpStack > 0 do
				if aOpStack[#aOpStack] == #sOps + 1 then
					table.insert(aPFArray, "d");
					table.remove(aOpStack);
				else
					local nPrec2 = (aOpStack[#aOpStack] - 1) / 2;
					local nPrec1 = (nFind - 1) / 2;
					if nPrec2 > nPrec1 then
						table.insert(aPFArray, sOps:sub(aOpStack[#aOpStack], aOpStack[#aOpStack]));
						table.remove(aOpStack);
					else
						break;
					end
				end
			end
			table.insert(aOpStack, nFind);
		elseif c == '(' then
			if sNonOp ~= "" then
				table.insert(aPFArray, sNonOp);
				sNonOp = "";
			end
			table.insert(aOpStack, -2);
		elseif c == ')' then
			if sNonOp ~= "" then
				table.insert(aPFArray, sNonOp);
				sNonOp = "";
			end
			while #aOpStack > 0 do
				if aOpStack[#aOpStack] == -2 then
					table.remove(aOpStack);
					break;
				else
					if aOpStack[#aOpStack] == #sOps + 1 then
						table.insert(aPFArray, "d");
					else
						table.insert(aPFArray, sOps:sub(aOpStack[#aOpStack], aOpStack[#aOpStack]));
					end
					table.remove(aOpStack);
				end
			end
		elseif c == 'd' or c == 'D' then
			local bValidDieOperator = true;
			if i > 1 then
				if s:sub(i-1,i-1):match("%a") then
					bValidDieOperator = false;
				end
			end
			
			if bValidDieOperator then
				if sNonOp == "" then
					sNonOp = "1";
				end
				table.insert(aPFArray, sNonOp);
				sNonOp = "";
				table.insert(aOpStack, #sOps + 1);
			else
				sNonOp = sNonOp .. c;
			end
		else
			sNonOp = sNonOp .. c;
		end
	end
	if sNonOp ~= "" then
		table.insert(aPFArray, sNonOp);
		sNonOp = "";
	end
	while #aOpStack > 0 do
		if aOpStack[#aOpStack] == #sOps + 1 then
			table.insert(aPFArray, "d");
		else
			table.insert(aPFArray, sOps:sub(aOpStack[#aOpStack], aOpStack[#aOpStack]));
		end
		table.remove(aOpStack);
	end

	-- Calculate result from post-fix array
	local aCalcStack = {};
	for _,v in ipairs(aPFArray) do
		if v == '*' then
			if #aCalcStack > 1 then
				local nTemp = (tonumber(aCalcStack[#aCalcStack - 1]) or 0) * (tonumber(aCalcStack[#aCalcStack]) or 0);
				table.remove(aCalcStack);
				table.remove(aCalcStack);
				table.insert(aCalcStack, nTemp);
			elseif #aCalcStack > 0 then
				table.remove(aCalcStack);
				table.insert(aCalcStack, 0);
			end
		elseif v == '/' then
			if #aCalcStack > 1 then
				local nTemp = 0;
				local nDividend = (tonumber(aCalcStack[#aCalcStack]) or 0);
				if nDividend ~= 0 then
					nTemp = (tonumber(aCalcStack[#aCalcStack - 1]) or 0) / nDividend;
				end
				table.remove(aCalcStack);
				table.remove(aCalcStack);
				table.insert(aCalcStack, nTemp);
			elseif #aCalcStack > 0 then
				table.remove(aCalcStack);
				table.insert(aCalcStack, 0);
			end
		elseif v == '-' then
			if #aCalcStack > 1 then
				local nTemp = (tonumber(aCalcStack[#aCalcStack - 1]) or 0) - (tonumber(aCalcStack[#aCalcStack]) or 0);
				table.remove(aCalcStack);
				table.remove(aCalcStack);
				table.insert(aCalcStack, nTemp);
			elseif #aCalcStack > 0 then
				local nTemp = (tonumber(aCalcStack[#aCalcStack]) or 0) * -1;
				table.remove(aCalcStack);
				table.insert(aCalcStack, nTemp);
			end
		elseif v == '+' then
			if #aCalcStack > 1 then
				local nTemp = (tonumber(aCalcStack[#aCalcStack - 1]) or 0) + (tonumber(aCalcStack[#aCalcStack]) or 0);
				table.remove(aCalcStack);
				table.remove(aCalcStack);
				table.insert(aCalcStack, nTemp);
			end
		elseif v == 'd' then
			if #aCalcStack > 0 then
				local nDieCount = 1;
				if #aCalcStack > 1 then
					nDieCount = math.max(tonumber(aCalcStack[#aCalcStack - 1]) or 1, 1);
				end
				local sDieType = "d" .. aCalcStack[#aCalcStack];

				local nTemp = 0;
				for i = 1, nDieCount do
					nTemp = nTemp + DiceManager.evalDie(sDieType, bMaxDice);
				end
				
				if #aCalcStack > 1 then
					table.remove(aCalcStack);
				end
				table.remove(aCalcStack);
				table.insert(aCalcStack, nTemp);
			end
		else
			table.insert(aCalcStack, v);
		end
	end

	local nTotal = 0;
	if #aCalcStack == 1 then
		nTotal = tonumber(aCalcStack[1]) or 0;
	end
	
	return nTotal;
end

-----------------------
-- Default D66 handling 
-- (Alien, Conan, Traveller, Vaesen, WOIN)
-----------------------
-- Requires a simple script, two customdie definitions, and one icon definition (if desired to replace customdice icon)
-- (as below)
--
-- <script name="D66Support">
-- 	function onInit()
-- 		DiceManager.addDefaultD66Handling();
-- 	end
-- </script>
-- <customdie name="d66">
-- 	<model>d6</model>
-- 	<menuicon>customdice</menuicon>
-- </customdie>
-- <customdie name="d60">
-- 	<model>d6</model>
-- 	<script>
-- 		function onValue(result)
-- 			return DiceManager.onD60ResultValue(result);
-- 		end
-- 	</script>
-- </customdie>
-----------------------

function addDefaultD66Handling()
	local tCustomD66 = {
		nMinValue = 11,
		nMaxValue = 66,
		fnRandomValue = DiceManager.onD66RandomValue,
	};
	DiceManager.registerCustomDieEvalHandler("d66", tCustomD66);
	local tCustomD60 = {
		nMinValue = 10,
		nMaxValue = 60,
		fnRandomValue = DiceManager.onD60RandomValue,
	};
	DiceManager.registerCustomDieEvalHandler("d60", tCustomD60);
	DiceManager.registerCustomPreEncodeRollHandler(DiceManager.onD66PreEncodeRoll);

	ChatManager.registerDropCallback("dice", DiceManager.onD66ChatDiceDrop);
end

function onD66RandomValue()
	return DiceManager.onD60ResultValue(math.random(6)) + math.random(6);
end
function onD60RandomValue()
	return DiceManager.onD60ResultValue(math.random(6));
end
function onD60ResultValue(result)
	return (result * 10);
end

function onD66PreEncodeRoll(tRoll)
	if not ActionsManager.doesRollHaveDice(tRoll) then
		return;
	end
	DiceManager.helperD66EncodeDice(tRoll.aDice);
end
function onD66ChatDiceDrop(draginfo)
	for i = 1, draginfo.getSlotCount() do
		draginfo.setSlot(i);
		local tDice = draginfo.getDieList();
		if DiceManager.helperD66EncodeDice(tDice) then
			draginfo.setDieList(tDice);
		end
	end
end
function helperD66EncodeDice(tDice, bDrop)
	if not tDice then
		return false;
	end

	local bChanged = false;
	for i = #(tDice), 1, -1 do
		if type(tDice[i]) == "table" then
			if tDice[i].type == "d66" then
				tDice[i].type = "d60";
				table.insert(tDice, i + 1, { type = "d6" });
				bChanged = true;
			end
		elseif tDice[i] == "d66" then
			tDice[i] = "d60";
			table.insert(tDice, i + 1, "d6");
			bChanged = true;
		end
	end
	if (tDice.expr or "") ~= "" then
		if tDice.expr:match("d66") then
			tDice.expr = tDice.expr:gsub("(%d*)d66", "(%1d60+%1d6)");
			bChanged = true;
		end
	end
	return bChanged;
end
