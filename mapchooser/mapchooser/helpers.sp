void ChatAll(char[] message, any ...) {
    char szBuffer[PLATFORM_MAX_PATH], szNewMessage[PLATFORM_MAX_PATH];
    Format(szBuffer, sizeof(szBuffer), "\x08%s", message);
    VFormat(szNewMessage, sizeof(szNewMessage), szBuffer, 2);

    for(int i = 1; i <= MaxClients; i++) {
        if(IsClientInGame(i) && !IsFakeClient(i)) {
            efrag_PrintToChat(i, "%s", szNewMessage);
        }
    }
}


int GetPlayerCount() {
    int count = 0;
    for(int i = 1; i <= MaxClients; i++) {
        if(IsClientInGame(i) && !IsFakeClient(i)) {
            count++;
        }
    }
    return count;
}