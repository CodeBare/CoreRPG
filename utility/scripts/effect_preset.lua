-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local rInternalEffect = nil;

function setEffect(rEffect)
	button.setText(rEffect.sDisplayName or rEffect.sName);
	rInternalEffect = rEffect;
end

function getEffect()
	return rInternalEffect;
end

function onDragStart(button, x, y, draginfo)
	return ActionEffect.performRoll(draginfo, nil, rInternalEffect);
end

function onButtonPress(x, y)
	local rRoll = ActionEffect.getRoll(nil, nil, rInternalEffect);
	if not rRoll then
		return true;
	end
	
	rRoll.sType = "effect";

	local rTarget = nil;
	if Session.IsHost then
		rTarget = ActorManager.resolveActor(CombatManager.getActiveCT());
	else
		rTarget = ActorManager.resolveActor(CombatManager.getCTFromNode("charsheet." .. User.getCurrentIdentity()));
	end
	
	ActionsManager.resolveAction(nil, rTarget, rRoll);
	return true;
end
