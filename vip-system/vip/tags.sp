/////////////////////////////////////////
//////////////   TAGS   /////////////////
/////////////////////////////////////////
enum {
	Tag = 0,
	Color
}

char g_sTags[][][] = {
    {"VIP", 	"\x06"},
    {"VIP+", 	"\x04"},
    {"PRO", 	"\x0C"},
    {"Pepe", 	"\x04"},
    {"Expert", 	"\x0F"},
    {"Cool", 	"\x10"},
    {"Insane", 	"\x0F"},
    {"God", 	"\x0E"},
    {"Baller", 	"\x02"},
    {"Poggers", "\x06"},
    {"Kappa", 	"\x08"}
}

public Action CreateTagsMenu(int client, int iArgs) {
	Menu menu = new Menu(TagMenuHandler)

	FormatMenuTitle(menu, "Trails");
	for(int i = 0; i < sizeof(g_sTags); i++) {
		if(StrEqual(g_sTags[i][0], "VIP", false) && Donor[client].rank != Rank_VIP) {
			menu.AddItem(g_sTags[i][Tag], g_sTags[i][Tag], ITEMDRAW_DISABLED);
		}
        else if(StrEqual(g_sTags[i][0], "VIP+", false) && Donor[client].rank != Rank_VIPPlus) {
			menu.AddItem(g_sTags[i][Tag], g_sTags[i][Tag], ITEMDRAW_DISABLED);
		}
        else if(StrEqual(g_sTags[i][0], "PRO", false) && Donor[client].rank != Rank_PRO) {
			menu.AddItem(g_sTags[i][Tag], g_sTags[i][Tag], ITEMDRAW_DISABLED);
		}
		else menu.AddItem(g_sTags[i][Tag], g_sTags[i][Tag]);
    }
	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int TagMenuHandler(Menu menu, MenuAction aAction, int client, int option)
{
    switch(aAction) {
        case MenuAction_Select: {
            Settings[client].tag = option;
            EF_Print(client, "\x08You changed your tag to \x0F%s", g_sTags[option][0]);
			
			CreateTagsMenu(client, 0);
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