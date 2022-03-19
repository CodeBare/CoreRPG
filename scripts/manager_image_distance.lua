-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	Interface.onDesktopInit = onDesktopInit;
end
function onDesktopInit()
	if Session.IsHost then
		ImageDistanceManager.setupDistanceOption();
	end
	OptionsManager.registerCallback("HRDD", ImageDistanceManager.onDistanceOptionChanged);
	ImageDistanceManager.onDistanceOptionChanged();
end

function setupDistanceOption()
	local sExisting = DB.getValue("options.HRDD");
	if not sExisting then
		local nDefault = Interface.getDistanceDiagMult();
		if nDefault <= 0 then
			OptionsManager.setOption("HRDD", "raw");
		elseif nDefault == 1.5 then
			OptionsManager.setOption("HRDD", "variant");
		else
			OptionsManager.setOption("HRDD", "");
		end
	end
end

function onDistanceOptionChanged()
	if OptionsManager.isOption("HRDD", "variant") then
		Interface.setDistanceDiagMult(1.5);
	elseif OptionsManager.isOption("HRDD", "raw") then
		Interface.setDistanceDiagMult("*");
	else
		Interface.setDistanceDiagMult(1);
	end
end

