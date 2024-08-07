public Action Command_eStore(int client, int args) {
    if(args > 1) {
        eStore_Print(client, "Invalid Command Usage");
        return Plugin_Handled;
    }
    eStore_MainMenu(client, 0);
    return Plugin_Handled;
}
public Action Command_eCredits(int client, int args) {
    if(args > 1) {
        eStore_Print(client, "Invalid Command Usage");
        return Plugin_Handled;
    }
    eStore_Print(client, "You have \x04%d\x08 credits!", eStore[client].credits);
    return Plugin_Handled;
}

public Action Command_eSpawnBox(int client, int args) {
    if(args > 1) {
        eStore_Print(client, "Invalid Command Usage");
        return Plugin_Handled;
    }
	BoxType type = (GetRandomInt(0, 3));
    eStore_SpawnBox(client, view_as<BoxType>(type));
    eStore_Print(client, "Spawned Box \x01[%s%s\x01]", g_sBoxRarityColors[type], g_sBoxRarities[type]);
    return Plugin_Handled;
}

public Action Command_eSetRebuildStringLevel(int client, int args) {
    // if(args > 1) {
    //     eStore_Print(client, "Invalid Command Usage");
    //     return Plugin_Handled;
    // }
	char sArg[16];
	GetCmdArg(1, sArg, sizeof(sArg));
	int level = StringToInt(sArg);
	g_iCurrentRebuildStringLevel = level;
    eStore_Print(client, "Set level to \x10%d", g_iCurrentRebuildStringLevel);
    return Plugin_Handled;
}

public Action Command_eReloadStuff(int client, int args) {
    if(args > 1) {
        eStore_Print(client, "Invalid Command Usage");
        return Plugin_Handled;
    }

	if(g_dataOrigin == DataOrigin_DB) {
		DB_FetchItems();
		DB_FetchCategories();
	}

	if(g_dataOrigin == DataOrigin_API) {
		API_GetAllCategories();
		API_GetAllItems();
	}

    eStore_Print(client, "Reloaded Items & Categories.");
    return Plugin_Handled;
}

public Action Command_eAddCredits(int client, int args) {
    if(args > 1) {
        eStore_Print(client, "\x08Invalid Command Usage");
        return Plugin_Handled;
    }
    char sCommand[128];GetCmdArg(1, sCommand, sizeof(sCommand));
    int credits = StringToInt(sCommand);
    eStore[client].add(credits);

    eStore_Print(client, "\x08Added \x04%d\x08 credits!", credits);
    
    return Plugin_Handled;
}

public Action Command_eRemoveCredits(int client, int args) {
    if(args > 1) {
        eStore_Print(client, "\x08Invalid Command Usage");
        return Plugin_Handled;
    }
    char sCommand[128];GetCmdArg(1, sCommand, sizeof(sCommand));
    int credits = StringToInt(sCommand);
    eStore[client].remove(credits);

    eStore_Print(client, "\x08Removed \x0F%d\x08 credits!", credits);
    
    return Plugin_Handled;
}

public Action Command_eSetAnimatedClantag(int client, int args) {
    char sArgs[128];
    GetCmdArgString(sArgs, sizeof(sArgs));
    // eStore_SetAnimatedClantag(client, sArgs);
    // char sCommand[128];GetCmdArg(1, sCommand, sizeof(sCommand));
    // int credits = StringToInt(sCommand);
    // eStore[client].remove(credits);

    eStore_Print(client, "\x08Set Animated clantag to %s", sArgs);
    
    return Plugin_Handled;
}

public Action Command_eShowInventory(int client, int args) {
    if(args > 1) {
        eStore_Print(client, "\x08Invalid Command Usage");
        return Plugin_Handled;
    }
    g_alInventory[client].Clear();
    g_alEquipped[client].Clear();
    API_GetInventoryItems(client);
    API_GetEquippedItems(client);
    int len = g_alInventory[client].Length;
    eStore_Print(client, "Inv Size: %d", len);

    for(int i = 0; i < len; i++) {
        Item item;
        g_alInventory[client].GetArray(i, item, sizeof(Item));
        eStore_Print(client, "Item: %s", item.name);
    }
    return Plugin_Handled;
}