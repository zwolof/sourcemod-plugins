
#include <discord>
int g_iJoinTime[MAXPLAYERS+1];

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
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(IsValidClient(client)) {
        if(CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC, true)) {

            int time = GetTime()-g_iJoinTime[client];
            int hours = time / 3600; time %= 3600;
            int minutes = time / 60; time %= 60;

            char sPlayTime[128];
            if(hours >= 1)  FormatEx(sPlayTime, sizeof(sPlayTime), "%d hours, %d minutes and %d seconds", hours, minutes, time);
            else if(minutes >= 1)  FormatEx(sPlayTime, sizeof(sPlayTime), "%d minutes and %d seconds", minutes, time);
            else FormatEx(sPlayTime, sizeof(sPlayTime), "%d seconds", time);

            ConVar hServer = FindConVar("hostname");
            char sHostname[64], szName[256], szSteamId[64];
            GetClientName(client, szName, sizeof(szName));
            GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof(szSteamId));
            hServer.GetString(sHostname, sizeof(sHostname));

            // Logging
            DiscordWebHook banWH = new DiscordWebHook("webhook goes here");
            banWH.SlackMode = true;

            banWH.SetUsername("[Shield] Admin Sessions");
            MessageEmbed Embed = new MessageEmbed();
            Embed.SetTitle("Admin Sessions");
            Embed.SetColor("#ff0000");
            Embed.AddField("Admin:", szName, true);
            Embed.AddField("SteamID:", szSteamId, true);
            Embed.AddField("Playtime:", sPlayTime, false);
            Embed.AddField("Server:", sHostname, false);
            
            banWH.Embed(Embed);
            banWH.Send();
            delete banWH;

        }
    }
}

public void OnClientPostAdminCheck(int client) {
	if(IsValidClient(client)) {
		g_iJoinTime[client] = GetTime();
	}
}

stock bool IsValidClient(int client) {
	return (1 <= client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client) && IsClientConnected(client));
}