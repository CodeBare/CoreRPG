-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sTarget = "";

function setTarget(sTargetParam)
	sTarget = sTargetParam;
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	return window[sTarget].activate(button);
end

function onHover(oncontrol)
	window[sTarget].refreshButtonDisplay(oncontrol);
end

