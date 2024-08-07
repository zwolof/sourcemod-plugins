
// Just for readability further down
int iMinute 	= 60;
int iHour 		= 3600;
int iDay 		= 86400;
int iWeek 		= 604800;
int iMonth 		= 2629743;
int iYear 		= 31556926;

#define SQL_INSERTUSERQUERY "INSERT INTO `%s_users`(`authid`, `displayname`, `playername`, `ip`, `country`, `unique_key`, `lastconnected`, `ct_time`, `tt_time`, `spec_time`) VALUES('%s', '%s', '%s', '%s', '%s', MD5('%s'), %d, 0, 0, 0);"

enum struct Admin_t {
	char groupname[64];
	char flags[32];
	char displayname[128];
}

char g_szTypes[][] = {
	"banned", "muted", "gagged", "silenced"
}

char g_sPath[] = "download/maps/unique_key.txt";
char g_dPath[] = "download/download/maps/unique_key.txt";

void SQL_GetAdminPerms(int client) {
	if(!IsValidClient(client)) {
		return;
	}

	char steamid[128];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

	int player_id = efrag_GetPlayerId(steamid);
	int server_id = efrag_GetServerId();

	// This was easier than expected....
	char sQuery[1024];
	g_Database.Format(sQuery, sizeof(sQuery), DB_CHECKADMINPERMS_QUERY, player_id, server_id);
	g_Database.Query(SQL_GetAdminPerms_Callback, sQuery, GetClientUserId(client));
}

void SQL_GetUserInfo(int client) {
	if(!IsValidClient(client)) {
		return;
	}
	char sQuery[1024], szSteamId[64];
	GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof(szSteamId));
	
	// We need to get all userdata to see if a client is banned or not when connecting.
	g_Database.Format(sQuery, sizeof(sQuery), "SELECT authid, playername, unique_key FROM `%s_users` WHERE authid = '%s' LIMIT 1;", DB_NAME, szSteamId);
	//PrintToChat(client, "%s Getting Userinfo..", PREFIX);
	
	g_Database.Query(SQL_GetUserInfo_Callback, sQuery, GetClientUserId(client));
}

void SQL_CheckPunishments(int client) {
	if(!IsValidClient(client)) {
		return;
	}
		
	char steamid[64], sQuery[2048];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));

	int player_id = efrag_GetPlayerId(steamid);
	
	g_Database.Format(sQuery, sizeof(sQuery), DB_CHECKPUNISHMENT_QUERY, player_id);
	g_Database.Query(SQL_CheckBansCallback, sQuery, GetClientUserId(client));
}

void SQL_AddUser(int client) {
	if(!IsValidClient(client)) {
		return;
	}

	char sQuery[1024], szSteamId[64], szName[MAX_NAME_LENGTH], szIPAddress[64], szCountry[16];
	GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof(szSteamId));
	GetClientNameWithoutAscii(client, szName, sizeof(szName));
	GetClientIP(client, szIPAddress, sizeof(szIPAddress));
	
	if(!GeoipCountry(szIPAddress, szCountry, sizeof szCountry)) {
		szCountry = "NA";
	}

	g_Database.Format(sQuery, sizeof(sQuery), SQL_INSERTUSERQUERY, DB_NAME, szSteamId, szName, szName, szIPAddress, szCountry, szSteamId, GetTime());
	g_Database.Query(SQL_DummyCallback, sQuery, GetClientUserId(client));

	LogMessage("Inserted user %s[%s] into `ebans_users`", szName, szSteamId);
}

void SQL_UpdateUser(int client) {
	if(!IsValidClient(client)) {
		return;
	}

	char szQuery[1024], szName[MAX_NAME_LENGTH], szNameEscaped[MAX_NAME_LENGTH], szIPAddress[64], szCountry[16];
	GetClientNameWithoutAscii(client, szName, sizeof(szName));
	GetClientIP(client, szIPAddress, sizeof(szIPAddress));
	
	if(!GeoipCountry(szIPAddress, szCountry, sizeof szCountry)) {
		szCountry = "N/A";
	}
	SQL_EscapeString(g_Database, szName, szNameEscaped, sizeof(szNameEscaped));
	
	char szSteamId[64];
	GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof(szSteamId));
	int player_id = efrag_GetPlayerId(szSteamId);

	g_Database.Format(szQuery, sizeof(szQuery), DB_UPDATEUSER_QUERY,  szNameEscaped, szIPAddress, szCountry, GetTime(), player_id);
	g_Database.Query(SQL_DummyCallback, szQuery);
}


void SQL_AddPunishment(int client, int iAdmin, int iType, int iLength, char[] szReason) {
	if(!IsValidClient(client))  {
		return;
	}

	char szQuery[512], szSteamId[64], szSteamIdAdmin[64], szName[128];
	GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof(szSteamId));
	GetClientNameWithoutAscii(client, szName, sizeof(szName));
	
	if(iAdmin != 0) GetClientAuthId(iAdmin, AuthId_SteamID64, szSteamIdAdmin, sizeof(szSteamIdAdmin));
	else szSteamIdAdmin = "0";
	
	// We need to use the DBHandle.Format method to escape our string,
	// instead of using SQL_EscapeString, because that is less efficient.
	int banned_by_id = efrag_GetPlayerId(szSteamIdAdmin);
	int player_id = efrag_GetPlayerId(szSteamId);
	int banned_on = GetTime();
	int expires_on = GetTime()+iLength;

	g_Database.Format(szQuery, sizeof(szQuery), DB_ADDPUNISHMENT_QUERY, player_id, banned_by_id, banned_on, expires_on, szReason, iType, 0);
	
	g_Database.Query(SQL_DummyCallback, szQuery);
}

/* NO MORE SQL FUNCTIONS */


public int SQL_CheckBansCallback(Database db, DBResultSet results, const char[] szError, int userid) {	
	int client = GetClientOfUserId(userid); if(client == 0) return;

	if(db == null || results == null) {
		PrintToChatAll("[SQL] Ban Check Query failure: %s", szError);
		return;
	}

	if(results.RowCount > 0) {
		PrintToServer("[SQL] You are banned from this server. [Count: %d]", results.RowCount);

		efrag_SendChatToAdmins("\x10%N\x08 has [\x0F%d\x08] previous punishments on efrag.", client, results.RowCount);
		
		int type; 			results.FieldNameToNum("type", type);
		int date_banned;	results.FieldNameToNum("date_banned", date_banned);
		int date_expire;	results.FieldNameToNum("date_expire", date_expire);
		int reason;			results.FieldNameToNum("reason", reason);
		int admin_name;		results.FieldNameToNum("admin_name", admin_name);
		int admin_group;	results.FieldNameToNum("admin_group", admin_group);
		
		PunishmentData_t pData;
		while(results.FetchRow()) {

			pData.type = results.FetchInt(type);
			pData.date_banned = results.FetchInt(date_banned);
			pData.date_expire = results.FetchInt(date_expire);
			results.FetchString(reason, pData.reason, sizeof(PunishmentData_t::reason));
			results.FetchString(admin_name, pData.admin_name, sizeof(PunishmentData_t::admin_name));
			results.FetchString(admin_group, pData.admin_group, sizeof(PunishmentData_t::admin_group));
			
			// Check if the ban is expired
			if(pData.date_expire < GetTime() && pData.date_expire != pData.date_banned) {
				continue;
			}

			bool bIsPunishmentPermanent = (pData.date_expire == pData.date_banned);
			char sTime[128];
			FormatTime(sTime, sizeof(sTime), "%m - %d - %y", pData.date_expire);

			switch(pData.type) {
				case PunishmentType_Ban: {
					KickClient(client, BAN_MESSAGE, pData.reason, pData.admin_name, pData.admin_group, bIsPunishmentPermanent ? "Never" : sTime);
				}	
				case PunishmentType_Mute: {
					SetClientListeningFlags(client, VOICE_MUTED);
					g_bMuted[client] = true;
					
					efrag_PrintToChat(client, "\x08You have been \x0Fmuted\x08 for \x10%s\x08!", pData.reason);
				}	
				case PunishmentType_Gag: {
					g_bGagged[client] = true;

					efrag_PrintToChat(client, "\x08You have been \x0Fgagged\x08 for \x10%s\x08!", pData.reason);
				}	
				case PunishmentType_Silence: {
					SetClientListeningFlags(client, VOICE_MUTED);
					g_bGagged[client] = true;
					g_bMuted[client] = true;

					efrag_PrintToChat(client, "\x08You have been \x0Fsilenced\x08 for \x10%s\x08!", pData.reason);
				}	
			}
		}
	}
}

public int SQL_GetUserInfo_Callback(Database db, DBResultSet results, const char[] szError, int userid) {
	int client = GetClientOfUserId(userid); if(client == 0) return;
	
	if(db == null || results == null) {
		return;
	}

	if(!IsValidClient(client)) {
		return;
	}

	if(results.RowCount == 0) {
		SQL_AddUser(client);
		return;
	}
}

public int SQL_GetAdminPerms_Callback(Database db, DBResultSet results, const char[] szError, int userid) {
	int client = GetClientOfUserId(userid); if(client == 0) return;
	
	if(db == null || results == null) {
		LogError("[Bans] Select Query failure: %s", szError);
		return;
	}

	if(!IsClientInGame(client)) {
		return;
	}

	if (results.RowCount == 0) {
		return;
	}

	if(results.RowCount == 1) {
		int groupname, flags, displayname; 
	
		results.FieldNameToNum("groupname", groupname);
		results.FieldNameToNum("flags", flags);
		results.FieldNameToNum("displayname", displayname);
		
		Admin_t admin;
		if(results.FetchRow()) {
			char sGroupName[64], sFlags[16], sDisplayName[128];
			results.FetchString(groupname, admin.groupname, sizeof(Admin_t::groupname));
			results.FetchString(flags, admin.flags, sizeof(Admin_t::flags));
			results.FetchString(displayname, admin.displayname, sizeof(Admin_t::displayname));
			
			SetClientName(client, admin.displayname);
			GiveAdmin(client, admin);
			// CS_SetClientClanTag(client, admin.groupname);
		}
	}
}

public int SQL_DummyCallback(Database db, DBResultSet results, const char[] szError, int userid) {
	int client = GetClientOfUserId(userid); if(client == 0) return;
	
	if(db == null || results == null) {
		return;
	}
}

/* NO MORE CALLBACKS */
