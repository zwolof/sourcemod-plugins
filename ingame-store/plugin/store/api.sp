//// Get All Categories From API ////
void API_GetAllCategories() {
    httpClient.Get(API_CATEGORIES_ENDPOINT, API_OnCategoriesReceived);
}

void API_GetAllItems() {
    httpClient.Get(API_ITEMS_ENDPOINT, API_OnItemsReceived);
}

// Marketplace
void API_SendItemToMarketplace(int client, int itemid, int count = 1) {
    char sBuffer[128], sSteamId[64];
    GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

    JSONObject json = new JSONObject();
    json.SetInt("item", itemid);
    API_RemoveItem(client, itemid);

    // Do the request  
    FormatEx(sBuffer, sizeof(sBuffer), API_MARKETPLACE_ENDPOINT, sSteamId);
    httpClient.Post(sBuffer, json, API_OnItemListenOnMarketplace, GetClientUserId(client));

    // delete the object
    delete json;
}

void API_AddItemsToMarketplace(int client, int itemid, int count = 1) {
    char sBuffer[128], sSteamId[64];
    GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

    JSONObject json = new JSONObject();
    json.SetInt("item", itemid);
    API_RemoveItem(client, itemid);

    // Do the request  
    FormatEx(sBuffer, sizeof(sBuffer), API_MARKETPLACE_ENDPOINT, sSteamId);
    httpClient.Get(sBuffer, json, API_OnItemListenOnMarketplace, GetClientUserId(client));

    // delete the object
    delete json;
}

void API_GetItemsFromMarketplace() {
    httpClient.Get("marketitems", API_OnMarketplaceItemsReceived);
}

// Boxes

void API_GetLootboxes(int client) {
    char sBuffer[128], sSteamId[64];
    GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

    FormatEx(sBuffer, sizeof(sBuffer), API_BOXES_FETCH_ENDPOINT, sSteamId);
    httpClient.Get(sBuffer, API_OnLootboxesFetched, GetClientUserId(client));
}

void API_OnLootboxesFetched(HTTPResponse response, any data) {
    if (response.Status != HTTPStatus_OK || response.Data == null) {
        return;
    }
    int client = GetClientOfUserId(data);
    JSONArray boxes = view_as<JSONArray>(response.Data);

    int count[BoxType] = {0, ...};
    for(int i = 0; i < boxes.Length; i++) {
        JSONObject _box = view_as<JSONObject>(boxes.Get(i));

        int typeCount = _box.GetInt("count");
        int type = _box.GetInt("type");

        Box box;
        for(int j = 0; j < typeCount; j++) {
            box.boxtype = view_as<BoxType>(type);
            g_alClientBoxes[client].PushArray(box, sizeof(Box));
            count[box.boxtype]++;
        }
        delete _box;
    }

    // List boxes
    for(int t = 0; t < _:BoxType; t++) {
        eStore_Print(client, "Fetched %d %s%s\x08 Boxes!", count[t], g_sBoxRarityColors[t], g_sBoxRarities[t]);
    }
} 

void API_RemoveLootboxByType(int client, BoxType type) {
    char sBuffer[128], sSteamId[64];
    GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

    JSONObject json = new JSONObject();
    json.SetInt("boxtype", view_as<int>(type));

    // Do the request  
    FormatEx(sBuffer, sizeof(sBuffer), API_BOXES_ADD_ENDPOINT, sSteamId);
    httpClient.Post(sBuffer, json, API_OnUserBoxesUpdated, GetClientUserId(client));

    // delete the object
    delete json;
}

void API_AddLootboxByType(int client, BoxType type) {
    char sBuffer[128], sSteamId[64];
    GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

    JSONObject json = new JSONObject();
    json.SetInt("boxtype", view_as<int>(type));

    // Do the request  
    FormatEx(sBuffer, sizeof(sBuffer), API_BOXES_ADD_ENDPOINT, sSteamId);
    httpClient.Post(sBuffer, json, API_OnUserBoxesUpdated, GetClientUserId(client));

    // delete the object
    delete json;
}


void API_OnUserBoxesUpdated(HTTPResponse response, any value) {
    if (response.Status != HTTPStatus_OK || response.Data == null) {
        return;
    }
    int client = GetClientOfUserId(value);
    if(IsClientInGame(client) && client > 0) {
        eStore_Print(client, "Boxes updated!");
    }
} 

// Inventory
void API_GetInventoryItems(int client) {
    char sBuffer[128], sSteamId[64];
    GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

    FormatEx(sBuffer, sizeof(sBuffer), API_INVENTORY_ENDPOINT, sSteamId);
    httpClient.Get(sBuffer, API_OnInventoryItemsReceived, GetClientUserId(client));
}

// Credits
void API_GetUserCredits(int client) {
    char sBuffer[128], sSteamId[64];
    GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

    FormatEx(sBuffer, sizeof(sBuffer), API_USERS_ENDPOINT, sSteamId);
    httpClient.Get(sBuffer, API_OnCreditsReceived, GetClientUserId(client));
}

void API_UpdateUserCredits(int client) {
    char sBuffer[128], sSteamId[64];
    GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

    JSONObject json = new JSONObject();
    json.SetInt("credits", eStore[client].credits);

    // Do the request  
    FormatEx(sBuffer, sizeof(sBuffer), API_USERS_ENDPOINT, sSteamId);
    httpClient.Post(sBuffer, json, API_OnUserCreditsUpdated, GetClientUserId(client));

    // delete the object
    delete json;
}
//////////////

// Purchase
void API_PurchaseItem(int client, int itemid) {
    char sBuffer[128], sSteamId[64];
    GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

    JSONObject json = new JSONObject();
    json.SetInt("item", itemid);

    // Do the request  
    FormatEx(sBuffer, sizeof(sBuffer), API_INVENTORY_BUY_ENDPOINT, sSteamId);
    httpClient.Post(sBuffer, json, API_OnItemCallback, GetClientUserId(client));

    // delete the object
    delete json;
}

void API_RemoveItem(int client, int itemid) {
    char sBuffer[128], sSteamId[64];
    GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

    JSONObject json = new JSONObject();
    json.SetInt("item", itemid);

    // Do the request  
    FormatEx(sBuffer, sizeof(sBuffer), API_INVENTORY_SELL_ENDPOINT, sSteamId);
    httpClient.Post(sBuffer, json, API_OnItemCallback, GetClientUserId(client));

    // delete the object
    delete json;
}

////////////

// Equip
void API_UnequipItem(int client, int itemid) {
    char sBuffer[128], sSteamId[64];
    GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

    JSONObject json = new JSONObject();
    json.SetInt("item", itemid);

    // Do the request  
    FormatEx(sBuffer, sizeof(sBuffer), API_EQUIPPED_UNEQUIP_ENDPOINT, sSteamId);
    httpClient.Post(sBuffer, json, API_OnItemCallback, GetClientUserId(client));

    // delete the object
    delete json;
}

void API_GetEquippedItems(int client) {
    char sBuffer[128], sSteamId[64];
    GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

    FormatEx(sBuffer, sizeof(sBuffer), API_EQUIPPED_ENDPOINT, sSteamId);
    httpClient.Get(sBuffer, API_OnEquippedItemsReceived, GetClientUserId(client));
}
///////////

// Unequip
void API_EquipItem(int client, int itemid) {
    char sBuffer[128], sSteamId[64];
    GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

    JSONObject json = new JSONObject();
    json.SetInt("item", itemid);

    // Do the request  
    FormatEx(sBuffer, sizeof(sBuffer), API_EQUIPPED_EQUIP_ENDPOINT, sSteamId);
    httpClient.Post(sBuffer, json, API_OnItemCallback, GetClientUserId(client));

    // delete the object
    delete json;
}

/////////////////////////////////////////////////
/////////////////////////////////////// Callbacks
/////////////////////////////////////////////////

void API_OnUserCreditsUpdated(HTTPResponse response, any value) {
    if(response.Status != HTTPStatus_Created) return;
    if(response.Data == null) return;

    int client = GetClientOfUserId(value);
    if(IsClientInGame(client)) {
        PrintToServer("Updated Credits for user %N", client);
    }
} 

void API_OnItemCallback(HTTPResponse response, any value) {
    if (response.Status != HTTPStatus_OK) {
        return;
    }
    int client = GetClientOfUserId(value);
    if(IsClientInGame(client)) {
        eStore_Print(client, "\x04Success!");
    }
}

void API_OnCreditsReceived(HTTPResponse response, any value) {
    if (response.Status != HTTPStatus_OK || response.Data == null) {
        return;
    }
    JSONArray data = view_as<JSONArray>(response.Data);
    JSONObject d = view_as<JSONObject>(data.Get(0));

    int client = GetClientOfUserId(value);
    if(IsClientInGame(client)) {
        int credits = d.GetInt("credits");
        eStore[client].credits =  credits;
        eStore_Print(client, "You have \x04%d\x08 credits!", credits);
    }
    delete d;
} 

// void API_UpdateEquippedItemsPerClient(int client) {
//     char sBuffer[128], sSteamId[64];
//     GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

//     if(g_alEquipped[client] == null) return;

//     Item item; char sItemBuffer[128]; char sTemp[16];
//     for(int i = 0; i < g_alEquipped[client].Length; i++) {
//         g_alEquipped[client].GetArray(i, item, sizeof(Item));
//         FormatEx(sTemp, sizeof(sTemp), "%d;", item.itemid);
//         StrCat(sItemBuffer, sizeof(sItemBuffer), sTemp);
//     }
//         // Encode JSON Object
//     JSONObject json = new JSONObject();
//     json.SetString("items", sItemBuffer);

//     // Do the request  
//     FormatEx(sBuffer, sizeof(sBuffer), "items/equipped/%s", sSteamId);
//     httpClient.Post(sBuffer, json, API_OnUserEquippedUpdated, GetClientUserId(client));

//     // delete the object
//     delete json;
// }

void API_UpdateEquippedItemsPerClient(int client) {
    char sBuffer[128], sSteamId[64];
    GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

    if(g_alEquipped[client] == null) return;

    int len = g_alEquipped[client].Length;
    for(int i = 0; i < len; i++) {
        Item item;
        g_alEquipped[client].GetArray(i, item, sizeof(Item));

        // Temporary ItemId String
        char sTemp[16];
        FormatEx(sTemp, sizeof(sTemp), "%d", item.itemid);

        // Encode JSON Object
        JSONObject json = new JSONObject();

        // Format a buffer
        json.SetString("items", sTemp);

        // Do the request  
        FormatEx(sBuffer, sizeof(sBuffer), "items/equipped/%s", sSteamId);
        httpClient.Post(sBuffer, json, API_OnUserEquippedUpdated, GetClientUserId(client));

        // delete the object
        delete json;
    }   
}

void API_UpdateInventoryItemsPerClient(int client) {
    char sBuffer[128], sSteamId[64];
    GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

    if(g_alInventory[client] == null) return;

    int len = g_alInventory[client].Length;
    for(int i = 0; i < len; i++) {
        Item item;
        g_alInventory[client].GetArray(i, item, sizeof(Item));

        // Temporary ItemId String
        char sTemp[16];
        FormatEx(sTemp, sizeof(sTemp), "%d", item.itemid);

        // Encode JSON Object
        JSONObject json = new JSONObject();

        // Format a buffer
        json.SetString("items", sTemp);

        // Do the request  
        FormatEx(sBuffer, sizeof(sBuffer), "items/inventory/%s", sSteamId);
        httpClient.Post(sBuffer, json, API_OnUserInventoryUpdated, GetClientUserId(client));

        // delete the object
        delete json;
    }   
}

void API_OnUserEquippedUpdated(HTTPResponse response, any value) {
    if(response.Status != HTTPStatus_Created) return;
    if(response.Data == null) return;

    int client = GetClientOfUserId(value);
    if(IsClientInGame(client)) {
        PrintToServer("Updated Equipped Items for user %N", client);
    }
} 

void API_OnUserInventoryUpdated(HTTPResponse response, any value) {
    if(response.Status != HTTPStatus_Created) return;
    if(response.Data == null) return;
    
    int client = GetClientOfUserId(value);
    if(IsClientInGame(client)) {
        PrintToServer("Updated Inventory Items for user %N", client);
    }
} 

// void API_OnEquippedItemsReceived(HTTPResponse response, any data) {
//     if (response.Status != HTTPStatus_OK || response.Data == null) {
//         return;
//     }
//     int client = GetClientOfUserId(data);
//     JSONArray items = view_as<JSONArray>(response.Data);

//     if(items.Length > 0) {
//         Item item;
//         JSONObject _item = view_as<JSONObject>(items.Get(0));

//         char sItems[256], sExplodedItems[128][128];_item.GetString("itemid", sItems, sizeof(sItems));
//         ExplodeString(sItems, ";", sExplodedItems, sizeof(sExplodedItems), sizeof(sExplodedItems[]));
//         for(int j = 0; j < sizeof(sExplodedItems); j++) {
//             if(strlen(sExplodedItems[j]) > 0) {
//                 int id = StringToInt(sExplodedItems[j]);
//                 int index = eStore_FindItemIndexById(g_alItems, id);
//                 if(index == -1) {
//                     return;
//                 }
//                 g_alItems.GetArray(index, item, sizeof(Item));
//                 g_alEquipped[client].PushArray(item, sizeof(Item));
//             }
//         }
//         delete _item;
//     }
// } 

void API_OnEquippedItemsReceived(HTTPResponse response, any data) {
    if (response.Status != HTTPStatus_OK || response.Data == null) {
        return;
    }
    int client = GetClientOfUserId(data);
    JSONArray items = view_as<JSONArray>(response.Data);
    eStore_Print(client, "Items (Equip) Length: \x0F%d", items.Length);

    for(int i = 0; i < items.Length; i++) {
        JSONObject _item = view_as<JSONObject>(items.Get(i));

        int id = _item.GetInt("itemid");

        int index = eStore_FindItemIndexById(g_alItems, id);
        if(index == -1) {
            return;
        }
        // Find and add item
        Item item;
        g_alItems.GetArray(index, item, sizeof(Item));
        g_alEquipped[client].PushArray(item, sizeof(Item));
        delete _item;
    }
} 

void API_OnInventoryItemsReceived(HTTPResponse response, any data) {
    if (response.Status != HTTPStatus_OK || response.Data == null) {
        return;
    }
    int client = GetClientOfUserId(data);
    JSONArray items = view_as<JSONArray>(response.Data);
    eStore_Print(client, "Items (Invent) Length: \x0F%d", items.Length);

    for(int i = 0; i < items.Length; i++) {
        JSONObject _item = view_as<JSONObject>(items.Get(i));

        int id = _item.GetInt("itemid");

        int index = eStore_FindItemIndexById(g_alItems, id);
        if(index == -1) {
            return;
        }
        // Find and add item
        Item item;
        g_alItems.GetArray(index, item, sizeof(Item));
        g_alInventory[client].PushArray(item, sizeof(Item));
        eStore_Print(client, "Pushed \x04%s", item.name);
        delete _item;
    }
} 

// void API_OnInventoryItemsReceived(HTTPResponse response, any data) {
//     if (response.Status != HTTPStatus_OK || response.Data == null) {
//         return;
//     }
//     int client = GetClientOfUserId(data);
//     JSONArray items = view_as<JSONArray>(response.Data);

//     if(items.Length > 0) {
//         Item item;
//         JSONObject _item = view_as<JSONObject>(items.Get(0));

//         char sItems[256], sExplodedItems[128][128];_item.GetString("itemid", sItems, sizeof(sItems));
//         ExplodeString(sItems, ";", sExplodedItems, sizeof(sExplodedItems), sizeof(sExplodedItems[]));
//         for(int j = 0; j < sizeof(sExplodedItems); j++) {
//             if(strlen(sExplodedItems[j]) > 0) {
//                 int id = StringToInt(sExplodedItems[j]);
//                 int index = eStore_FindItemIndexById(g_alItems, id);
//                 if(index == -1) {
//                     return;
//                 }
//                 g_alItems.GetArray(index, item, sizeof(Item));
//                 g_alInventory[client].PushArray(item, sizeof(Item));
//             }
//         }
//         delete _item;
//     }
// } 

void API_OnCategoriesReceived(HTTPResponse response, any value)
{
    if (response.Status != HTTPStatus_OK || response.Data == null) {
        return;
    }
    JSONArray categories = view_as<JSONArray>(response.Data);
    g_alCategories.Clear();

    for(int i = 0; i < categories.Length; i++) {
        JSONObject _category = view_as<JSONObject>(categories.Get(i));

        Category category;

        // Integers
        category.id = _category.GetInt("id");

        // String
        _category.GetString("name", category.name, sizeof(Category::name));
        _category.GetString("shortname", category.shortname, sizeof(Category::shortname));

        Call_StartForward(g_hForward_OnCategoryFetched);
        Call_PushCell(category.id);
        Call_Finish();

        g_alCategories.PushArray(category, sizeof(Category));

        delete _category;
    }
} 

void API_OnItemsReceived(HTTPResponse response, any value) {
    if (response.Status != HTTPStatus_OK || response.Data == null) {
        return;
    }
    JSONArray items = view_as<JSONArray>(response.Data);
    g_alItems.Clear();
    
    for(int i = 0; i < items.Length; i++) {
        JSONObject _item = view_as<JSONObject>(items.Get(i));

        Item item;
        item.itemid = _item.GetInt("id");
        item.price = _item.GetInt("price");
        item.categoryid = _item.GetInt("categoryid");

        _item.GetString("name", item.name, sizeof(Item::name));
        // _item.GetString("description", item.description, sizeof(Item::description));
        // _item.GetString("flags", item.flags, sizeof(Item::flags));
        // _item.GetString("path", item.path, sizeof(Item::path));

        // Push to arraylist
        g_alItems.PushArray(item, sizeof(Item));

        delete _item;
    }
} 

void API_OnMarketplaceItemsReceived(HTTPResponse response, any value)
{
    if (response.Status != HTTPStatus_OK || response.Data == null) {
        return;
    }
    JSONArray items = view_as<JSONArray>(response.Data);
    g_alItems.Clear();
    
    for(int i = 0; i < items.Length; i++) {
        JSONObject _item = view_as<JSONObject>(items.Get(i));

        Item item;

        // Integers
        item.itemid = _item.GetInt("id");
        item.categoryid = _item.GetInt("categoryid");
        item.price = _item.GetInt("price");

        // Strings
        _item.GetString("name", item.name, sizeof(Item::name));
        // _item.GetString("description", item.description, sizeof(Item::description));
        // _item.GetString("flags", item.flags, sizeof(Item::flags));
        // _item.GetString("path", item.path, sizeof(Item::path));
        
        // Push to arraylist
        g_alMarketplace.PushArray(item, sizeof(Item));

        delete _item;
    }
} 
///////////////////////////////////

