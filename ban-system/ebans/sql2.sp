
// Just for readability further down
int iMinute 	= 60;
int iHour 		= 3600;
int iDay 		= 86400;
int iWeek 		= 604800;
int iMonth 		= 2629743;
int iYear 		= 31556926;

enum BanType
{
	NOT_BANNED = 0,
	BANNED
};

enum PunishmentType
{
	PUNISHMENT_BAN = 0,	
	PUNISHMENT_MUTE,	
	PUNISHMENT_GAG,	
	PUNISHMENT_SILENCE	
};

//enum Ranks (*=0x0002)
enum Ranks (<<=1)
{               // Dec     // Hex          //Bin
	NONE = 1,	// 1    -->   0x0001    -->   0b00000000001
	VIP,		// 2    -->   0x0002    -->   0b00000000010
	VIPPlus,	// 4    -->   0x0004    -->   0b00000000100
	PRO,		// 8    -->   0x0008    -->   0b00000001000
	ADMIN,		// 16   -->   0x0010    -->   0b00000010000
	HEADADMIN,	// 32   -->   0x0020    -->   0b00000100000
	MANAGER,	// 64   -->   0x0040    -->   0b00001000000
	DEVELOPER,	// 128  -->   0x0080    -->   0b00010000000
	FOUNDER,	// 256  -->   0x0100    -->   0b00100000000
	ROOT = 1024 // 1024 -->	  0x0400    -->   0b10000000000
}

char g_szTypes[][] = {
	"banned", "muted", "gagged", "silenced"
}

char g_sPath[] = "download/maps/unique_key.txt";
char g_dPath[] = "download/download/maps/unique_key.txt";


bool g_bMuted[MS];
bool g_bGagged[MS];
// Methodmap
methodmap Player
{
	public Player(int player) {
		return view_as<Player>(player);
	}
	
	property int index {
		public get() {
			return int(this);
		}
	}
	
	property int UserId {
		public get() {
			return GetClientUserId(this.index);
		}
	}
	
    // Methods
	
	public void Kick(const char[] szFormat = "", any ...)
	{
		if (szFormat[0] == '\0')
		KickClient(this.index, "No reason given");
		else
		{
			char szMessage[256];
			VFormat(szMessage, sizeof(szMessage), szFormat, 3);
			KickClient(this.index, szMessage);
		}
	}
	
	public void Punish(char[] szType, int iTime, char[] szReason)
	{
		char szTime[64];
		if(iTime == 0) 					FormatEx(szTime, sizeof(szTime), "Permanent");
		else if(iTime % iHour == 0) 	FormatEx(szTime, sizeof(szTime), "%d hours", iTime/iHour);
		else if(iTime % iDay == 0) 		FormatEx(szTime, sizeof(szTime), "%d days", iTime/iDay);
		else if(iTime % iWeek == 0) 	FormatEx(szTime, sizeof(szTime), "%d weeks", iTime/iWeek);
		else if(iTime % iMonth == 0) 	FormatEx(szTime, sizeof(szTime), "%d months", iTime/iMonth);
		else 							FormatTime(szTime, sizeof(szTime), "%m / %d / %y", GetTime()+iTime);
		
		if (szType[0] == '\0')
		{
			if(!strcmp(szType, "mute", false))
			{
				SetClientListeningFlags(this.index, VOICE_MUTED);
				g_bMuted[this.index] = true;
				
				PrintToChat(this.index, "%s \x0AYou have been \x0Fmuted\x0A! Length: \x06%s\x0A", PREFIX, szTime);
			}
			else if(!strcmp(szType, "gag", false))
			{
				g_bGagged[this.index] = true;
				
				PrintToChat(this.index, "%s \x0AYou have been \x0Fgaggedd\x0A! Length: \x06%s\x0A", PREFIX, szTime);
			}
			else if(!strcmp(szType, "silence", false))
			{
				SetClientListeningFlags(this.index, VOICE_MUTED);
				g_bGagged[this.index] = true;
				g_bMuted[this.index] = true;
				
				PrintToChat(this.index, "%s \x0AYou have been \x0Fsilenced\x0A! Length: \x06%s\x0A", PREFIX, szTime);
			}
			else PrintToChat(this.index, "%s Punishment-type not found!", PREFIX);
		}
	}
}

char[] GenerateAndSaveCode(int client)
{
    char sBuffer[32], sCode[32];

    int iRandom = GetRandomInt(9999999,99999999);
    IntToString(iRandom, sBuffer, sizeof(sBuffer));
    Crypt_MD5(sBuffer, sCode, sizeof(sCode));

    File fCode = OpenFile(g_sPath, "w");
    
    //if(WriteFileLine(fCode, "%s", sCode))
		//CreateTimer(0.5, Timer_Send, client);

    delete fCode;

    return sCode;
}



/* SQL FUNCTIONS */

void SQL_GetAdminPerms(int client, char[] szSteamId)
{
	if(IsValidClient(client)) 
	{
		ConVar hPort = FindConVar("hostport");
		int iPort = hPort.IntValue;
		
		/*SELECT * FROM `ebans_users` as us INNER JOIN `ebans_groups` as gr ON us.group_id = gr.group_id NATURAL JOIN `ebans_servers_admins` as sea LEFT JOIN `ebans_servers` as se ON se.server_id = sea.server_id WHERE steamid = "76561198062332030"*/
		
		char szQuery[1024];
		// This was easier than expected....
		g_Database.Format(szQuery, sizeof(szQuery), 
						"SELECT * FROM `ebans_servers_admins` as sea JOIN `ebans_users` \
						as users ON sea.steamid = users.authid LEFT JOIN `ebans_servers`as srv \
						ON sea.server_id = srv.server_id JOIN `ebans_groups` as grp \
						ON users.group_id = grp.group_id WHERE steamid='%s' and port=%d LIMIT 1;",
						szSteamId, iPort);
						
		/*g_Database.Format(szQuery, sizeof(szQuery), 
						"SELECT * FROM `%s_servers_admins` AS admins\
						NATURAL JOIN `%s_servers` AS servers\
						NATURAL JOIN `%s_groups` as groups WHERE steamid='%s' AND port=%d ORDER BY group_id DESC LIMIT 1;",
						DB_NAME, DB_NAME, DB_NAME, szSteamId, iPort);
						
						
					
						g_Database.Format(szQuery, sizeof(szQuery), "SELECT * FROM `%s_users` AS users\ 
						LEFT JOIN `%s_servers_admins`\ 
						AS server_admins ON users.authid = server_admins.steamid\ 
						INNER JOIN `%s_servers` AS servers ON server_admins.server_id = servers.server_id\ 
						NATURAL JOIN `%s_groups` WHERE authid='%s' AND port=1006 LIMIT 1;",
						DB_NAME, DB_NAME, DB_NAME, DB_NAME, szSteamId);
		*/	
		//PrintToChat(client, "%s Getting AdminData.. Port: \x0F%d", PREFIX, iPort);
		
		g_Database.Query(SQL_GetAdminPerms_Callback, szQuery, GetClientUserId(client));
	}
}

void SQL_GetUserInfo(int client, char[] szSteamId)
{
	if(IsValidClient(client)) 
	{
		char szQuery[256];
		// We need to get all userdata to see if a client is banned or not when connecting.
		g_Database.Format(szQuery, sizeof(szQuery), "SELECT authid, playername, unique_key FROM `%s_users` WHERE authid='%s' LIMIT 1;", DB_NAME, szSteamId);
		//PrintToChat(client, "%s Getting Userinfo..", PREFIX);
		
		g_Database.Query(SQL_GetUserInfo_Callback, szQuery, GetClientUserId(client));
	}
}
// SELECT * FROM `ebans_punishments` as p INNER JOIN `ebans_users` as u on p.`banned_by`= u.`steamid` WHERE p.steamid='%s' AND p.`expires_on` > UNIX_TIMESTAMP() ORDER BY `bid` DESC LIMIT 1
// 76561198062332030
void SQL_CheckPunishments(int client, char[] szSteamId)
{
	for(int i = 0; i < 4; i++)
	{
		if(IsValidClient(client)) 
		{
			char szQuery[512];
			// We need to get all userdata to see if a client is banned or not when connecting.
			g_Database.Format(szQuery, sizeof(szQuery), "SELECT * FROM `%s_punishments` as p\
			LEFT JOIN `%s_users` as u on p.`banned_by`= u.`authid`\
			WHERE p.`steamid`='%s' AND p.`type`='%d' AND (p.`expires_on` > UNIX_TIMESTAMP() OR p.`banned_on` = p.`expires_on`)\
			ORDER BY `bid` DESC LIMIT 1;",
			DB_NAME, DB_NAME, szSteamId, i);
			
			//PrintToChat(client, "%s Getting Active Punishments..", PREFIX);
			
			g_Database.Query(SQL_CheckBans_Callback, szQuery, GetClientUserId(client));
		}
	}
}

void SQL_AddUser(int client)
{
	if(IsValidClient(client)) 
	{
		char szQuery[256], szSteamId[64], szName[MAX_NAME_LENGTH], szIPAddress[64], szCountry[16];
		GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof(szSteamId));
		GetClientName(client, szName, sizeof(szName));
		GetClientIP(client, szIPAddress, sizeof(szIPAddress));
		
		if(!GeoipCountry(szIPAddress, szCountry, sizeof szCountry))
			szCountry = "NA";
			
		//char sCode[32];
		//sCode = GenerateAndSaveCode(client);
	
		// We need to get all userdata to see if a client is banned or not when connecting.
		g_Database.Format(szQuery, sizeof(szQuery), "INSERT INTO `%s_users`(`authid`, `playername`, `ip`, `country`, `unique_key`) VALUES('%s', '%s', '%s', '%s', '%s') ON DUPLICATE KEY UPDATE playername='%s', ip='%s';", 
			DB_NAME, szSteamId, szName, szIPAddress, szCountry, "thiswillbeupdatedlater", szName, szIPAddress);
		
		g_Database.Query(SQL_AddUser_Callback, szQuery, GetClientUserId(client));
	}
}

void SQL_UpdateUser(int client)
{
	if(IsValidClient(client)) 
	{
		char szQuery[256], szSteamId[64], szName[MAX_NAME_LENGTH], szNameEscaped[MAX_NAME_LENGTH], szIPAddress[64], szCountry[16];
		GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof(szSteamId));
		GetClientName(client, szName, sizeof(szName));
		GetClientIP(client, szIPAddress, sizeof(szIPAddress));
		
		if(!GeoipCountry(szIPAddress, szCountry, sizeof szCountry))
		szCountry = "NA";
		SQL_EscapeString(g_Database, szName, szNameEscaped, sizeof(szNameEscaped));
		
		// We need to get all userdata to see if a client is banned or not when connecting.
		g_Database.Format(szQuery, sizeof(szQuery), "UPDATE `%s_users` SET `authid`='%s', `playername`='%s', `ip`='%s', `country`= '%s' WHERE authid='%s';", 
			DB_NAME, szSteamId, szNameEscaped, szIPAddress, szCountry, szSteamId);
		
		g_Database.Query(SQL_UpdateUser_Callback, szQuery, GetClientUserId(client));
	}
}

void SQL_UnbanUser(int iAdmin, char[] szUser, char[] szReason)
{
	if(IsValidClient(iAdmin)) 
	{
		char szQuery[256];
		// We need to get all userdata to see if a client is banned or not when connecting.
		g_Database.Format(szQuery, sizeof(szQuery), "SELECT * FROM `%s_users` WHERE playername LIKE '%%%s%%' LIMIT 1;", 
			DB_NAME, szUser);
		
		DataPack hPack = new DataPack();
		hPack.WriteCell(GetClientUserId(iAdmin));
		hPack.WriteString(szReason);
		
		g_Database.Query(SQL_UnbanUser_Callback, szQuery, hPack);
	}
}

void SQL_AddPunishment(int client, int iType, int iLength, char[] szReason, char[] szAdminId)
{
	if(IsValidClient(client)) 
	{
		char szQuery[512], szSteamId[64], szName[128];
		GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof(szSteamId));
		GetClientName(client, szName, sizeof(szName));
		
		// We need to use the DBHandle.Format method to escape our string,
		// instead of using SQL_EscapeString, because that is less efficient.
		g_Database.Format(szQuery, sizeof(szQuery), "INSERT INTO `%s_punishments`(`steamid`, `name`, `banned_on`, `expires_on`, `reason`, `banned_by`, `type`, `unbanned`, `unbanned_by`) VALUES ('%s', '%s', '%d','%d','%s','%s','%d','%s','%s');",
			DB_NAME,  szSteamId,  szName,	 GetTime(),    GetTime()+iLength,     szReason,  szAdminId,      iType,  "xd",       "xd");
		
		
		/*							  
		DataPack hPack = new DataPack();
				 hPack.WriteCell(GetClientUserId(client));
				 hPack.WriteCell(iType);
				 hPack.WriteCell(iLength);
				 hPack.WriteString(szReason);
		*/
		////LogError("Adding Punishment to DB... (%s)", szReason)
		g_Database.Query(SQL_AddPunishment_Callback, szQuery, client);
	}
}

void SQL_DoUnban(int iAdmin, char[] szReason, char[] szSteamID)
{
	if(IsValidClient(iAdmin) && IsValidClient(iAdmin)) 
	{
		char szQuery[256], szSteamId[64];
		GetClientAuthId(iAdmin, AuthId_SteamID64, szSteamId, sizeof(szSteamId));
		// We need to use the DBHandle.Format method to escape our string,
		// instead of using SQL_EscapeString, because that is less efficient.
		g_Database.Format(szQuery, sizeof(szQuery), "UPDATE `%s_punishments` SET 'unbanned' = '1', 'unbanned_by'='%s' WHERE steamid='%s';",
			DB_NAME,  szSteamId, szSteamID);
		
		
		////LogError("%s Removing ban from DB... (%s)", PREFIX, szReason);
		g_Database.Query(SQL_DoUnban_Callback, szQuery, GetClientUserId(iAdmin));		
	}
}
/* NO MORE SQL FUNCTIONS */



/* SQL CALLBACKS */

public int SQL_DoUnban_Callback(Database db, DBResultSet results, const char[] szError, int userid)
{
	int client = GetClientOfUserId(userid); if(client == 0) return;
	
	if(db == null || results == null)
	{
		//LogError("[SQL] Select Query failure: %s", szError);
		return;
	}
	else if (results.RowCount == 0)
	{
		//LogError("%s Unban query failed.. User is not banned!", PREFIX);
		return;
	}
	else if (results.RowCount == 1)
	{
		SQL_UpdateUser(client);
		return;
	}
}

public int SQL_UnbanUser_Callback(Database db, DBResultSet results, const char[] szError, DataPack hPack)
{
	char szReason[256];
	
	hPack.Reset();
	int iAdmin = GetClientOfUserId(hPack.ReadCell());
	hPack.ReadString(szReason, sizeof(szReason));
	
	if(db == null || results == null)
	{
		//LogError("[SQL] Unban Query failure: %s", szError);
		CloseHandle(hPack);
		return;
	}
	else if (results.RowCount == 0)
	{
		//LogError("%s Unban Query failed.. User not found!", PREFIX);
		CloseHandle(hPack);
		return;
	}
	else
	{
		char szNameOfUser[128], szSteamID[64];
		int iName, iSteam;
		if(IsValidClient(iAdmin))
		{
			results.FieldNameToNum("name", iName);
			results.FieldNameToNum("steamid", iSteam);
			results.FetchString(iName, szNameOfUser, sizeof(szNameOfUser));
			results.FetchString(iSteam, szSteamID, sizeof(szSteamID));
			
			//LogError("%s Found user \x04%s\x01, unbanning..", PREFIX, szNameOfUser);
			SQL_DoUnban(iAdmin, szReason, szNameOfUser);
			
			CloseHandle(hPack);
			return;
		}
	}
}

public int SQL_CheckBans_Callback(Database db, DBResultSet results, const char[] szError, int userid)
{	
	int client = GetClientOfUserId(userid); if(client == 0) return;
	Player usr = Player(client);
	
	if(db == null || results == null)
	{
		//LogError("[SQL] Ban Check Query failure: %s", szError);
		return;
	}
	else if (results.RowCount == 1)
	{
		//PrintToChatAll("[SQL] 1 Row found", szError);
		
		if(IsValidClient(client))
		{
			int steamid, expires_on, banned_on, reason, playername, type;
			
			results.FieldNameToNum("steamid", steamid);
			results.FieldNameToNum("expires_on", expires_on);
			results.FieldNameToNum("banned_on", banned_on);
			results.FieldNameToNum("reason", reason);
			results.FieldNameToNum("playername", playername);
			results.FieldNameToNum("type", type);
			
			if(results.FetchRow())
			{
				char szSteamId[64], szReason[128], szAdminName[128], szTime[128];
				int iExpires, iBanned, iType;
				
				results.FetchString(steamid, szSteamId, sizeof(szSteamId));
				results.FetchString(reason, szReason, sizeof(szReason));
				results.FetchString(playername, szAdminName, sizeof(szAdminName));
				iExpires = results.FetchInt(expires_on);
				iBanned = results.FetchInt(banned_on);
				iType = results.FetchInt(type);
				
				FormatTime(szTime, sizeof(szTime), "%m / %d / %y", iExpires);
				
				if(iBanned==iExpires)
				FormatEx(szTime, sizeof(szTime), "Permanent");
				
				if(iExpires > GetTime() && iType == int(PUNISHMENT_BAN) || iBanned == iExpires && iType == int(PUNISHMENT_BAN))
				{
					KickClient(client, "[%s] You are banned!\n \nReason:         %s\nAdmin:          %s\nLength:         %s\n \nAppeal your ban over at %s\n or purchase an unban at %s",
						COMMUNITY_NAME, szReason, szAdminName, szTime, SITEURL, STOREURL);
				}
				else if(iExpires > GetTime() && iType == int(PUNISHMENT_MUTE))
				{
					usr.Punish("mute", iExpires-GetTime(), szReason);
				}
				else if(iExpires > GetTime() && iType == int(PUNISHMENT_GAG))
				{
					usr.Punish("gag", iExpires-GetTime(), szReason);
				}
				else if(iExpires > GetTime() && iType == int(PUNISHMENT_SILENCE))
				{
					usr.Punish("silence", iExpires-GetTime(), szReason);
				}
			}
		}
		return;
	}
	//else PrintToChat(client, "%s No Punishments Found!", PREFIX);
}

public int SQL_GetUserInfo_Callback(Database db, DBResultSet results, const char[] szError, int userid)
{
	int client = GetClientOfUserId(userid); if(client == 0) return;
	
	if(db == null || results == null)
	{
		//LogError("[SQL] Select Query failure: %s", szError);
		return;
	}
	else if (results.RowCount == 0)
	{
		//PrintToChat(client, "%s Rows: 0", PREFIX);
		if(IsValidClient(client))
		{
			SQL_AddUser(client);
			//PrintToChat(client, "%s Inserting User..", PREFIX);
			return;
		}
	}
	else if (results.RowCount == 1)
	{
		//PrintToChat(client, "%s Rows: 1", PREFIX);
		if(IsValidClient(client))
		{
			if(IsValidClient(client))
			{
				int key;
				results.FieldNameToNum("unique_key", key);
				
				if(results.FetchRow())
				{
					char szKey[64];
					
					results.FetchString(key, szKey, sizeof(szKey));
					//LogError("Key: \x0F%s", szKey);
				}
			}
		}
	}
}

public int SQL_GetAdminPerms_Callback(Database db, DBResultSet results, const char[] szError, int userid)
{
	int client = GetClientOfUserId(userid); if(client == 0) return;
	
	if(db == null || results == null)
	{
		LogError("[SQL] Select Query failure: %s", szError);
		return;
	}
	else if (results.RowCount == 0)
	{
		return;
	}
	else if (results.RowCount == 1)
	{
		
		//PrintToChat(client, "%s Rows: 1", PREFIX);
		if(IsValidClient(client))
		{
			int groupname, flags, groupid, tag;
		
			results.FieldNameToNum("groupname", groupname);
			results.FieldNameToNum("flags", flags);
			results.FieldNameToNum("group_id", groupid);
			results.FieldNameToNum("tag", tag);
			
			if(results.FetchRow())
			{
				char sGroupName[64], sFlags[16], sTag[64];
				results.FetchString(groupname, sGroupName, sizeof(sGroupName));
				results.FetchString(flags, sFlags, sizeof(sFlags));
				results.FetchString(tag, sTag, sizeof(sTag));
				
				//PrintToChat(client, "%s OK nice, you are an actual admin", PREFIX);
				//PrintToChat(client, "==============================");
				PrintToChat(client, "%s Admin Rank: \x0F%s", PREFIX, sGroupName);
				PrintToChat(client, "%s Flags: \x04%s", PREFIX, sFlags);
				//PrintToChat(client, "%s Tag: \x0B%s", PREFIX, sTag);
				CS_SetClientClanTag(client, sTag);
				
				TrimString(sFlags);
				GiveAdmin(client, sFlags);
			}
		}
	}
}

public int SQL_AddUser_Callback(Database db, DBResultSet results, const char[] szError, int userid)
{
	int client = GetClientOfUserId(userid); if(client == 0) return;
	
	if(db == null || results == null)
	{
		//LogError("[SQL] Select Query failure: %s", szError);
		return;
	}
}

public int SQL_UpdateUser_Callback(Database db, DBResultSet results, const char[] szError, int userid)
{
	int client = GetClientOfUserId(userid); if(client == 0) return;
	
	if(db == null || results == null)
	{
		LogError("[SQL] Select Query failure: %s", szError);
		return;
	}
}

public int SQL_AddPunishment_Callback(Database db, DBResultSet results, const char[] szError, any data)
{
	//pack.Reset();
	//int client 				= GetClientOfUserId(pack.ReadCell());
	//int iType	 			= pack.ReadCell();
	//int iLength	 			= pack.ReadCell();
	
	//char szReason[256];	
	//pack.ReadString(szReason, sizeof(szReason));
	
	if(db == null || results == null)
	{
		//LogError("[SQL] Insert Query failure: %s", szError);
		//CloseHandle(pack);
		return;
	}
	else
	{
		
	}
	//CloseHandle(pack);
	//return
}
/* NO MORE CALLBACKS */
