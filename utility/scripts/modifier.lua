-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onDrop(x, y, draginfo)
	return windowlist.onDrop(x, y, draginfo);
end

function actionDrag(draginfo)
	if not label.isEmpty() then
		draginfo.setType("number");
		draginfo.setDescription(label.getValue());
		draginfo.setStringData(label.getValue());
		draginfo.setNumberData(bonus.getValue());
	end
	return true;
end

function action()
	ModifierStack.addSlot(label.getValue(), bonus.getValue());
	return true;
end
