-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local tEffects = VisionManager.getLightPresetEffects();
	if #tEffects > 0 then
		for _,rEffect in ipairs(tEffects) do
			local w = lights_list.createWindow();
			w.setEffect(rEffect);
		end
	else
		lights_label.setVisible(false);
		lights_list.setVisible(false);
	end

	if DataCommon and DataCommon.conditions and (#(DataCommon.conditions) > 0) then
		for _,sCondition in ipairs(DataCommon.conditions) do
			local rEffect = { sName = StringManager.capitalize(sCondition) };
			local w = conditions_list.createWindow();
			w.setEffect(rEffect);
		end
	else
		conditions_label.setVisible(false);
		conditions_list.setVisible(false);
	end
end
