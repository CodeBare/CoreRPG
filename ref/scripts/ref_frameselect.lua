-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _bLeft = false;
local _wBlock = nil;

function setBlockData(wBlock, bLeft)
	if not wBlock then
		close();
		return;
	end
	local nodeBlock = wBlock.getDatabaseNode();
	if not nodeBlock then
		close();
		return;
	end
	_bLeft = bLeft;
	_wBlock = wBlock;
end

function activate(sName)
	if _wBlock then
		if _bLeft then
			DB.setValue(_wBlock.getDatabaseNode(), "frameleft", "string", sName);
		else
			DB.setValue(_wBlock.getDatabaseNode(), "frame", "string", sName);
		end

		ReferenceManualManager.onBlockRebuild(_wBlock);
	end
	close();
end
