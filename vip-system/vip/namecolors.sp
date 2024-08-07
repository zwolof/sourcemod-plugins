/////////////////////////////////////////
///////////   NAMECOLORS   //////////////
/////////////////////////////////////////

char g_sColors[][][] = {
    {"White", 	"\x01"},
    {"Red", 	"\x02"},
    {"Purple", 	"\x03"},
    {"Green", 	"\x04"},
    {"Blue", 	"\x0B"},
    {"Gray", 	"\x08"},
    {"Orange", 	"\x10"},
    {"Yellow", 	"\x09"}
}

public Action CreateNamecolorMenu(int client, int iArgs) {
	Menu menu = new Menu(NamecolorMenuHandler)

	FormatMenuTitle(menu, "Namecolors");
	for(int i = 0; i < sizeof(g_sColors); i++) {
        menu.AddItem(g_sColors[i][Tag], g_sColors[i][Tag]);
    }
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int NamecolorMenuHandler(Menu menu, MenuAction aAction, int client, int option)
{
    switch(aAction) {
        case MenuAction_Select: {
            Settings[client].namecolor = option;
            EF_Print(client, "\x08You changed your namecolor to \x0F%s", g_sColors[option]);
			
			CreateNamecolorMenu(client, 0);
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