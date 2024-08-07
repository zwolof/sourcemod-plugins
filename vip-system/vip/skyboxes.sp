/////////////////////////////////////////
////////////   SKYBOXES   ///////////////
/////////////////////////////////////////
char g_sSkyboxes[][][] = {
	{"amethyst", "Amethyst"},
	{"dreamyocean", "Dreamy Ocean"},
	{"grimmnight", "Grimm Night"},
	{"otherworld", "Other World"},
	{"Clear_night_sky", "Clear Night Sky"},
	{"cloudynight", "Cloudy Night"},
	{"sky051", "Cloudy Sky"},
	{"sky081", "Ethereal Sky"},
	{"sky091", "Void Sky"},
	{"sky561", "Dream World"},
	{"cs_tibet", "cs_tibet"},
	{"embassy", "embassy"},
	{"jungle", "jungle"},
	{"office", "office"},
	{"sky_cs15_daylight01_hdr","sky_cs15_daylight01_hdr"},
	{"sky_csgo_cloudy01", "sky_csgo_cloudy01"},
	{"sky_csgo_night_flat", "sky_csgo_night_flat"},
	{"sky_csgo_night02", "sky_csgo_night02"},
	{"sky_dust", "sky_dust"},
	{"vertigo", "vertigo"},
	{"vietnam", "vietnam"}
};

public void LoadSkyboxes() {
	char buffer[PLATFORM_MAX_PATH];
	
	static char suffix[][] = {
		"bk", "Bk",
		"dn", "Dn",
		"ft", "Ft",
		"lf", "Lf",
		"rt", "Rt",
		"up", "Up"
	};
	static char ending[][] = {"vtf", "vmt"};
	
	//Loop through suffixes and add to downloads table
	for(int i = 0; i < sizeof(g_sSkyboxes); i++) {
		for (int j = 0; j < sizeof(suffix); j++) {
			for (int k = 0; k < 2; k++) {
				// Format string
				FormatEx(buffer, sizeof(buffer), "materials/skybox/%s%s.%s", g_sSkyboxes[i], suffix[j], ending[k]);
				
				// Add to Downloads
				if(FileExists(buffer, false)) {
					AddFileToDownloadsTable(buffer);
				}
			}
		}
	}
	PrintToServer("[VIP] Loaded Skyboxes!");
}

public Action CreateSkyboxMenu(int client, int iArgs) {
	Menu menu = new Menu(SkyboxMenuHandler)

	FormatMenuTitle(menu, "Skyboxes");
	for(int i = 0; i < sizeof(g_sSkyboxes); i++) {
        menu.AddItem(g_sSkyboxes[i][0], g_sSkyboxes[i][1]);
    }
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int SkyboxMenuHandler(Menu menu, MenuAction aAction, int client, int option)
{	
    switch(aAction) {
        case MenuAction_Select: {
            Settings[client].skybox = option;
			SetSkybox(client, g_sSkyboxes[option][0]);
			EF_Print(client, "\x08You changed your skybox to \x0F%s", g_sSkyboxes[option][1]);
			CreateSkyboxMenu(client, 0);
        }
		case MenuAction_Cancel:
		{
			if(option == MenuCancel_ExitBack) {
				CreateMainMenu(client, 0);
			}
		}
        case MenuAction_End: {
            delete menu;
        }
    }
}
/////////////////////////////////////////