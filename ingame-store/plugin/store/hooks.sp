void eStore_OnPluginStart() {
    if(g_dataOrigin == DataOrigin_API) {
        httpClient = new HTTPClient(API_ENDPOINT);
    }

    if(g_dataOrigin == DataOrigin_DB) {
        Database.Connect(SQL_ConnectCallback, "ebans");
    }

    // ArrayLists
    g_alCategories = new ArrayList(sizeof(Category));
    g_alItems = new ArrayList(sizeof(Item));
    g_alMarketplace = new ArrayList(sizeof(MarketItem));
    g_alBoxes = new ArrayList(sizeof(Box));

    // API
    if(g_dataOrigin == DataOrigin_API) {
        API_GetAllCategories();
        API_GetAllItems();
    }

    // Events
    HookEvent("round_start", eStore_OnRoundStart, EventHookMode_Post);
    HookEvent("player_spawn", eStore_OnPlayerSpawn, EventHookMode_Post);

    // Chat Listeners
    AddCommandListener(eStore_ChatHook, "say");
    AddCommandListener(eStore_ChatHook, "say_team");

    if(eStore_IsValidReference(g_iHudEntity)) {
        AcceptEntityInput(g_iHudEntity, "Kill");
    }

	// cc_proc_APIHandShake(cc_get_APIKey());
}

public void SQL_ConnectCallback(Database db, const char[] error, any data) {
    if(error[0] != '\0') {
        SetFailState("Database Could not connect: %s", error);
        return;
    }
    g_StoreDatabase = db;

    DB_FetchCategories();
    DB_FetchItems();
}

public Action eStore_ChatHook(int client, const char[] command, int argc) {
    if(g_bIsClientTakingQuiz[client][QT_Math]) {
        char sAnswer[32];
        FormatEx(sAnswer, sizeof(sAnswer), "%d", g_iClientQuizAnswer[client]);
        if(StrEqual(command, sAnswer, false)) {

            int reward = GetRandomInt(10, 40);
            eStore_Print(client, "\x08You answered the question correctly, you got \x04+%d\x08 %s", reward, STORE_CREDITSNAME_LC);
            eStore[client].add(reward);

            return Plugin_Handled;
        }   
    }
    return Plugin_Continue;
}

public void eStore_OnPlayerSpawn(Event event, const char[] sName, bool bDontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client <= 0) {
		return;
	}

    int len = g_alEquipped[client].Length;
    if(len <= 0) return;

    Item item;
    for(int i = 0; i < len; i++) {
        g_alEquipped[client].GetArray(i, item, sizeof(item));

		int index = eStore_FindItemIndexById(g_alItems, item.itemid);
		if(index == -1) {
			continue;
		}

		bool isPlayerModel = eStore_IsItemInCategoryByShortname("playermodel", item);

		if(isPlayerModel) {
			char sTeamAttribute[128];
			bool hasTeamAttribute = eStore_GetItemAttributeValueByKey(item, "team", sTeamAttribute, sizeof(sTeamAttribute));

			if(!hasTeamAttribute) {
				continue;
			}
			int team = StringToInt(sTeamAttribute);

			if(GetClientTeam(client) != team) {
				continue;
			}
			Helpers_HandleItemEquip(client, item, true);
			continue;
		}
		Helpers_HandleItemEquip(client, item, true);
    }
}

public void eStore_OnRoundStart(Event event, const char[] sName, bool bDontBroadcast) {
    if(g_alBoxes == null) {
        g_alBoxes = new ArrayList(sizeof(Box));
    }

    int len = g_alBoxes.Length;
    if(len <= 0) return;

    Box box;
    for(int i = 0; i < len; i++) {
        g_alBoxes.GetArray(i, box, sizeof(Box));

        if(IsValidEntity(box.entity_id) && IsValidEdict(box.entity_id)) {
            SDKUnhook(box.entity_id, SDKHook_Touch, eStore_BoxPickedUp);
            AcceptEntityInput(box.entity_id, "kill");
            RemoveEdict(box.entity_id);
        }
    }
    g_alBoxes.Clear();
}

void eStore_OnPluginEnd() {

}

public Action CP_OnChatMessage(int& client, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors) {
	Format(name, MAXLENGTH_NAME, "%s%s%s%s",
		g_szEquippedChatTag[client],
		strlen(g_szEquippedChatTag[client]) > 0 ? " " : "",
		g_szEquippedNameColor[client],
		name
	);
	Format(message, MAXLENGTH_MESSAGE, "{grey}%s", message);
	return Plugin_Changed;
}


// public Processing cc_proc_OnRebuildString(const int[] props, int part, ArrayList params, int &level, char[] value, int size) {

//     char szIndent[64];
//     params.GetString(0, szIndent, sizeof(szIndent));

// 	int client = SENDER_INDEX(props[1]);
// 	int pLevel = 1;
// 	// PrintToConsoleAll("RebuildString: %s :: %d", value, client);

//     if(!client || client == 0 || !IsPlayerInGame(client)) {
// 		PrintToConsoleAll("Could not find client");
//         return Proc_Continue;
//     } 

// 	switch(part) {
// 		case BIND_NAME: {
// 			if(strlen(g_szEquippedNameColor[client]) <= 0) {
// 				FormatEx(value, size, "");
// 				return Proc_Change;
// 			}
//     		FormatEx(value, size, "%s%N", g_szEquippedNameColor[client], client);
// 			return Proc_Change;
// 		}
// 		case BIND_PREFIX: {
// 			if(strlen(g_szEquippedChatTag[client]) <= 0) {
// 				FormatEx(value, size, "");
// 				return Proc_Change;
// 			}
//     		FormatEx(value, size, "%s", g_szEquippedChatTag[client]);
// 			return Proc_Change;
// 		}
// 		default: {
// 			FormatEx(value, size, "%s", value);
//     		return Proc_Continue;
// 		}
// 	}
// 	FormatEx(value, size, "%s", value);
// 	return Proc_Continue;
// }
// public Processing cc_proc_OnRebuildString(const int[] props, int part, ArrayList params, int &level, char[] value, int size) {

//     char szIndent[64];
//     params.GetString(0, szIndent, sizeof(szIndent));

// 	int client = SENDER_INDEX(props[1]);
// 	int pLevel = 1;
// 	// PrintToConsoleAll("RebuildString: %s :: %d", value, client);

//     if((szIndent[0] != 'S' && szIndent[1] != 'T' && strlen(szIndent) < 3) || !client) {
// 		PrintToConsoleAll("Could not find client");
//         return Proc_Continue;
//     } 

// 	if(part != BIND_PREFIX || level > pLevel) {
//         return Proc_Continue;
// 	}

//     if(strlen(g_szEquippedChatTag[client]) <= 0) {
// 		FormatEx(value, size, "");
//         return Proc_Change;
// 	}

//     level = pLevel;
//     // FormatEx(value, size, "%s", g_szEquippedChatTag[client]);
// 	// PrintToConsoleAll("props[1] << 3: %d", props[1] << 3);
	
//     FormatEx(value, size, "%s%s", g_szEquippedChatTag[client], g_szEquippedNameColor[client]);

//     return Proc_Change;
// }

public void OnClientPutInServer(int client) {
    if(eStore_IsValidClient(client)) {
        g_iClientQuizAnswer[client] = -1;
        g_bIsClientTakingQuiz[client][QT_Math] = false;
        g_bIsClientTakingQuiz[client][QT_Facts] = false;
		g_hAnimatedClantagTimer[client] = null;
    }
	if(IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {

        // Save userId In struct
        eStore[client].userid = GetClientUserId(client);

		// FormatEx(g_szEquippedNameColor[client], g_szEquippedNameColor[], "");
		strcopy(g_szEquippedNameColor[client], sizeof(g_szEquippedNameColor[]), "");
        // Get Their Inventory Items
        // if(g_alInventory[client] == null) {
		delete g_alInventory[client];
		g_alInventory[client] = new ArrayList(sizeof(Item));

		if(g_dataOrigin == DataOrigin_API) {
			API_GetInventoryItems(client);
		}

		if(g_dataOrigin == DataOrigin_DB) {
			DB_GetClientInventory(client);
		}
        // }
        
        // Get Their Equipped Items
        // if(g_alEquipped[client] == null) {
		delete g_alEquipped[client];
		g_alEquipped[client] = new ArrayList(sizeof(Item));

		if(g_dataOrigin == DataOrigin_API) {
			API_GetEquippedItems(client);
		}

		if(g_dataOrigin == DataOrigin_DB) {
			DB_GetClientEquipped(client);
		}
        // }

        // Get Their Lootboxes
        // if(g_alClientBoxes[client] == null) { 
		delete g_alClientBoxes[client];
		g_alClientBoxes[client] = new ArrayList(sizeof(Box));

		if(g_dataOrigin == DataOrigin_API) {
			API_GetLootboxes(client);
		}

		if(g_dataOrigin == DataOrigin_DB) {
			DB_FetchLootboxes(client);
		}
        // }

        // Get users credits
        if(g_dataOrigin == DataOrigin_API) {
            API_GetUserCredits(client);
        }

        if(g_dataOrigin == DataOrigin_DB) {
            DB_GetClientCredits(client);
        }

		// Cache their current playermodel
		GetClientModel(client, g_szOldPlayerModel[client], sizeof(g_szOldPlayerModel[]));

        // Create a timer to hand out credits
        g_hCreditsTimer[client] = CreateTimer(eUtils_GetSecondsFromMinutes(5), Timer_GiveCredits, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
    }
}

public void OnClientDisconnect(int client) {
    if(eStore_IsValidClient(client)) {

        // Update their credits
		// if(g_dataOrigin == DataOrigin_API) {
        // 	API_UpdateUserCredits(client);
        // }

		// if(g_dataOrigin == DataOrigin_DB) {
        //     DB_SetClientCredits(client, eStore[client].credits);
        // }

		ChatTags.Clear(client);
		ClanTags.Clear(client);
		NameColors.Clear(client);
		PlayerModels.Clear(client);

        // Timer handle
        delete g_hCreditsTimer[client];

        // Client Arraylists
        delete g_alInventory[client];
        delete g_alEquipped[client];
        delete g_alClientBoxes[client];
    }
}

public void OnMapEnd() {
    delete g_alBoxes;
    delete g_alMarketplace;
}

public Action Hook_eStoreWeaponDrop(int client, int wpnid)
{
	if(wpnid < 1) return;
    RequestFrame(Hook_SetWorldModel, EntIndexToEntRef(wpnid));
}

public void Hook_SetWorldModel(any data) {
    int wpnid = EntRefToEntIndex(data);

    if(wpnid == INVALID_ENT_REFERENCE || !IsValidEntity(wpnid) || !IsValidEdict(wpnid)) return;
	
	char globalName[64];
    GetEntPropString(wpnid, Prop_Data, "m_iGlobalname", globalName, sizeof(globalName));

    PrintToChatAll("Set worldmodel %d", wpnid);
    //SetEntityModel(wpnid, bit[1]);
}
