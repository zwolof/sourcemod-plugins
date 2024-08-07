#include <sdkhooks>
#include <sdktools>
#include <SteamWorks>

int g_iOffset = -1;
int g_iRank[MAXPLAYERS+1] = {1548, ...};

public Plugin myinfo = 
{
	name = "Clans - Scoreboard",
	author = "zwolof",
	description = "Adds custom ranks to scoreboard.",
	version = "1.0",
	url = "www.efrag.eu"
};

enum ClanImages {
    ClanImages_FMUB = 1548,
    ClanImages_OWNER = 1538,
    ClanImages_VIP = 1537,
}

int g_iFMUBRank = 1548;

bool g_bIsFMUBMember[MAXPLAYERS+1] = {false, ...};
bool bHasCheckedFMUB[MAXPLAYERS+1] = {false, ...};

int g_iClanID = 35272217;

public void OnPluginStart() {
	g_iOffset = FindSendPropInfo("CCSPlayerResource", "m_iCompetitiveRanking");

    if(g_iOffset == -1) {
        SetFailState("Count not find offset for CCSPlayerResource::m_iCompetitiveRanking");
    }
    RegConsoleCmd("sm_setscoreboardoffset", Command_SetScoreboardOffset);
}

public void OnMapStart() {
    // AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup75373128318.svg");
    AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup1548.svg");
    AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup1538.svg");
    AddFileToDownloadsTable("materials/panorama/images/icons/skillgroups/skillgroup1537.svg");

	SDKHook(GetPlayerResourceEntity(), SDKHook_ThinkPost, OnThinkPost);
}

public Action Command_SetScoreboardOffset(int client, int args) {
    char sArg[16];
    GetCmdArg(1, sArg, sizeof(sArg));
    int number = StringToInt(sArg);
    // if(number) {
        PrintToChat(client, "Set Value to \x04%s", sArg);
        g_iRank[client] = number;
    // }
    return Plugin_Handled;
}

public void OnClientConnected(int client) {
    if((0 < client <= MaxClients) && !IsFakeClient(client) && IsClientInGame(client)) {
        SteamWorks_GetUserGroupStatus(client, g_iClanID);
    }
}

public void OnClientDisconnected(int client) {
    if((0 < client <= MaxClients) && !IsFakeClient(client) && IsClientInGame(client)) {
        g_iRank[client] = -1;
        g_bIsFMUBMember[client] = false;
    }
}

public void OnThinkPost(int iEnt) {
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && 0 < i <= MaxClients && !IsFakeClient(i)) {
            int offset = g_iOffset+(i*4);

            bool isRoot = (GetUserFlagBits(i) & ADMFLAG_ROOT);
            // bool isVIP = (GetUserFlagBits(i) & ADMFLAG_RESERVATION);
    
            if(!g_bIsFMUBMember[i] && isRoot) {
                SetEntData(iEnt, offset, view_as<int>(ClanImages_OWNER));
            }

            // if(isVIP) {
                // SetEntData(iEnt, offset, view_as<int>(ClanImages_VIP));
            // }
            if(g_bIsFMUBMember[i] && !isRoot) {
                SetEntData(iEnt, offset, view_as<int>(ClanImages_FMUB));
            }
		}
	}
}

public void OnPlayerRunCmdPost(int iClient, int iButtons) {
	static int iOldButtons[MAXPLAYERS+1];

	if(iButtons & IN_SCORE && !(iOldButtons[iClient] & IN_SCORE)) {
		StartMessageOne("ServerRankRevealAll", iClient, USERMSG_BLOCKHOOKS);
		EndMessage();
	}
	iOldButtons[iClient] = iButtons;
}

public void SteamWorks_OnClientGroupStatus(int authid, int groupAccountID, bool isMember, bool isOfficer) {
	int client = GetUserFromAuthID(authid);
	
	if((0 < client <= MaxClients) && IsClientInGame(client) && !IsFakeClient(client)) {
		if(groupAccountID == g_iClanID) {
			g_bIsFMUBMember[client] = isMember;
			bHasCheckedFMUB[client] = true;
		}
	}
}

int GetUserFromAuthID(int authid) {
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && 0 < i <= MaxClients && !IsFakeClient(i)) {
			char sAuthstring[50], sAuthstring2[50];
			GetClientAuthId(i, AuthId_Steam3, sAuthstring, sizeof(sAuthstring));
			IntToString(authid, sAuthstring2, sizeof(sAuthstring2));

			if(StrContains(sAuthstring, sAuthstring2) != -1) {
                return i;
		    }
		}
	}
	return -1;
}