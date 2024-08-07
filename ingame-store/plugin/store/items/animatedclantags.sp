#define MAX_CLANTAG_LENGTH 128

Handle g_hAnimatedClantagTimer[MAXPLAYERS+1] = {null, ...};
int g_iAnimatedClantagIndex[MAXPLAYERS+1] = {0, ...};
char g_szAnimatedClantag[MAXPLAYERS+1][MAX_CLANTAG_LENGTH];
bool g_bAnimatedClantagGoBackwards[MAXPLAYERS+1] = {false, ...};
bool g_bAnimatedClantagDidJustBlink[MAXPLAYERS+1] = {false, ...};

#define ANIMATED_CLANTAG_SPACE_CHAR ' '
#define ANIMATED_CLANTAG_SPACE_CHAR_WIDTH 2

enum AnimatedClantagStyle_t {
	AnimatedClantagStyle_NORMAL = 0,
	AnimatedClantagStyle_BLINKING,

	MAX_ANIMATEDCLANTAGSTYLES
}

enum struct AnimatedClantags_t {
	int _dummy;
	
	void Set(int client, Item item) {
		char sValue[128];
		bool hasValueAttribute = eStore_GetItemAttributeValueByKey(item, "animated_clantag", sValue, sizeof(sValue));

		if(hasValueAttribute) {
			strcopy(g_szAnimatedClantag[client], sizeof(g_szAnimatedClantag[]), sValue);
			if(g_hAnimatedClantagTimer[client] != null) {
				delete g_hAnimatedClantagTimer[client];
			}

			char sType[128]; eStore_GetItemAttributeValueByKey(item, "type", sType, sizeof(sType));
			int iStyle = StringToInt(sType);

			StringMap map = new StringMap();
			map.SetValue("userid", GetClientUserId(client));
			map.SetValue("style", iStyle);

			g_hAnimatedClantagTimer[client] = CreateTimer(1.0, Store_AnimatedClanTagTimer, map, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

			// delete map;
		}
	}

	void Clear(int client) {
		strcopy(g_szAnimatedClantag[client], sizeof(g_szAnimatedClantag[]), "");
		delete g_hAnimatedClantagTimer[client];
	}
}

public Action Store_AnimatedClanTagTimer(Handle tmr, StringMap map) {
	
	int userid, iStyle;
	map.GetValue("userid", userid);
	map.GetValue("style", iStyle);

	int client = GetClientOfUserId(userid);
	
	if(strlen(g_szAnimatedClantag[client]) == 0) {
		g_hAnimatedClantagTimer[client] = null;
		delete map;
		return Plugin_Stop;
	}

	AnimatedClantagStyle_t style = view_as<AnimatedClantagStyle_t>(iStyle);

	char sBuffer[128];
	switch(style) {
		case AnimatedClantagStyle_NORMAL: {
			if(g_bAnimatedClantagGoBackwards[client]) {

				if(g_iAnimatedClantagIndex[client] <= 0) {
					g_iAnimatedClantagIndex[client] = 0;
					g_bAnimatedClantagGoBackwards[client] = false;
				}
			}
			else {
				if(g_iAnimatedClantagIndex[client] >= strlen(g_szAnimatedClantag[client])) {
					g_bAnimatedClantagGoBackwards[client] = true;
				}
			}
			GetCharsInString(g_iAnimatedClantagIndex[client], g_szAnimatedClantag[client], sBuffer, sizeof(sBuffer));
			g_iAnimatedClantagIndex[client] += g_bAnimatedClantagGoBackwards[client] ? -1 : 1;
		}
		case AnimatedClantagStyle_BLINKING: {
			g_bAnimatedClantagDidJustBlink[client] = !g_bAnimatedClantagDidJustBlink[client];
			FormatEx(sBuffer, sizeof(sBuffer), g_bAnimatedClantagDidJustBlink[client] ? g_szAnimatedClantag[client] : "")
		}
	}
	CS_SetClientClanTag(client, sBuffer);

	return Plugin_Continue;
}

bool GetCharsInString(int count, const char[] tag, char[] buffer, int maxlen) {
	// append a string with "count" characters to the end of the string "str"
	// if the string is too long, return false
	if(count == 0) {
		return false;
	}
	
	int i = 0;
	char str[128];
	for(i = 0; i < count; i++) {
		str[i] = tag[i];
	}
	str[i+1] = '\0';
	return strcopy(buffer, maxlen, str);
}

int CountCharsInString(const char[] str) {
	int len = strlen(str);

	if(len == 0) {
		return 0;
	}

	int count = 0;

	for(int i = 0; i < len; i++) {
		if(str[i] != '\0') {
			count++;
		}
	}
	return count;
}

AnimatedClantags_t AnimatedClantags;