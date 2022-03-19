-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onClickDown()
	return window.onClickDown();
end
function onClickRelease()
	return window.onClickRelease();
end
function onDragStart(button, x, y, draginfo)
	return window.onDragStart(button, x, y, draginfo);
end
function onDragEnd(draginfo)
	return window.onDragEnd(draginfo);
end
