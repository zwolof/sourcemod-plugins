public Action MC_Timer_DisplayVoteResults(Handle timer, any data) {
    int client = GetClientOfUserId(data);

    if(!((0 < client <= MaxClients) && IsClientInGame(client) && !IsFakeClient(client))) {
        return Plugin_Continue;
    }

    if(g_currentState == EState_PostVote) {
        g_hMapvoteResultsTimer[client] = null;
        return Plugin_Stop;
    }
	
	if(g_bShouldShowVoteResultsMenu[client]) {
    	MC_ShowMapvoteResults(client, 0);
	}
    return Plugin_Continue;
}

public Action MC_Timer_CalculateVoteCountTimer(Handle timer, any data) {
	g_iVoteCountDownTimer++;

    if(g_iVoteCountDownTimer == 30) {
        g_hVoteCountDownTimer = null;
        return Plugin_Stop;
    }
	return Plugin_Continue;
}

public Action MC_Timer_CalculateVoteCount(Handle timer, any data) {

	int iRandArrLen = g_alMaps_Random.Length;
	if(g_iExtendMapVotes > MC_GetBiggestIntFromArray(g_iVoteCount, iRandArrLen)) {
		g_bShouldMapBeExtended = true;
		g_currentState = EState_PostVote;
		g_bIsVoteDone = true;
		g_nextMapIdx = -1;

		for(int i = 1; i <= MaxClients; i++) {
			if(IsClientInGame(i) && !IsFakeClient(i)) {
				MC_ShowMapvoteResults(i, MENU_TIME_FOREVER);
			}
		}
    	ChatAll("The map will be extended.");

    	return Plugin_Stop;
	}

    g_nextMapIdx = MC_GetBiggestIntIndexFromArray(g_iVoteCount, iRandArrLen);

    char mapName[256];
    MC_GetMapCleanNameByIndex(g_alMaps_Random, g_nextMapIdx, mapName, sizeof(mapName));

    g_currentState = EState_PostVote;
    g_bIsVoteDone = true;

    for(int i = 1; i <= MaxClients; i++) {
        if(IsClientInGame(i) && !IsFakeClient(i)) {
            MC_ShowMapvoteResults(i, MENU_TIME_FOREVER);
        }
    }
    ChatAll("The next map will be \x10%s", mapName);
    
    return Plugin_Stop;
}

public Action Timer_EnableRTV(Handle tmr, any data) {
    g_hAllowRTVTimer = null;
    g_bIsRTVAllowed = true;

    ChatAll("RTV Is now allowed!");
    return Plugin_Stop
}

public Action Task_ForceMapVote(Handle tmr, any data) {
	g_iTimeToNextVote = 10;
    CreateTimer(1.0, Task_PrintVoteCountDown, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
    return Plugin_Stop;
}

public Action Task_PrintVoteCountDown(Handle tmr, any data) {
    int timeLeft = g_iTimeToNextVote;

    if(timeLeft == 0) {
        // g_bVoteInProgress = true;
        g_currentState = EState_Vote;
        // g_currentState = EState_Vote;

        PrepareVote();
        MC_OpenMapvoteMenuToEveryone();

        g_hForceVoteTimer = null;
        return Plugin_Stop;
    }
    ChatAll("Mapvote starting in \x0F%d\x08 seconds", g_iTimeToNextVote);

	g_iTimeToNextVote--;
    return Plugin_Continue;
}