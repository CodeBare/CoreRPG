-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

triggers = {};
sCurrentColor = "FFFFFFFF";
bBlackDieText = true;

widgetColorMain = nil;
widgetColorDieTextBG = nil;
widgetColorDieTextFG = nil;

bColorDialogShown = false;

function onInit()
	color_main.addBitmapWidget("colorgizmo_bigbtn_base");
	widgetColorMain = color_main.addBitmapWidget("colorgizmo_bigbtn_color");
	color_main.addBitmapWidget("colorgizmo_bigbtn_effects");

	color_dietext.addBitmapWidget("colorgizmo_bigbtn_base");
	widgetColorDieTextBG = color_dietext.addBitmapWidget("colorgizmo_bigbtn_color");
	widgetColorDieTextFG = color_dietext.addBitmapWidget("colorgizmo_bigbtn_text");
	color_dietext.addBitmapWidget("colorgizmo_bigbtn_effects");
	
	sCurrentColor, bBlackDieText = User.getCurrentIdentityColors();
	updateColors();
end

function onClose()
	if bDialogShown then
		Interface.dialogColorClose();
	end
end

function onMainColorButtonPressed()
	bDialogShown = Interface.dialogColor(onMainColorDialogCallback, sCurrentColor);
end

-- Valid results are: "update", "ok", "cancel"
function onMainColorDialogCallback(sResult, sColor)
	if #sColor > 6 then
		sColor = sColor:sub(-6);
	end
	sCurrentColor = sColor;
	if sResult == "ok" or sResult == "cancel" then
		bDialogShown = false;
	end
	updateColors();
end

function onDieTextColorButtonPressed()
	bBlackDieText = not bBlackDieText;
	updateColors();
end

function updateColors()
	-- Main color
	widgetColorMain.setColor(sCurrentColor);

	-- Die text color
	if bBlackDieText then
		widgetColorDieTextBG.setColor("FFFFFFFF");
		widgetColorDieTextFG.setColor("FF000000");
	else
		widgetColorDieTextBG.setColor("FF000000");
		widgetColorDieTextFG.setColor("FFFFFFFF");
	end

	-- System settings
	User.setCurrentIdentityColors(sCurrentColor, bBlackDieText);
	
	-- Save in registry
	local identity = User.getCurrentIdentity();
	if identity then
		CampaignRegistry.colortables = CampaignRegistry.colortables or {};
		CampaignRegistry.colortables[identity] = CampaignRegistry.colortables[identity] or {};

		CampaignRegistry.colortables[identity].color = sCurrentColor;
		CampaignRegistry.colortables[identity].blacktext = bBlackDieText;
	end
end
