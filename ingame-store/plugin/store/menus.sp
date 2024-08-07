public Action eStore_MainMenu(int client, int iArgs) {
	Menu menu = new Menu(eStore_MainMenu_Handler);

    eStore_SetMenuTitle(menu, client);

    menu.AddItem("buy",         " ▪ View Store");
    menu.AddItem("inventory",   " ▪ Inventory");
    menu.AddItem("lootboxes",   " ▪ Lootboxes");
    menu.AddItem("marketplace", " ▪ Marketplace\n ");
    // menu.AddItem("vip_menu", " ▪ VIP\n ");

    menu.AddItem("trade",       "⇆ Trade");

	menu.ExitButton = true;
    menu.ExitBackButton = false;

	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public Action eStore_MarketplaceMenu(int client, int iArgs) {
	Menu menu = new Menu(eStore_MarketplaceMenu_Handler);

    eStore_SetMenuTitle(menu, client);

    Item item; char sTitle[128]; char sId[64];
    if(g_alMarketplace.Length <= 0) {
        menu.AddItem(sId, "No Items listed.", ITEMDRAW_DISABLED);
        menu.ExitButton = true;
        menu.ExitBackButton = false;
        menu.Display(client, MENU_TIME_FOREVER);

        return Plugin_Handled;
    }

    // Loop Items
    for(int i = 0; i < g_alMarketplace.Length; i++) {
        g_alMarketplace.GetArray(i, item, sizeof(Item));
        int count = eStore_GetOccouranceCountByItemId(g_alMarketplace, item.itemid);

        FormatEx(sTitle, sizeof(sTitle), "%s ▪ %d", item.name, count);
        IntToString(item.itemid, sId, sizeof(sId));
        menu.AddItem(sId, sTitle);
    }

	menu.ExitButton = true;
    menu.ExitBackButton = false;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int eStore_MarketplaceMenu_Handler(Menu menu, MenuAction aAction, int client, int option) {	
    
    char sItem[128];
    menu.GetItem(option, sItem, sizeof(sItem));
    if(StringToInt(sItem) > 0) {
        Item item;
        g_alMarketplace.GetArray(eStore_FindItemIndexById(g_alItems, StringToInt(sItem)), item, sizeof(Item))
    }
    switch(aAction) {
        case MenuAction_Select: {
            g_iChosenMarketItem[client] = StringToInt(sItem);
            eStore_ShowItemFromMarketplace(client, 0);
        }
		case MenuAction_Cancel: {
			if(option == MenuAction_ExitBack) {
				eStore_MainMenu(client, 0);
			}
		}
        case MenuAction_End: {
            delete menu;
        }
    }
}

public Action eStore_ShowItemFromMarketplace(int client, int iArgs) {
    //PrintToChatAll("Opening Item :: \x0F%d", g_iChosenItem[client]);
	Menu menu = new Menu(eStore_ShowMarketItem_Handler);
    eStore_SetMenuTitle(menu, client);

    Item item; char sItemName[128], sId[64];
    if(g_alMarketplace.Length > 0) {
        g_iMarketItemCount[client] = 1;
        g_alMarketplace.GetArray(g_iChosenMarketItem[client], item, sizeof(Item));

        IntToString(g_iChosenMarketItem[client], sId, sizeof(sId));

        if(!eStore_UserHasItem(client, item.itemid)) {
            menu.AddItem(sId, "Purchase");
        }
        else {
            menu.AddItem(sId, "You already own this item!", ITEMDRAW_DISABLED);
        }
    }
    else menu.AddItem("none", "No Item found!");
    
	menu.ExitButton = true;
    menu.ExitBackButton = true;
    
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int eStore_ShowMarketItem_Handler(Menu menu, MenuAction aAction, int client, int option) {	
    char sItem[128];
    menu.GetItem(option, sItem, sizeof(sItem));
    switch(aAction) {
        case MenuAction_Select: {
            eStore_Print(client, "not done sori");
            eStore_MainMenu(client, 0);
        }
        case MenuAction_End: {
            delete menu;
        }
    }
}

public int eStore_MainMenu_Handler(Menu menu, MenuAction aAction, int client, int option) {	
    
    char sItem[128];
    menu.GetItem(option, sItem, sizeof(sItem));
    switch(aAction) {
        case MenuAction_Select: {
            if(StrEqual(sItem, "buy", false)) {
                eStore_CategoryMenu(client, MENU_TIME_FOREVER);
            }
            else if(StrEqual(sItem, "inventory", false)) {
                eStore_OpenInventory(client, MENU_TIME_FOREVER);
            }
            else if(StrEqual(sItem, "lootboxes", false)) {
                eStore_OpenLootboxInventory(client, MENU_TIME_FOREVER);
            }
            // else if(StrEqual(sItem, "vip_menu", false)) {
            //     eStore_OpenVIPMenu(client, MENU_TIME_FOREVER);
            // }
            else eStore_MainMenu(client, MENU_TIME_FOREVER);
        }
        case MenuAction_End: {
            delete menu;
        }
    }
}

public Action eStore_OpenLootboxInventory(int client, int iArgs) {
	Menu menu = new Menu(eStore_LootboxInventoryHandler);
    eStore_SetMenuTitle(menu, client);

    int len = g_alClientBoxes[client].Length;

    if(len <= 0) {
        menu.AddItem("none", "You have no boxes!", ITEMDRAW_DISABLED);
        menu.ExitButton = true;
        menu.ExitBackButton = true;

        menu.Display(client, MENU_TIME_FOREVER);
        return Plugin_Handled;
    }

    int typeCount[BoxType] = {0, ...};
    for(int i = 0; i < _:BoxType; i++) {
        int type = view_as<BoxType>(i);
        typeCount[type] = eStore_GetBoxCountByType(client, type);
    }

    char sTitle[128], sType[128];
    for(int j = 0; j < _:BoxType; j++) {
        FormatEx(sTitle, sizeof(sTitle), "%s Box ▸ %d", g_sBoxRarities[j], typeCount[j]);
        IntToString(j, sType, sizeof(sType));
        menu.AddItem(sType, sTitle, typeCount[j] <= 0 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    }
    
	menu.ExitButton = true;
    menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int eStore_LootboxInventoryHandler(Menu menu, MenuAction aAction, int client, int option) {	
    char sItem[128];
    menu.GetItem(option, sItem, sizeof(sItem));

    BoxType type = view_as<BoxType>(StringToInt(sItem));
    switch(aAction) {
        case MenuAction_Select: {
            if(eStore_GetBoxCountByType(client, type) <= 0) {
                eStore_Print(client, "You have no boxes of this type.");
                eStore_OpenLootboxInventory(client, 0);
            }
            else {
                // Start opening animation
                StartOpening(client, type);

                // Remove from DB
                if(g_dataOrigin == DataOrigin_API) {
                    API_RemoveLootboxByType(client, type);
                }

                if(g_dataOrigin == DataOrigin_DB) {
                    DB_RemoveLootboxByType(client, type);
                }

                if(eStore_FindBoxIndexByType(client, type) != -1) {
                    g_alClientBoxes[client].Erase(eStore_FindBoxIndexByType(client, type));
                    // eStore_Print(client, "Removed lootbox from g_alClientBoxes ArrayList");
                }
            }
        }
        case MenuAction_End: {
            delete menu;
        }
    }
}

void StartOpening(int client, BoxType type) {
    DataPack pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteCell(type);
    g_iBoxOpeningAnimationState[client] = BOX_OPENING_ANIM_COUNT;
    g_hOpeningTimer[client] = CreateTimer(0.2, eStore_BoxOpeningTimer, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public Action eStore_BoxOpeningTimer(Handle timer, DataPack pack) {
    pack.Reset();
    int client = GetClientOfUserId(pack.ReadCell());
    BoxType type = pack.ReadCell();
    
    // eStore_Print(client, "Opening Box... (%d)", g_iBoxOpeningAnimationState[client]);

    // Animation
    char sHint[256];
    StrCat(sHint, sizeof(sHint), "[ ");
    for(int i = g_iBoxOpeningAnimationState[client]; i >= 0; i--) {
        StrCat(sHint, sizeof(sHint), "| ");
    }
    StrCat(sHint, sizeof(sHint), "]");
    PrintCenterText(client, sHint);
    
    if(g_iBoxOpeningAnimationState[client] == 0) {
        // eStore_Print(client, "Finished Animation..");
        eStore_PrintBoxReward(client, type);
        delete pack;

        return Plugin_Stop;
    }
    g_iBoxOpeningAnimationState[client] -= 1;

    return Plugin_Continue;
}

public Action eStore_OpenInventory(int client, int iArgs) {
	Menu menu = new Menu(eStore_InventoryHandler);
    eStore_SetMenuTitle(menu, client);

	// eStore_Print(client, "Opening Inventory...");
	// eStore_Print(client, "Inventory is null? (%s)", g_alInventory[client] == null ? "true" : "false");
	// eStore_Print(client, "Inventory count %d", g_alInventory[client].Length);
	// eStore_Print(client, "Equipped count %d", g_alEquipped[client].Length);

    if(g_alInventory[client].Length == 0) {
        menu.AddItem("none", "Inventory is empty!", ITEMDRAW_DISABLED);
        menu.ExitButton = true;
        menu.ExitBackButton = true;

        menu.Display(client, MENU_TIME_FOREVER);

        return Plugin_Handled;
    }

    Item item; char sItemName[128], sId[64];
    if(g_alItems.Length > 0) {
        for(int i = 0; i < g_alItems.Length; i++) {
            g_alItems.GetArray(i, item, sizeof(Item));
            
            if(eStore_UserHasItem(client, item.itemid)) {
                FormatEx(sItemName, sizeof(sItemName), "%s%s", eStore_IsItemEquipped(client, item.itemid) ? "▸ " : "", item.name);
                IntToString(item.itemid, sId, sizeof(sId));
                menu.AddItem(sId, sItemName);
            }
        }
    }
	else {
		menu.AddItem("none", "No items found!", ITEMDRAW_DISABLED);
	}

	menu.ExitButton = true;
    menu.ExitBackButton = true;

	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int eStore_InventoryHandler(Menu menu, MenuAction aAction, int client, int option) {	
    
    char sItem[128];
    menu.GetItem(option, sItem, sizeof(sItem));

    switch(aAction) {
        case MenuAction_Select: {

            Item item;
            // int index = StringToInt(sItem);
            int index = eStore_FindItemIndexById(g_alItems, StringToInt(sItem));
			if(index == -1) {
				eStore_Print(client, "Error, item not found.");
            	eStore_ShowItem(client, 0);
				return;
			}
            g_alItems.GetArray(index, item, sizeof(Item));
            g_iChosenItemId[client] = item.itemid;

            eStore_ShowItem(client, MENU_TIME_FOREVER);
        }
		case MenuAction_Cancel: {
			if(option == MenuAction_ExitBack) {
				eStore_MainMenu(client, 0);
			}
		}
        case MenuAction_End: {
            delete menu;
        }
    }
}

public Action eStore_CategoryMenu(int client, int iArgs) {
	Menu menu = new Menu(eStore_CategoryMenu_Handler);
    eStore_SetMenuTitle(menu, client);

    Category category; char sItemName[128], sId[64];
    if(g_alCategories.Length > 0) {
        for(int i = 0; i < g_alCategories.Length; i++) {
            g_alCategories.GetArray(i, category, sizeof(Category));

			ArrayList temp = eStore_GetItemsByCategoryId(g_alItems, category.id);
			int iCount = !(temp == null) ? temp.Length : 0;
			delete temp;

            // FormatEx(sItemName, sizeof(sItemName), category.name);
			// TrimString(sItemName);

			// int bytes = 0;

			// // get string bytes
			// for(int j = 0; j < strlen(sItemName); j++) {
			// 	bytes += GetCharBytes(sItemName[j]);
			// }
			// int len = strlen(category.name);
			// for(int j = 0; j < 25-bytes; j++) {
			// 	// FormatEx(sItemName, sizeof(sItemName), "%s ", sItemName);
			// 	StrCat(sItemName, sizeof(sItemName), " ");
			// }
			// PrintToChatAll("%s(%d)[bytes: %d]", sItemName, len, bytes);

			// FormatEx(sItemName, sizeof(sItemName), "%s| %d", sItemName, iCount);
			FormatEx(sItemName, sizeof(sItemName), "%s%s", category.name, iCount == 0 ? " (No items)" : "");
            IntToString(category.id, sId, sizeof(sId));

			if(iCount > 0) {
            	menu.AddItem(sId, sItemName);
			}
        }
    }
    else menu.AddItem("none", "No categories found!", ITEMDRAW_DISABLED);
    
	menu.ExitButton = true;
    menu.ExitBackButton = true;

	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int eStore_CategoryMenu_Handler(Menu menu, MenuAction aAction, int client, int option) {	
    
    char sItem[128];
    menu.GetItem(option, sItem, sizeof(sItem));
    switch(aAction) {
        case MenuAction_Select: {
            g_iChosenCategory[client] = StringToInt(sItem);
            eStore_ListCategoryItems(client, 0);
        }
		case MenuAction_Cancel: {
			if(option == MenuAction_ExitBack) {
				eStore_MainMenu(client, 0);
			}
		}
        case MenuAction_End: {
            delete menu;
        }
    }
}

public Action eStore_ListCategoryItems(int client, int iArgs) {
	Menu menu = new Menu(eStore_ItemListMenu_Handler);
	eStore_SetMenuTitle(menu, client);

    Item item; char sItemName[128], sId[64];
    int count = 0;
    int len = g_alItems.Length;

    if(len > 0) {
        for(int i = 0; i < len; i++) {
            g_alItems.GetArray(i, item, sizeof(Item));

            // Is it the correct cat-id?
            if(item.categoryid == g_iChosenCategory[client]) {
                
                FormatEx(sItemName, sizeof(sItemName), item.name);
                IntToString(i, sId, sizeof(sId));
                menu.AddItem(sId, sItemName);

                count++;
            }
        }
    }

    if(count <= 0) {
        menu.AddItem("none", "No Items found!", ITEMDRAW_DISABLED);
        menu.ExitButton = true;
        menu.ExitBackButton = true;
        menu.Display(client, MENU_TIME_FOREVER);
	    return Plugin_Handled;
    }
    
	menu.ExitButton = true;
    menu.ExitBackButton = true;

	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int eStore_ItemListMenu_Handler(Menu menu, MenuAction aAction, int client, int option) {	
    
    char sItem[128];
    menu.GetItem(option, sItem, sizeof(sItem));
    switch(aAction) {
        case MenuAction_Select: {
            Item item;
            int index = StringToInt(sItem);
            g_alItems.GetArray(index, item, sizeof(Item));
            g_ChosenItem[client] = item;
            
            // g_iChosenItem[client] = StringToInt(sItem);
            eStore_ShowItem(client, MENU_TIME_FOREVER);
        }
        case MenuAction_End: {
            delete menu;
        }
    }
}

public Action eStore_ShowItem(int client, int iArgs) {
    //PrintToChatAll("Opening Item :: \x0F%d", g_iChosenItem[client]);
	Menu menu = new Menu(eStore_ShowItem_Handler);

    Item item; char sItemName[128], sId[64];
    if(g_alItems.Length > 0) {
        // g_alItems.GetArray(g_iChosenItem[client], item, sizeof(Item));
        item = g_ChosenItem[client];
        
		char sItemNameTitle[256];
		FormatEx(sItemNameTitle, sizeof(sItemNameTitle), "%s", item.name);

		bool isPlayerModel = eStore_IsItemInCategoryByShortname("playermodel", item);
		if(isPlayerModel) {
			char sItemTeamAttribute[128];
			bool hasTeamAttribute = eStore_GetItemAttributeValueByKey(item, "team", sItemTeamAttribute, sizeof(sItemTeamAttribute));

			if(hasTeamAttribute) {
				int itemTeam = StringToInt(sItemTeamAttribute);
				FormatEx(sItemNameTitle, sizeof(sItemNameTitle), "%s%s", sItemNameTitle, itemTeam == CS_TEAM_CT ? " (CT)" : " (T)");
			}
		}

        menu.SetTitle(STORE_MENUTITLE..."\nYou have %d "...STORE_CREDITSNAME_LC..."💳\n \nItem: %s\n \nPrice: %d", eStore[client].credits, sItemNameTitle, item.price);
        
        IntToString(item.itemid, sId, sizeof(sId));
        menu.AddItem(sId, "Purchase", eStore_UserHasItem(client, item.itemid) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

        if(eStore_UserHasItem(client, item.itemid)) {
            char sSell[128], sEquip[64];
            FormatEx(sSell, sizeof(sSell), "Sell for %d", RoundFloat(item.price * MAX_SELL_PERCENTAGE));
            menu.AddItem(sId, sSell);

            FormatEx(sEquip, sizeof(sEquip), "%s", eStore_IsItemEquipped(client, item.itemid) ? "Unequip" : "Equip");
            menu.AddItem(sId, sEquip);
            // menu.AddItem("list_on_market", "List on Market");
        }
    }
    else menu.AddItem("none", "No Item found!");
    
	menu.ExitButton = true;
    menu.ExitBackButton = true;
    
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int eStore_ShowItem_Handler(Menu menu, MenuAction aAction, int client, int option) {	
    
    char sItem[128];
    menu.GetItem(option, sItem, sizeof(sItem));

    // Item
    int itemIndex = -1;
    // g_alItems.GetArray(StringToInt(sItem), item, sizeof(Item));

    // if(g_alInventory[client] != null) {
    //     itemIndex = 
    //     g_alItems.GetArray(itemIndex, item, sizeof(Item));
    // }
	int index = eStore_FindItemIndexById(g_alItems, g_iChosenItem[client]);

	if(index == -1) {
		g_iChosenItemIndex[client] = -1;
		delete menu;

		eStore_OpenInventory(client, MENU_TIME_FOREVER);
		return;
	}

    Item item;
	g_alItems.GetArray(index, item, sizeof(Item));
    
    // Menu Stuff
    if(aAction == MenuAction_Select) {
        switch(option) {
            case 0: {
                if(eStore_CanAffordItem(client, item)) {
                    if(!eStore_UserHasItem(client, item.itemid)) {
                        if(g_dataOrigin == DataOrigin_API) {
                            API_PurchaseItem(client, item.itemid);
                            API_UpdateUserCredits(client);
                        }

                        if(g_dataOrigin == DataOrigin_DB) {
                            DB_AddInventoryItem(client, item.itemid);
                            DB_UpdateClientCredits(client, item.price, MA_Remove);
                        }
                        eStore[client].remove(item.price);

                        // Push to Inventory Array
                        g_alInventory[client].PushArray(item);
                        eStore_Print(client, "\x08Purchased item \"\x10%s\x08\" for \x04%d "...STORE_CREDITSNAME_LC, item.name, item.price);
                    }
                    else {
                        eStore_Print(client, "\x08You already own this item!");
                    }
                }
                else {
                    eStore_Print(client, "\x08You cannot afford this item!");
                }
            }
            case 1: {
                int itemIndexInArray = eStore_FindItemIndexById(g_alInventory[client], g_ChosenItem[client].itemid);

                if(itemIndexInArray != -1) {
                    g_alInventory[client].Erase(itemIndexInArray);

                    int amount = RoundFloat(item.price * MAX_SELL_PERCENTAGE);

                    if(g_dataOrigin == DataOrigin_API) {
                        API_RemoveItem(client, item.itemid);
                        DB_UnequipItem(client, item.itemid);
                        // API_UpdateUserCredits(client);
                    }

                    if(g_dataOrigin == DataOrigin_DB) {
                        DB_RemoveInventoryItem(client, item.itemid);
                        DB_UnequipItem(client, item.itemid);
						
                        DB_UpdateClientCredits(client, amount, MA_Add);
                    }
                    eStore[client].add(amount);

					if(!eStore_IsItemInCategoryByShortname("playermodel", item)) {
						bool didUnequip = Helpers_HandleItemEquip(client, item, false);

						if(!didUnequip) {
							PrintToChatAll(" \x08 Failed to unequip \x04%s\x08!", client, item.name);
						}
					}
                    eStore_Print(client, "\x08Sold Item \"\x0F%s\x08\" for \x04%d "...STORE_CREDITSNAME_LC, item.name, RoundFloat(item.price*MAX_SELL_PERCENTAGE));
                }
                else {
                    eStore_Print(client, "\x08Failed to sell item, contact a Developer!");
                }
            }
            case 2: {
				if(eStore_IsItemEquipped(client, item.itemid)) {
					UnequipItem(client, item);

					if(!eStore_IsItemInCategoryByShortname("playermodel", item)) {
						bool didUnequip = Helpers_HandleItemEquip(client, item, false);

						if(!didUnequip) {
							eStore_Print(client, "\x08Failed to unequip \x04%s\x08!", client, item.name);
						}
					}
					// eStore_Print(client, "\x08 unequipped \x04%s\x08!", item.name);
				}
				else {
					EquipItem(client, item);

					if(!eStore_IsItemInCategoryByShortname("playermodel", item)) {
						bool didEquip = Helpers_HandleItemEquip(client, item, true);

						if(!didEquip) {
							eStore_Print(client, "\x08Failed to equip \x04%s\x08!", client, item.name);
						}
					}
					// eStore_Print(client, "\x08 Equipped \x04%s\x08!", item.name);
				}
            }
            case 3: {
				// DB_AddItemToMarket(client, item);
                eStore_Print(client, "not done sori bois, I'll get to it later!");
                // eStore_ShowMarketListingMenu(client, MENU_TIME_FOREVER);
            }
        }
        eStore_ShowItem(client, 0);
    }
    else if(aAction == MenuAction_End) {
        delete menu;
    }
}

public Action eStore_ShowItemToMarketplaceMenu(int client, int iArgs) {
    //PrintToChatAll("Opening Item :: \x0F%d", g_iChosenItem[client]);
	Menu menu = new Menu(eStore_ShowItemToMarketplaceMenu_Handler);

    char sItemName[128], sId[64];
    if(g_alItems.Length > 0) {
        Item item;
		item = g_ChosenItem[client];
        
        menu.SetTitle(STORE_MENUTITLE..."\nYou have %d "...STORE_CREDITSNAME_LC..."💳\n \nItem: %s\n", eStore[client].credits, item.name);
        
        IntToString(item.itemid, sId, sizeof(sId));
        menu.AddItem(sId, "Purchase", eStore_UserHasItem(client, item.itemid) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		menu.AddItem("start_chat_hook_price", "Set Price");

		// char sQuantityItem[64];
		// FormatEx(sQuantityItem, sizeof(sQuantityItem), "Quantity: %d", item.quantity);
		// menu.AddItem("start_chat_hook_price", "Quantity");
    }
    else menu.AddItem("none", "No Item found!");
    
	menu.ExitButton = true;
    menu.ExitBackButton = true;
    
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int eStore_ShowItemToMarketplaceMenu_Handler(Menu menu, MenuAction aAction, int client, int option) {	
    
    char sItem[128];
    menu.GetItem(option, sItem, sizeof(sItem));
    
    // Menu Stuff
    if(aAction == MenuAction_Select) {
		if(StrEqual(sItem, "start_chat_hook_price", false)) {
			g_bSetPriceChatHook[client] = true;
		}
	}
}
