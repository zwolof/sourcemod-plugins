public void GetClientNameWithoutAscii(int client, char[] buffer, int len) {
    char szName[MAX_NAME_LENGTH], szOutput[MAX_NAME_LENGTH];
    GetClientName(client, szName, sizeof(szName));
    
    int iPos = 0;
    for (int i = 0; i < sizeof(szName); i++) {
        szOutput[(IsCharAlpha(szName[i]) || IsCharNumeric(szName[i]) ? iPos++ : iPos)] = szName[i];
	}
    szOutput[iPos] = '\0';

    strcopy(buffer, len, szOutput);
}

public void RemoveAscii(char[] buffer, int len) {
	char szOutput[MAX_NAME_LENGTH];

    int iPos = 0;
    for (int i = 0; i < len; i++) {
        szOutput[(IsCharAlpha(buffer[i]) || IsCharNumeric(buffer[i]) ? iPos++ : iPos)] = buffer[i];
	}
    szOutput[iPos] = '\0';

    strcopy(buffer, len, szOutput);
}

int CheckTargets(int client, const char[] args, PunishmentType_t type) {
    char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool whatthefuck;
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), whatthefuck)) > 0) {

		for (int i = 0; i < target_count; i++)
		{
			
		}
	}
	else {
		ReplyToTargetError(client, target_count);
	}
}

void GiveAdmin(int client, Admin_t admin) {
	int iBits = ReadFlagString(admin.flags);
	SetUserFlagBits(client, iBits);
}

public Action Command_eBan(int client, int iArgs) {
	if(iArgs <= 1) {
		PrintToChat(client, "%s \x0AUsage /ban <user/steamid64> <time[m, d, w, m, y]> <reason>", PREFIX);
		return Plugin_Handled;
	}
	
	char szUser[128], szTime[128], szReason[128];
	GetCmdArg(1, szUser, sizeof(szUser));
	StringToLower(szUser, szUser, sizeof(szUser));
	StripQuotes(szUser);
	
	int iTarget = FindTarget(client, szUser); 
	
	// Get 2nd and 3rd arg, transform to lowercase
	GetCmdArg(2, szTime, sizeof(szTime));
	StripQuotes(szTime);
	//GetCmdArg(3, szReason, sizeof(szReason));
	//StripQuotes(szReason);
	
	char sBuffer[100];
	if(iArgs >= 3) {
		GetCmdArg(3, szReason, sizeof(szReason));

		for (int i = 4; i <= iArgs; i++) {
			GetCmdArg(i, sBuffer, sizeof(sBuffer));
			Format(szReason, sizeof(szReason), "%s %s", szReason, sBuffer);
		}
	}
	else {
		szReason[0] = '\0';
	}
	
	StringToLower(szTime, szTime, sizeof(szTime));

    char sReasons[][] = {"cheat", "wh", "aimb", "spinb", "rage", "ss"};
    PunishmentType_t _pType = PunishmentType_Ban;

    for(int r = 0; r < sizeof(sReasons); r++) {
        if(StrContains(szReason, sReasons[r], false) != -1){
            szReason = "Cheating Infraction";
            break;
        }
    }

    char sChangeToMuteStrings[][] = {
        "racism", "nword", "disrespect", "admin"
    }

    for(int str = 0; str < sizeof(sChangeToMuteStrings); str++) {
        if(StrContains(szReason, sChangeToMuteStrings[str], false) != -1) {
            szReason = "Inappropriate Language";
            _pType = PunishmentType_Silence;
            break;
        }
    }
	PunishPlayer(client, iTarget, _pType, szTime, szReason);
	
	return Plugin_Handled;
}

public Action Command_eMute(int client, int iArgs) {
	if(0 >= iArgs < 4) {
		PrintToChat(client, "%s \x0AUsage /mute <user/steamid64> <time[m, d, w, m, y]> <reason>", PREFIX);
		return Plugin_Handled;
	}
	
	char szUser[128], szTime[128], szReason[128];
	GetCmdArg(1, szUser, sizeof(szUser));
	StringToLower(szUser, szUser, sizeof(szUser));
	StripQuotes(szUser);

	int iTarget = FindTarget(client, szUser); 
	
	// Get 2nd and 3rd arg, transform to lowercase
	GetCmdArg(2, szTime, sizeof(szTime));
	StripQuotes(szTime);
	GetCmdArg(3, szReason, sizeof(szReason));
	StripQuotes(szReason);

	StringToLower(szTime, szTime, sizeof(szTime));
	
	efrag_PrintToChat(client, "\x08Sending Mute for player \x0F%s", szUser);
	
	PunishPlayer(client, iTarget, view_as<PunishmentType_t>(PunishmentType_Mute), szTime, szReason);
	
	return Plugin_Handled;
}

public Action Command_eGag(int client, int iArgs) {
	if(0 >= iArgs < 4) {
		PrintToChat(client, PREFIX..." \x0AUsage /gag <user/steamid64> <time[m, d, w, m, y]> <reason>");
		return Plugin_Handled;
	}
	
	char szUser[128], szTime[128], szReason[128];
	GetCmdArg(1, szUser, sizeof(szUser));
	StringToLower(szUser, szUser, sizeof(szUser));
	StripQuotes(szUser);
	
	int iTarget = FindTarget(client, szUser); 
	
	// Get 2nd and 3rd arg, transform to lowercase
	GetCmdArg(2, szTime, sizeof(szTime));
	StripQuotes(szTime);
	GetCmdArg(3, szReason, sizeof(szReason));
	StripQuotes(szReason);

	StringToLower(szTime, szTime, sizeof(szTime));
	
	efrag_PrintToChat(client, "\x08Sending Gag for player \x0F%s", szUser);
	
	PunishPlayer(client, iTarget, view_as<PunishmentType_t>(PunishmentType_Gag), szTime, szReason);
	
	return Plugin_Handled;
}

stock int PunishPlayer(int iAdmin, int iTarget, PunishmentType_t Type, char[] szTimeString, char[] szReason) {

	if(IsValidClient(iTarget)) {
		if(__checkTimeArguments(iAdmin, szTimeString) == 6969420420) {
			if(iAdmin != 0) PrintToChat(iAdmin, "%s Invalid Date/Time string.", PREFIX);
			else			PrintToServer("Invalid Date/Time string");
			//PrintToChat(iAdmin, "%s 1", PREFIX);
			
			return Plugin_Handled;
		}
		else {
			if(strlen(szReason) >= 2) {
				int iTime = __checkTimeArguments(iAdmin, szTimeString);
				char szTime[64];
	
				if(iTime == 0) 					FormatEx(szTime, sizeof(szTime), "Permanent");
				else if(iTime % iMinute == 0) 	FormatEx(szTime, sizeof(szTime), "%d Minutes", iTime/60);
				else if(iTime % iHour == 0) 	FormatEx(szTime, sizeof(szTime), "%d Hours", iTime/3600);
				else if(iTime % iDay == 0) 		FormatEx(szTime, sizeof(szTime), "%d Days", iTime/86400);
				else if(iTime % iWeek == 0) 	FormatEx(szTime, sizeof(szTime), "%d Weeks", iTime/604800);
				else if(iTime % iMonth == 0) 	FormatEx(szTime, sizeof(szTime), "%d Months", iTime/2629746);
				else 							FormatTime(szTime, sizeof(szTime), "%m / %d / %y", GetTime()+iTime);
				
				//PrintToChat(iAdmin, "%s 5", PREFIX);
				
				SQL_UpdateUser(iTarget);
				SQL_AddPunishment(iTarget, iAdmin, view_as<PunishmentType_t>(Type), iTime, szReason);
				//void SQL_AddPunishment(int iAdmin, int Type, int iLength, char[] szReason)
				//PrintToChat(iAdmin, "%s 6", PREFIX);
				
				char sName[128];
				if(iAdmin != 0) GetClientNameWithoutAscii(iAdmin, sName, sizeof(sName));
				else sName = "[Shield]";
				
                switch(Type) {
                    case PunishmentType_Ban: {
                        char sPunishmentTimeString[128];
                        bool isPermanent = (StrContains(szTime, "Permanent", false) != -1);

                        FormatEx(sPunishmentTimeString, sizeof(sPunishmentTimeString), PREFIX..."\x0F%N\x08 has been%s banned for \"\x0F%s\x08\"!", iTarget, isPermanent ? " \x0Fpermanently\x08" : "", szReason);
                        PrintToChatAll("%s", sPunishmentTimeString);

                        KickClient(iTarget, "[EFRAG] You have been %s!\n \nReason:         %s\nAdmin:          %s\nLength:         %s\n \nTo appeal, head over to %s.\nIf you have been banned for cheating\n you can purchase an unban over at %s!",
                            g_szTypes[Type], szReason, sName, szTime, DISCORDURL, STOREURL);
                        
                    }
                    case PunishmentType_Mute, PunishmentType_Gag, PunishmentType_Silence: {
                        
                        char szPunishmentType_tLocal[][] = {
                            "BANNED", "MUTED", "GAGGED", "SILENCED"
                        }

                        if(Type == PunishmentType_Mute || Type == PunishmentType_Silence) {
                            SetClientListeningFlags(iTarget, VOICE_MUTED);
                            g_bMuted[iTarget] = true;
                        }

                        if(Type == PunishmentType_Gag || Type == PunishmentType_Silence) {
                            g_bGagged[iTarget] = true;
                        }

                        char PunishmentType_tLocalLower[128];
                        StringToLower(PunishmentType_tLocalLower[Type], PunishmentType_tLocalLower, sizeof(PunishmentType_tLocalLower));

                        PrintHintText(iTarget, "You have been <font color='#ff0000'>%s</font>!\nLength: <font color='#ff0000'>%s</font>", szPunishmentType_tLocal[Type], szTime);
                        PrintToChat(iTarget, PREFIX..."\x08You have been \x0F%s\x0A! Length: \x06%s\x0A", PunishmentType_tLocalLower, szTime);
                        
                        for(int i = 1; i <= MaxClients; i++) {
                            if(IsValidClient(i) && iTarget != i) {
                                PrintToChat(i, PREFIX..."\x0F%N\x08 has been \x0F%s\x0A!", iTarget, PunishmentType_tLocalLower);
                            }
                        }
                    }
                }
			}
			else
			{
				PrintToChat(iAdmin, "%s Please supply a reason! (min 2 chars)", PREFIX);
				return Plugin_Handled;
			}
		}
	}
	/*else
	{
		PrintToChat(client, "%s Check Console for output!", PREFIX);
		
		for(int i = 0; i < 6; i++)
		PrintToConsole(client, "\n ");
		
		PrintToConsole(client, "                                List of suffixes:");
		PrintToConsole(client, "               d = day          | /eban <name> 7d <reason> (1 week or 7d)");
		PrintToConsole(client, "               m = minute       | /eban <name> 7m <reason> (7 minutes or 7m)");
		PrintToConsole(client, "               s = second       | /eban <name> 7s <reason> (7 seconds or 7s)");
		PrintToConsole(client, "               y = year         | /eban <name> 7y <reason> (7 years or 7y)");
		PrintToConsole(client, "               p = permanent    | /eban <name> p <reason> (permanent ban)");
		
		for(int i = 0; i < 6; i++)
			PrintToConsole(client, "\n ");
	}*/
	return Plugin_Handled;
}

stock int PunishPlayerBySteamId(int iAdmin, const char[] steamid, const char[] name, PunishmentType_t Type, char[] szTimeString, char[] szReason)
{
    if(__checkTimeArguments(iAdmin, szTimeString) == 6969420420)
    {
        if(iAdmin != 0) PrintToChat(iAdmin, "%s Invalid Date/Time string.", PREFIX);
        else			PrintToServer("Invalid Date/Time string");

        return Plugin_Handled;
    }
    else
    {
        //PrintToChat(iAdmin, "%s 2", PREFIX);
        if(strlen(szReason) >= 2)
        {
            //PrintToChat(iAdmin, "%s 3", PREFIX);
            int iTime = __checkTimeArguments(iAdmin, szTimeString);
            char szTime[64];

            if(iTime == 0) 					FormatEx(szTime, sizeof(szTime), "Permanent");
            else if(iTime % iMinute == 0) 	FormatEx(szTime, sizeof(szTime), "%d Minutes", iTime/60);
            else if(iTime % iHour == 0) 	FormatEx(szTime, sizeof(szTime), "%d Hours", iTime/3600);
            else if(iTime % iDay == 0) 		FormatEx(szTime, sizeof(szTime), "%d Days", iTime/86400);
            else if(iTime % iWeek == 0) 	FormatEx(szTime, sizeof(szTime), "%d Weeks", iTime/604800);
            else if(iTime % iMonth == 0) 	FormatEx(szTime, sizeof(szTime), "%d Months", iTime/2629746);
            else 							FormatTime(szTime, sizeof(szTime), "%m / %d / %y", GetTime()+iTime);

            char sName[128];
            if(iAdmin != 0) GetClientNameWithoutAscii(iAdmin, sName, sizeof(sName));
            else sName = "[Shield]";
            SQL_AddPunishmentBySteamId(steamid, name, iAdmin, view_as<PunishmentType_t>(Type), iTime, szReason);
        }
        else
        {
            PrintToChat(iAdmin, "%s Please supply a reason! (min 2 chars)", PREFIX);
            return Plugin_Handled;
        }
    }
	return Plugin_Handled;
}

void StartChatHook(int client) {
	EmitSoundToClient(client, g_sBlipSound, client, _, _, _, 0.5);
	bChatIsHooked[client] = true;
	
	if(g_hChatHook[client] != INVALID_HANDLE)
	{
		KillTimer(g_hChatHook[client]);
		g_hChatHook[client] = INVALID_HANDLE;
	}
	g_hChatHook[client] = CreateTimer(15.0, Task_CheckChatHook, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Task_CheckChatHook(Handle hTimer, any client) {
	if(IsClientInGame(client)) {
		PrintToChat(client, PREFIX..."\x0815 seconds passed with no chat message.");
		bChatIsHooked[client] = false;
	}
	g_hChatHook[client] = INVALID_HANDLE;
}

public Action Command_Say(int client, int iArg)
{
	char sArgs[256];
	GetCmdArgString(sArgs, sizeof(sArgs));
	StripQuotes(sArgs);

	if(g_hChatHook[client] != INVALID_HANDLE) {
		PrintToChatAll(" \x0F======== ADMIN MESSAGE ========");
		PrintToChatAll(" ");
		PrintToChatAll(" \x0B\x01\x10%s", sArgs);
		PrintToChatAll(" ");
		PrintToChatAll(" \x0F======== ADMIN MESSAGE ========");
		
		if(g_hChatHook[client] != INVALID_HANDLE) {
			KillTimer(g_hChatHook[client]);
			g_hChatHook[client] = INVALID_HANDLE;
		}
		bChatIsHooked[client] = false;
		PrintToChat(client, PREFIX..."\x08Chat has been un-hooked!");

        if(CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC)) {
            CreateAdminMenu(client, MENU_TIME_FOREVER);
        } 
		return Plugin_Handled;
	}
}
			
stock int __checkTimeArguments(int client, char[] szDuration)
{
	int iTime;
	char szExplodedString[4][64];
	// Let us say duration is a string, "24d", I explode the d out of there and now we only have 24 left, then i 
	// convert the "24" into an integer using StringToInt, then I multiply the iTime variable(our time as an int)
	// with how many seconds we have in a day, this will now be our Time, and this will be saved as expiry_date(UNIX Timestamp)
	// in our mysql database as `GetTime()+iTime`, their ban will then be 24*86400
	if(client != 0) {
		if(0 <= strlen(szDuration) < 1 || strlen(szDuration) > 8) {
			PrintToChat(client, "%s \x0FInvalid\x0A Date/Time Format!", PREFIX);
			return 6969420420;
		}
	} else {
        PrintToServer("Invalid Date/Time Format");
    }

	// Parser

    // enum Time {
    //     Time_Second = 1,
    //     Time_Minute = 60,
    //     Time_Hour   = 3600,
    //     Time_Day    = 86400,
    //     Time_Week   = 604800,
    //     Time_Month  = 2629746
    // }

    // int test[6];
    // test[0] = ParseBanTimeString(szDuration, "s", Time_Second);
    // test[1] = ParseBanTimeString(szDuration, "m", Time_Minute);
    // test[2] = ParseBanTimeString(szDuration, "h", Time_Hour);
    // test[3] = ParseBanTimeString(szDuration, "d", Time_Day);
    // test[4] = ParseBanTimeString(szDuration, "w", Time_Week);
    // test[5] = ParseBanTimeString(szDuration, "mo", Time_Month);
    
    // int val = -1;

    // for(int i = 0; i < 6; i++) {
    //     if(test[i] != -1) {
    //         val += test[i];
    //     }
    // }
    // if(val == -1) {
    //     // invalid time passed
    // }
    // return val;


    // char TimeArgs[][] = {"s", "m", "h", "d", "w", "mo" };
    // for(int i = 0; i < sizeof(TimeArgs); i++) {
    //     int val = -1;
    //     if((val = ParseBanTimeString(szDuration, TimeArgs[i], Time[i]) != -1)) {
    //         value += val;
    //     }
    // }
    if(strlen(szDuration) > 1 && StrContains(szDuration, "d", false) != -1)
    {
        ExplodeString(szDuration, "d", szExplodedString, sizeof(szExplodedString), sizeof(szExplodedString[]));
        iTime = StringToInt(szExplodedString[0]);
        iTime *= 86400;
    }
    else if(strlen(szDuration) > 1 && StrContains(szDuration, "s", false) != -1)
    {
        ExplodeString(szDuration, "s", szExplodedString, sizeof(szExplodedString), sizeof(szExplodedString[]));
        iTime = StringToInt(szExplodedString[0]);
        iTime *= 1;
    }
    else if(strlen(szDuration) > 1 && StrContains(szDuration, "w", false) != -1)
    {
        ExplodeString(szDuration, "w", szExplodedString, sizeof(szExplodedString), sizeof(szExplodedString[]));
        iTime = StringToInt(szExplodedString[0]);
        iTime *= 604800;
    }
    else if(strlen(szDuration) > 1 && StrContains(szDuration, "h", false) != -1)
    {
        ExplodeString(szDuration, "h", szExplodedString, sizeof(szExplodedString), sizeof(szExplodedString[]));
        iTime = StringToInt(szExplodedString[0]);
        iTime *= 3600;
    }
    else if(strlen(szDuration) > 1 && StrContains(szDuration, "m", false) != -1)
    {
        if(StrContains(szDuration, "mo", false) != -1)
        {
            ExplodeString(szDuration, "mo", szExplodedString, sizeof(szExplodedString), sizeof(szExplodedString[]));
            iTime = StringToInt(szExplodedString[0]);
            iTime *= 2629746;
        }
        else
        {
            ExplodeString(szDuration, "m", szExplodedString, sizeof(szExplodedString), sizeof(szExplodedString[]));
            iTime = StringToInt(szExplodedString[0]);
            iTime *= 60;
        }
    }
    else if(strlen(szDuration) >= 1 && StrContains(szDuration, "p", false) != -1)
    {
        ExplodeString(szDuration, "p", szExplodedString, sizeof(szExplodedString), sizeof(szExplodedString[]));
        iTime = StringToInt(szExplodedString[0]);
        iTime *= 1;
    }
    else {
        if(!StrContains(szDuration, "d", false) != -1
        && !StrContains(szDuration, "s", false) != -1
        && !StrContains(szDuration, "w", false) != -1
        && !StrContains(szDuration, "h", false) != -1
        && !StrContains(szDuration, "m", false) != -1
        && !StrContains(szDuration, "mo", false) != -1
        && !StrContains(szDuration, "p", false) != -1 )
        {
            iTime = StringToInt(szDuration);
            iTime *= 60;
        }
        PrintToConsole(client, "time: %d", iTime);
    }
	//PrintToChat(client, "%s GetTime(): { \x04%d\x01 }", PREFIX, GetTime()/*UnixToTime(GetTime()+iTime, iYear, iMonth, iDay, iHour, iMinute, iSecond)*/);
	return iTime;
}

stock int ParseBanTimeString(const char[] duration, const char[] str, const int time) {
    char exploded[16][16];
    int retVal = 60;

    if(strlen(duration) > 1 && StrContains(duration, str, false) != -1) {
        ExplodeString(duration, str, exploded, sizeof(exploded), sizeof(exploded[]));
        retVal = StringToInt(exploded[0]) * time;
    }
    return retVal;
}


stock StringToLower(const char[] input, char[] output, int size)
{
	size--;
	
	int x = 0;
	while(input[x] != '\0' && x < size)
	{
		output[x] = CharToLower(input[x]);
		x++;
	}
	output[x] = '\0';
}

stock bool Substring(char[] dest, int destSize, char[] source, int sourceSize, int start, int end)
{
    if (end < start || end > (sourceSize-1))
    {
        strcopy(dest, destSize, NULL_STRING);
        return false;
    }
    else
    {
        strcopy(dest, (end-start+1), source[start]);
        return true;
    }
} 

public void SubString2(char[] buffer, int len)
{
	char szOutput[MAX_NAME_LENGTH];
	int pos = 0;
    for (int pos = 0; pos <= 12; pos++)
    {
    	szOutput[pos] = buffer[pos];
    }
    szOutput[pos] = '\0';

    strcopy(buffer, len, szOutput);
}

stock bool IsValidClient(int client)
{
	return view_as<bool>((0 < client <= MaxClients) && IsClientInGame(client) && !IsFakeClient(client));
}