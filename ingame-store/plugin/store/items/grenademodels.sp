enum struct GrenadeModels_t {
	int _dummy;
	
	void Set(int client, IItemAttribute_t attr) {
		int precached = PrecacheModel(attr.value, false);

		FPVMI_AddViewModelToClient(client, "weapon_knife", precached);
	}

	void Clear(int client) {
		FPVMI_RemoveViewModelToClient(client, "weapon_knife");
	}
}

GrenadeModels_t GrenadeModels;