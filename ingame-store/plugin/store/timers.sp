public Action Timer_GiveCredits(Handle timer, any data) {
    int client = GetClientOfUserId(data);
    if(eStore_IsValidClient(client)) {
        int amount = STORE_CREDITS_PER_MINUTE;
        
        eStore[client].add(amount);
        
        if(g_dataOrigin == DataOrigin_API) {
            API_UpdateUserCredits(client);
        }

        if(g_dataOrigin == DataOrigin_DB) {
            DB_UpdateClientCredits(client, amount, MA_Add);
        }
        eStore_Print(client, "You have been given \x04%d\x08 credits", STORE_CREDITS_PER_MINUTE);
    }
    return Plugin_Continue;
}