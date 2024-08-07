enum struct PlayerModels_t {
	int _dummy;
	
	void Set(int client, IItemAttribute_t attribute, Item item) {
		int iPrecached = g_iPrecachedModel[item.itemid];

		if(iPrecached != -1) {
			SetEntityModel(client, attribute.value);
		}
		else {
			eStore_Print(client, "Could not apply model. Model not precached.");
		}
	}

	void Clear(int client) {
		SetEntityModel(client, g_szOldPlayerModel[client]);
	}
}

PlayerModels_t PlayerModels;