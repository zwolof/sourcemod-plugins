void Database_OnPluginStart() {
    Database.Connect(SQL_ConnectDatabase, "ebans");
}
 
public void SQL_ConnectDatabase(Database db, const char[] error, any data) {
    if(db == null) {
        LogMessage("Database failure: %s", error);
        return;
    } 
    g_Database = db;
    SQL_GetMaplist();
}

void SQL_GetServerId() {
    
}

bool SQL_GetMaplist() {
	ConVar hPort = FindConVar("hostport");
    ConVar hIP = FindConVar("ip");
    int iPort = hPort.IntValue;
    
    // Get IP
    char sIP[64];		
    hIP.GetString(sIP, sizeof(sIP));
    
    char query[1024];
    g_Database.Format(query, sizeof(query), "SELECT id, filename, cleanname FROM `efrag_mapchooser_maplist` WHERE server_id = (SELECT server_id from ebans_servers_new WHERE ip='%s' AND port=%d) ORDER BY cleanname ASC;", sIP, iPort);
    g_Database.Query(SQL_GetMaplist_Callback, query);
}

void SQL_InsertRecentlyPlayed() {

	int server_id = efrag_GetServerId();

	char sMap[128];
	GetCurrentMap(sMap, sizeof(sMap));

	char query[1024];
	g_Database.Format(query, sizeof(query), "INSERT INTO `efrag_mapchooser_recently_played` (map_id, server_id) VALUES((SELECT id from `efrag_mapchooser_maplist` WHERE filename='%s' LIMIT 1), %d);", sMap, server_id);
	g_Database.Query(SQL_InsertRecentlyPlayed_Callback, query);
}

void SQL_GetRecentlyPlayed(int count = 5) {
    char query[1024];

	int server_id = efrag_GetServerId();
    
    g_Database.Format(query, sizeof(query), "SELECT mlist.filename, mlist.id FROM `efrag_mapchooser_maplist` mlist RIGHT JOIN `efrag_mapchooser_recently_played` rp ON mlist.id = rp.mapid WHERE rp.serverid = %d ORDER BY mlist.id ASC LIMIT %d;", server_id, count);
    g_Database.Query(SQL_GetRecentlyPlayed_Callback, query);
}

void SQL_GetRecentlyPlayed_Callback(Database db, DBResultSet results, const char[] error, any data) {
    if(db == null || results == null) {
		return;
	}
	else if (results.RowCount > 0) {

        int fields[2];
        results.FieldNameToNum("id", fields[0]);
        results.FieldNameToNum("filename", fields[1]);

        while(results.FetchRow()) {
            RecentlyPlayed played;
            results.FetchString(fields[1], played.filename, sizeof(RecentlyPlayed::filename));
            played.id = results.FetchInt(fields[0]);

            g_alRecentlyPlayed.PushArray(played, sizeof(RecentlyPlayed));
        }
    }
}

void SQL_InsertRecentlyPlayed_Callback(Database db, DBResultSet results, const char[] error, any data) {
	if(db == null || results == null || error[0] == '\0') {
		return;
	}
}

void SQL_GetMaplist_Callback(Database db, DBResultSet results, const char[] error, any data) {
    if(db == null || results == null) {
		return;
	}
	else if (results.RowCount > 0)
	{
        int fields[3];
        results.FieldNameToNum("id", fields[0]);
        results.FieldNameToNum("filename", fields[1]);
        results.FieldNameToNum("cleanname", fields[2]);
        
		g_alMaps.Clear();

        while(results.FetchRow()) {

            SMap map;
            map.id = results.FetchInt(fields[0]);
            results.FetchString(fields[1], map.filename, sizeof(SMap::filename));
            results.FetchString(fields[2], map.cleanname, sizeof(SMap::cleanname));

            g_alMaps.PushArray(map, sizeof(SMap));
        }
        MC_ShuffleMaps();
		MC_CreateMaplistMenu();
		// ChatAll("Loaded %d maps from database.", g_alMaps.Length);
	}
}