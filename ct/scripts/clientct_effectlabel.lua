-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onValueChanged();
end

function onValueChanged()
	setTooltipText(EffectManager.getEffectString(window.getDatabaseNode()));
end

function onDragStart(button, x, y, draginfo)
	if window.onDragStart then
		return window.onDragStart(button, x, y, draginfo);
	end
end
