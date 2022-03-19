-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local tModulesLoaded = ModuleManager.getLoadedModuleInfo();
	for sModule,tInfo in pairs(tModulesLoaded) do
		onModuleLoad(sModule, tInfo);
	end

	local tModuleCategories = ModuleManager.getLoadedModuleCategories();
	for sCategory,_ in pairs(tModuleCategories) do
		onCategoryAdded(sCategory);
	end
end

function onModuleLoad(sModule, tInfo)
	local w = booklist.createWindow();
	if w then
		w.setData(sModule, tInfo);
	end
end
function onModuleUnload(sModule)
	for _,w in ipairs(booklist.getWindows()) do
		if (w.getClass() == "library_booklistentry") and (w.getName() == sModule) then
			w.close();
			break;
		end
	end
end

function onCategoryAdded(sCategory)
	local w = booklist.createWindowWithClass("library_booklistcategory");
	if w then
		w.setData(sCategory);
	end
end
function onCategoryRemoved(sCategory)
	for _,w in ipairs(booklist.getWindows()) do
		if (w.getClass() == "library_booklistcategory") and (w.getCategory() == sCategory) then
			w.close();
			break;
		end
	end
end
