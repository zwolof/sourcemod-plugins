
#include <discord>
#include <efrag>
int g_iJoinTime[MAXPLAYERS+1];

#define DISCORD_WEBOOK_URL "discord webhook goes here"

public Plugin myinfo = {
    name = "efrag.gg | Admin Sessions",
    author = "zwolof",
    description = "Logs Admin Sessions",
    version = "1.0.0",
    url = "www.efrag.gg"
};

public void OnPluginStart() {
	HookEvent("player_disconnect", Event_OnPlayerDisconnect, EventHookMode_Post);

    for(int i = 1; i <= MaxClients; i++) {
        if(IsValidClient(i)) {
            OnClientPostAdminCheck(i);
        }
    }
}

public void Event_OnPlayerDisconnect(Event event, const char[] sName, bool bDontBroadcast) {
    InsertConnection(GetClientOfUserId(event.GetInt("userid")));
}

stock void InsertConnection(int client) {
	if(IsValidClient(client)) {
		char szSteamId[64];
		GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof(szSteamId));

		char sMap[128];
		GetCurrentMap(sMap, sizeof(sMap));

		ConVar hPort = FindConVar("hostport");
		ConVar hIP = FindConVar("ip");
		int iPort = hPort.IntValue;
		
        // Get IP
        char sIP[64];
        hIP.GetString(sIP, sizeof(sIP));

		int port = GetConVar("hostport").IntValue;
		int playerId = efrag_GetPlayerId(szSteamId);
		int serverId = efrag_GetServerId(sIP, iPort);

		char query[512];
		g_Database.Format(query, sizeof(query), "INSERT INTO ebans_connection_logs(server_id, user_id, ip, map, join_time, leave_time) VALUES(%i, %i, '%s', %i, %i)", serverId, playerId, sIP, sMap, g_iJoinTime[client], GetTime());
		g_Database.Query(SQL_InsertConnection_Callback, szQuery);
    }
}

stock void SendConnectionToDiscord(int client) {
	if(IsValidClient(client)) {
		char sHostname[64]
		ConVar hServer = FindConVar("hostname");
		hServer.GetString(sHostname, sizeof(sHostname));

		char szName[256], szSteamId[64];
		GetClientName(client, szName, sizeof(szName));
		GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof(szSteamId));

		int time = GetTime()-g_iJoinTime[client];
		int hours = time / 3600; time %= 3600;
		int minutes = time / 60; time %= 60;

		char sPlayTime[128];
		if(hours >= 1)  FormatEx(sPlayTime, sizeof(sPlayTime), "%d hours, %d minutes and %d seconds", hours, minutes, time);
		else if(minutes >= 1)  FormatEx(sPlayTime, sizeof(sPlayTime), "%d minutes and %d seconds", minutes, time);
		else FormatEx(sPlayTime, sizeof(sPlayTime), "%d seconds", time);

		
		DiscordWebHook connectionWebhook = new DiscordWebHook(DISCORD_WEBOOK_URL);
		connectionWebhook.SlackMode = true;
		
		connectionWebhook.SetUsername("[Shield] Player Sessions");
		MessageEmbed Embed = new MessageEmbed();
		Embed.SetTitle("Player Sessions");
		Embed.SetColor("#ff0000");
		Embed.AddField("Playtime:", sPlayTime, false);
		Embed.AddField("Server:", sHostname, false);
		
		connectionWebhook.Embed(Embed);
		connectionWebhook.Send();

		delete connectionWebhook;
	}
}

stock bool FormatTimeAsReadableString(int time, char[] szBuffer, int iBufferSize) {
	int hours = time / 3600; time %= 3600;
	int minutes = time / 60; time %= 60;
	int seconds = time;
	if(hours >= 1) FormatEx(szBuffer, iBufferSize, "%d hours, %d minutes and %d seconds", hours, minutes, seconds);
	else if(minutes >= 1)  FormatEx(szBuffer, iBufferSize, "%d minutes and %d seconds", minutes, seconds);
	else FormatEx(szBuffer, iBufferSize, "%d seconds", seconds);
}

public void OnClientPostAdminCheck(int client) {
	if(IsValidClient(client)) {
		g_iJoinTime[client] = GetTime();
	}
}

stock bool IsValidClient(int client) {
	return (1 <= client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client) && IsClientConnected(client));
}