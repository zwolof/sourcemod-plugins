// Called when plugins gets loaded
public void OnPluginStart() {
    eStore_OnPluginStart();
    eStore_Forwards_OnPluginStart();
    
    // Creates all command

    // Testing Purposes Only
    RegConsoleCmd("sm_store", Command_eStore);
    RegConsoleCmd("sm_shop", Command_eStore);

    // Commands
    RegConsoleCmd("sm_credits", Command_eCredits);

    // Dev Commands
    // RegAdminCmd("sm_addcredits", Command_eAddCredits, ADMFLAG_ROOT);
    // RegAdminCmd("sm_removecredits", Command_eRemoveCredits, ADMFLAG_ROOT);
    // RegAdminCmd("sm_showinventory", Command_eShowInventory, ADMFLAG_ROOT);
    RegAdminCmd("sm_reloadstuff", Command_eReloadStuff, ADMFLAG_ROOT);
    // RegAdminCmd("sm_setrebuildstring", Command_eSetRebuildStringLevel, ADMFLAG_ROOT);
    RegAdminCmd("sm_spawnbox", Command_eSpawnBox, ADMFLAG_ROOT);
    // RegAdminCmd("sm_setanimatedtag", Command_eSetAnimatedClantag, ADMFLAG_ROOT);

	g_mhGroundEntityOffset = FindSendPropInfo("CBasePlayer", "m_hGroundEntity");
	CreateTimer(2.0, Timer_HeadBoostIncrement, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_HeadBoostIncrement(Handle timer, any data) {
	g_iHeadBoostTime += 1;

	return Plugin_Continue;
}

// On Plugin End
public void OnPluginEnd() {
    eStore_OnPluginEnd();
}