
enum MenuType {
	BAN = 0,
	MUTE,
	GAG,
	SILENCE,
	SLAP,
	WARN,
	KICK,
	SLAY
};

enum struct BanMenu {
	int id;
	MenuType type;
	int player;
	int admin;
	
	char time[64];
	char reason[64];
}

enum struct PlayerInfo {
	char steamid[64];
	char name[128];
}

BanMenu bMenu[MS];
Handle hTagEnabledCookie = INVALID_HANDLE;
int g_iShowTag[MS] = {0, ...};
int g_iOldTeam[MS];

public Action Command_eAdmin(int client, int iArgs) {
	if(iArgs > 0) {
		return Plugin_Handled;
	}
	CreateAdminMenu(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

void __setMenuTitle(Menu menu, char[] szFormat, any ...)
{
    char buffer[128], buffer2[128];
    Format(buffer, sizeof(buffer), "%s", szFormat);
    VFormat(buffer2, sizeof(buffer2), buffer, 2);

	char sTitle[192];														  
	FormatEx(sTitle, sizeof sTitle, "efrag.gg | Admin Menu\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");
	menu.SetTitle(sTitle);
}

public CreateAdminMenu(int client, int iArgs) {
	Menu hMenu = new Menu(AdminMenuHandler);

	__setMenuTitle(hMenu, "Main Menu");
	
	hMenu.AddItem("punishments", "Punishments");
	hMenu.AddItem("miscellaneous", "Miscellaneous");
	hMenu.AddItem("m2e", "Message to everyone", bChatIsHooked[client] ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
	// char sItem[128];
	// FormatEx(sItem, sizeof(sItem), "Stealth             [%s]", g_bIsInvisible[client] ? "✔" : "✘");
	// hMenu.AddItem("stealth", sItem);
	
	// FormatEx(sItem, sizeof(sItem), "Admin Tag       [%s]", g_iShowTag[client]==1 ? "✔" : "✘");
	// hMenu.AddItem("admin_tag", sItem);
	
	hMenu.ExitButton = true;
	hMenu.ExitBackButton = true;
	hMenu.Display(client, MENU_TIME_FOREVER);
}

public CreatePunishmentMenu(int client, int iArgs) {
	Menu hMenu = new Menu(Admin_PunishmentHandler);
	
	__setMenuTitle(hMenu, "Punishments");
	
	hMenu.AddItem("#1", "Ban Player");
	hMenu.AddItem("#1", "Mute Player");
	hMenu.AddItem("#1", "Gag Player");
	hMenu.AddItem("#1", "Silence Player\n ");
	
	hMenu.ExitButton = true;
	hMenu.ExitBackButton = true;
	hMenu.Display(client, MENU_TIME_FOREVER);
}

public CreateMiscMenu(int client, int iArgs) {
	Menu hMenu = new Menu(Admin_MiscMenuHandler);
	
	__setMenuTitle(hMenu, "Miscellaneous");
	
	hMenu.AddItem("#1", "Slap Player");
	hMenu.AddItem("#1", "Warn Player");
	hMenu.AddItem("#1", "Kick Player");
	hMenu.AddItem("#1", "Slay Player\n ");
	hMenu.AddItem("#1", "Swap Player");
	
	hMenu.ExitButton = true;
	hMenu.ExitBackButton = true;
	hMenu.Display(client, MENU_TIME_FOREVER);
}

public CreateTimeMenu(int client, int iArgs) {
	Menu hMenu = new Menu(DurationMenuHandler);
	
	__setMenuTitle(hMenu, "Choose Duration");
	
	hMenu.AddItem("30m", "30 minutes");
	hMenu.AddItem("1h", "1 hour");
	hMenu.AddItem("2h", "2 hours");
	hMenu.AddItem("6h", "6 hours");
	hMenu.AddItem("12h", "12 hours");
	hMenu.AddItem("1d", "1 day");
	hMenu.AddItem("2d", "2 days");
	hMenu.AddItem("2d", "3 days");
	hMenu.AddItem("2d", "4 days");
	hMenu.AddItem("1w", "1 week");
	hMenu.AddItem("2w", "2 weeks");
	hMenu.AddItem("2w", "3 weeks");
	hMenu.AddItem("1mo", "1 month");
	hMenu.AddItem("1mo", "2 month");
	hMenu.AddItem("3mo", "3 months");
	hMenu.AddItem("6mo", "6 months");

    hMenu.AddItem("p", "---Permanent---");
	
	hMenu.ExitButton = true;
	hMenu.ExitBackButton = true;
	hMenu.Display(client, MENU_TIME_FOREVER);
}

public CreateAdminGuideMenu(int client, int iArgs) {
	Menu hMenu = new Menu(AdminGuideMenuHandler);
	
	__setMenuTitle(hMenu, "Admin Guide");
	
	hMenu.AddItem("p", "Times\n ");
	
	hMenu.AddItem("1d", "Reasons");
	hMenu.AddItem("2d", "Punishments");
	hMenu.AddItem("2d", "Behaviour");
	
	hMenu.ExitButton 				= true;
	hMenu.ExitBackButton 			= true;
	hMenu.Display(client, 			MENU_TIME_FOREVER);
}

public CreateChoosePlayerMenu(int client, int iArgs) {
	Menu hMenu = new Menu(ChoosePlayerHandler);
	
	__setMenuTitle(hMenu, "Choose Player");
	
	char sBuffer[128], sNum[64], sName[128];
	for(int i = 1; i <= MaxClients; i++) {
		if((1 <= i <= MaxClients) && IsClientConnected(i) && !IsFakeClient(i)) {
			GetClientName(i, sName, sizeof(sName));
			
			IntToString(i, sNum, sizeof(sNum));
			FormatEx(sBuffer, sizeof(sBuffer), "%s", sName);
			hMenu.AddItem(sNum, sBuffer);
		}
	}	
	hMenu.ExitButton = false;
	hMenu.ExitBackButton = true;
	hMenu.Display(client, MENU_TIME_FOREVER);
}

public CreateReasonMenu(int client, int iArgs) {
	Menu hMenu = new Menu(ReasonMenuHandler);
	
	__setMenuTitle(hMenu, "Select Reason");
		
	if(bMenu[client].type == BAN) {
		hMenu.AddItem("Blatant Cheating",		"Blatant Cheating");
		hMenu.AddItem("Ghosting", 				"Ghosting");
        hMenu.AddItem("Trolling", 				"Trolling");
		hMenu.AddItem("Racism", 				"Racism");
		hMenu.AddItem("Constant Rulebreak", 	"Constant Rulebreak");
	}
	else if(bMenu[client].type == MUTE || bMenu[client].type == GAG || bMenu[client].type == SILENCE) {
		hMenu.AddItem("Racism", 				"Racism");
        hMenu.AddItem("Advertisements", 		"Advertisements");
        hMenu.AddItem("Posting Links", 		    "Posting Links");
		hMenu.AddItem("Disrespecting Admin", 	"Disrespecting Admin");
		hMenu.AddItem("Micspam", 				"Micspam");
		hMenu.AddItem("Other", 				    "Other");
	}
	else {
		hMenu.AddItem("Running",				"Running");
		hMenu.AddItem("Camping", 				"Camping");
		hMenu.AddItem("Understabing", 			"Understabbing");
		hMenu.AddItem("Targetswitching", 		"Targetswitching");
		hMenu.AddItem("Undercamping", 			"Undercamping");
		hMenu.AddItem("Airflashing", 			"Airflashing");
		hMenu.AddItem("Funjumping", 			"Funjumping");
		hMenu.AddItem("Blocking", 				"Blocking");
		//hMenu.AddItem("Blocking", 				"Blocking");
	}

	hMenu.ExitButton = true;
	hMenu.ExitBackButton = true;
	hMenu.Display(client, MENU_TIME_FOREVER);
}


public ReasonMenuHandler(Menu hMenu, MenuAction action, int client, int iOption) {
	if(action == MenuAction_Select) {
		char sItem[64];
		hMenu.GetItem(iOption, sItem, sizeof(sItem));
		
		strcopy(bMenu[client].reason, BanMenu::reason, sItem);
		
		MenuType type = bMenu[client].type;
		if(type == BAN || type == MUTE || type == GAG || type == SILENCE) {
			CreateTimeMenu(client, 0)
		}
		else if(type == SLAP) {
            SlapPlayer(bMenu[client].player, 0, true);
        }
		else if(type == WARN) {
            efrag_PrintToChat(bMenu[client].player, "\x08Stop \x0F%s\x08 or you will be punished!", bMenu[client].reason);
        }
		else if(type == KICK) {
            KickClient(bMenu[client].player, "[EFRAG] You were kicked for %s, please read the rules before joining back!", bMenu[client].reason);
        }
		else if(type == SLAY) {
			efrag_PrintToChat(bMenu[client].player, "\x08You were slain for \x0F%s\x08, please read the rules before playing!", bMenu[client].reason);
			ForcePlayerSuicide(bMenu[client].player);
		}
	}
	else if(action == MenuAction_End) {
		delete hMenu;
	}
}

public AdminMenuHandler(Menu hMenu, MenuAction action, int client, int iOption) {
	char sItem[128];
	hMenu.GetItem(iOption, sItem, sizeof(sItem));

	if(action == MenuAction_Select) {
		if(StrEqual(sItem, "punishments", false)) {
			CreatePunishmentMenu(client, MENU_TIME_FOREVER);
		}
		else if(StrEqual(sItem, "miscellaneous", false)) {
			CreateMiscMenu(client, MENU_TIME_FOREVER);
		}
		else {
			StartChatHook(client);
			EmitSoundToClient(client, g_sBlipSound, client, _, _, _, 0.2);
			CreateAdminMenu(client, 0);

		}
	}
	else if(action == MenuAction_End) {
		delete hMenu;
	}
}

public AdminGuideMenuHandler(Handle hMenu, MenuAction action, int client, int iOption) {
	if(action == MenuAction_End) {
		delete hMenu;
	}
}

public ChoosePlayerHandler(Menu hMenu, MenuAction action, int client, int iOption) {
	if(action == MenuAction_Select) {
		if(IsValidClient(client)) {
			char sInfo[32];
			hMenu.GetItem(iOption, sInfo, sizeof(sInfo));
			
			bMenu[client].admin = client;
			bMenu[client].player = StringToInt(sInfo);
		}

		if(bMenu[client].type != 8) {
			CreateReasonMenu(client, 0);
		}
		else {
			int user = bMenu[client].player;
			ForcePlayerSuicide(user);
			CS_SwitchTeam(user, GetClientTeam(user) == CS_TEAM_CT ? CS_TEAM_T : CS_TEAM_CT);
			PrintToChat(client, "%s \x03%N\x08 has been swapped!", PREFIX, user);
		}
	}
	else if(action == MenuAction_End) delete hMenu;
}

public Admin_PunishmentHandler(Menu hMenu, MenuAction action, int client, int iOption) {
	if(action == MenuAction_Select) {
		switch(iOption) {
			case 0: {
				CreateChoosePlayerMenu(client, 0);
				bMenu[client].type = BAN;
			}
			case 1: {
				CreateChoosePlayerMenu(client, 0);
				bMenu[client].type = MUTE;
			}
			case 2: {
				CreateChoosePlayerMenu(client, 0);
				bMenu[client].type = GAG;
			}
			case 3: {
				CreateChoosePlayerMenu(client, 0);
				bMenu[client].type = SILENCE;
			}
		}
	}
	else if(action == MenuAction_End) {
		delete hMenu;
	}
}

public Admin_MiscMenuHandler(Menu hMenu, MenuAction action, int client, int iOption) {
	if(action == MenuAction_Select) {
		CreateChoosePlayerMenu(client, 0);
		bMenu[client].type = (iOption+4);
	}
	else if(action == MenuAction_End) {
		delete hMenu;
	}
}

public DurationMenuHandler(Menu hMenu, MenuAction action, int client, int iOption) {
	if(action == MenuAction_Select) {
		char sItem[64];
		hMenu.GetItem(iOption, sItem, sizeof(sItem));

		PunishPlayer(client, bMenu[client].player, view_as<PunishmentType_t>(bMenu[client].type), sItem, bMenu[client].reason);
	}
	else if(action == MenuAction_End) {
		delete hMenu;
	}
}
