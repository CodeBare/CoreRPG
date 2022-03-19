-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sAssetName;
local sAssetType;

function setData(sAssetNameParam, sAssetTypeParam)
	sAssetName = sAssetNameParam;
	sAssetType = sAssetTypeParam;

	preview.setAsset(sAssetName);

	if Session.IsHost then
		local bIsImage = ((sAssetType or "") == "image")
		button_import.setVisible(bIsImage);
		button_decal.setVisible(bIsImage);
	end
end

function handleDrag(draginfo)
	if (sAssetType or "") ~= "" then
		draginfo.setType(sAssetType);
		draginfo.setTokenData(sAssetName);
		return true;
	end
end

function onImportClicked()
	if (sAssetType or "") ~= "" then
		CampaignDataManager.createImageRecordFromAsset(sAssetName, true);
		close();
	end
end

function onDecalClicked()
	if (sAssetType or "") ~= "" then
		DecalManager.setDecal(sAssetName);
		close();
	end
end
