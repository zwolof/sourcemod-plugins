#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <geoip>
#include <eranks>

int MIN_PLAYERS_FOR_RANKING_TO_WORK = 4;
int g_iOffset = -1;

public Plugin myinfo = {
    name = "EFRAG [Ranking]",
    author = "zwolof",
    description = "Full ranking system for eFrag.eu",
    version = "1.0",
    url = "www.efrag-community.com"
};

public void OnPluginStart()
{
	// HUD Text
	if(isValidRef(g_iHnsClientHud))
		AcceptEntityInput(g_iHnsClientHud, "Kill");
	
	// Connect to database
	Database.Connect(SQL_ConnectCallback, SQL_CONNECTION);
	
	// Commands
	RegConsoleCmd("sm_rank", Command_eRank);
	//RegConsoleCmd("sm_etest", Command_eTest);
	RegConsoleCmd("sm_top", Command_eTop);
	RegConsoleCmd("sm_ranks", Command_eRanks);
	
	RegConsoleCmd("sm_rs", Command_eResetScore);
	RegConsoleCmd("sm_resetscore", Command_eResetScore);
	RegConsoleCmd("sm_formatquery", Command_eTestQuery);

	//RegConsoleCmd("sm_testranking", Command_eTestRanking);
	//RegConsoleCmd("sm_connect", Command_eConnect);
    
	// Events
	HookEvent("player_disconnect", Event_OnPlayerDisconnect_Pre, EventHookMode_Pre);
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_Post);
	
	g_iOffset = FindSendPropInfo("CCSPlayerResource", "m_iCompetitiveRanking");

    // ConVar hHostname = FindConVar("hostname");
    // char sHost[128];
    // hHostname.GetString(sHost, sizeof(sHost));
    // if(StrContains(sHost, "retake", false) != -1) {
    //     FormatEx(SERVER, sizeof(SERVER), "retakes");
    // }
    // else if(StrContains(sHost, "competi", false) != -1) {
    //     FormatEx(SERVER, sizeof(SERVER), "competitive");
    // }
    // else if(StrContains(sHost, "hns", false) != -1) {
    //     FormatEx(SERVER, sizeof(SERVER), "hnspre");
    //     FormatEx(SERVER, sizeof(SERVER), "hnspre");
    // }

    FormatEx(SERVER, sizeof(SERVER), "awpwars");
}

public void OnMapStart() {
	SDKHook(GetPlayerResourceEntity(), SDKHook_ThinkPost, OnThinkPost);
}

public void OnPluginEnd() {
	if(isValidRef(g_iHnsClientHud)) {
        AcceptEntityInput(g_iHnsClientHud, "Kill");
    }
}

public Action Command_eResetScore(int client, int iArgs)
{
	if(IsValidClient(client))
	{
		SetEntProp(client, Prop_Data, "m_iFrags", 0);
		SetEntProp(client, Prop_Data, "m_iDeaths", 0);
		
		CS_SetMVPCount(client, 0);
		CS_SetClientAssists(client, 0);
		CS_SetClientContributionScore(client, 0);
		
		PrintToChat(client, "%s Your score has been reset!", PREFIX);
	}
	return Plugin_Handled;
}

public Action Command_eTestQuery(int client, int iArgs)
{
    char szQuery[512];
	FormatUpdateQuery(client, szQuery, sizeof(szQuery));
    PrintToConsoleAll(szQuery);
    return Plugin_Handled;
}

public Action Command_eRanks(int client, int iArgs)
{
	if(iArgs > 1) return Plugin_Handled;
	
	if(IsValidClient(client))
	{
		CreateRanksMenu(client, 0);
	}
	return Plugin_Handled;
}

public Action Event_OnPlayerDisconnect_Pre(Handle hEvent, const char[] szName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	// Is the leaving client valid? Update their stats
	if(IsValidClient(client))
	{
        if(g_Session[client].stats[Stats_Points] < 0) {
            g_Session[client].stats[Stats_Points] *= -1
        }
        SQL_UpdateStats(client);
    }
	return Plugin_Continue;	
}

public Action Event_OnRoundEnd(Handle hEvent, const char[] szName, bool bDontBroadcast)
{
	int iWinner = GetEventInt(hEvent, "winner");

    // Is it a valid roundend? Did CT or T win?
    if(__GetTotalPlayers() >= MIN_PLAYERS_FOR_RANKING_TO_WORK)
    {
        // Loop all clients
        for(int i = 1; i <= MaxClients; i++)
        {
            if((0 < i <= MaxClients) && IsClientInGame(i) && !IsFakeClient(i))
            {
                // Is the client valid and are they in the winners team?
                if(GetClientTeam(i) == iWinner)
                {
                    // Increment points by 5 for round win!
                    PrintToChat(i, "%s \x08You got \x10+3 points\x08 for winning the round!", PREFIX);
                    g_Session[i].AddPoints(3);
                    
                    // Increment round wins
                    g_Session[i].stats[Stats_Roundswon]++;
                }
                else {
                    if(GetClientTeam(i) != CS_TEAM_SPECTATOR) {
                        PrintToChat(i, "%s \x08You lost \x102 points\x08 for losing the round!", PREFIX);
                        g_Session[i].RemovePoints(2);
                    }
                }
                
                // if(GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_T) {
                    //PrintToChat(i, "%s \x08You have \x10%d\x08 points! [\x10%d\x08 kills | \x10%d\x08 deaths]",
                    //PREFIX, g_Rank[i].stats[Stats_Points], g_Rank[i].stats[Stats_Kills], g_Rank[i].stats[Stats_Deaths]);

                    //PrintToChat(i, "%s \x08Current rank: \x10%s\x08", PREFIX, g_sRanks[g_Rank[i].stats[Stats_Rank]][0]);
                //}
                //g_iLastPoints[i] = g_Session[i].iPoints;
            }
        }
    }
    return Plugin_Continue;
}

public Action Event_OnPlayerDeath(Handle hEvent, const char[] szName, bool bDontBroadcast)
{
	// Initialize variables
	int ATTACKER 	= GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	int VICTIM 		= GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int ASSISTER	= GetClientOfUserId(GetEventInt(hEvent, "assister"));
	//int iWeapon 	= GetEntPropEnt(ATTACKER, Prop_Data, "m_hActiveWeapon");
	
	// Is it a headshot?
	bool bHeadshot 	= GetEventBool(hEvent, "headshot");
	
	// Get The weapon name
	char sWeapon[16];
	GetEventString(hEvent, "weapon", sWeapon, sizeof(sWeapon));

	// Get points before doing anything
	int points = g_Session[ATTACKER].stats[Stats_Points];
	
	if(__GetTotalPlayers() >= MIN_PLAYERS_FOR_RANKING_TO_WORK) {
		if(IsValidClient(VICTIM) && IsValidClient(ATTACKER)) {
			char sWeapon[32];
			GetClientWeapon(ATTACKER, sWeapon, sizeof(sWeapon));
			
			// Make sure attacker != victim, so they dont kill themselves
			if(ATTACKER != VICTIM) {
				g_Session[ATTACKER].stats[Stats_Kills]++;
				g_Session[VICTIM].stats[Stats_Deaths]++;
				/////////////////////////////////////////////////////////
				
				// Increment Headshots
				if(bHeadshot) g_Session[ATTACKER].stats[Stats_Headshot]++;
				
				// Is the assister valid?
				if(ASSISTER && IsValidClient(ASSISTER))
				{
					// Increment Assists
					//g_Rank[ATTACKER].iAssists++;
					g_Session[ASSISTER].stats[Stats_Assists]++;
					
					// Give assister points
					g_Session[ASSISTER].AddPoints(1);
					PrintToChat(ASSISTER, "%s \x08You got \x10+1 point\x08 for \x0Fassist\x08.", PREFIX);
				}
				
				// Print message to attacker, 
				if(StrEqual(sWeapon, "weapon_awp", true) && !GetEntProp(ATTACKER, Prop_Send, "m_bIsScoped") || StrEqual(sWeapon, "weapon_ssg08", true) && !GetEntProp(ATTACKER, Prop_Send, "m_bIsScoped")) {
					g_Session[ATTACKER].AddPoints(bHeadshot ? 4 : 3);
					PrintToChat(ATTACKER, "%s \x08You got \x10+%d points\x08 for killing \x03%N\x08 with a noscope%s.", PREFIX, bHeadshot ? 4: 3, VICTIM, bHeadshot ? " headshot" : "");
				}
				else {
                    int pointsForKill = bHeadshot ? 3 : 2;
					g_Session[ATTACKER].AddPoints(pointsForKill);
					PrintToChat(ATTACKER, "%s \x08You got \x10+%d points\x08 for killing \x03%N\x08%s.", PREFIX, pointsForKill, VICTIM, bHeadshot ? " with a headshot" : "");
				}
				g_Session[VICTIM].RemovePoints(2);
				PrintToChat(VICTIM, "%s \x08You lost \x102 point\x08 for \x0Fdying\x08.", PREFIX);
			}

			//if(g_bUserHasBeenLoaded[ATTACKER] && g_bUserHasBeenLoaded[VICTIM])
			//{
            //    SQL_UpdateStats(ATTACKER);
            //    SQL_UpdateStats(VICTIM);
			//}
			
			// Check if the client has ranked up or down
			CheckRank(ATTACKER);
			CheckRank(VICTIM);
		}
	}
	return Plugin_Continue;	
}

// When client is put into the server, aka joins
public void OnClientPutInServer(int client)
{
	if(IsValidClient(client))
	{
		// Reset variables to 0
		g_Rank[client].id = client;
        g_Session[client].id = client;
        g_Session[client].Reset();
		
		// Create Timer to fetch data after 5.0s
        //PrintToChat(client, PREFIX..."\x08Loading your rank..");
		RequestFrame(GetStats_Callback, GetClientUserId(client));
	}
}

// Timer Fetch userinfo
public void GetStats_Callback(any data)
{
    int client = GetClientOfUserId(data);
    // Is the client valid?
	if(IsValidClient(client)) {
		SQL_FetchUserData(client);
	}
}

public Action Command_eTest(int client, int iArgs)
{
	if(iArgs > 0) return Plugin_Handled;
	
	int iTest = 322359;
	int iLast = iTest % 10;
	
	if(IsValidClient(client)) {
        PrintToChat(client, "%s \x10%d", PREFIX, iLast);
    }
	return Plugin_Handled;
}

public Action Command_eRank(int client, int iArgs)
{
	if(iArgs > 0) return Plugin_Handled;
	
	if(IsValidClient(client)) {
		SQL_GetRank(client);
        //PrintToChat(client, "g_Session[client].stats[Stats_Rank] == %d", g_Session[client].stats[Stats_Rank]);
	}
	return Plugin_Handled;
}

int __GetTotalPlayers() {
	int players = 0;
	for(int p = 1; p <= MaxClients; p++) {
		if(IsValidClient(p)) {
			players++;
		}
	}
	return players;
}

public void OnThinkPost(int iEnt)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && 0 < i <= MaxClients && !IsFakeClient(i))
		{   
			SetEntData(iEnt, g_iOffset+(i*4), g_Session[i].stats[Stats_Rank]+1);
		}
	}
}

public void OnPlayerRunCmdPost(int client, int iButtons)
{
	static int iOldButtons[MAXPLAYERS+1];

	if(iButtons & IN_SCORE && !(iOldButtons[client] & IN_SCORE))
	{
		StartMessageOne("ServerRankRevealAll", client, USERMSG_BLOCKHOOKS);
		EndMessage();
	}
	iOldButtons[client] = iButtons;
}