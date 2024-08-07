/////////////////////////////////////////
/////////////   TRAILS   ////////////////
/////////////////////////////////////////
char g_sTrails[][] = {
    "White",
    "Red",
    "Green",
    "Blue",
    "Cyan",
    "Purple",
    "Orange"
}

int g_iTrailColors[][] = {
    {255, 255, 255, 255},
    {255, 0, 0, 255},
    {0, 255, 0, 255},
    {0, 0, 255, 255},
    {0, 255, 255, 255},
    {154, 18, 179, 1},
    {255, 165, 0, 255}
}

public Action CreateTrailsMenu(int client, int iArgs) {
	Menu menu = new Menu(TrailMenuHandler)

	FormatMenuTitle(menu, "Trails");
	for(int i = 0; i < sizeof(g_sTrails); i++) {
        menu.AddItem(g_sTrails[i], g_sTrails[i]);
    }
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int TrailMenuHandler(Menu menu, MenuAction aAction, int client, int option)
{
    switch(aAction) {
        case MenuAction_Select: {
            Settings[client].trail = option;
            EF_Print(client, "\x08You changed your trail-color to \x0F%s", g_sTrails[option]);
			
			int color = Settings[client].trail;
			
			TE_SetupBeamFollow(client, PrecacheModel("materials/sprites/laserbeam.vmt"), 0, 1.0, 5.0, 1.0, 1, g_iTrailColors[color]);
			TE_SendToClient(client);
			
			CreateTrailsMenu(client, 0);
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