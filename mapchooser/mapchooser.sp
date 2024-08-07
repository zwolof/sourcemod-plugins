#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <efrag>

#define SOUND_DOWNLOAD	"sound/efrag2022/mapchooser/its_time_to_choose.mp3"
#define SOUND_PLAY		"efrag2022/mapchooser/its_time_to_choose.mp3"


bool g_DEBUG = false;
#pragma tabsize 0

#include "mapchooser/structs/SMap.sp"
#include "mapchooser/structs/SNomination.sp"
#include "mapchooser/structs/SMapGroup.sp"
#include "mapchooser/structs/SPlayer.sp"
// #include "mapchooser/structs/SSpawns.sp" 
#include "mapchooser/structs/SVote.sp"

#include "mapchooser/globals.sp"
#include "mapchooser/database.sp"
#include "mapchooser/helpers.sp"
#include "mapchooser/lib.sp"

#include "mapchooser/menus.sp"
#include "mapchooser/menus_handlers.sp"
#include "mapchooser/timers.sp"

public Plugin myinfo = {
	name = "efrag.gg | Custom Mapchooser",
	author = "zwolof",
	description = "Custom Mapchooser plugin for CS:GO",
	version = "1.0.0",
	url = "www.efrag.gg"
};

public void OnPluginStart() {
    g_alMaps = new ArrayList(sizeof(SMap));
    g_alMapGroups = new ArrayList(sizeof(SMapGroup));
    g_alVotes = new ArrayList(sizeof(SVote));
    g_alRecentlyPlayed = new ArrayList(sizeof(RecentlyPlayed));

    // Listen for <say> and <say_team>
    AddCommandListener(MC_CommandListener, "say");
    AddCommandListener(MC_CommandListener, "say_team");

    // Events
    HookEvent("round_start", Event_OnRoundStart, EventHookMode_Post);
    HookEvent("round_end", Event_OnRoundEnd, EventHookMode_Post);
    HookEvent("player_connect", Event_OnPlayerConnect, EventHookMode_Post);
    HookEvent("player_disconnect", Event_OnPlayerDisconnect, EventHookMode_Post);
    
    // Initialize menus that wont ever change
    g_mMenuMaps = new Menu(MC_Menu_Maplist_Handler);
    g_MapvoteMenu = new Menu(MC_Menu_Mapvote_Handler);
    g_mVoteMenu = new Menu(MC_Menu_Mapvote_Handler);
    g_mVoteMenu.SetTitle("efrag.gg | Choose a map");
    // g_smVotes = new StringMap();

    // Create the static maplist, this wont change since
    // this is just the list of all the available maps

    // Set Vote In Progress to false, cause we have no vote at the moment
    // g_bVoteInProgress = false;

    // Commands
    RegConsoleCmd("sm_maps", Command_DisplayMaplistMenu);
    RegAdminCmd("sm_forcemapvote", Command_ForceMapVote, ADMFLAG_GENERIC);

    Database_OnPluginStart();

    for(int i = 1; i <= MaxClients; i++) {
        g_iVoteCount[i] = 0;
    }
    // g_iVoteCount = {0, ...};
    g_currentState = EState_NULL;
    g_iRockTheVotes = 0;
}

public void OnPluginEnd() {
    delete g_mMenuMaps;
    // delete g_smVotes;
    delete g_MapvoteMenu;
    delete g_mVoteMenu;
}

public void OnMapEnd() {
	// if(g_Database != null) {
	// 	SQL_InsertRecentlyPlayed();
	// }
	for(int i = 1; i <= MaxClients; i++) {
        g_iVoteCount[i] = 0;
        g_bRockTheVote[i] = false;
    }
	g_iRoundsPlayed = 0;
	g_iRockTheVotes = 0;
	g_bHasPrintedRTVMessage = false;
	g_currentState = EState_NULL;
}

public Action Command_DisplayMaplistMenu(int client, int args) {
    g_mMenuMaps.Display(client, 30);
    return Plugin_Handled;
}

public Action Command_ForceMapVote(int client, int args) {
    // g_bVoteInProgress = true;
	g_iVoteCountDownTimer = 0;
	PrepareVote();
	MC_OpenMapvoteMenuToEveryone();

    return Plugin_Handled;
}

public void Event_OnRoundEnd(Event event, const char[] name, bool bDontBroadcast) {
	g_iRoundsPlayed++;
}

public void Event_OnRoundStart(Event event, const char[] name, bool bDontBroadcast) {
    if(g_currentState == EState_PostVote && !g_bShouldMapBeExtended) {
        // Change the map if vote is done
        SMap map; g_alMaps.GetArray(g_nextMapIdx, map, sizeof(SMap));
        // ChatAll("Changing map to \x10%s", map.filename);

        RequestFrame(Task_ChangeMap);
		g_currentState = EState_NULL;
		return;
    }
	bool isRtvAllowed = (g_iRoundsPlayed >= 4);
	g_bIsRTVAllowed = isRtvAllowed;
	
	if(isRtvAllowed && !g_bHasPrintedRTVMessage) {
    	ChatAll("RTV Is now allowed!");
		g_bHasPrintedRTVMessage = true;
	}
	// else SQL_GetMaplist();
}

public void Event_OnPlayerConnect(Event event, const char[] name, bool bDontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));

    if(client > 0 && !IsFakeClient(client)) {
        g_bRockTheVote[client] = false;
    }
}

public void Event_OnPlayerDisconnect(Event event, const char[] name, bool bDontBroadcast) {
    float fVotes = float(g_iRockTheVotes);
	
    if(fVotes >= (GetPlayerCount() * 0.6)) {
        // g_bVoteInProgress = true;
        // g_currentState = EState_Vote;

        PrepareVote();
        MC_OpenMapvoteMenuToEveryone();
    }
}

public void Task_ChangeMap(any data) {
	SQL_InsertRecentlyPlayed();

    SMap map; g_alMaps_Random.GetArray(g_nextMapIdx, map, sizeof(SMap));
    ChatAll("Changing map to \x10%s", map.filename);

    ServerCommand("changelevel %s", map.filename);
}

public Action MC_CommandListener(int client, const char[] command, int argc) {
    char rtvCommands[][] = { "!rtv", "/rtv", "rtv" };
    char nominateCommands[][] = { "!nominate", "/nominate", "nominate" };
    char nextMapCommands[][] = { "!nextmap", "/nextmap", "nextmap" };

    char sCommandArgs[256];
    GetCmdArgString(sCommandArgs, sizeof(sCommandArgs));
    StripQuotes(sCommandArgs);

	if(IsChatCommand(nextMapCommands, sCommandArgs, 3)) {
		// Nextmap command
		if(g_currentState != EState_PostVote || g_nextMapIdx == -1) {
			efrag_PrintToChat(client, "The Next map has not been decided yet.");
			return Plugin_Handled;
		}

		SMap map; g_alMaps.GetArray(g_nextMapIdx, map, sizeof(SMap));
		efrag_PrintToChat(client, "Next map \x10%s", map.filename);
		return Plugin_Handled;
	}

	if(IsChatCommand(nominateCommands, sCommandArgs, 3)) {
		// nominate command
		char sMap[256], buffer[512];

		if(g_currentState == EState_Vote) {
			efrag_PrintToChat(client, "A vote is in progress, you cannot nominate right now.");
			return Plugin_Handled;
		}
		MC_OpenNominationMenu(client, MENU_TIME_FOREVER);
		
		return Plugin_Handled;
	}

	if(IsChatCommand(rtvCommands, sCommandArgs, 3)) {
		if(!g_bIsRTVAllowed) {
			efrag_PrintToChat(client, "\x08RTV is not allowed yet! Wait for \x0F%d\x08 rounds!", MIN_ROUNDS_TIL_RTV - g_iRoundsPlayed);
			return Plugin_Handled;
		}

		if(g_player[client].hasRTVd) {
			efrag_PrintToChat(client, "\x08You have already rocked the vote!");
			return Plugin_Handled;
		}

		if(g_player[client].hasVoted) {
			efrag_PrintToChat(client, "\x08You have already voted!");
			return Plugin_Handled;
		}
		if(!g_currentState >= EState_Vote) {
			RequestFrame(CheckRTVState, GetClientUserId(client));
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void CheckRTVState(any data) {
    if(g_currentState == EState_Vote) return;
    if(g_currentState == EState_PostVote) return;

    int client = GetClientOfUserId(data);
    if(client <= 0) return;

    g_iRockTheVotes += 1;
    
    efrag_PrintToChat(client, "\x08You rocked the vote! (\x04%d\x08/\x04%d\x08)", g_iRockTheVotes, GetPlayerCount());
    g_player[client].hasRTVd = true;

	float fVotes = float(g_iRockTheVotes);
	
    if(fVotes >= (GetPlayerCount() * 0.6)) {
        // g_bVoteInProgress = true;
        // g_currentState = EState_Vote;

        PrepareVote();
        MC_OpenMapvoteMenuToEveryone();
    }
}

bool IsChatCommand(char[][] commandList, char[] chatMessage, int commandCount) {
    for(int i = 0; i < commandCount; i++) {
        if(StrEqual(chatMessage, commandList[i], false)) {
            return true;
        }
    }
    return false;
}

public void OnClientPutInServer(int client) {
    if(g_player[client].init(client)) {
        if(g_DEBUG) {
            efrag_PrintToChat(client, "Initialized Player");
        }
        g_hMapvoteResultsTimer[client] = null;
        g_iNomination[client] = -1;
        g_iVoteCount[client] = 0;
        g_bRockTheVote[client] = false;
        g_player[client].hasVoted = false;
        g_player[client].hasRTVd = false;
        g_bShouldShowVoteResultsMenu[client] = true;
    }
}

public void OnMapStart() {
    g_currentState = EState_MapStart;
    // g_hAllowRTVTimer = CreateTimer(30.0, Timer_EnableRTV, _, TIMER_FLAG_NO_MAPCHANGE);
	g_bIsRTVAllowed = false;

    // Reset vars
    g_iVoteCountDownTimer = 1;
    g_iRockTheVotes = 0;

    for(int i = 1; i <= MaxClients; i++) {
        g_iNomination[i] = -1;
        g_iVoteCount[i] = 0;
    }

	// if(g_Database != null) {
	// 	SQL_GetMaplist();
	// }
	PrecacheSound(SOUND_PLAY, true);
	AddFileToDownloadsTable(SOUND_DOWNLOAD);

    // g_hForceVoteTimer = CreateTimer(600.0, Task_ForceMapVote, _, TIMER_FLAG_NO_MAPCHANGE);
}

void MC_ShuffleMaps() {
    if(g_alMaps == null) return;

    g_alMaps_Random = g_alMaps.Clone();

    for(int i = g_alMaps_Random.Length-1; i >= 0; i--) {
        int k = GetRandomInt(0, i);
        g_alMaps_Random.SwapAt(k, i);

        // Fix Nominations
        for(int j = 1; j <= MaxClients; j++) {
            int temp = g_iNomination[i];
            g_iLastNomination[i] = temp;

            g_iNomination[i] = g_iNomination[k];
            g_iNomination[k] = temp;
        }

        // for(int m = 0; m < g_alMaps_Random.Length; m++) {
        //     int tempVotes = g_iVoteCount[m];
        //     g_iVoteCount[m] = g_iVoteCount[k];
        //     g_iVoteCount[k] = tempVotes;
        // }
    }
}