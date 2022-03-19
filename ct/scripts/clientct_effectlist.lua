-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onEffectsUpdated();
	local node = window.getDatabaseNode();
	DB.addHandler(DB.getPath(node, "effects"), "onChildUpdate", onEffectsUpdated);
	DB.addHandler(DB.getPath(node, "effects.*"), "onObserverUpdate", onEffectsUpdated);
end

function onClose()
	local node = window.getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "effects"), "onChildUpdate", onEffectsUpdated);
	DB.removeHandler(DB.getPath(node, "effects.*"), "onObserverUpdate", onEffectsUpdated);
end

function onEffectsUpdated()
	applyFilter();
end

function onFilter(w)
	return EffectManager.onEffectFilter(w);
end

function deleteChild(child)
	local nodeChild = child.getDatabaseNode();
	if nodeChild then
		nodeChild.delete();
	else
		child.close();
	end
end
