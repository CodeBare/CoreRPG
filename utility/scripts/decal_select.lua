-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _sLastDecal;

function onInit()
	_sLastDecal = DecalManager.getDecal();
end

function onActivate(sAsset)
	DecalManager.setDecal(sAsset);
end
function onValueUpdate()
	local nPage = assets.getPage();
	page_prev.setVisible(nPage > 1);
	page_next.setVisible(nPage < assets.getPageMax());
end

function handlePagePrev()
	assets.setPage(assets.getPage() - 1);
end
function handlePageNext()
	assets.setPage(assets.getPage() + 1);
end
function handleClear()
	DecalManager.clearDecal();
end
function handleOK()
	close();
end
function handleCancel()
	DecalManager.setDecal(_sLastDecal);
	close();
end
