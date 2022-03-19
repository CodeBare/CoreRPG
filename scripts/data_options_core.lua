-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	OptionsManager.registerOption2("MANUALROLL", true, "option_header_client", "option_label_MANUALROLL", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("CMAT", true, "option_header_client", "option_label_CMAT", "option_entry_cycler",
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" })
	OptionsManager.registerOption2("CWHR", true, "option_header_client", "option_label_CWHR", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });

	OptionsManager.registerOption2("CTAV", false, "option_header_game", "option_label_CTAV", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("SHPW", false, "option_header_game", "option_label_SHPW", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("REVL", false, "option_header_game", "option_label_REVL", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("PSIN", false, "option_header_game", "option_label_PSIN", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("TBOX", false, "option_header_game", "option_label_TBOX", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });

	OptionsManager.registerOption2("NNPC", false, "option_header_combat", "option_label_NNPC", "option_entry_cycler", 
			{ labels = "option_val_append|option_val_random", values = "append|random", baselabel = "option_val_off", baseval = "off", default = "append" });
	OptionsManager.registerOption2("RING", false, "option_header_combat", "option_label_RING", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("CTSI", false, "option_header_combat", "option_label_CTSI", "option_entry_cycler", 
			{ labels = "option_val_all|option_val_friendly", values = "on|friend", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("RSHT", false, "option_header_combat", "option_label_RSHT", "option_entry_cycler", 
			{ labels = "option_val_all|option_val_friendly", values = "all|on", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("RSHE", false, "option_header_combat", "option_label_RSHE", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("CTSD", false, "option_header_combat", "option_label_CTSD", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("CTSH", false, "option_header_combat", "option_label_CTSH", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("RNDS", false, "option_header_combat", "option_label_RNDS", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });

	OptionsManager.registerOption2("TASG", false, "option_header_token", "option_label_TASG", "option_entry_cycler", 
			{ labels = "option_val_scale80|option_val_scale100", values = "80|100", baselabel = "option_val_off", baseval = "off", default = "80" });
	OptionsManager.registerOption2("TFAC", false, "option_header_token", "option_label_TFAC", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("TPTY", false, "option_header_token", "option_label_TPTY", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("TNAM", false, "option_header_token", "option_label_TNAM", "option_entry_cycler", 
			{ labels = "option_val_tooltip|option_val_title|option_val_titlehover", values = "tooltip|on|hover", baselabel = "option_val_off", baseval = "off", default = "tooltip" });

	OptionsManager.registerOption2("HRDD", false, "option_header_houserule", "option_label_HRDD", "option_entry_cycler", 
			{ labels = "option_val_x1_5|option_val_raw", values = "variant|raw", baselabel = "option_val_x1", baseval = "", default = "" });

	OptionsManager.registerButton("option_label_currencies", "currencylist", "currencies");
	OptionsManager.registerButton("option_label_decalselect", "decal_select", "");
	OptionsManager.registerButton("option_label_languages", "languagelist", "languages");
	OptionsManager.registerButton("option_label_motd", "motd", "motd");
	OptionsManager.registerButton("option_label_setup", "setup", "");
	OptionsManager.registerButton("option_label_tokenlights", "tokenlightlist", "settings.tokenlight");
end
