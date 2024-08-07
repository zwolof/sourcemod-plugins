stock bool eStore_Helpers_IsPluginValid(Handle plugin) {
	Handle hIterator = GetPluginIterator();
	bool bIsValid = false;
	
	while (MorePlugins(hIterator)) {
		if (plugin == ReadPlugin(hIterator)) {
			bIsValid = (GetPluginStatus(plugin) == Plugin_Running);
			break;
		}
	}
	delete hIterator;
	return bIsValid;
}


stock bool Helpers_HandleItemEquip(int client, Item item, bool equip = true) {

	int _itemid = item.itemid;
	int itemIndex = eStore_FindItemIndexById(g_alItems, _itemid);
	// eStore_Print(client, "itemIndex: %d", itemIndex);

	if(itemIndex == -1) {
		return false;
	}

	Item itemToEquip;
	g_alItems.GetArray(itemIndex, itemToEquip, sizeof(Item));
	
	// if(g_bIsDebugging) {
	// 	eStore_Print(client, "itemToEquip: %d", itemToEquip.itemid);
	// }

	int len = itemToEquip.attributes.Length;

	if(len == 0) {
		return false;
	}

	IItemAttribute_t attr;
	for(int i = 0; i < len; i++) {
		itemToEquip.attributes.GetArray(i, attr, sizeof(IItemAttribute_t));
		
		if(StrEqual(attr.key, "playermodel", false)) {
			if(equip) {
				PlayerModels.Set(client, attr, item);
				return true;
			}
			PlayerModels.Clear(client);
			return true;
		}
		
		if(StrEqual(attr.key, "skybox", false)) {
			if(equip) {
				Skyboxes.Set(client, attr.value);
				return true;
			}
			Skyboxes.Clear(client);
			return true;
		}

		if(StrEqual(attr.key, "custom_knife_model", false)) {
			if(equip) {
				CustomKnives.Set(client, item);
				return true;
			}
			CustomKnives.Clear(client);
			return true;
		}

		if(StrEqual(attr.key, "chat_tag", false)) {
			if(equip) {
				ChatTags.Set(client, attr);
				return true;
			}
			ChatTags.Clear(client);
			return true;
		}

		if(StrEqual(attr.key, "clan_tag", false)) {
			if(equip) {
				ClanTags.Set(client, attr);
				return true;
			}
			ClanTags.Clear(client);
			return true;
		}

		if(StrEqual(attr.key, "name_color", false)) {
			if(equip) {
				NameColors.Set(client, attr);
				return true;
			}
			NameColors.Clear(client);
			return true;
		}

		if(StrEqual(attr.key, "animated_clantag", false)) {
			if(equip) {
				AnimatedClantags.Set(client, item);
				return true;
			}
			AnimatedClantags.Clear(client);
			return true;
		}

		// if(g_bIsDebugging) {
		// 	eStore_Print(client, "{attr.key: %s, attr.value: %s}", attr.key, attr.value);
		// }
	}
	return true;
}

stock bool eStore_Helpers_Substring(char[] dest, int destSize, char[] source, int sourceSize, int start, int end) {
    if (end < start || end > (sourceSize-1)) {
        strcopy(dest, destSize, NULL_STRING);
        return false;
    }
    else {
        strcopy(dest, (end-start+1), source[start]);
        return true;
    }
} 

stock void eStore_HUD(int client, char[] channel, char[] color, char[] color2, char[] effect, char[] fadein, char[] fadeout, char[] fxtime, char[] holdtime, char[] message, char[] x, char[] y){
	if(!eStore_IsValidReference(g_iHudEntity)) {
		int ent = CreateEntityByName("game_text");
		DispatchKeyValue(ent, "channel", channel);
		DispatchKeyValue(ent, "color", color);
		DispatchKeyValue(ent, "color2", color2);
		DispatchKeyValue(ent, "effect", effect);
		DispatchKeyValue(ent, "fadein", fadein);
		DispatchKeyValue(ent, "fadeout", fadeout);
		DispatchKeyValue(ent, "fxtime", fxtime);         
		DispatchKeyValue(ent, "holdtime", holdtime);
		DispatchKeyValue(ent, "spawnflags", "0");
		DispatchKeyValue(ent, "x", x);
		DispatchKeyValue(ent, "y", y);         
		DispatchSpawn(ent);
		g_iHudEntity = EntIndexToEntRef(ent);
	}
	DispatchKeyValue(g_iHudEntity, "message", message);
	SetVariantString("!activator");
	AcceptEntityInput(g_iHudEntity, "display", client);
}

stock bool eStore_IsValidReference(int ref) {
	int iEnt = EntRefToEntIndex(ref);
	return (iEnt > MaxClients && IsValidEntity(iEnt))
}

char g_ColorNames[][] = {"{WHITE}",	"{DEFAULT}",	"{RED}",	"{RED2}",	"{GREEN}",	"{GREEN2}",	"{BLUE}",	"{LIGHTBLUE}",	"{GRAY}",	"{GRAY2}",	"{GOLD}",	"{ORANGE}",	"{PINK}",	"{PURPLE}"};
char g_ColorCodes[][] = {"\x08",	"\x08",			"\x0F",		"\x0F",		"\x04",		"\x06",		"\x0C",		"\x0B",			"\x0A",		"\x08",		"\x10",		"\x10",		"\x0E",		"\x03"};

stock void Colorize(char[] str, int maxlen){for (int i = 0; i < sizeof(g_ColorNames); i++) ReplaceString(str, maxlen, g_ColorNames[i], g_ColorCodes[i]);}