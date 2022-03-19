-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bLocked = false;
local sLink = nil;

function onInit()
	if not Session.IsHost then
		setReadOnly(true);
	end

	if self.update then
		self.update();
	end
end

function onClose()
	if sLink then
		DB.removeHandler(sLink, "onUpdate", onLinkUpdated);
	end
end

function onDrop(x, y, draginfo)
	if Session.IsHost then
		if draginfo.getType() ~= "string" then
			return false;
		end

		if self.handleDrop then
			self.handleDrop(draginfo);
			return true;
		end
	end
end

function onValueChanged()
	if sLink then
		if not bLocked then
			bLocked = true;

			if self.update then
				self.update();
			end

			if sLink and not isReadOnly() then
				DB.setValue(sLink, "string", getValue());
			end

			bLocked = false;
		end
	else
		if self.update then
			self.update();
		end
	end
end

function onLinkUpdated()
	if sLink and not bLocked then
		bLocked = true;

		setValue(DB.getValue(sLink, ""));

		if self.update then
			self.update();
		end

		bLocked = false;
	end
end

function setLink(dbnode, bLock)
	if sLink then
		DB.removeHandler(sLink, "onUpdate", onLinkUpdated);
		sLink = nil;
	end
		
	if dbnode then
		sLink = dbnode.getPath();

		if not nolinkwidget then
			addBitmapWidget("field_linked").setPosition("bottomright", 0, -2);
		end
		
		if bLock == true then
			setReadOnly(true);
		end

		DB.addHandler(sLink, "onUpdate", onLinkUpdated);
		onLinkUpdated();
	end
end
