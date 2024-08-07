enum struct ChatTags_t {
	int _dummy;

	bool Set(int client, IItemAttribute_t attribute) {
		if(strlen(attribute.value) <= 0) {
			return false;
		}
		strcopy(g_szEquippedChatTag[client], sizeof(g_szEquippedChatTag[]), attribute.value);
		Colorize(g_szEquippedChatTag[client], sizeof(g_szEquippedChatTag[]));
		return true;
	}
	
	void Clear(int client) {
		strcopy(g_szEquippedChatTag[client], sizeof(g_szEquippedChatTag[]), "");
	}
}

ChatTags_t ChatTags;