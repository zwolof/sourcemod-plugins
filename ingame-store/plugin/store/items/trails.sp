enum struct Trails_t {
	int _dummy;

	bool Set(int client, IItemAttribute_t attribute) {
		if(strlen(attribute.value) <= 0) {
			return false;
		}
		strcopy(g_szEquippedClanTag[client], sizeof(g_szEquippedClanTag[]), attribute.value);
		// Colorize(g_szEquippedClanTag[client], sizeof(g_szEquippedClanTag[]));
		CS_SetClientClanTag(client, g_szEquippedClanTag[client]);
		return true;
	}
	
	void Clear(int client) {
		CS_SetClientClanTag(client, "");
		strcopy(g_szEquippedClanTag[client], sizeof(g_szEquippedClanTag[]), "");
	}
}

Trails_t Trails;