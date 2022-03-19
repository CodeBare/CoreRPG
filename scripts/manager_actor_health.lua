-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Standard detailed health statuses
STATUS_HEALTHY = "Healthy"; -- 0% Wounded
STATUS_LIGHT = "Light"; -- <25% Wounded
STATUS_MODERATE = "Moderate"; -- <50% Wounded
STATUS_HEAVY = "Heavy"; -- <75% Wounded
STATUS_CRITICAL = "Critical"; -- <100% Wounded
STATUS_DEAD = "Dead"; -- >=100% Wounded

-- Simplified health statuses
STATUS_SIMPLE_WOUNDED = "Wounded"; -- <50% Wounded
STATUS_SIMPLE_HEAVY = "Heavy"; -- <100% Wounded

-- Special case statuses for common game system conditions
STATUS_DESTROYED = "Destroyed";
STATUS_DYING = "Dying";
STATUS_UNCONSCIOUS = "Unconscious";
STATUS_DISABLED = "Disabled";
STATUS_STAGGERED = "Staggered";

local _tStatusHealthColor = {};

function registerStatusHealthColor(sStatus, sColor)
	_tStatusHealthColor[sStatus] = sColor;
end

function getWoundPercent(v)
	return 0, STATUS_HEALTHY;
end

function getHealthStatus(v)
	local _,sStatus = ActorHealthManager.getWoundPercent(v);
	return sStatus;
end

-- Based on the percent wounded, change the font color for the Wounds field
function getHealthColor(v)
	local _,_,sColor = ActorHealthManager.getHealthInfo(v);
	return sColor;
end

-- Based on the percent wounded, change the font color for the Wounds field
function getHealthInfo(v)
	local nPercentWounded,sStatus = ActorHealthManager.getWoundPercent(v);
	
	local sColor = _tStatusHealthColor[sStatus];
	if not sColor then
		sColor = ColorManager.getHealthColor(nPercentWounded, false);
	end

	return nPercentWounded,sStatus,sColor;
end

function getTokenHealthInfo(v)
	local nPercentWounded,sStatus = ActorHealthManager.getWoundPercent(v);
	
	local sColor = _tStatusHealthColor[sStatus];
	if not sColor then
		sColor = ColorManager.getTokenHealthColor(nPercentWounded, true);
	end

	return nPercentWounded,sStatus,sColor;
end

function getDefaultStatusFromWoundPercent(nPercentWounded)
	local sStatus;
	if nPercentWounded <= 0 then
		sStatus = ActorHealthManager.STATUS_HEALTHY;
	elseif nPercentWounded >= 1 then
		sStatus = ActorHealthManager.STATUS_DEAD;
	else
		local bDetailedStatus = OptionsManager.isOption("WNDC", "detailed");

		if bDetailedStatus then
			if nPercentWounded >= .75 then
				sStatus = ActorHealthManager.STATUS_CRITICAL;
			elseif nPercentWounded >= .5 then
				sStatus = ActorHealthManager.STATUS_HEAVY;
			elseif nPercentWounded >= .25 then
				sStatus = ActorHealthManager.STATUS_MODERATE;
			else
				sStatus = ActorHealthManager.STATUS_LIGHT;
			end
		else
			if nPercentWounded >= .5 then
				sStatus = ActorHealthManager.STATUS_SIMPLE_HEAVY;
			else
				sStatus = ActorHealthManager.STATUS_SIMPLE_WOUNDED;
			end
		end
	end
	return sStatus;
end

function isDyingOrDead(rActor)
	local _, sStatus = ActorHealthManager.getWoundPercent(rActor);
	return ActorHealthManager.isDyingOrDeadStatus(sStatus);
end
function isDyingOrDeadStatus(sStatus)
	return ((sStatus == ActorHealthManager.STATUS_DYING) or 
			(sStatus == ActorHealthManager.STATUS_DEAD) or 
			(sStatus == ActorHealthManager.STATUS_DESTROYED));
end
