-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	CharacterListManager.registerWindow(self);
	onLockStateChanged();
end

function onHover(bOnWindow)
	if getLockState() then
		if bOnWindow then
			button_lock.setVisible(true);
		else
			button_lock.setVisible(false);
		end
	end
end

function onLockStateChanged()
	if getLockState() then
		setFrame();
		button_lock.setValue(1);
		button_reset.setVisible(false);
	else
		setFrame("border");
		button_lock.setValue(0);
		button_reset.setVisible(true);
	end
end

function onLockButtonPressed()
	if button_lock.getValue() == 1 then
		setLockState(true);
	else
		setLockState(false);
	end
end

function onResetButtonPressed()
	resetPosition();
end
