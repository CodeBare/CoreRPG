-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	buildCalendarWindows();
end

function rebuildCalendarWindows()
	closeAll();
	buildCalendarWindows();
end

function buildCalendarWindows()
	local nYear = CalendarManager.getCurrentYear();
	local aLunarWeek = CalendarManager.getLunarWeek();
	local nMonthsInYear = CalendarManager.getMonthsInYear();
	
	local nColumnWidth = (#aLunarWeek * 25) + 15;
	if nColumnWidth < 75 then
		nColumnWidth = 75;
	end
	setColumnWidth(nColumnWidth);

	for nMonth = 1, nMonthsInYear do
		local wMonth = createWindow();
		wMonth.month.setValue(nMonth);

		for i = 1, #aLunarWeek do
			local wHeader = wMonth.list_days.createWindow();
			wHeader.day.setValue(0);

			wHeader.label_day.setFont("calendarday-b");
			wHeader.label_day.setStateFrame("hover", "null", 0,0,0,0);
			local sUTF8Substring = StringUTF8Manager.getSubstringPositive(aLunarWeek[i], 1, 2);
			wHeader.label_day.setValue(sUTF8Substring);
		end
		
		local nStartDay = CalendarManager.getStartDayOfMonth(nMonth);
		local nLunarDay = CalendarManager.getLunarDay(nYear, nMonth, nStartDay);
		for i = 2, nLunarDay do
			local wBlank = wMonth.list_days.createWindow();
			wBlank.day.setValue(0);
			wBlank.label_day.setStateFrame("hover", "null", 0,0,0,0);
		end
		
		local nDaysInMonth = CalendarManager.getDaysInMonth(nMonth);
		local nMonthLength = nDaysInMonth + nStartDay - 1;
		for i = nStartDay, nMonthLength do
			local wDay = wMonth.list_days.createWindow();
			wDay.day.setValue(i);

			wDay.label_day.setValue(CalendarManager.getDayString(i));
			if CalendarManager.isHoliday(nMonth, i) then
				wDay.label_day.setTooltipText(CalendarManager.getHolidayName(nMonth, i));
			end
		end
	end
end

function scrollToCampaignDate()
	local nMonth = CalendarManager.getCurrentMonth();
	for _,v in pairs(getWindows()) do
		if v.month.getValue() == nMonth then
			scrollToWindow(v);
			break;
		end
	end
end
