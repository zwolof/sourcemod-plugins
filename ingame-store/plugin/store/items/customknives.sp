enum struct CustomKnives_t {
	int _dummy;
	
	void Set(int client, Item item) {
		int iPrecached = g_iPrecachedModel[item.itemid];

		if(iPrecached != -1) {
			FPVMI_AddViewModelToClient(client, "weapon_knife", iPrecached);
		}
		else {
			eStore_Print(client, "Could not apply model. Model not precached.");
		}
	}

	void Clear(int client) {
		FPVMI_RemoveViewModelToClient(client, "weapon_knife");
	}
}

CustomKnives_t CustomKnives;