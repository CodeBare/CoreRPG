-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onLoseFocus()
	super.onLoseFocus();
	window.windowlist.updateContainers();
end
