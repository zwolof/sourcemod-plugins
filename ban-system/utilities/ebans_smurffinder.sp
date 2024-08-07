Database g_Database 	= null;
#define SQL_CONNECTION "ebans"

native void EB_BanKickSmurfAccount(int client, char[] sReason);
#define QUERY "SELECT DISTINCT playerid, ip, authid FROM `ebans_users` WHERE ip = '%s' ORDER BY playerid DESC;"

public Plugin myinfo = {
    name = "EFRAG [Smurf Finder]",
    author = "zwolof",
    description = "Checks for Smurf Account",
    version = "1.0.6",
    url = "www.efrag-community.com"
};

public void OnPluginStart() {
	Database.Connect(SQL_ConnectCallback, SQL_CONNECTION);
}

public void SQL_ConnectCallback(Database db, const char[] error, any data) {
	if(db == null) {
        SetFailState("Unable to connect to "...SQL_CONNECTION);
    }
	g_Database = db;
}

public void OnClientPostAdminCheck(int client) {
	if(!IsFakeClient(client)) {
		char szQuery[1024], sIPAddr[128]; 
        GetClientIP(client, sIPAddr, sizeof(sIPAddr));

        // Database Query + Format
		g_Database.Format(szQuery, sizeof(szQuery), QUERY, SQL_CONNECTION, SQL_CONNECTION, sIPAddr);
		g_Database.Query(SQL_CheckSmurf_Callback, szQuery, GetClientUserId(client));
	}
}

public int SQL_CheckSmurf_Callback(Database db, DBResultSet results, const char[] szError, int userid) {
	int client = GetClientOfUserId(userid); if(client == 0) return;

    char szSteamId[64];
    GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof(szSteamId));

	if(db == null || results == null) {
		LogError("[SQL] Check Query failure: %s", szError);
	}
	else if(results.RowCount >= 1) {
		if((1 <= client <= MaxClients) && IsClientInGame(client) && !IsFakeClient(client)) {
			while(results.FetchRow()) {
                EB_BanEvadingPlayer(client);
                LogMessage("RowCount: %d / Name: %N", results.RowCount, client);
                return;
			}
		}
	}
}