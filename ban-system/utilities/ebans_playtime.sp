#include <cstrike>

Database g_Database 	= null;
#define SQL_CONNECTION 	"ebans"
#define PREFIX " \x01\x04\x01[\x06☰  FRAG\x01] "

enum Teams { Team_CT = 0, Team_TT, Team_SPEC }

int g_iPlayTime[MAXPLAYERS+1][Teams];
int g_iServerId;
Handle g_hPlayTimeTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
public Plugin myinfo = {
	name = "efrag.gg | Playtime Tracker",
	author = "zwolof",
	description = "Stores player playtime in a database.",
	version = "1.0.0",
	url = "www.efrag.gg"
};

public void OnPluginStart() {
	Database.Connect(SQL_ConnectCallback, SQL_CONNECTION);
	
	// Commands
	RegConsoleCmd("sm_time", Command_Timeplayed);
	RegConsoleCmd("sm_played", Command_Timeplayed);
	//RegConsoleCmd("sm_timeplayed", Command_Timeplayed);
	
	// Event Hooks
	HookEvent("player_disconnect", Event_OnPlayerDisconnect, EventHookMode_Pre);
	
	for(int i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			OnClientPutInServer(i);
		}
	}
}

public Action Command_Timeplayed(int client, int args) {
	if(args > 1) return Plugin_Handled;
	int time = g_iPlayTime[client][Team_CT] + g_iPlayTime[client][Team_TT] + g_iPlayTime[client][Team_SPEC];

	int minutes = RoundToFloor(time / 60);
	time %= 60;
	
	PrintToChat(client, "%s \x08You have played for \x10%d minutes\x08 and \x10%d seconds\x08!", PREFIX, minutes, time);
	return Plugin_Handled;
}

public Action PlayTimeTimer(Handle timer, any data)
{
	int client = data; 
	if(!IsValidClient(client)) return Plugin_Handled;
	
	if(IsValidClient(client)) {
		int iTeam = GetClientTeam(client);
		
		if(iTeam == CS_TEAM_T) {
			g_iPlayTime[client][0]++;
		}
		else if(iTeam == CS_TEAM_CT) {
			g_iPlayTime[client][1]++;
		}
		else g_iPlayTime[client][2]++;
	}
	return Plugin_Handled;
}

public void OnPluginEnd() {
	for(int i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			ResetTimer(i);
			SQL_UpdatePlayTime(i);
		}
	}
}

void ResetTimer(int i) {
	//for(int i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			if (g_hPlayTimeTimer[i] != INVALID_HANDLE) {
				CloseHandle(g_hPlayTimeTimer[i]);
				g_hPlayTimeTimer[i] = INVALID_HANDLE;
			}
		}
	//}
}

public void OnMapEnd() {
	for(int i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			ResetTimer(i);
			SQL_UpdatePlayTime(i);
		}
	}
}

public void Event_OnPlayerDisconnect(Event event, const char[] sName, bool bDontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid")); 
	if(IsValidClient(client)) {
		SQL_UpdatePlayTime(client);
	}
}

public void SQL_ConnectCallback(Database db, const char[] error, any data) {
	if(db == null) {
		LogError("T_Connect returned invalid Database Handle");
		return;
	}
	g_Database = db;
	SQL_GetServerId();
}

public void OnClientPutInServer(int client)
{
	if(IsValidClient(client)) {
		// Reset integer values
		g_iPlayTime[client][Team_CT] 	= 0;
		g_iPlayTime[client][Team_TT] 	= 0;
		g_iPlayTime[client][Team_SPEC] 	= 0;
		
		// Fetch their data from database
		SQL_GetPlayTime(client);
		if(g_hPlayTimeTimer[client] == INVALID_HANDLE) {
			g_hPlayTimeTimer[client] = CreateTimer(1.0, PlayTimeTimer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			//PrintToChatAll("started timer");
		}
	}
}

// =================== GET SERVER ID ===================

void SQL_GetPlayTime(int client) {
	char sQuery[512], sSteamId[64];
	GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));
		
	g_Database.Format(sQuery, sizeof(sQuery), "SELECT ct_time, tt_time, spec_time FROM `%s_users` WHERE authid='%s' LIMIT 1;", SQL_CONNECTION, sSteamId);
	g_Database.Query(SQL_GetPlayTime_Callback, sQuery, GetClientUserId(client));
}

public int SQL_GetPlayTime_Callback(Database db, DBResultSet results, const char[] szError, any data)
{
	int client = GetClientOfUserId(data);
	if(!IsValidClient(client)) return;
	
	if(db == null || results == null) {
		LogError("[SQL] Select Query failure: %s", szError);
	}
	else {
		int ct_time, tt_time, spec_time;	
		results.FieldNameToNum("ct_time", ct_time);
		results.FieldNameToNum("tt_time", tt_time);
		results.FieldNameToNum("spec_time", spec_time);
			
		if(results.FetchRow()) {
			g_iPlayTime[client][Team_CT] 	= results.FetchInt(ct_time);
			g_iPlayTime[client][Team_TT] 	= results.FetchInt(tt_time);
			g_iPlayTime[client][Team_SPEC] 	= results.FetchInt(spec_time);
		}
	}
}

void SQL_GetServerId() {
	ConVar hPort = FindConVar("hostport");
	int iPort = hPort.IntValue;
		
	char sIP[64], sQuery[512];
	ConVar hIP = FindConVar("ip");
	hIP.GetString(sIP, sizeof(sIP));
	
	g_Database.Format(sQuery, sizeof(sQuery), "SELECT server_id FROM `%s_servers` WHERE ip='%s' AND port = %d LIMIT 1;", SQL_CONNECTION, iPort, sIP);
	g_Database.Query(SQL_GetServerId_Callback, sQuery);
}

public int SQL_GetServerId_Callback(Database db, DBResultSet results, const char[] szError, any data)
{
	if(db == null || results == null) {
		LogError("[SQL] Select Query failure: %s", szError);
	}
	else {
		int server_id;	
		results.FieldNameToNum("server_id", server_id);
			
		if(results.FetchRow()) {
			g_iServerId = results.FetchInt(server_id);
		}
	}
}

// =================== UPDATE PLAYTIME ===================
void SQL_UpdatePlayTime(int client) {
	char sQuery[512], sSteamId[64];
	GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));
	g_Database.Format(sQuery, sizeof(sQuery), "UPDATE `%s_users` SET ct_time = %d, tt_time = %d, spec_time = %d WHERE authid = '%s';", SQL_CONNECTION, g_iPlayTime[client][Team_CT], g_iPlayTime[client][Team_TT], g_iPlayTime[client][Team_SPEC], sSteamId);
	
	g_Database.Query(SQL_UpdatePlayTime_Callback, sQuery, GetClientUserId(client));									  
}

public int SQL_UpdatePlayTime_Callback(Database db, DBResultSet results, const char[] szError, any data) {
	if(db == null || results == null) {
		LogError("[SQL] Select Query failure: %s", szError);
	}
}

stock bool IsValidClient(int client) {
	return view_as<bool>((0 < client <= MaxClients) && IsClientInGame(client) && !IsFakeClient(client));
}