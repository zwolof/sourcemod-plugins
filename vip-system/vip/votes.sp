/////////////////////////////////////////
//////////////   VOTES   ////////////////
/////////////////////////////////////////
enum VoteTypes {
	Vote_Gag = 0,
	Vote_Mute,
	Vote_Kick
}

char g_sVoteTypes[][] = {
	"Gag",
	"Mute",
	"Kick"
};
int g_iYesVotes = 0;
int g_iNoVotes = 0;
int g_iCurrentVote = 0;
int g_iCurrentVoteTarget = -1;
bool bVoteInProgress = false;

// Main Vote Menu
public Action CreateVoteMenu	(int client, int iArgs) {
	Menu menu = new Menu(VoteMenuHandler)

	FormatMenuTitle(menu, "Votes");
    for(int i = 0; i < sizeof(g_sVoteTypes); i++) {
        menu.AddItem(g_sVoteTypes[i], g_sVoteTypes[i]);
    }
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int VoteMenuHandler(Menu menu, MenuAction aAction, int client, int option)
{
    switch(aAction) {
        case MenuAction_Select: {
			Settings[client].vote = option;
			DoVote(client, 0);
        }
        case MenuAction_End: {
            delete menu;
        }
    }
}

// Choose Vote Type
public Action DoVote(int client, int iArgs) {
	Menu menu = new Menu(CreateVoteMenuHandler)

	int type = Settings[client].vote;
	FormatMenuTitle(menu, g_sVoteTypes[type]);
    menu.AddItem(g_sVoteTypes[type], g_sVoteTypes[type]);
    
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int CreateVoteMenuHandler(Menu menu, MenuAction aAction, int client, int option)
{
    switch(aAction) {
        case MenuAction_Select: {
			g_iCurrentVote = option;
			bVoteInProgress = true;
			DoVote(client, 0);
        }
		case MenuAction_Cancel: {
            bVoteInProgress = false;
        }
        case MenuAction_End: {
            delete menu;
        }
    }
}

// Choose Player
public Action ChoosePlayer(int client, int iArgs) {
	Menu menu = new Menu(ChoosePlayerMenuHandler)
	
	FormatMenuTitle(menu, "Votes :: Choose Player");
	
	char sName[128], sIdx[16];
	for(int idx = 1; idx <= MaxClients; idx++) {
		if(IsValidClient(idx)) {
			FormatEx(sName, sizeof(sName), "%N", idx);
			FormatEx(sIdx, sizeof(sIdx), "%d", idx);
			menu.AddItem(sIdx, sName);
		}
	}
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int ChoosePlayerMenuHandler(Menu menu, MenuAction aAction, int client, int option)
{
	char sItem[16];
	menu.GetItem(option, sItem, sizeof(sItem));
	int userid = StringToInt(sItem);
	
    switch(aAction) {
        case MenuAction_Select: {
			for(int idx = 1; idx <= MaxClients; idx++) {
				if(IsValidClient(idx)) {
					FinalizeVoteMenu(idx, 0);
				}
			}
			CreateTimer(15.0, CheckVote, _, TIMER_FLAG_NO_MAPCHANGE);
        }
        case MenuAction_Cancel: {
            bVoteInProgress = false;
        }
		case MenuAction_End: {
            delete menu;
        }
    }
}

public Action CheckVote(Handle timer) {
	int iVoteResult = 100*(g_iYesVotes/(g_iNoVotes+g_iYesVotes));
	int type = g_iCurrentVote;
	int target = g_iCurrentVoteTarget;
	
	if(iVoteResult > 70) {
		switch(type) {
			case 0: {
				
			}
			case 1: {
				
			}
			case 2: {
				
			}
		}
		EF_PrintAll("\x08Vote passed!");
	}
	else EF_PrintAll("\x08Vote did not pass.");
	bVoteInProgress = false;
	
	return Plugin_Continue;
}

// Yes or no?
public Action FinalizeVoteMenu(int client, int iArgs) {
	Menu menu = new Menu(FinalizeVoteMenuHandler)
	
	char sTitle[256];
	FormatEx(sTitle, sizeof(sTitle), "%s %s");
	FormatMenuTitle(menu, sTitle);
	
	menu.AddItem("yes", "Yes");
	menu.AddItem("no", "No");

	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int FinalizeVoteMenuHandler(Menu menu, MenuAction aAction, int client, int option)
{
    switch(aAction) {
        case MenuAction_Select: {
			switch(option) {
				case 0: g_iYesVotes++;
				case 1: g_iNoVotes++;
			}
        }
        case MenuAction_End: {
            delete menu;
        }
    }
}
/////////////////////////////////////////