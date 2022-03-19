-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

COLOR_DAY_DEFAULT = "000000";
COLOR_DAY_HOLIDAY = "333399";
COLOR_DAY_CURRENT = "FFFFFF";
BACKGROUND_DAY_CURRENT = "000000";

local aLunarDayCalc = {};
local aMonthVarCalc = {};

local aDayDisplay = {};
local aDateDisplay = {};

local callbacks = {};

function onInit()
	aLunarDayCalc["gregorian"] = calcGregorianLunarDay;
	aMonthVarCalc["gregorian"] = calcGregorianMonthVar;
	aLunarDayCalc["golarion"] = calcGolarionLunarDay;
	aMonthVarCalc["golarion"] = calcGolarionMonthVar;
	aDayDisplay["traveller_imperial"] = displayImperialDay;
	aDateDisplay["traveller_imperial"] = displayImperialDate;
	aLunarDayCalc["ravnica"] = calcRavnicaLunarDay;
	
	DB.addHandler("calendar.data", "onChildAdded", onCalendarChanged);
end

function registerChangeCallback(fCallback)
	table.insert(callbacks, fCallback);
end
function unregisterChangeCallback(fCallback)
	for k, v in pairs(callbacks) do
		if v == fCallback then
			callbacks[k] = nil;
		end
	end
end
function onCalendarChanged(_, nodeNew)
	if nodeNew.getName() == "complete" then
		for _,v in pairs(callbacks) do
			v();
		end
	end
end

function registerLunarDayHandler(sCalendarType, fCallback)
	aLunarDayCalc[sCalendarType] = fCallback;
end
function registerMonthVarHandler(sCalendarType, fCallback)
	aMonthVarCalc[sCalendarType] = fCallback;
end
function registerDayDisplayHandler(sCalendarType, fCallback)
	aDayDisplay[sCalendarType] = fCallback;
end
function registerDateDisplayHandler(sCalendarType, fCallback)
	aDateDisplay[sCalendarType] = fCallback;
end

function adjustMinutes(n)
	local nAdjMinutes = DB.getValue("calendar.current.minute", 0) + n;
	
	local nHourAdj = 0;
	
	if nAdjMinutes >= 60 then
		nHourAdj = math.floor(nAdjMinutes / 60);
		nAdjMinutes = nAdjMinutes % 60;
	elseif nAdjMinutes < 0 then
		nHourAdj = -math.floor(-nAdjMinutes / 60) - 1;
		nAdjMinutes = nAdjMinutes % 60;
	end
	
	if nHourAdj ~= 0 then
		CalendarManager.adjustHours(nHourAdj);
	end
	
	DB.setValue("calendar.current.minute", "number", nAdjMinutes);
end
function adjustHours(n)
	local nAdjHours = DB.getValue("calendar.current.hour", 0) + n;
	
	local nDayAdj = 0;
	
	if nAdjHours >= 24 then
		nDayAdj = math.floor(nAdjHours / 24);
		nAdjHours = nAdjHours % 24;
	elseif nAdjHours < 0 then
		nDayAdj = -math.floor(-nAdjHours / 24) - 1;
		nAdjHours = nAdjHours % 24;
	end
	
	if nDayAdj ~= 0 then
		CalendarManager.adjustDays(nDayAdj);
	end
	
	DB.setValue("calendar.current.hour", "number", nAdjHours);
end
function adjustDays(n)
	local nAdjDay = DB.getValue("calendar.current.day", 0) + n;
	
	local nDaysInMonth = CalendarManager.getDaysInMonth(DB.getValue("calendar.current.month", 0));
	if nDaysInMonth == 0 then
		return;
	end
	
	if nAdjDay > nDaysInMonth then
		while nAdjDay > nDaysInMonth do
			nAdjDay = nAdjDay - nDaysInMonth;
			CalendarManager.adjustMonths(1);

			nDaysInMonth = CalendarManager.getDaysInMonth(DB.getValue("calendar.current.month", 0));
			if nDaysInMonth == 0 then
				break;
			end
		end
	elseif nAdjDay <= 0 then
		while nAdjDay <= 0 do
			CalendarManager.adjustMonths(-1);
			nDaysInMonth = CalendarManager.getDaysInMonth(DB.getValue("calendar.current.month", 0));
			if nDaysInMonth == 0 then
				break;
			end
			nAdjDay = nAdjDay + nDaysInMonth;
		end
	end
	
	DB.setValue("calendar.current.day", "number", nAdjDay);
end
function adjustMonths(n)
	local nAdjMonth = DB.getValue("calendar.current.month", 0) + n;
	local nMonthsInYear = CalendarManager.getMonthsInYear();
	
	if nMonthsInYear > 0 then
		local nYearAdj = 0;

		if nAdjMonth > nMonthsInYear then
			nYearAdj = math.floor((nAdjMonth - 1) / nMonthsInYear);
			nAdjMonth = ((nAdjMonth - 1) % nMonthsInYear) + 1;
		elseif nAdjMonth <= 0 then
			nYearAdj = -math.floor(-(nAdjMonth - 1) / nMonthsInYear) - 1;
			nAdjMonth = ((nAdjMonth - 1) % nMonthsInYear) + 1;
		end
		
		if nYearAdj ~= 0 then
			CalendarManager.adjustYears(nYearAdj);
		end
	end
	
	DB.setValue("calendar.current.month", "number", nAdjMonth);
end
function adjustYears(n)
	DB.setValue("calendar.current.year", "number", DB.getValue("calendar.current.year", 0) + n);
end

function setCurrentDay(nDay)
	DB.setValue("calendar.current.day", "number", nDay);
end
function setCurrentMonth(nMonth)
	DB.setValue("calendar.current.month", "number", nMonth);
end
function getCurrentYear()
	return DB.getValue("calendar.current.year", 0);
end
function getCurrentMonth()
	return DB.getValue("calendar.current.month", 0);
end
function getCurrentDay()
	return DB.getValue("calendar.current.day", 0);
end

function getLunarDay(nYear, nMonth, nDay)
	local nLunarDay;
	
	local sLunarDayCalc = DB.getValue("calendar.data.lunardaycalc", "")
	if aLunarDayCalc[sLunarDayCalc] then
		nLunarDay = aLunarDayCalc[sLunarDayCalc](nYear, nMonth, nDay);
	else
		local nDaysInWeek = CalendarManager.getDaysInWeek();
		if nDaysInWeek > 0 then
			local nStartDay = CalendarManager.getStartDayOfMonth(nMonth);
			nLunarDay = ((nDay - nStartDay) % nDaysInWeek) + 1;
		else
			nLunarDay = 0;
		end
	end
	
	return nLunarDay;
end
function getLunarWeek()
	local aLunarWeek = {};
	for i = 1, CalendarManager.getDaysInWeek() do
		table.insert(aLunarWeek, DB.getValue("calendar.data.lunarweek.day" .. i, ""));
	end
	return aLunarWeek;
end

function getStartDayOfMonth(nMonth)
	return DB.getValue("calendar.data.periods.period" .. nMonth .. ".start", 1);
end
function getDaysInMonth(nMonth)
	local nDays = DB.getValue("calendar.data.periods.period" .. nMonth .. ".days", 0);

	local sMonthVarCalc = DB.getValue("calendar.data.periodvarcalc", "")
	if aMonthVarCalc[sMonthVarCalc] then
		local nVar = aMonthVarCalc[sMonthVarCalc](nYear, nMonth);
		nDays = nDays + nVar;
	end
	
	return nDays;
end
function getDaysInWeek()
	return DB.getChildCount("calendar.data.lunarweek");
end
function getMonthsInYear()
	return DB.getChildCount("calendar.data.periods");
end

function calcRavnicaLunarDay(nYear, nMonth, nDay)
	local nLunarDay;
	if nMonth <= 1 then
		nLunarDay = nDay;
	elseif nMonth == 2 then
		nLunarDay = nDay + 31;
	elseif nMonth == 3 then
		nLunarDay = nDay + 61;
	elseif nMonth == 4 then
		nLunarDay = nDay + 92;
	elseif nMonth == 5 then
		nLunarDay = nDay + 122;
	elseif nMonth == 6 then
		nLunarDay = nDay + 153;
	elseif nMonth == 7 then
		nLunarDay = nDay + 184;
	elseif nMonth == 8 then
		nLunarDay = nDay + 214;
	elseif nMonth == 9 then
		nLunarDay = nDay + 245;
	elseif nMonth == 10 then
		nLunarDay = nDay + 275;
	elseif nMonth == 11 then
		nLunarDay = nDay + 306;
	elseif nMonth >= 12 then
		nLunarDay = nDay + 337;
	end

	nLunarDay = (((nYear - 1) * 365) + nLunarDay) % 7;
	if nLunarDay == 0 then
		return 7;
	end
	return nLunarDay;
end
function calcGregorianLunarDay(nYear, nMonth, nDay)
	local nZellerYear = nYear;
	local nZellerMonth = nMonth
	if nMonth < 3 then
		nZellerYear = nZellerYear - 1;
		nZellerMonth = nZellerMonth + 12;
	end
	local nZellerDay = (nDay + math.floor(2.6*(nZellerMonth + 1)) + nZellerYear + math.floor(nZellerYear / 4) + (6*math.floor(nZellerYear / 100)) + math.floor(nZellerYear / 400)) % 7;
	if nZellerDay == 0 then
		return 7;
	end
	return nZellerDay;
end
function calcGregorianMonthVar(nYear, nMonth)
	if nMonth == 2 then
		local nYear = DB.getValue("calendar.current.year", 0);
		if (nYear % 400) == 0 then
			return 1;
		elseif (nYear % 100) == 0 then
			return 0;
		elseif (nYear % 4) == 0 then
			return 1;
		end
	end
	
	return 0;
end
function displayImperialDay(nDay)
	return string.format("%03d", nDay);
end
function displayImperialDate(sEpoch, nYear, nMonth, nDay, bAddWeekDay, bShortOutput)
	local sDay = CalendarManager.displayImperialDay(nDay);
	
	local sOutput;
	if bShortOutput or (nYear == 0) then
		sOutput = sDay;
	else
		sOutput = string.format("%04d", nYear) .. "-" .. sDay;
	end
	if bAddWeekDay then
		local nWeekDay = CalendarManager.getLunarDay(nYear, nMonth, nDay);
		local sWeekDay = CalendarManager.getLunarDayName(nWeekDay);
		sOutput = sWeekDay .. ", " .. sOutput;
	end
	return sOutput
end
function calcGolarionLunarDay(nYear, nMonth, nDay)
	local nZellerYear = nYear;
	local nZellerMonth = nMonth;
	if nMonth < 3 then
		nZellerYear = nZellerYear - 1;
		nZellerMonth = nZellerMonth + 12;
	end
	local nZellerDay = (nDay + math.floor(2.6*(nZellerMonth + 1)) + nZellerYear + math.floor(nZellerYear / 8) -1)  % 7;
	if nZellerDay == 0 then
		return 7;
	end
	return nZellerDay;
end
function calcGolarionMonthVar(nYear, nMonth)
	if nMonth == 2 then
		local nYear = DB.getValue("calendar.current.year", 0);
		if (nYear % 8) == 0 then
			return 1;
		end
	end
	return 0;
end

function getDayString(nDay)
	local sDayFormat = DB.getValue("calendar.data.dayformat");
	if sDayFormat and aDayDisplay[sDayFormat] then
		return aDayDisplay[sDayFormat](nDay);
	end
	return tostring(nDay);
end
function getLunarDayName(nLunarDay)
	return DB.getValue("calendar.data.lunarweek.day" .. nLunarDay, "");
end
function getMonthName(nMonth)
	return DB.getValue("calendar.data.periods.period" .. nMonth .. ".name", "");
end

function getHolidayName(nMonth, nDay)
	local aHolidays = {};
	
	for _,v in pairs(DB.getChildren("calendar.data.periods.period" .. nMonth .. ".holidays")) do
		local nStartDay = DB.getValue(v, "startday", 0);
		local nDuration = DB.getValue(v, "duration", 1);
		local nEndDay;
		if nDuration > 1 then
			nEndDay = nStartDay + (nDuration - 1);
		else
			nEndDay = nStartDay;
		end

		if nDay >= nStartDay and nDay <= nEndDay then
			local sHoliday = DB.getValue(v, "name", "");
			if sHoliday ~= "" then
				table.insert(aHolidays, sHoliday);
			end
		end
	end
	
	return table.concat(aHolidays, " / ");
end
function isHoliday(nMonth, nDay)
	for _,v in pairs(DB.getChildren("calendar.data.periods.period" .. nMonth .. ".holidays")) do
		local nStartDay = DB.getValue(v, "startday", 0);
		local nDuration = DB.getValue(v, "duration", 1);
		local nEndDay;
		if nDuration > 1 then
			nEndDay = nStartDay + (nDuration - 1);
		else
			nEndDay = nStartDay;
		end

		if nDay >= nStartDay and nDay <= nEndDay then
			return true;
		end
	end
	
	return false;
end

function outputDate()
	local msg = {sender = "", font = "chatfont", icon = "portrait_gm_token", mode = "story"};
	msg.text = Interface.getString("message_calendardate") .. " " .. CalendarManager.getCurrentDateString();
	Comm.deliverChatMessage(msg);
end
function getCurrentDateString()
	local nDay = DB.getValue("calendar.current.day", 0);
	local nMonth = DB.getValue("calendar.current.month", 0);
	local nYear = DB.getValue("calendar.current.year", 0);
	local sEpoch = DB.getValue("calendar.current.epoch", "");
	
	return CalendarManager.getDateString(sEpoch, nYear, nMonth, nDay, true, false);
end
function getDateString(sEpoch, nYear, nMonth, nDay, bAddWeekDay, bShortOutput)
	local sDateFormat = DB.getValue("calendar.data.dateformat");
	if sDateFormat and aDateDisplay[sDateFormat] then
		return aDateDisplay[sDateFormat](sEpoch, nYear, nMonth, nDay, bAddWeekDay, bShortOutput);
	end
	
	local sMonth = CalendarManager.getMonthName(nMonth);
	local sDaySuffix;
	local nDaySuffix = (nDay % 100);
	if nDaySuffix > 10 and nDaySuffix < 20 then
		sDaySuffix = Interface.getString("message_calendardaysuffix_default");
	else
		sDaySuffix = Interface.getString("message_calendardaysuffix" .. (nDaySuffix % 10));
	end
	local sDay = tostring(nDay) .. sDaySuffix;
	
	local sOutput;
	if bShortOutput or (nYear == 0) then
		sOutput = sDay .. " " .. sMonth;
	else
		sOutput = sDay .. " " .. sMonth .. ", " .. nYear .. " " .. sEpoch;
	end
	if bAddWeekDay then
		local nWeekDay = CalendarManager.getLunarDay(nYear, nMonth, nDay);
		local sWeekDay = CalendarManager.getLunarDayName(nWeekDay);
		sOutput = sWeekDay .. ", " .. sOutput;
	end
	return sOutput;
end

function outputTime()
	local msg = {sender = "", font = "chatfont", icon = "portrait_gm_token", mode = "story"};
	msg.text = Interface.getString("message_calendartime") .. " " .. CalendarManager.getCurrentTimeString();
	Comm.deliverChatMessage(msg);
end
function getCurrentTimeString()
	local nHour = DB.getValue("calendar.current.hour", 0);
	local nMinute = DB.getValue("calendar.current.minute", 0);

	local sPhase = "AM";
	if nHour >= 12 then
		sPhase = "PM";
	end
	nHour = nHour % 12;
	if nHour == 0 then
		nHour = 12;
	end
	
	return string.format("%d:%02d %s", nHour, nMinute, sPhase);
end
function getDisplayHour()
	local nHour = DB.getValue("calendar.current.hour", 0);
	local sPhase = "AM";
	if nHour >= 12 then
		sPhase = "PM";
	end
	nHour = nHour % 12;
	if nHour == 0 then
		nHour = 12;
	end
	
	return nHour, sPhase;
end

function reset()
	for _,v in pairs(DB.getChildren("calendar.data")) do
		v.delete();
	end
	DB.setValue("calendar.data.complete", "number", 1);
end
function select(nodeSource)
	for _,v in pairs(DB.getChildren("calendar.data")) do
		v.delete();
	end
	DB.copyNode(nodeSource, "calendar.data");
	DB.setValue("calendar.data.complete", "number", 1);
end
