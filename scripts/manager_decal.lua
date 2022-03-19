--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _sDefaultAsset = "images/decals/swk_decal.png@SmiteWorks Assets";

function onInit()
	Interface.onDesktopInit = onDesktopInit;
end

function onDesktopInit()
	if Session.IsHost then
		local nodeCustom = DB.findNode("options.DDCL-custom");
		if not nodeCustom then
			DB.setValue("options.DDCL-custom", "string", _sDefaultAsset);
		end
	end

	DecalManager.update();

	DB.addHandler("options.DDCL-custom", "onAdd", update);
	DB.addHandler("options.DDCL-custom", "onUpdate", update);
end

function update()
	local wDecal = Interface.findWindow("desktopdecal", "");
	if not wDecal then
		return;
	end

	local sAsset = DB.getValue("options.DDCL-custom", "");
	if sAsset == "-" then
		sAsset = "";
	end
	wDecal.decal.setAsset(sAsset, true);
end

function setDefault(sAsset)
	_sDefaultAsset = sAsset;
end

function getDecal(sAsset)
	return DB.getValue("options.DDCL-custom", "");
end
function setDecal(sAsset)
	DB.setValue("options.DDCL-custom", "string", sAsset or "");
end
function clearDecal()
	DB.setValue("options.DDCL-custom", "string", "-");
end
