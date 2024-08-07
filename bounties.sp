#include <sourcemod>
#include <cstrike>
#include <efrag>

enum struct Bounty {
    int target;
	int amount;
}
Bounty g_bounty;

public Plugin myinfo =
{ 
	name	= "efrag.gg [Anti Camp]",
	author	= "zwolof",
	version	= "1.0",
	url		= "www.efrag.eu"
};

public void OnPluginStart() {
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("round_start", EventRoundStart, EventHookMode_Post);
}

void Bounty_ResetBounty() {
    g_bounty.target = GetRandomPlayer(CS_TEAM_T);
    g_bounty.amount = GetRandomInt(20, 100);

    if(IsValidClient(g_bounty.target)) {
		efrag_PrintToChat("\x08Bounty for \x0F%N\x08 has been set to \x10%d\x08 credits!", g_bounty.target, g_bounty.amount);
	}
}

public Action EventRoundStart(Handle hEvent, const char[] szName, bool bDontBroadcast) {
	Bounty_ResetBounty();
	return Plugin_Continue;
}

public Action EventPlayerDeath(Handle hEvent, const char[] szName, bool bDontBroadcast) {
	int victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));

	if(IsValidKill(victim, attacker)) {
        if(victim == g_bounty.target) {
			char sSteamId[64];
			GetClientAuthId(attacker, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

			efrag_AddPlayerCredits(sSteamId, g_bounty.amount);
			efrag_PrintToChat(attacker, "\x08You received \x0F%d\x08 credits for killing \x03%N\x08!", g_bounty.amount, g_bounty.target);
        }
	}
	return Plugin_Continue;	
}


public void OnClientDisconnect(int client) {
	if(client == g_bounty.target) {
		efrag_PrintToChatAll("\x08Bounty Target has \x04left\x08 the game, choosing a new player..");

        Bounty_ResetBounty();
	}
}

stock bool IsValidClient(int client) {
	return ((1 <= client <= MaxClients) && IsClientInGame(client) && !IsFakeClient(client));
}

stock bool IsValidKill(int iVictim, int iAttacker) {
	return (iVictim != 0 && iAttacker != 0 && iVictim != iAttacker && iVictim <= MaxClients && iAttacker <= MaxClients && GetClientTeam(iVictim) != GetClientTeam(iAttacker));
}

stock int GetRandomPlayer(int iTeam) {
	new players[MaxClients+1], clientCount;
		
	for(int i = 1; i <= MaxClients; i++) {
        if(IsValidClient(i) && GetClientTeam(i)==iTeam) {
            players[clientCount++] = i;
        } 
    }
	return (clientCount == 0) ? -1 : players[GetRandomInt(0, clientCount-1)];
}
