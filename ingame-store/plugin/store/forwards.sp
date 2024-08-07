
void eStore_Forwards_OnPluginStart() {
    g_hForward_OnCreditsAdded = CreateGlobalForward("eStore_OnCreditsAdded_Post", ET_Hook, Param_Cell, Param_Cell);
    g_hForward_OnCreditsRemoved = CreateGlobalForward("eStore_OnCreditsRemoved_Post", ET_Hook, Param_Cell, Param_Cell);
    g_hForward_OnCategoryFetched = CreateGlobalForward("eStore_OnCategoryFetched_Post", ET_Hook, Param_Cell);
}