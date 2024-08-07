// Maplist


void MC_CreateMaplistMenu() {
    g_mMenuMaps.SetTitle("efrag.gg | Maps\n▬▬▬▬▬▬▬▬▬▬▬");

    int len = g_alMaps_Random.Length;

    g_mMenuMaps.RemoveAllItems();
    if(len == 0) {
        g_mMenuMaps.AddItem("no_maps_found", "No Maps Available", ITEMDRAW_DISABLED);
    }
    else {
        SMap map;
        for(int i = 0; i < g_alMaps_Random.Length; i++) {
            g_alMaps_Random.GetArray(i, map, sizeof(SMap));

            g_mMenuMaps.AddItem(map.filename, map.cleanname);
        }
    }
    g_mMenuMaps.ExitButton = true;
}

// Open Mapvote for everyone
void MC_OpenMapvoteMenuToEveryone() {1

    g_currentState = EState_Vote;
    PrepareVote();

    // ChatAll("Randomized Maps...");
    ChatAll("Choose wisely!");
    
    // Loop clients and open the menu for everyone
    for(int i = 1; i <= MaxClients; i++) {
        if(IsClientInGame(i) && !IsFakeClient(i)) {
			ClientCommand(i, "play \"%s\"", SOUND_PLAY); 

			if(g_bShouldShowVoteResultsMenu[i]) {
            	MC_Menu_Mapvote(i, MENU_TIME_FOREVER);
			}
        }
    }
    CreateTimer(30.0, MC_Timer_CalculateVoteCount, _, TIMER_FLAG_NO_MAPCHANGE);
    g_hVoteCountDownTimer = CreateTimer(1.0, MC_Timer_CalculateVoteCountTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

// Nominations

enum struct VoteResult {
    SMap map;
    int votes;
}

public Action MC_ShowMapvoteResults(int client, int args) {
    Panel panel = new Panel();
    
    char TitleBuffer[2048];
    FormatEx(TitleBuffer, sizeof(TitleBuffer), "efrag.gg | Mapvote Results\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬", g_iExtendMapVotes);

	if(g_iExtendMapVotes > 0) {
    	FormatEx(TitleBuffer, sizeof(TitleBuffer), "%s\n ▸ Extend map: %d\n ", TitleBuffer, g_iExtendMapVotes);
	}

    ArrayList sortedArray = new ArrayList(sizeof(VoteResult));

    for(int i = 0; i < g_alMaps_Random.Length; i++) {
        SMap map; g_alMaps_Random.GetArray(i, map, sizeof(SMap));
        int value = g_iVoteCount[i];

        VoteResult result;
        result.map = map;
        result.votes = value;

        sortedArray.PushArray(result);
    }

    sortedArray.SortCustom(ArrayADTCustomCallback);

    for(int i = 0; i < sortedArray.Length; i++) {
        VoteResult voteresult;
        sortedArray.GetArray(i, voteresult, sizeof(VoteResult));

        // Variables
        SMap map;
        map = voteresult.map;
        
        int votes = 0;
        votes = voteresult.votes;

        if(votes <= 0) continue;
        if(MC_IsMapRecentlyPlayed(map.filename)) continue;
        
        FormatEx(TitleBuffer, sizeof(TitleBuffer), "%s\n ▸ %s [%d vote%s]", TitleBuffer, map.cleanname, votes, (votes > 1 || votes == 0) ? "s" : "");
        // menu.AddItem(map.filename, mapItemBuffer, ITEMDRAW_DISABLED);
    }
	delete sortedArray;
	
    int timeLeftInVote = (30-g_iVoteCountDownTimer);
    char sTimeLeftInVote[256];
    FormatEx(sTimeLeftInVote, sizeof(sTimeLeftInVote), "%d second%s left", timeLeftInVote, (timeLeftInVote > 1 || timeLeftInVote == 0) ? "s" : "");
    if(timeLeftInVote <= 0) {
        FormatEx(sTimeLeftInVote, sizeof(sTimeLeftInVote), "Vote ended");
    }

    FormatEx(TitleBuffer, sizeof(TitleBuffer), "%s\n \n \n%s", TitleBuffer, sTimeLeftInVote);
    panel.SetTitle(TitleBuffer);

	panel.DrawItem("Do not show this again");
    panel.Send(client, MC_MapvoteResultsMenu_Handler, 1);

    return Plugin_Handled;
}

public ArrayADTCustomCallback(int index1, int index2, Handle array, Handle hndl) {
    VoteResult result1; VoteResult result2;

    GetArrayArray(array, index1, result1, sizeof(VoteResult));
    GetArrayArray(array, index2, result2, sizeof(VoteResult));

	return (result2.votes > result1.votes);
}

public Action MC_OpenNominationMenu(int client, int args) {
    Menu menu = new Menu(MC_Menu_Nominations_Handler);
    menu.SetTitle("efrag.gg | Nominate\n▬▬▬▬▬▬▬▬▬▬▬▬");

    int len = g_alMaps.Length;

    if(len == 0) {
        menu.AddItem("no_maps_found", "No Maps Available", ITEMDRAW_DISABLED);
    }
    else {
        SMap map; char buffer[512];

        for(int i = 0; i < g_alMaps.Length; i++) {
            g_alMaps.GetArray(i, map, sizeof(SMap));
            // g_iNomination[client] = map.id;
            
            bool nominated = (g_iNomination[client] == map.id);

            FormatEx(buffer, sizeof(buffer), "%s%s", nominated ? "*" : "", map.cleanname);

            char sId[32];
            IntToString(map.id, sId, sizeof(sId));

            if(MC_IsMapRecentlyPlayed(map.filename)) {
            	FormatEx(buffer, sizeof(buffer), "%s (Recent)", map.cleanname);
            	menu.AddItem(sId, buffer, ITEMDRAW_DISABLED);
                continue;
            }
            menu.AddItem(sId, buffer, nominated ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
        }
    }
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
 
    return Plugin_Handled;
}

void MC_ResetVotes() {
    for(int i = 0; i < g_alMaps_Random.Length; i++) {
        g_iVoteCount[i] = 0;
    }
}

void PrepareVote() {
	g_iExtendMapVotes = 0;
	g_bShouldMapBeExtended = false;

	g_mVoteMenu.SetTitle("efrag.gg | Choose a map\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");
    g_mVoteMenu.RemoveAllItems();
    MC_ShuffleMaps();
    MC_ResetVotes();

    int len = g_alMaps_Random.Length;

    if(len == 0) {
        g_mVoteMenu.AddItem("no_maps_found", "No Maps Available", ITEMDRAW_DISABLED);
    }
    else {
        g_mVoteMenu.AddItem("extend_map", "Extend Map\n ");
        SMap map; char buffer[512];

        int mapCount = 0;
        StringMap smAlreadyAdded = new StringMap();

        SMap nominatedMap; char sNominatedId[16];
        char FormattedMenuItem[256];

        for(int i = 1; i <= MaxClients; i++) {
            int mapId = g_iNomination[i];

            if(mapId == -1) {
                continue;
            }

            PrintToConsoleAll("Nominated: %d", mapId);

            int foundMapIndex = MC_FindMapIndexByMapId(g_alMaps_Random, mapId);

            if(foundMapIndex == -1) {
                continue;
            }      

			char sCurrentMap[128];
			GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));


            IntToString(foundMapIndex, sNominatedId, sizeof(sNominatedId));

            if(smAlreadyAdded.SetValue(sNominatedId, true, false)) {
                g_alMaps_Random.GetArray(foundMapIndex, nominatedMap, sizeof(SMap));

				ReplaceString(nominatedMap.filename, sizeof(SMap::filename), ".bsp", "", false);


				if(StrEqual(sCurrentMap, nominatedMap.filename, false)) {
					PrintToConsoleAll("[Mapvote] Skipping map \x10%s (%s) [index: %d]", nominatedMap.filename, sCurrentMap, foundMapIndex);
					continue;
				}     

                FormatEx(FormattedMenuItem, sizeof(FormattedMenuItem), "* %s", nominatedMap.cleanname);
                IntToString(nominatedMap.id, sNominatedId, sizeof(sNominatedId));
                g_mVoteMenu.AddItem(sNominatedId, FormattedMenuItem);

                // PrintToChatAll("Added Nominated map \x10%s [index: %d]", nominatedMap.cleanname, foundMapIndex);
                mapCount++;
            }
        }

        if(mapCount > 0) {
            if(mapCount == MAX_MAPS_IN_VOTE) {
                g_mVoteMenu.ExitButton = false;
                return;
            }

            SMap randomExtraMap; char sRandomId[16];
            while(mapCount < MAX_MAPS_IN_VOTE) {

                if(mapCount == MAX_MAPS_IN_VOTE) {
                    break;
                }

                int randIdx = GetRandomInt(0, g_alMaps_Random.Length-1);
                int foundIdRandom = MC_FindMapIdByIndex(g_alMaps_Random, randIdx);

                if(MC_IsNominated(foundIdRandom)) {
                    continue;
                }

                g_alMaps_Random.GetArray(randIdx, randomExtraMap, sizeof(SMap));
				
				char sCurrentMap[128];
				GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
				ReplaceString(randomExtraMap.filename, sizeof(SMap::filename), ".bsp", "", false);

                if(StrEqual(sCurrentMap, randomExtraMap.filename, false)) {
					PrintToChatAll("[Mapvote] Skipping map \x10%s(%s) [index: %d]", randomExtraMap.filename, sCurrentMap, randIdx);
                    continue;
                }

                IntToString(randomExtraMap.id, sRandomId, sizeof(sRandomId));

                if(!smAlreadyAdded.SetValue(sRandomId, true, false)) {
                    continue;
                }

                g_mVoteMenu.AddItem(sRandomId, randomExtraMap.cleanname);
                PrintToConsoleAll("[CMS] Added random map %s : %d", randomExtraMap.cleanname, randomExtraMap.id);

                mapCount++;
            }
        }
        else {
            // PrintToChatAll("No Maps Nominated, randomizing...");

            SMap randomMap;
            char sId[16], menuKey[16];

            while(mapCount < MAX_MAPS_IN_VOTE) {
                int iRandom = GetRandomInt(0, g_alMaps_Random.Length-1);
                int foundMapId = MC_FindMapIdByIndex(g_alMaps_Random, iRandom);

                if(MC_IsNominated(foundMapId)) {
                    continue;
                }

                g_alMaps_Random.GetArray(iRandom, randomMap, sizeof(SMap));
                IntToString(foundMapId, sId, sizeof(sId));

                if(!smAlreadyAdded.SetValue(sId, true, false)) {
                    continue;
                }
                // IntToString(iRandom, menuKey, sizeof(menuKey));
                g_mVoteMenu.AddItem(sId, randomMap.cleanname);

                mapCount++;
            }
            // for(int j = 0; j < 6; j++) {
            //     g_alMaps_Random.GetArray(j, randomMap, sizeof(SMap));

            //     char idx[16]; IntToString(j, idx, sizeof(idx));
            //     g_mVoteMenu.AddItem(idx, randomMap.cleanname);
            // }
        }
        delete smAlreadyAdded;
    }
    g_mVoteMenu.ExitButton = false;
}

public bool MC_IsNominated(int mapId) {
    for(int i = 1; i <= MaxClients; i++) {
        if(g_iNomination[i] == mapId) {
            return true;
        }
    }
    return false;
}

public Action MC_Menu_Mapvote(int client, int args) {
    g_mVoteMenu.Display(client, 29);
 
    return Plugin_Handled;
}

// void MC_BuildMapvoteMenu() {

//     char sMapTitle[256];
//     g_MapvoteMenu.SetTitle("Choose the next map");

//     SMap map;
//     for(int i = 0; i < g_alMaps.Length; i++) {
//         g_alMaps.GetArray(i, map, sizeof(SMap));

//         FormatEx(sMapTitle, sizeof(sMapTitle), "%s (%d/%d)", map.cleanname, map.votes, GetPlayerCount());
//         g_MapvoteMenu.AddItem(map.filename, sMapTitle);
//     }
// }

// void MC_OpenRTVMenuForAll() {
//     g_smVotes = new StringMap();
//     float fTimer = 30.0;
//     for(int i = 1; i <= MaxClients; i++) {
//         if(IsClientInGame(i) && !IsFakeClient(i)) {
//             g_MapvoteMenu.Display(i, view_as<int>(FloatAbs(fTimer)))
//         }
//     }
//     CreateTimer(fTime, MC_Timer_CalculateVoteCount, _, TIMER_FLAG_NO_MAPCHANGE);
// }

