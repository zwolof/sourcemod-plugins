// void eStore_StartBoxOpeningAnimation(int client, BoxType type) {
//     int colors[4][4] = {
//         {255, 255, 255, 255},
//         {255, 255, 255, 255},
//         {255, 255, 255, 255},
//         {255, 255, 255, 255},
//     }
//     g_iAnimationState[client] = 13;
//     RequestFrame(StartOpening, colors[view_as<int>(type)]);
// }

// public void StartOpening(int client) {
//     CreateTimer(g_fBoxOpeningAnimationTime, Timer_BoxAnimation, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
// }

// public Action Timer_BoxAnimation(Handle timer, any data) {

//     if(g_iAnimationState-1 == 1) {
//         int iRandom = GetRandomInt(0, g_alItems.Length-1);
//         PrintHintText(client, "You got %s", g_sItem[data][iRandom]);
//         return Plugin_Stop;
//     }
    
//     char sAnim[64];
//     FormatEx(sAnim, sizeof(sAnim), "[");
//     for(int i = g_iAnimationState[client]; i > 0; --i) {
//         StrCat(sAnim, sizeof(sAnim), "|");
//         g_iAnimationState[client]--;
//     }
//     FormatEx(sAnim, sizeof(sAnim), "]");

//     PrintHintText(client, sAnim);
//     return Plugin_Continue;
// }

public void eStore_SpawnBox(int client, BoxType boxtype){	
	if(IsClientInGame(client)) {
		int iEnt = CreateEntityByName("prop_physics_override");

        // Box Logic
        Box box;
        box.entity_id = iEnt;
		box.boxtype = boxtype;

        // Box Texture
        int iType = view_as<int>(boxtype);

		if(iEnt > -1) {
			char sModel[256];
			FormatEx(sModel, sizeof(sModel), "%s.mdl", g_sBoxModels[0]);

			char sTypeString[16];
			IntToString(iType, sTypeString, sizeof(sTypeString));
			DispatchKeyValue(box.entity_id, "skin", sTypeString);

			DispatchKeyValue(box.entity_id, "model", sModel);
			// SetEntPropFloat(box.entity_id, Prop_Send, "m_flModelScale", 10.0); 
			// DispatchKeyValueFloat(box.entity_id, "modelscale", 3.0); 

			// Box Origin Spawn
			float fOrigin[3];
			GetAimOrigin(client, fOrigin);
			TeleportEntity(box.entity_id, fOrigin, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(box.entity_id);

			// Play Sound
			// EmitAmbientSound(g_sBoxSoundCached, fOrigin, box.entity_id, SNDLEVEL_RAIDSIREN, SND_NOFLAGS, 0.15);	 

			// Set MoveType
			SetEntityMoveType(box.entity_id, MOVETYPE_VPHYSICS);

			// Entity Flags
			SetEntProp(box.entity_id, Prop_Send, "m_usSolidFlags", 0x0008); 
			SetEntProp(box.entity_id, Prop_Data, "m_nSolidType", 6);
			SetEntProp(box.entity_id, Prop_Send, "m_CollisionGroup", 1);
			
			// Beam
			// TE_SetupBeamRingPoint

			// Position
			TeleportEntity(box.entity_id, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, 340.0}));

			// Hook Touch
			SDKHook(box.entity_id, SDKHook_Touch, eStore_BoxPickedUp);

			// Set Owner
			SetEntPropEnt(box.entity_id, Prop_Send, "m_hOwnerEntity", client);

			// Push to boxes arr
			g_alBoxes.PushArray(box);
			// eStore_Print(client, "Pushed box to ArrayList");
			// API
			// API_AddBoxToClient(client, box);

			// CreateTimer(0.6, eStore_TaskEffectOnBox, iEnt, TIMER_FLAG_NO_MAPCHANGE);
		} else eStore_Print(client, "Could not spawn box");
	}
}

public void eStore_BoxPickedUp(int iEnt, int client) {

    // Get box owner entity index
    int owner = GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity");

    // If someone else tries to take your box
    if(owner != client) {
        // PrintToChatAll("You are not the owner of this");
		eStore_Print(client, "This box belongs to \x0F%N", owner);
		// return;
	}
    // else PrintToChatAll("This is your box mate");

    if(iEnt != -1) {
        int idx = eStore_FindBoxByEntId(iEnt);
        if(idx != -1) {
            Box box;
            g_alBoxes.GetArray(idx, box, sizeof(Box));

            // Box Type
            int type = view_as<int>(box.boxtype);
            eStore_Print(client, "Picked up a %s%s\x08 lootbox", g_sBoxRarityColors[type], g_sBoxRarities[type]);
            g_alClientBoxes[client].PushArray(box);
			DB_AddLootboxByType(client, type);

            // Remove from ArrayList, we call the function incase someone
            // else picked up a box at the same time, making the index invalid
            // so we refetch it.
            g_alBoxes.Erase(eStore_FindBoxByEntId(iEnt));
            // eStore_Print(client, "Removed from ArrayList");
        }
    }
	SDKUnhook(iEnt, SDKHook_Touch, eStore_BoxPickedUp);
	AcceptEntityInput(iEnt, "kill");
	RemoveEdict(iEnt);
}

void eStore_PrintBoxReward(int client, BoxType type) {
    StringMap rewards = eStore_GetBoxRewardByType(type);

    Item item; char sRewards[512]; char sChatReward[512];

    // Item & Reward Formatting
    if(rewards.GetArray("item", item, sizeof(Item))) {
        if(eStore_UserHasItem(client, item.itemid)) {
            eStore_Print(client, "You already owned this item, instead you got \x04%d\x08 "...STORE_CREDITSNAME_LC..."!", item.price);
            eStore[client].add(item.price);
        }
        else {
            FormatEx(sRewards, sizeof(sRewards), "<br /><font color=\""...REWARD_COLOR_ITEM..."\">%s</font>", item.name);
            FormatEx(sChatReward, sizeof(sChatReward), "%s", item.name);

			eStore_Print(client, "You received \x10%s", strlen(sChatReward) < 5 ? "absolutely nothing" : sChatReward);
            eStore_AddItem(client, item);
        }
    }

    // Credits
    int credits = 0;
    rewards.GetValue("credits", credits);
    
    if(credits > 0) {
        eStore[client].add(credits);
        FormatEx(sRewards, sizeof(sRewards), "%s<br /><font color=\""...REWARD_COLOR_CREDITS..."\">%d</font>", sRewards, credits);

		FormatEx(sChatReward, sizeof(sChatReward), "%s%s \x04%d\x08 "...STORE_CREDITSNAME_LC, sChatReward, strlen(sChatReward) < 5 ? " \x08and" : "", credits);
		eStore_Print(client, "You received \x10%s", strlen(sChatReward) < 5 ? "absolutely nothing" : sChatReward);
    }
	// Print to client
	PrintCenterText(client, "You received %s", strlen(sRewards) < 5 ? "absolutely nothing" : sRewards);
}

// public Action eStore_TaskEffectOnBox(Handle hTimer, any iBox) {
// 	if(IsValidEntity(iBox)7) {
// 		AcceptEntityInput(iBox, "disablemotion");
		
// 		float fOrigin[3];
// 		GetEntPropVector(iBox, Prop_Send,"m_vecOrigin", fOrigin);

//         // Color
//         // Lower Box Origin by Z axis a little
// 		fOrigin[2] -= 0.5;
// 		for(int i = 0; i < 3; i++){
// 			TE_SetupBeamRingPoint(fOrigin, 1.0, 45.0, g_iBoxSprites[BOXSPRITE_LASER], g_iBoxSprites[BOXSPRITE_HALO],  1, 30, 0.2, 10.0, 0.1, {255, 255, 64, 255}, 10, 0);
// 			TE_SendToAll();
// 		}
// 		g_iBoxTrigered[iBox]=1;
// 	}
// }