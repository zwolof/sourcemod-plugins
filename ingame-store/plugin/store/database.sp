
#define DB_CORE_TABLE "ebans_users"
#define DB_CATEGORIES_TABLE "ebans_store_categories"
#define DB_ITEMS_TABLE "ebans_store_items"
#define DB_INVENTORY_TABLE "ebans_store_inventory"
#define DB_EQUIPPED_TABLE "ebans_store_equipped"
#define DB_LOOTBOX_TABLE "ebans_store_boxes"
#define DB_MARKETPLACE_TABLE "ebans_store_marketplace"

// Get Categories
void DB_FetchCategories() {
    char query[512];
    g_StoreDatabase.Format(query, sizeof(query), "SELECT * FROM "...DB_CATEGORIES_TABLE..." ORDER BY id ASC;");
    g_StoreDatabase.Query(DB_FetchCategories_Callback, query);
}

// Get Items
void DB_FetchItems() {
    char query[512];
    g_StoreDatabase.Format(query, sizeof(query), "SELECT * FROM "...DB_ITEMS_TABLE..." ORDER BY id ASC;");
    g_StoreDatabase.Query(DB_FetchItems_Callback, query);
}

// Update Credits
void DB_GetClientCredits(int client) {

    char steamid[64], query[512];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

    g_StoreDatabase.Format(query, sizeof(query), "SELECT credits FROM "...DB_CORE_TABLE..." WHERE authid = %s;", steamid);
    g_StoreDatabase.Query(DB_FetchCredits_Callback, query, GetClientUserId(client));
}

void DB_UpdateClientCredits(int client, int amount, MoneyAction action) {

    char steamid[64], query[512], operation[16];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

    // Queries
    FormatEx(operation, sizeof(operation), action == MA_Add ? "+" : "-");

    g_StoreDatabase.Format(query, sizeof(query), "UPDATE "...DB_CORE_TABLE..." SET credits = credits %s '%d' WHERE authid = '%s';", operation, amount, steamid);
    g_StoreDatabase.Query(DB_SimpleCallback, query);
}

void DB_AddItemToMarket(int client, Item item, int price, int quantity) {

    char steamid[64], query[512];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

	int playerId = efrag_GetPlayerId(steamid);
    g_StoreDatabase.Format(query, sizeof(query), "INSERT INTO "...DB_MARKETPLACE_TABLE..."('item_id', 'owner_id', 'price', 'quantity') VALUES('%d', '%d', '%d');", price, playerId, item.itemid, quantity);
	
	DataPack pack = new DataPack();
	pack.WriteCell(GetClientUserId(client));
	pack.WriteString(item.name);
	pack.WriteCell(price);

    g_StoreDatabase.Query(DB_ListOnMarketCallback, query, pack);
}

void DB_SetClientCredits(int client, int amount) {

    char steamid[64], query[512];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

    g_StoreDatabase.Format(query, sizeof(query), "UPDATE `"...DB_CORE_TABLE..."` SET credits = '%d' WHERE authid = '%s';", amount, steamid);
    g_StoreDatabase.Query(DB_SimpleCallback, query);
}

// Get Inventory
void DB_GetClientInventory(int client) {
    char steamid[64], query[512];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

    g_StoreDatabase.Format(query, sizeof(query), "SELECT itemid FROM `"...DB_INVENTORY_TABLE..."` WHERE steamid = '%s' ORDER BY id ASC;", steamid);
    g_StoreDatabase.Query(DB_FetchInventory_Callback, query, GetClientUserId(client));
}

// Get Equipped
void DB_GetClientEquipped(int client) {
    char steamid[64], query[512];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

    g_StoreDatabase.Format(query, sizeof(query), "SELECT itemid FROM `"...DB_EQUIPPED_TABLE..."` WHERE steamid = '%s' ORDER BY id ASC;", steamid);
    g_StoreDatabase.Query(DB_FetchEquipped_Callback, query, GetClientUserId(client));
}

// Add Inventory Item
void DB_AddInventoryItem(int client, int itemid) {
    char steamid[64], query[512];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

    g_StoreDatabase.Format(query, sizeof(query), "INSERT INTO "...DB_INVENTORY_TABLE..."(`steamid`, `itemid`) VALUES('%s', '%d');", steamid, itemid);
    g_StoreDatabase.Query(DB_SimpleCallback, query);
}

// Remove Inventory Item
void DB_RemoveInventoryItem(int client, int itemid) {
    char steamid[64], query[512];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
    PrintToChatAll("Database::DB_RemoveInventoryItem --> %s", steamid);

    g_StoreDatabase.Format(query, sizeof(query), "DELETE FROM %s WHERE itemid = '%d' AND steamid = '%s';", DB_INVENTORY_TABLE, itemid, steamid);
    g_StoreDatabase.Query(DB_SimpleCallback, query);
}

void DB_RemoveLootboxByType(int client, BoxType type) {
    char steamid[64], query[512];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

    g_StoreDatabase.Format(query, sizeof(query), "DELETE FROM "...DB_LOOTBOX_TABLE..." WHERE type = '%d' AND steamid = '%s' LIMIT 1;", view_as<int>(type), steamid);
    g_StoreDatabase.Query(DB_SimpleCallback, query);
}

void DB_AddLootboxByType(int client, BoxType type) {
    char steamid[64], query[512];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

    g_StoreDatabase.Format(query, sizeof(query), "INSERT INTO "...DB_LOOTBOX_TABLE..." (`steamid`, `type`) VALUES('%s', '%d');", steamid, view_as<int>(type));
    g_StoreDatabase.Query(DB_SimpleCallback, query);
}

// Equip Item
void DB_EquipItem(int client, int itemid) {
    char steamid[64], query[512];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

    g_StoreDatabase.Format(query, sizeof(query), "INSERT INTO "...DB_EQUIPPED_TABLE..."(`steamid`, `itemid`) VALUES('%s', '%d');", steamid, itemid);
    g_StoreDatabase.Query(DB_SimpleCallback, query);
}

// Unequip Item
void DB_UnequipItem(int client, int itemid) {
    char steamid[64], query[512];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

    g_StoreDatabase.Format(query, sizeof(query), "DELETE FROM "...DB_EQUIPPED_TABLE..." WHERE steamid = '%s' AND itemid = '%d';", steamid, itemid);
    g_StoreDatabase.Query(DB_SimpleCallback, query);
}

// Get Lootboxes
void DB_FetchLootboxes(int client) {
    char steamid[64], query[512];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

    g_StoreDatabase.Format(query, sizeof(query), "SELECT type, COUNT(*) as count FROM "...DB_LOOTBOX_TABLE..." WHERE steamid = '%s' GROUP BY type;", steamid);
    g_StoreDatabase.Query(DB_OnBoxesReceived, query, GetClientUserId(client));
}

// void OnBoxesReceived() {
//     int count[BoxType] = {0, ...};
//     for(int i = 0; i < boxes.Length; i++) {
//         JSONObject _box = view_as<JSONObject>(boxes.Get(i));

//         int typeCount = _box.GetInt("count");
//         int type = _box.GetInt("type");

//         Box box;
//         for(int j = 0; j < typeCount; j++) {
//             box.boxtype = view_as<BoxType>(type);
//             g_alClientBoxes[client].PushArray(box, sizeof(Box));
//             count[box.boxtype]++;
//         }
//         delete _box;
//     }

//     // List boxes
//     for(int t = 0; t < _:BoxType; t++) {
//         eStore_Print(client, "Fetched %d %s%s\x08 Boxes!", count[t], g_sBoxRarityColors[t], g_sBoxRarities[t]);
//     }
// }




// enum struct Box {
//     int entity_id;
//     int owner;
//     BoxType boxtype;
// }

// Callbacks
void DB_FetchCredits_Callback(Database db, DBResultSet results, const char[] error, any data) {
    if(db == null || results == null || error[0] != '\0') {
        LogError("[STORE] Query failed: %s", error);
    }

    if(results.RowCount > 0) {
        int client = GetClientOfUserId(data);

        // Field
        int credits_field; results.FieldNameToNum("credits", credits_field);

        if(results.FetchRow()) {
            eStore[client].credits = results.FetchInt(credits_field);
        }
    }
}

void DB_ListOnMarketCallback(Database db, DBResultSet results, const char[] error, DataPack pack) {
    if(db == null || results == null || error[0] != '\0') {
        LogError("[STORE] Query failed: %s", error);
    }

	pack.Reset();
	int userId = pack.ReadCell();
	int client = GetClientOfUserId(userId);

	if(client == -1) {
    	// eStore_Print(client, "Listed \x04%s\x08 on the market for \x04%d\x08 credits!", sItemName, price);
		return;
	}
	char sItemName[128];
	pack.ReadString(sItemName, sizeof(sItemName));

	int price = pack.ReadCell();
	delete pack;

    eStore_Print(client, "Listed \x04%s\x08 on the market for \x04%d\x08 credits!", sItemName, price);
}

void DB_FetchInventory_Callback(Database db, DBResultSet results, const char[] error, any data) {
    if(db == null || results == null || error[0] != '\0') {
        LogError("[STORE] Query failed: %s", error);
    }

    if(results.RowCount > 0) {
        int client = GetClientOfUserId(data);

        g_alInventory[client].Clear();

        // Field
        int itemid_field; results.FieldNameToNum("itemid", itemid_field);

        Item item;
        while(results.FetchRow()) {
            int id = results.FetchInt(itemid_field);

			int index = eStore_FindItemIndexById(g_alItems, id);
			if(index == -1) continue;
			
            g_alItems.GetArray(index, item, sizeof(Item));

            g_alInventory[client].PushArray(item, sizeof(Item));

			// if(g_bIsDebugging) {
            // 	eStore_Print(client, "Pushed (Inventory): \x04%s", item.name);
			// }
        }
		// if(g_bIsDebugging) {
		// 	eStore_Print(client, "Fetched \x04%d \x08Items! (inv)", g_alInventory[client].Length);
		// }
    }
}

void DB_FetchEquipped_Callback(Database db, DBResultSet results, const char[] error, any data) {
    if(db == null || results == null || error[0] != '\0') {
        LogError("[STORE] Query failed: %s", error);
    }

    if(results.RowCount > 0) {
        int client = GetClientOfUserId(data);

        g_alEquipped[client].Clear();

        // Field
        int itemid_field; results.FieldNameToNum("itemid", itemid_field);

        Item item;
        while(results.FetchRow()) {
            int id = results.FetchInt(itemid_field);

			int index = eStore_FindItemIndexById(g_alItems, id);
            g_alItems.GetArray(index, item, sizeof(Item));

            g_alEquipped[client].PushArray(item, sizeof(Item));
			// Helpers_EquipItem(client, item);

			// if(g_bIsDebugging) {
            // 	eStore_Print(client, "Pushed (Equipped): \x04%s", item.name);
			// }
        }

		// if(g_bIsDebugging) {
		// 	eStore_Print(client, "Fetched \x04%d \x08Items! (equip)", g_alEquipped[client].Length);
		// }
    }
}

void DB_OnBoxesReceived(Database db, DBResultSet results, const char[] error, any data) {
    if(db == null || results == null || error[0] != '\0') {
        LogError("[STORE] Query failed: %s", error);
    }

	// if(g_bIsDebugging) {
	// 	eStore_Print(GetClientOfUserId(data), "Fetched \x04%d \x08Lootboxes!", results.RowCount);
	// }

    if(results.RowCount > 0) {
        int client = GetClientOfUserId(data);
        
        g_alClientBoxes[client].Clear();

        int count[BoxType] = {0, ...};

        int fields[2];
		int iTypeField, iCountField;
        results.FieldNameToNum("type", iTypeField);
        results.FieldNameToNum("count", iCountField);

		Box box;
        while(results.FetchRow()) {
            int t = results.FetchInt(iTypeField);
            int c = results.FetchInt(iCountField);

            for(int i = 0; i <= c; i++) {
                box.boxtype = view_as<BoxType>(t);
                g_alClientBoxes[client].PushArray(box, sizeof(Box));
                count[box.boxtype-1]++;
            }
        }
    }
}

void DB_FetchCategories_Callback(Database db, DBResultSet results, const char[] error, any data) {
    if(db == null || results == null || error[0] != '\0') {
        LogError("[STORE] Query failed: %s", error);
    }

    g_alCategories.Clear();
    if(results.RowCount > 0) {

        Category category; int fields[3];
		
        results.FieldNameToNum("id", fields[0]);
        results.FieldNameToNum("name", fields[1]);
        results.FieldNameToNum("shortname", fields[2]);

        while(results.FetchRow()) {
			category.id = results.FetchInt(fields[0]);

            results.FetchString(fields[1], category.name, sizeof(Category::name));
            results.FetchString(fields[2], category.shortname, sizeof(Category::shortname));

            g_alCategories.PushArray(category, sizeof(Category));
        }
    }
}

void DB_FetchItems_Callback(Database db, DBResultSet results, const char[] error, any data) {
    if(db == null || results == null || error[0] != '\0') {
        LogError("[STORE] Query failed: %s", error);
    }

    g_alItems.Clear();
    if(results.RowCount > 0) {

        Item item; int fields[5];
		
        results.FieldNameToNum("id", fields[0]);
        results.FieldNameToNum("name", fields[1]);
        results.FieldNameToNum("categoryid", fields[2]);
        results.FieldNameToNum("price", fields[3]);
        results.FieldNameToNum("attributes", fields[4]);

		char sAttributes[1024];
        while(results.FetchRow()) {

			item.__init();
			item.attributes.Clear();

			item.itemid = results.FetchInt(fields[0]);
            results.FetchString(fields[1], item.name, sizeof(Item::name));
			item.categoryid = results.FetchInt(fields[2]);
			item.price = results.FetchInt(fields[3]);

			results.FetchString(fields[4], sAttributes, sizeof(sAttributes));

			item.attributes.Clear();
			if(strlen(sAttributes) > 0) {
				JSONArray attributeJsonArray = JSONArray.FromString(sAttributes);

				int length = attributeJsonArray.Length;
				if(length == 0) {
					delete attributeJsonArray;
					g_alItems.PushArray(item, sizeof(Item));
					continue;
				}

				IItemAttribute_t currentAttribute; JSONObject attributeObject;
				for(int i = 0; i < length; i++) {
					attributeObject = view_as<JSONObject>(attributeJsonArray.Get(i));

					if(attributeObject.HasKey("key")) {
						attributeObject.GetString("key", currentAttribute.key, sizeof(IItemAttribute_t::key));
					}

					if(attributeObject.HasKey("value")) {
						attributeObject.GetString("value", currentAttribute.value, sizeof(IItemAttribute_t::value));
					}
					
					if(g_bIsDebugging) {
						PrintToServer("[Store] %s: %s", currentAttribute.key, currentAttribute.value);
					}
					item.attributes.PushArray(currentAttribute, sizeof(IItemAttribute_t));
				}
				delete attributeJsonArray;
				delete attributeObject;
			}
            g_alItems.PushArray(item, sizeof(Item));
			if(g_bIsDebugging) {
				PrintToServer("[STORE] Attribute count (2): %d", item.attributes.Length);
			}
			// item.__destroy();
        }

		Item itm;
		for(int x = 0; x < g_alItems.Length; x++) {
			g_alItems.GetArray(x, itm, sizeof(Item));

			if(g_bIsDebugging) {
				PrintToServer("[STORE] Id: %d, attrs: %d", itm.itemid, itm.attributes.Length);
			}
		}
    }
}

stock ArrayList _ParseItemAttributes(const char[] attributes, ArrayList list) {
	ArrayList attributeList = new ArrayList(sizeof(IItemAttribute_t));

	JSONArray attributeJsonArray = JSONArray.FromString(attributes);

	int length = attributeJsonArray.Length;

    // Guards
    if(length == 0) {
        delete attributeJsonArray;
        return false;
    }

	IItemAttribute_t currentAttribute; JSONObject attributeObject;
	for(int i = 0; i < length; i++) {
		attributeObject = view_as<JSONObject>(attributeJsonArray.Get(i));

		if(attributeObject.HasKey("key")) {
			attributeObject.GetString("key", currentAttribute.key, sizeof(IItemAttribute_t::key));
        }

		if(attributeObject.HasKey("value")) {
			attributeObject.GetString("value", currentAttribute.value, sizeof(IItemAttribute_t::value));
        }
		PrintToServer("[Store] %s: %s", currentAttribute.key, currentAttribute.value);
		attributeList.PushArray(currentAttribute, sizeof(IItemAttribute_t));
	}

	delete attributeObject;
	delete attributeJsonArray;

	list = attributeList.Clone();
	delete attributeList;

	return true;
}

// void FetchItemAttributes() {
// 	char query[256],steamid[128];
// 	GetNativeString(1, steamid, sizeof(steamid));
//     Format(query, sizeof(query), "SELECT key, value FROM `"...DB_ITEMS_ATTRIBUTES_TABLE..."` WHERE itemid = '%d' ORDER BY id ASC;", itemid);

//     DBResultSet result = Query(g_Database, query);

//     if(!result.FetchRow() || SQL_IsFieldNull(result, 0)) {
//         CloseHandle(result);
//         return -1;
//     }
//     int count = result.FetchInt(0);
// }

void DB_SimpleCallback(Database db, DBResultSet results, const char[] error, any data) {
    if(db == null || results == null || error[0] != '\0') {
        LogError("[STORE] Query failed: %s", error);
    }
}
