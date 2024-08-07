public Action OnPlayerRunCmd(int client) {
    // if(!IsFakeClient(client) && IsClientInGame(client) && IsPlayerAlive(client)) {
    //     char sCreditString[128];
    //     FormatEx(sCreditString, sizeof(sCreditString), STORE_CREDITSNAME_UC...": %d", eStore[client].credits);

    //     eStore_HUD(client, "2", "196 196 196", "96 96 96", "0", "0.3", "5.0", "0.5", "0.5", sCreditString, "0.03", "0.2");
    // }   
    return Plugin_Continue;
}