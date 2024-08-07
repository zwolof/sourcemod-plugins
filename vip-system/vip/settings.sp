
public Action CreateSettingsMenu(int client, int args)
{
	Menu menu = new Menu(SettingsMenuHandler);	
	FormatMenuTitle(menu, "Settings");
	
	menu.AddItem("tag", 		"Tag: Toggle");
	menu.AddItem("trail", 		"Trail: Toggle");
	menu.AddItem("skybox", 		"Skybox: Reset");
	menu.AddItem("namecolor", 	"Namecolor: Reset");
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int SettingsMenuHandler(Menu menu, MenuAction aAction, int client, int option)
{
    char sItem[64];
	menu.GetItem(option, sItem, sizeof(sItem));
	
    switch(aAction) {
        case MenuAction_Select: {
            if(StrEqual(sItem, "tag", false)) {
                Settings[client].toggle_tag = !Settings[client].toggle_tag;
				EF_Print(client, "Your Tag has been toggled %s", Settings[client].toggle_tag ? "\x04On" : "\x0FOff");
            }
            else if(StrEqual(sItem, "trail", false)) { 
                Settings[client].toggle_tag = !Settings[client].toggle_tag;
				EF_Print(client, "Your Trail has been toggled %s", Settings[client].toggle_tag ? "\x04On" : "\x0FOff");
            }
			else if(StrEqual(sItem, "skybox", false)) { 
                Settings[client].skybox = -1;
				SetSkybox(client, "default");
            }
			else if(StrEqual(sItem, "namecolor", false)) { 
                Settings[client].namecolor = -1;
            }
			CreateSettingsMenu(client, 0);
        }
        case MenuAction_End: {
            delete menu;
        }
    }
}