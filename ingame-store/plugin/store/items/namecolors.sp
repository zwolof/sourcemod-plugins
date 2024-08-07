enum struct NameColors_t {
	int _dummy;

	bool Set(int client, IItemAttribute_t attribute) {
		if(strlen(attribute.value) <= 0) {
			return false;
		}
		strcopy(g_szEquippedNameColor[client], sizeof(g_szEquippedNameColor[]), attribute.value);
		Colorize(g_szEquippedNameColor[client], sizeof(g_szEquippedNameColor[]));
		return true;
	}
	
	void Clear(int client) {
		strcopy(g_szEquippedNameColor[client], sizeof(g_szEquippedNameColor[]), "");
	}
}

NameColors_t NameColors;