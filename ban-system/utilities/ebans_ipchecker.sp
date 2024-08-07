Database g_Database 	= null;
#define SQL_CONNECTION "ebans"

native void EB_BanEvadingPlayer(int client);
#define QUERY \
        "SELECT DISTINCT u.ip, \
        p.type, \
        p.expires_on, \
        u.authid, \
        p.steamid FROM `%s_users` u \
        INNER JOIN `%s_punishments` p ON \
        p.steamid=u.authid WHERE p.type = 0 \
        AND u.ip='%s' AND p.expires_on=p.expires_on AND p.unbanned != 1;"

#define NEWQUERY "SELECT * FROM ebans_punishments WHERE steamid IN(\
                SELECT authid FROM ebans_users WHERE ip = (\
                SELECT ip FROM ebans_users where authid = '%s' LIMIT 1))\
                AND type = 0"


public Plugin myinfo = {
    name = "EFRAG [Evasion Checker]",
    author = "zwolof",
    description = "Checks for Ban Evasions",
    version = "1.0.6",
    url = "www.efrag-community.com"
};

public void OnPluginStart() {
	Database.Connect(SQL_ConnectCallback, SQL_CONNECTION);
}

public void SQL_ConnectCallback(Database db, const char[] error, any data) {
	if(db == null) SetFailState("Unable to connect to "...SQL_CONNECTION);
	g_Database = db;
}
// SELECT DISTINCT u.ip, p.type, p.expires_on, p.banned_on, \
// u.authid, p.steamid FROM `ebans_users` u INNER JOIN \
// `ebans_punishments` p ON p.steamid=u.authid WHERE p.type = 0 AND u.ip = "77.123.105.199"

public void OnClientPostAdminCheck(int client) {
	if(!IsFakeClient(client)) {
		char szQuery[1024], sIPAddr[128]; GetClientIP(client, sIPAddr, sizeof(sIPAddr));
		g_Database.Format(szQuery, sizeof(szQuery), QUERY, SQL_CONNECTION, SQL_CONNECTION, sIPAddr);

		g_Database.Query(SQL_CheckIPAddr_Callback, szQuery, GetClientUserId(client));
	}
}

public int SQL_CheckIPAddr_Callback(Database db, DBResultSet results, const char[] szError, int userid) {
	int client = GetClientOfUserId(userid); if(client == 0) return;
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