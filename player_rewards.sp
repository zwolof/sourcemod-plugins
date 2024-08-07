#include <sourcemod>
#include <efrag>

#define PREFIX                          " \x01\x04\x01[\x0Fefrag.gg\x01] "
#define COMMUNITY_NAME                  "efrag.gg"
#define TIME_FOR_REWARD                 5*60.0

Database g_Database = null;

native bool efrag_IsSteamGroupMember(int client);

public Plugin myinfo =
{
	name = "efrag.gg | Member Rewards",
	author = "zwolof",
	description = "Rewards community advertisements.",
	version = "1.0.0",
	url = "/id/zwolof"
};

public void OnPluginStart() {
    Database.Connect(Database_ConnectCallback, "ebans");
}

public void OnClientConnected(int client) {
    if(client > 0 && !IsFakeClient(client) && IsClientConnected(client)) {
        CreateTimer(TIME_FOR_REWARD, Task_CheckClientAndGiveReward, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        PrintToServer("[ERewards] Created timer for [%N]", client);
    }
}

public Action Task_CheckClientAndGiveReward(Handle timer, any data) {
    int userid = data;
    int client = GetClientOfUserId(userid);

    char name[128], sSteamId[64];
    GetClientName(client, name, sizeof(name));
	GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

    // Check if name contains efrag.gg
	int credits = 0;
    if(StrContains(name, "efrag.gg", false) != -1) {
		credits += 15;
    }

    // Check if theyre a member of the efrag steam group(native)
    if(efrag_IsSteamGroupMember(client)) {
		credits += 10;
    }

    if(efrag_IsPlayerVerified(sSteamId)) {
		credits += 10;
    }
	Database_GiveUserReward(userid, credits);

    return Plugin_Continue;
}

public void Database_ConnectCallback(Database db, const char[] error, any data) {
    if(error[0] != '\0') {
        SetFailState("Database Could not connect: %s", error);
        return;
    }
    g_Database = db;
    g_Database.SetCharset("utf8mb4");
}

void Database_GiveUserReward(int userid, int amount = 15) {
    char query[512], steamid[64];
	int client = GetClientOfUserId(userid);
	if(!(0 < client <= MaxClients)) {
		return;
	}

    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
    
    g_Database.Format(query, sizeof(query), "UPDATE ebans_users SET credits = credits + %d WHERE authid = '%s';", amount, steamid);

    DataPack pack = new DataPack();
    pack.WriteCell(userid);
    pack.WriteCell(amount);

    g_Database.Query(Database_RewardCallback, query, pack);
    PrintToServer("[ERewards] Sent Query");
}

void Database_RewardCallback(Database db, DBResultSet results, const char[] error, DataPack pack) {
    if(db == null || results == null || error[0] != '\0') {
        LogError("[REWARDS] Query failed: %s", error);
        return;
    }

    pack.Reset();
    int userid = pack.ReadCell();
    int amount = pack.ReadCell();

    delete pack;

    // PrintToServer("[ERewards] Sending Chat Message");
    int client = GetClientOfUserId(userid);
    if(client > 0 && !IsFakeClient(client) && IsClientConnected(client)) {
        efrag_PrintToChat(client, "\x08You have received \x0F%d\x08 fragments as a reward.", amount);
    }
}