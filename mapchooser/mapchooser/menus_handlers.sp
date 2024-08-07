
// public int MC_Menu_Nominations_Handler(Menu menu, MenuAction action, int client, int choice) {

//     char sItem[128];
//     menu.GetItem(choice, sItem, sizeof(sItem));

//     // Switch the actions boys
//     switch(action) {
//         case MenuAction_Select: {

//             // int id = MC_FindMapIdByFilename(sItem);

//             // if(id == -1) {
//             //     Chat(client, "\x08Could not nominate map, map was not found.");
//             // }
//             // else {
//             //     // g_player[client].nominations.mapid = id;

//             //     char name[128]; MC_GetMapCleanName(sItem, name, sizeof(name));
//             //     Chat(client, "\x08Successfully nominated \x10%s", name);
//             // }
//         }
//         case MenuAction_End: {
//             delete menu;
//         }
//     }
// }
// enum struct SMap {
//     int id;
//     int votes;
    
//     char filename[128];
//     char cleanname[128];
// }
public int MC_Menu_Nominations_Handler(Menu menu, MenuAction action, int client, int choice) {
    char sItem[128]; menu.GetItem(choice, sItem, sizeof(sItem));

    int id = StringToInt(sItem);

    switch(action) {
        case MenuAction_Select: {
            int foundArrayIndex = MC_FindMapIndexByMapId(g_alMaps_Random, id);

            if(foundArrayIndex == -1) {
                return;
            }
            SMap map; g_alMaps_Random.GetArray(foundArrayIndex, map, sizeof(SMap));
            g_iNomination[client] = map.id;
            
            efrag_PrintToChat(client, "You nominated \x10%s", map.cleanname);

            // MC_OpenNominationMenu(client, MENU_TIME_FOREVER);
        }
        case MenuAction_End: {
            delete menu;
        }
    }
}

public int MC_Menu_Maplist_Handler(Menu menu, MenuAction action, int client, int choice) {
    char sItem[128]; menu.GetItem(choice, sItem, sizeof(sItem));

    switch(action) {
        case MenuAction_Select: {
            efrag_PrintToChat(client, "Map: \x10%s", sItem);
        }
    }
}

public int MC_MapvoteResultsMenu_Handler(Menu menu, MenuAction action, int client, int choice) {
    switch(action) {
        case MenuAction_Select: {
            // if(choice == 0) {
				g_bShouldShowVoteResultsMenu[client] = false;
                // Chat(client, "Deleting Menu Handle Here")
                // delete menu;
            // }
        }
        case MenuAction_Cancel: {
			// g_bShouldShowVoteResultsMenu[client] = false;
            // delete menu;
        }
    }
}

public int MC_Menu_Mapvote_Handler(Menu menu, MenuAction action, int client, int choice) {

    char sItem[128];
    menu.GetItem(choice, sItem, sizeof(sItem));
    
    // Switch the actions boys
    switch(action) {
        case MenuAction_Select: {
			if(StrEqual(sItem, "extend_map", false)) {
				g_iExtendMapVotes++;
            	g_player[client].hasVoted = true;
				
            	efrag_PrintToChat(client, "\x08You voted to extend the map.");

            	g_hMapvoteResultsTimer[client] = CreateTimer(1.0, MC_Timer_DisplayVoteResults, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				return;
			}
            
            // Menu Item key is the array index of g_alMaps
            int mapId = StringToInt(sItem);
            int mapIndex = MC_FindMapIndexByMapId(g_alMaps_Random, mapId);

            // Get map object from array by index supplied
            SMap map; g_alMaps_Random.GetArray(mapIndex, map, sizeof(SMap));
            
            // Increment votes for that map
            g_iVoteCount[mapIndex]++;

            // Set Voted to true cuz they just voted right?
            g_player[client].hasVoted = true;

            // Print Vote confirmation to chat
            efrag_PrintToChat(client, "\x08You voted for \x10%s \x08(\x0F%d\x08 vote%s)", map.cleanname, g_iVoteCount[mapIndex], g_iVoteCount[mapIndex] > 1 ? "s" : "");
            // Chat(client, "post_vote: %d", map.id);

            // Create Timer to reopen Mapvote Results menu every 1.0s
            g_hMapvoteResultsTimer[client] = CreateTimer(1.0, MC_Timer_DisplayVoteResults, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
        }
		// case MenuAction_Cancel: {
		// 	g_bShouldShowVoteResultsMenu[client] = false;
		// }
    }
}