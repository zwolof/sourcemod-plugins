#include <sourcemod>
#include <cstrike>

// okay so the idea is to make a function that shifts the array,
// so if the array looks like: [d, i, a, b, l, i, x], we want the last index to be removed
// [d, i, a, b, l, i], i know i can just pop it, but thing is I want to split up a string and push it,
// could just do this: 

int g_iCurrentIdx[MAXPLAYERS+1] = {0, ...};
Handle g_hTagTimer[MAXPLAYERS+1];
char g_sTag[128][MAXPLAYERS+1];

int g_iAnimation[MAXPLAYERS+1];

public void OnPluginStart() {
    RegConsoleCmd("sm_tag", Command_Tag);
    RegConsoleCmd("sm_tagstop", Command_TagStop);
}

public Action Command_Tag(int client, int args) {
    
    char sTag[128];
    GetCmdArgString(sTag, sizeof(sTag));
    strcopy(g_sTag[client], sizeof(g_sTag), sTag);

    StartTimer(client, 0.3);

    return Plugin_Handled;
}

public Action Command_TagStop(int client, int args) {
    StopTimer(client);
    return Plugin_Handled;
}

void StartTimer(int client, float time) {
    StopTimer(client);

    g_hTagTimer[client] = CreateTimer(0.3, Timer_SetTag, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
    PrintToChat(client, "Started Timer @ %.2f", time);
}

void StopTimer(int client) {
    delete g_hTagTimer[client];
    PrintToChat(client, "Killed Timer");
}

public Action Timer_SetbackwardsTag(Handle tmr, int userid) {
    int client = GetClientOfUserId(userid);
    StartTimer(client, 0.2);
    return Plugin_Stop;
}

void StartBackwardsTimer(int client) {
    delete g_hTagTimer[client];
    g_hTagTimer[client] = CreateTimer(2.0, Timer_SetbackwardsTag, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_SetTag(Handle tmr, int userid) {
    int client = GetClientOfUserId(userid);

    static bool bBackwards[MAXPLAYERS+1] = {false, ...};
    char sCurrentTag[128], sTag[128];

    // Format The Tag to The clients own tag
    FormatEx(sTag, sizeof(sCurrentTag), "%s", g_sTag[client]);

    int idx = g_iCurrentIdx[client];
    if(idx == (strlen(sTag)) && !bBackwards[client]) {
        bBackwards[client] = true;
        StartBackwardsTimer(client);

        if((idx) > 0 && bBackwards[client]) {
            g_iCurrentIdx[client]--;
        }
        else {
            bBackwards[client] = false;
            StopTimer(client);
            StartTimer(client, 0.3);
            g_iCurrentIdx[client]++;
        }
    }
    else {
        if(bBackwards[client]) {
            if((idx) > 0 && bBackwards[client]) {
                g_iCurrentIdx[client]--;
            }
            else bBackwards[client] = false;
        }
        else {
            bBackwards[client] = false;
            g_iCurrentIdx[client]++;
        }
    }
    Substring(sCurrentTag, sizeof(sCurrentTag), sTag, sizeof(sTag), 0, idx);
    CS_SetClientClanTag(client, sCurrentTag);

    return Plugin_Continue;
}

stock bool Substring(char[] dest, int destSize, char[] source, int sourceSize, int start, int end) {
    if (end < start || end > (sourceSize-1)) {
        strcopy(dest, destSize, NULL_STRING);
        return false;
    }
    else {
        strcopy(dest, (end-start+1), source[start]);
        return true;
    }
} 