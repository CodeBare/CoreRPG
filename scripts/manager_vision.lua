-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- NOTE: Low-light vision mechanics not supported (i.e. light multiplication) (3.5E/PFRPG) 

DEFAULT_LIGHT_COLOR = "FFFFFFFF";
DEFAULT_LIGHT_FALLOFF_BRIGHT = 25;
DEFAULT_LIGHT_FALLOFF_DIM = 50;
DEFAULT_LIGHT_ANIM_SPEED = 100;

SETTINGS_TOKENLIGHT_LIST = "settings.tokenlight";

local _tTokenLightPresets = {};
-- NOTE: .sName assigned dynamically from string asset "lighting_" .. <key> in populateLightPresets
-- NOTE: .sEffectTag assigned dynamically from string asset "lighting_" .. <key> .. "_tag" in populateLightPresets
local _tTokenLightDefaults = {
	["candle"] = {
		sColor = "FFFFFCC3",
		nBright = 1,
		nDim = 2,
		sAnimType = "flicker",
		nAnimSpeed = 100,
		nDuration = 600,
	},
	["lamp"] = {
		sColor = "FFFFF3E1",
		nBright = 3,
		nDim = 9,
		sAnimType = "flicker",
		nAnimSpeed = 25,
		nDuration = 3600,
	},
	["torch"] = {
		sColor = "FFFFF3E1",
		nBright = 4,
		nDim = 8,
		sAnimType = "flicker",
		nAnimSpeed = 25,
		nDuration = 600,
	},
	["lantern"] = {
		sColor = "FFF9FEFF",
		nBright = 6,
		nDim = 12,
		nDuration = 3600,
	},
	["spell_darkness"] = {
		sColor = "FF000000",
		nBright = 3,
		nDim = 3,
		nDuration = 100,
	},
	["spell_light"] = {
		sColor = "FFFFF3E1",
		nBright = 4,
		nDim = 8,
		nDuration = 600,
	},
};

local _tVisionTypes = {};
local _tVisionTypesBlinded = {};
local _tVisionFields = { "senses" };

function onInit()
	Interface.onDesktopInit = onDesktopInit;

	if Session.IsHost then
		DB.createNode(VisionManager.SETTINGS_TOKENLIGHT_LIST).setPublic(true);

		EffectManager.registerEffectCompType("LIGHT", { bIgnoreExpire = true, bIgnoreTarget = true });
		EffectManager.registerEffectCompType("VISION", { bIgnoreExpire = true, bIgnoreTarget = true });
		EffectManager.registerEffectCompType("VISMAX", { bIgnoreExpire = true, bIgnoreTarget = true });
		EffectManager.registerEffectCompType("VISMOD", { bIgnoreExpire = true, bIgnoreTarget = true });

		VisionManager.addVisionType(Interface.getString("vision_darkvision"), "darkvision");
		VisionManager.addVisionType(Interface.getString("vision_blindsight"), "blindsight", true);
		VisionManager.addVisionType(Interface.getString("vision_truesight"), "truesight");
	end
end

function onDesktopInit()
	if Session.IsHost then
		if DB.getChildCount(VisionManager.SETTINGS_TOKENLIGHT_LIST) == 0 then
			populateLightPresets();
		end
		updateLightPresets();
		DB.addHandler(VisionManager.SETTINGS_TOKENLIGHT_LIST, "onChildUpdate", updateLightPresets);
		
		for _,vField in ipairs(_tVisionFields) do
			CombatManager.addCombatantFieldChangeHandler(vField, "onUpdate", updateTokenVision);
		end
	else
		updateLightPresets();
		DB.addHandler(VisionManager.SETTINGS_TOKENLIGHT_LIST, "onChildUpdate", updateLightPresets);
	end
end

function onClose()
	if Session.IsHost then
		DB.removeHandler(SETTINGS_TOKENLIGHT_LIST, "onChildUpdate", updateLightPresets);
	end
end

--
-- LIGHTING FUNCTIONS
--

function clearLightDefaults()
	_tTokenLightDefaults = {};
end
function addLightDefault(sKey, rLight)
	if sKey and rLight and (sKey ~= "") then
		_tTokenLightDefaults[sKey] = rLight;
	end
end
function addLightDefaults(tLights)
	for sKey,rLight in pairs(tLights) do
		VisionManager.addLightDefault(sKey, rLight);
	end
end
function removeLightDefault(sKey)
	_tTokenLightDefaults[sKey] = nil;
end

function clearLightPresets()
	_tTokenLightPresets = {};
end
function addLightPreset(tLight)
	table.insert(_tTokenLightPresets, tLight);
end
function populateLightPresets()
	for sKey,tLight in pairs(_tTokenLightDefaults) do
		tLight.sName = Interface.getString("lighting_" .. sKey);
		if tLight.sName == "" then
			tLight.sName = sKey;
		end
		tLight.sEffectTag = Interface.getString("lighting_" .. sKey .. "_tag"):lower();
		if tLight.sEffectTag == "" then
			tLight.sEffectTag = tLight.sName:lower();
		end

		local nodeLight = DB.createChild(VisionManager.SETTINGS_TOKENLIGHT_LIST);
		DB.setValue(nodeLight, "name", "string", tLight.sName or "");
		DB.setValue(nodeLight, "color", "string", tLight.sColor or "");
		DB.setValue(nodeLight, "bright", "number", (tLight.nBright or 0) * GameSystem.getDistanceUnitsPerGrid());
		DB.setValue(nodeLight, "dim", "number", (tLight.nDim or 0) * GameSystem.getDistanceUnitsPerGrid());
		DB.setValue(nodeLight, "falloff", "number", tLight.nBrightFalloff or VisionManager.DEFAULT_LIGHT_FALLOFF_BRIGHT);
		DB.setValue(nodeLight, "dimfalloff", "number", tLight.nDimFalloff or VisionManager.DEFAULT_LIGHT_FALLOFF_DIM);
		DB.setValue(nodeLight, "animtype", "string", tLight.sAnimType or "");
		DB.setValue(nodeLight, "animspeed", "number", tLight.nAnimSpeed or VisionManager.DEFAULT_LIGHT_ANIM_SPEED);
		DB.setValue(nodeLight, "tag", "string", tLight.sEffectTag or "");
		DB.setValue(nodeLight, "duration", "number", tLight.nDuration or 0);
	end
end
function updateLightPresets()
	VisionManager.clearLightPresets();
	for _,nodeLight in pairs(DB.getChildren(VisionManager.SETTINGS_TOKENLIGHT_LIST)) do
		local tLight = {};
		tLight.sName = DB.getValue(nodeLight, "name", "");
		tLight.sColor = DB.getValue(nodeLight, "color", "");
		tLight.nBright = DB.getValue(nodeLight, "bright", 0);
		tLight.nDim = DB.getValue(nodeLight, "dim", 0);
		tLight.nBrightFalloff = DB.getValue(nodeLight, "falloff", VisionManager.DEFAULT_LIGHT_FALLOFF_BRIGHT);
		tLight.nDimFalloff = DB.getValue(nodeLight, "dimfalloff", VisionManager.DEFAULT_LIGHT_FALLOFF_DIM);
		tLight.sAnimType = DB.getValue(nodeLight, "animtype", "");
		tLight.nAnimSpeed = DB.getValue(nodeLight, "animspeed", VisionManager.DEFAULT_LIGHT_ANIM_SPEED);
		tLight.sEffectTag = DB.getValue(nodeLight, "tag", "");
		tLight.nDuration = DB.getValue(nodeLight, "duration", 0);

		VisionManager.addLightPreset(tLight);
	end
end

function getLightPresetEffects()
	local tEffects = {};
	for _,rLight in ipairs(_tTokenLightPresets) do
		local sEffectTag = rLight.sEffectTag;
		if sEffectTag == "" then
			sEffectTag = rLight.sName;
		end
		local nBright = rLight.nBright;
		local nDim = rLight.nDim;
		if (sEffectTag ~= "") and ((nBright > 0) or (nDim > 0)) then
			local sEffect = "LIGHT: " .. nBright;
			if nDim ~= (2 * nBright) then
				sEffect = sEffect .. "/" .. nDim;
			end
			sEffect = sEffect .. " " .. sEffectTag;

			local rEffect = {};
			rEffect.sDisplayName = rLight.sName;
			rEffect.sName = sEffect;
			rEffect.nDuration = rLight.nDuration or 0;
			table.insert(tEffects, rEffect);
		end
	end
	table.sort(tEffects, function(a,b) return a.sDisplayName < b.sDisplayName end);
	return tEffects;
end

--
-- VISION FUNCTIONS
--

function addVisionType(sText, sKey, bIgnoreBlind)
	_tVisionTypes[sText:lower()] = sKey;
	if bIgnoreBlind then
		_tVisionTypesBlinded[sText:lower()] = sKey;
	end
end
function removeVisionType(sText)
	_tVisionTypes[sText:lower()] = nil;
	_tVisionTypesBlinded[sText:lower()] = nil;
end

function clearVisionFields()
	_tVisionFields = {};
end
function addVisionField(s)
	if (s or "") ~= "" then
		table.insert(_tVisionFields, s);
	end
end
function getVisionFields()
	return _tVisionFields;
end

--
-- TOKEN UPDATE FUNCTIONS
--

function updateTokenVision(nodeField)
	local nodeCT = nodeField.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		VisionManager.updateTokenVisionHelper(tokenCT, nodeCT);
	end
end
function updateTokenVisionHelper(tokenCT, nodeCT)
	local rToken = VisionManager.getTokenVisionInfo(tokenCT, nodeCT);
	if not rToken then
		return;
	end

	VisionManager.removeCurrentVisions(rToken);

	VisionManager.processSenseVisions(rToken);
	VisionManager.processEffectVisions(rToken);

	VisionManager.addTokenVisions(rToken);

	VisionManager.saveTokenVisionInfo(rToken);
end
function getTokenVisionInfo(tokenCT, nodeCT)
	if not tokenCT or not nodeCT then
		return nil;
	end

	local rActor = ActorManager.resolveActor(nodeCT);
	local bDefaultVision = not EffectManager.hasEffect(rActor, "Blinded");
	local nTokenDistanceBaseUnits = tokenCT.getImageDistanceBaseUnits();

	local rToken = {
		actor = rActor,
		token = tokenCT,
		distanceunits = nTokenDistanceBaseUnits,
		node = nodeCT,
		vision_ids = {},
		defaultvision = bDefaultVision,
		defaultrange = 0,
		visions = {},
		rangemax = 0,
		rangemod = 0,
	};
	local sVisions = DB.getValue(nodeCT, "addedvisions", "");
	if sVisions ~= "-" then
		if sVisions ~= "" then
			local tVisions = StringManager.split(sVisions, "|");
			for _,v in ipairs(tVisions) do
				local nVisionID = tonumber(v) or 0;
				if nVisionID > 0 then
					table.insert(rToken.vision_ids, nVisionID);
				end
			end
		else
			rToken.visionreset = true;
		end
	end
	return rToken;
end
function removeCurrentVisions(rToken)
	if rToken.visionreset then
		rToken.token.resetVisions();
	else
		for _,nVisionID in ipairs(rToken.vision_ids) do
			rToken.token.removeVision(nVisionID);
		end
		rToken.vision_ids = {};
	end
end
function processSenseVisions(rToken)
	for _,vField in ipairs(VisionManager.getVisionFields()) do
		if DB.getType(DB.getPath(rToken.node, vField)) == "string" then
			local sSensesLower = DB.getValue(rToken.node, vField, ""):lower();
			local tSenses = StringManager.split(sSensesLower, ",;\r\n", true);
			for _,v in ipairs(tSenses) do
				VisionManager.processTokenVisionHelper(rToken, v, v:match("(%d+)"));
			end
		end
	end
end
function processEffectVisions(rToken)
	local tEffects = EffectManager.getEffectsByType(rToken.actor, "VISION");
	for _,vEffect in ipairs(tEffects) do
		local sVision = "";
		if vEffect.remainder then
			sVision = table.concat(vEffect.remainder, " ");
		end
		local nDistance = vEffect.mod or 0;
		if sVision == "" then
			if nDistance >= 0 then
				rToken.defaultrange = math.max(rToken.defaultrange or 0, nDistance);
			end
		else
			VisionManager.processTokenVisionHelper(rToken, sVision, nDistance);
		end
	end

	local tEffects = EffectManager.getEffectsByType(rToken.actor, "VISMAX");
	for _,vEffect in ipairs(tEffects) do
		local nDistance = vEffect.mod or 0;
		if nDistance >= 0 then
			rToken.rangemax = math.max(rToken.rangemax or 0, nDistance);
		end
	end

	local tEffects = EffectManager.getEffectsByType(rToken.actor, "VISMOD");
	for _,vEffect in ipairs(tEffects) do
		rToken.rangemod = (rToken.rangemod or 0) + (vEffect.mod or 0);
	end
end
function processTokenVisionHelper(rToken, sText, nDistance)
	if rToken.defaultvision then
		for kVisionType, sVisionTypeMap in pairs(_tVisionTypes) do
			if StringManager.startsWith(sText, kVisionType) then
				VisionManager.processTokenVisionHelper2(rToken, sVisionTypeMap, nDistance);
				return;
			end
		end
	else
		for kVisionType, sVisionTypeMap in pairs(_tVisionTypesBlinded) do
			if StringManager.startsWith(sText, kVisionType) then
				VisionManager.processTokenVisionHelper2(rToken, sVisionTypeMap, nDistance);
				return;
			end
		end
	end
end
function processTokenVisionHelper2(rToken, sVision, nDistance)
	nDistance = tonumber(nDistance) or 0;

	if rToken.visions[sVision] then
		if rToken.visions[sVision] ~= 0 then
			rToken.visions[sVision] = math.max(rToken.visions[sVision], nDistance);
		end
	else
		rToken.visions[sVision] = nDistance;
	end
end
function addTokenVisions(rToken)
	for sVision,nDistance in pairs(rToken.visions) do
		local nGridDistance = VisionManager.calcTokenVisionGridDistance(rToken, sVision, nDistance);
		if nGridDistance >= 0 then
			-- If vision created, add to tracking
			local nVisionID = rToken.token.addVision(sVision, nGridDistance);
			if nVisionID > 0 then
				table.insert(rToken.vision_ids, nVisionID);
			end
		end
	end

	local nDefaultGridDistance = VisionManager.calcTokenVisionGridDistance(rToken, "", rToken.defaultrange);
	if nDefaultGridDistance < 0 then
		rToken.token.setDefaultVision(false);
		rToken.token.setDefaultVisionRange(0);
	else
		rToken.token.setDefaultVision(rToken.defaultvision);
		rToken.token.setDefaultVisionRange(nDefaultGridDistance);
	end
end
-- Return 0 for infinite, positive for limited, -1 for none
function calcTokenVisionGridDistance(rToken, sVision, nDistance)
	local bApplyMaxMod = true;
	for _,sVisionTypeMap in pairs(_tVisionTypesBlinded) do
		if sVision == sVisionTypeMap then
			bApplyMaxMod = false;
			break;
		end
	end

	if bApplyMaxMod then
		local nLimitedDistance;
		if rToken.rangemax <= 0 then
			nLimitedDistance = nDistance;
		else
			if nDistance <= 0 then
				nLimitedDistance = rToken.rangemax;
			else
				nLimitedDistance = math.min(nDistance, rToken.rangemax);
			end
		end

		local nReducedDistance;
		if rToken.rangemod == 0 then
			nReducedDistance = nLimitedDistance;
		else
			if nLimitedDistance <= 0 then
				nReducedDistance = nLimitedDistance;
			else
				nReducedDistance = nLimitedDistance + rToken.rangemod;
				if nReducedDistance <= 0 then
					nReducedDistance = -1;
				end
			end
		end

		nDistance = nReducedDistance;
	end

	if nDistance < 0 then
		return -1;
	end

	local nGridDistance = math.floor(nDistance / rToken.distanceunits);
	if (nGridDistance <= 0) and (nDistance ~= 0) then
		return -1;
	end

	return nGridDistance;
end
function saveTokenVisionInfo(rToken)
	if #(rToken.vision_ids) > 0 then
		DB.setValue(rToken.node, "addedvisions", "string", table.concat(rToken.vision_ids, "|"));
	else
		DB.setValue(rToken.node, "addedvisions", "string", "-");
	end
end

function updateTokenLightingHelper(tokenCT, nodeCT)
	local rToken = VisionManager.getTokenLightingInfo(tokenCT, nodeCT);
	if not rToken then
		return;
	end

	VisionManager.removeCurrentLights(rToken);

	VisionManager.addEffectLights(rToken);

	VisionManager.saveTokenLightingInfo(rToken);
end
function getTokenLightingInfo(tokenCT, nodeCT)
	if not tokenCT or not nodeCT then
		return nil;
	end

	local rActor = ActorManager.resolveActor(nodeCT);
	local nTokenDistanceBaseUnits = tokenCT.getImageDistanceBaseUnits();
	
	local rToken = {
		actor = rActor,
		token = tokenCT,
		distanceunits = nTokenDistanceBaseUnits,
		node = nodeCT,
		lights = {},
	};
	if rToken.token.removeLight then
		local sLights = DB.getValue(rToken.node, "addedlights", "");
		if sLights ~= "-" then
			if sLights ~= "" then
				local tLights = StringManager.split(sLights, "|");
				for _,v in ipairs(tLights) do
					local nLightID = tonumber(v) or 0;
					if nLightID > 0 then
						table.insert(rToken.lights, nLightID);
					end
				end
			else
				rToken.lightreset = true;
			end
		end
	end
	return rToken;
end
function removeCurrentLights(rToken)
	if rToken.token.removeLight then
		if rToken.lightreset then
			rToken.token.resetLights();
		else
			for _,nLightID in ipairs(rToken.lights) do
				rToken.token.removeLight(nLightID);
			end
			rToken.lights = {};
		end
	else
		rToken.token.resetLights();
	end
end
function addEffectLights(rToken)
	local tEffects = EffectManager.getEffectsByType(rToken.actor, "LIGHT");
	for _,vEffect in ipairs(tEffects) do
		VisionManager.addTokenLightHelper(rToken, vEffect.mod, vEffect.remainder);
	end
end
function addTokenLightHelper(rToken, nDistance, tRemainder)
	local nRemainderIndex = 1;
	local nBrightDistance = (nDistance or 0);
	local nDimDistance = nil;

	-- If number is zero, check remainder
	if nBrightDistance == 0 and #tRemainder >= nRemainderIndex then
		local sBright, sDim = tRemainder[nRemainderIndex]:match("(%d+)[/\\](%d+)");
		-- If first remainder is bright/dim string, then use
		if sBright and sDim then
			nBrightDistance = tonumber(sBright) or 0;
			nDimDistance = tonumber(sDim) or 0;
			nRemainderIndex = nRemainderIndex + 1;
		-- Otherwise, if first remainder is light effect tag, use default light preset values
		else
			local sCheckLower = tRemainder[nRemainderIndex]:lower();
			for _, rLight in ipairs(_tTokenLightPresets) do
				if sCheckLower == rLight.sEffectTag:lower() then
					VisionManager.addTokenLightHelper2(
							rToken, 
							rLight.sColor, 
							rLight.nBright, 
							rLight.nDim, 
							rLight.nBrightFalloff, 
							rLight.nDimFalloff, 
							rLight.sAnimType, 
							rLight.nAnimSpeed);
					return;
				end
			end
		end
	end

	-- Otherwise, determine if there are two numbers in a row to denote dim distance value, or use default (2 * Bright)
	if not nDimDistance and #tRemainder >= nRemainderIndex then
		if StringManager.isNumberString(tRemainder[nRemainderIndex]) then
			nDimDistance = tonumber(tRemainder[nRemainderIndex]);
			nRemainderIndex = nRemainderIndex + 1;
		end
	end
	if not nDimDistance then
		nDimDistance = nBrightDistance * 2;
	end

	-- Next, determine if light effect tag defined, or otherwise treat remainder as "[color] <animtype> <animspeed>"
	local sColor = nil;
	local nBrightFalloff = nil;
	local nDimFalloff = nil;
	local sAnimType = nil;
	local nAnimSpeed = nil;
	if #tRemainder >= nRemainderIndex then
		local sCheckLower = tRemainder[nRemainderIndex]:lower();
		for _, rLight in ipairs(_tTokenLightPresets) do
			if sCheckLower == rLight.sEffectTag:lower() then
				sColor = rLight.sColor or VisionManager.DEFAULT_LIGHT_COLOR;
				nBrightFalloff = rLight.nBrightFalloff;
				nDimFalloff = rLight.nDimFalloff;
				sAnimType = rLight.sAnimType;
				nAnimSpeed = rLight.nAnimSpeed;
				break;
			end
		end
		if not sColor then
			sColor = sCheckLower;
			nRemainderIndex = nRemainderIndex + 1;
			if #tRemainder >= nRemainderIndex then
				sAnimType = tRemainder[nRemainderIndex]:lower();
				nRemainderIndex = nRemainderIndex + 1;
				if #tRemainder >= nRemainderIndex then
					nAnimSpeed = tonumber(tRemainder[nRemainderIndex]) or 0;
				end
			end
		end
	end

	-- If we have a color value, then try to create a light with it
	if sColor then
		VisionManager.addTokenLightHelper2(rToken, sColor, nBrightDistance, nDimDistance, nBrightFalloff, nDimFalloff, sAnimType, nAnimSpeed);
	end
end
function addTokenLightHelper2(rToken, sColor, nBrightDistance, nDimDistance, nBrightFalloff, nDimFalloff, sAnimType, nAnimSpeed)
	local nBrightGridDistance = math.floor(nBrightDistance / rToken.distanceunits);
	local nDimGridDistance = math.floor(nDimDistance / rToken.distanceunits);
	if nBrightGridDistance <= 0 and nDimGridDistance <= 0 then
		return;
	end

	local bInverse = false;
	if sColor then
		local sColorLower = sColor:lower();
		if (sColorLower == "ff000000") or (sColorLower == "000000") then
			bInverse = true;
		end
	else
		sColor = VisionManager.DEFAULT_LIGHT_COLOR;
	end

	-- 
	local tLight = {
		color = sColor,
		inverse = bInverse,
		bright = nBrightGridDistance,
		dim = nDimGridDistance,
		falloff = nBrightFalloff or VisionManager.DEFAULT_LIGHT_FALLOFF_BRIGHT,
		dimfalloff = nDimFalloff or VisionManager.DEFAULT_LIGHT_FALLOFF_DIM,
		animtype = sAnimType or "",
		animspeed = nAnimSpeed or VisionManager.DEFAULT_LIGHT_ANIM_SPEED,
	};
	local nLightID = rToken.token.addLight(tLight);

	-- If light created, add to tracking
	if rToken.token.removeLight and nLightID > 0 then
		table.insert(rToken.lights, nLightID);
	end
end
function saveTokenLightingInfo(rToken)
	if rToken.token.removeLight then
		if #(rToken.lights) > 0 then
			DB.setValue(rToken.node, "addedlights", "string", table.concat(rToken.lights, "|"));
		else
			DB.setValue(rToken.node, "addedlights", "string", "-");
		end
	end
end
