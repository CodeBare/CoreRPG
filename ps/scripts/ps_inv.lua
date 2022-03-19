-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if Session.IsHost then
		if coins.getWindowCount() == 0 then
			for _,sCurrency in ipairs(CurrencyManager.getCurrencies()) do
				local w = coins.createWindow();
				w.description.setValue(sCurrency);
			end
		end
		
		PartyLootManager.rebuild();
	else
		OptionsManager.registerCallback("PSIN", onOptionChanged);
		onOptionChanged();
	end
end

function onClose()
	if not Session.IsHost then
		OptionsManager.unregisterCallback("PSIN", onOptionChanged);
	end
end

function onOptionChanged()
	local bOptPSIN = OptionsManager.isOption("PSIN", "on");

	label_coin_main.setVisible(bOptPSIN);
	label_coin_count.setVisible(bOptPSIN);
	label_coin_name.setVisible(bOptPSIN);
	label_coin_carried.setVisible(bOptPSIN);
	coinlist.setVisible(bOptPSIN);
	
	label_inv_main.setVisible(bOptPSIN);
	label_inv_count.setVisible(bOptPSIN);
	label_inv_name.setVisible(bOptPSIN);
	label_inv_carried.setVisible(bOptPSIN);
	itemlist.setVisible(bOptPSIN);
	
	if bOptPSIN then
		coins.setAnchor("bottom", "", "center", "absolute", "-20");
		items.setAnchor("bottom", "", "center", "absolute", "-20");
	else
		coins.setAnchor("bottom", "", "bottom", "absolute", "-30");
		items.setAnchor("bottom", "", "bottom", "absolute", "-30");
	end
end

function onDrop(x, y, draginfo)
	return ItemManager.handleAnyDrop("partysheet", draginfo);
end

