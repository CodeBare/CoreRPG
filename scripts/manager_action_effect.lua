-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	Interface.onHotkeyDrop = onHotkeyDrop;

	ActionsManager.registerResultHandler("effect", onEffect);
end

function onHotkeyDrop(draginfo)
	local rEffect = EffectManager.decodeEffectFromDrag(draginfo);
	if rEffect then
		draginfo.setSlot(1);
		draginfo.setStringData(EffectManager.encodeEffectAsText(rEffect));
	end
end

function getRoll(draginfo, rActor, rAction)
	local rRoll = EffectManager.encodeEffect(rAction);
	if rRoll.sDesc == "" then
		return nil;
	end
	
	if draginfo and Input.isShiftPressed() then
		local aTargetNodes = {};
		local aTargets;
		if rRoll.bSelfTarget then
			aTargets = { rActor };
		else
			aTargets = TargetingManager.getFullTargets(rActor);
		end
		for _,v in ipairs(aTargets) do
			local sCTNode = ActorManager.getCTNodeName(v);
			if sCTNode ~= "" then
				table.insert(aTargetNodes, sCTNode);
			end
		end
		
		if #aTargetNodes > 0 then
			rRoll.aTargets = table.concat(aTargetNodes, "|");
		end
	end
	
	return rRoll;
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = ActionEffect.getRoll(draginfo, rActor, rAction);
	if not rRoll then
		return false;
	end
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
	return true;
end

function onEffect(rSource, rTarget, rRoll)
	-- Decode effect from roll
	local rEffect = EffectManager.decodeEffect(rRoll);
	if not rEffect then
		ChatManager.SystemMessage(Interface.getString("ct_error_effectdecodefail"));
		return;
	end
	
	-- If no target, then report to chat window and exit
	if not rTarget then
		EffectManager.onUntargetedDrop(rEffect);
		rRoll.sDesc = EffectManager.encodeEffectAsText(rEffect);

		-- Report effect to chat window
		local rMessage = ActionsManager.createActionMessage(nil, rRoll);
		rMessage.icon = "roll_effect";
		Comm.deliverChatMessage(rMessage);
		return;
	end

	-- If target not in combat tracker, then we're done
	local sTargetCT = ActorManager.getCTNodeName(rTarget);
	if sTargetCT == "" then
		ChatManager.SystemMessage(Interface.getString("ct_error_effectdroptargetnotinct"));
		return;
	end

	-- If effect is not a CT effect drag, then figure out source and init
	if rEffect.sSource == "" then
		local sSourceCT = "";
		if rSource then
			sSourceCT = ActorManager.getCTNodeName(rSource);
		end
		if sSourceCT == "" then
			local nodeTempCT = nil;
			if Session.IsHost then
				nodeTempCT = CombatManager.getActiveCT();
			else
				nodeTempCT = CombatManager.getCTFromNode("charsheet." .. User.getCurrentIdentity());
			end
			if nodeTempCT then
				sSourceCT = nodeTempCT.getPath();
			end
		end
		if sSourceCT ~= "" then
			rEffect.sSource = sSourceCT;
			EffectManager.onEffectSourceChanged(rEffect, DB.findNode(sSourceCT));
		end
	end
	
	-- If source is same as target, then don't specify a source
	if rEffect.sSource == sTargetCT then
		rEffect.sSource = "";
	end
	
	-- If source is non-friendly faction and target does not exist or is non-friendly, then effect should be GM only
	if (rSource and not ActorManager.isFaction(rSource, "friend")) and (not rTarget or not ActorManager.isFaction(rTarget, "friend")) then
		rEffect.nGMOnly = 1;
	end
	
	-- Resolve
	-- If shift-dragging, then apply to the source actor targets, then target the effect to the drop target
	if rRoll.aTargets then
		local aTargets = StringManager.split(rRoll.aTargets, "|");
		for _,v in ipairs(aTargets) do
			rEffect.sTarget = sTargetCT;
			EffectManager.notifyApply(rEffect, v);
		end
	
	-- Otherwise, just apply effect to drop target normally
	else
		EffectManager.notifyApply(rEffect, sTargetCT);
	end
end
