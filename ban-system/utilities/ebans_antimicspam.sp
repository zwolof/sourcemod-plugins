
native bool EB_IsMuted(int id);
native bool EB_PunishMicspam(int id);

public Plugin myinfo = {
    name = "EFRAG [Anti Soundboard]",
    author = "zwolof",
    description = "Custom Administrator system",
    version = "1.2.5",
    url = "www.efrag-community.com"
};


public void OnPluginStart() {
	CreateTimer(1.0, Timer_CheckAudio, _, TIMER_REPEAT);
}

public Action Timer_CheckAudio(Handle timer, any data) {
	for(int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i)) {
			QueryClientConVar(i, "voice_inputfromfile", CB_CheckAudio);
		}
	}
}

public void CB_CheckAudio(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue) {
    if(result == ConVarQuery_Okay) {
		if(!EB_IsMuted(client)) {
			EB_PunishMicspam(client);
		}
    }
}