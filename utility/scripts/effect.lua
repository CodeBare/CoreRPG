-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function actionDrag(draginfo)
	local rEffect = EffectManager.getEffect(getDatabaseNode());
	if not rEffect or (rEffect.sName or "") == "" then
		return true;
	end
	return ActionEffect.performRoll(draginfo, nil, rEffect);
end

function action()
	local rEffect = EffectManager.getEffect(getDatabaseNode());
	if not rEffect or (rEffect.sName or "") == "" then
		return false;
	end
	local rRoll = ActionEffect.getRoll(nil, nil, rEffect);
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

function onGainFocus()
	window.setFrame("rowshade");
end

function onLoseFocus()
	window.setFrame(nil);
end
