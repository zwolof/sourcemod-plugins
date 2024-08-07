Database g_Database 	= null;

#define SQL_TABLENAME	"ebans"

#define WEBSITEURL					"\x03www.efrag.gg"
#define DISCORDURL					"\x03www.efrag.gg/discord"
#define STOREURL					"\x03www.efrag.gg/store"

#define SERVERTYPE 					"all"
#define PREFIX						"\x01\x0B\x01[\x03eFrag\x01]"
#define ADVERTISEMENT_TIME			90.0
#define MAX_ADS						64
#define MAX_COLORS					14

enum Type { CHAT = 0, HINT = 1, CENTER = 2 };
enum EColorCodes { EColorCodes_Name = 0, EColorCodes_Hex }

char g_Colors[MAX_COLORS][EColorCodes][] = {
	{"{WHITE}", 	"\x08"},
	{"{DEFAULT}", 	"\x08"},	
	{"{RED}", 		"\x0F"},	
	{"{RED2}", 		"\x0F"},	
	{"{GREEN}", 	"\x04"},	
	{"{GREEN2}", 	"\x06"},	
	{"{BLUE}", 		"\x0C"},	
	{"{LIGHTBLUE}", "\x0B"},	
	{"{GRAY}", 		"\x0A"},	
	{"{GRAY2}", 	"\x08"},
	{"{GOLD}", 		"\x10"},	
	{"{ORANGE}", 	"\x10"},	
	{"{PINK}", 		"\x0E"},
	{"{PURPLE}", 	"\x03"},
};

/*
CREATE TABLE `efrag_adverts` (
  `id` INT(7) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `message` VARCHAR(255) NOT NULL,
  `color` VARCHAR(255) NOT NULL DEFAULT "{RED}",
  `position` tinyint NOT NULL,
  `vip` tinyint NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
*/

public Plugin myinfo = {
	name = "efrag.gg | Advertisements",
	author = "zwolof",
	description = "Send chat advertisements",
	version = "1.0.0",
	url = "www.efrag.gg"
};

enum struct Advertisement_t {
	char message[256];
	char color[64];
	bool vip;
	
	int position;
}
ArrayList g_alAdvertisements = null;

public void OnPluginStart() {
	Database.Connect(SQL_ConnectCallback, SQL_TABLENAME);

	g_alAdvertisements = new ArrayList(sizeof(Advertisement_t));
}

public void OnPluginEnd() {
	delete g_alAdvertisements;
}

public void SQL_ConnectCallback(Database db, const char[] error, any data) {
	if(db == null) {
		SetFailState("T_Connect returned invalid Database Handle");
		return;
	}
	g_Database = db;
	SQL_FetchAds();
}

void SQL_FetchAds() {
	char szQuery[1024];
	g_Database.Format(szQuery, sizeof(szQuery), "SELECT * FROM `efrag_adverts_v1` WHERE servertype = '%s' OR servertype = 'all' ORDER BY id ASC;", SERVERTYPE);
	g_Database.Query(SQL_FetchAds_Callback, szQuery);
}

public int SQL_FetchAds_Callback(Database db, DBResultSet results, const char[] szError, any data) {	
	if(db == null || results == null) {
		LogError("[SQL] Select Query failure: %s", szError);
		return;
	}

	if(results.RowCount <= 0) {
		LogError("[SQL] Select Query failure: %s", szError);
		return;
	}

	int message, position, vip, color;
	results.FieldNameToNum("message", message);
	results.FieldNameToNum("position", position);
	results.FieldNameToNum("vip", vip);
	results.FieldNameToNum("color", color);
	
	Advertisement_t ad;
	while(results.FetchRow()) {
		results.FetchString(message, ad.message, sizeof(Advertisement_t::message));
		results.FetchString(color, ad.color, sizeof(Advertisement_t::color));
		ad.vip = results.FetchInt(vip);
		ad.position = results.FetchInt(position);
		
		g_alAdvertisements.PushArray(ad, sizeof(Advertisement_t));
	}
	CreateTimer(ADVERTISEMENT_TIME, AdvertisementTimer_CallBack, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action AdvertisementTimer_CallBack(Handle tmr, any data) {
	static int currentAd = 0;

	if(g_alAdvertisements.Length == 0) {
		return Plugin_Continue;
	}

	Advertisement_t ad; g_alAdvertisements.GetArray(currentAd, ad, sizeof(Advertisement_t));
	Colorize(ad.message, sizeof(Advertisement_t::message));
	Colorize(ad.color, sizeof(Advertisement_t::color));
	
	ReplaceString(ad.message, sizeof(Advertisement_t::message), "{WEBSITE}", WEBSITEURL, true);
	ReplaceString(ad.message, sizeof(Advertisement_t::message), "{DISCORD}", DISCORDURL, true);
	ReplaceString(ad.message, sizeof(Advertisement_t::message), "{STORE}", STOREURL, true);
	ReplaceString(ad.message, sizeof(Advertisement_t::message), "{PREFIX}", PREFIX, true);
	ReplaceString(ad.message, sizeof(Advertisement_t::message), "{COLOR}", ad.color, true);

	char sMultipleLines[9][1024];
	int iCount = ExplodeString(ad.message, "\\n", sMultipleLines, sizeof(sMultipleLines), sizeof(sMultipleLines[]));
	
	for(int i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || IsFakeClient(i)) {
			continue;
		}

		if(ad.vip && CheckCommandAccess(i, "sm_vip", ADMFLAG_CUSTOM6, true)) {
			continue;
		}

		PrintToChat(i, " %s▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬", ad.color);
		for(int y = 0; y < iCount; y++) {
			PrintToChat(i, " \x01\x0B\x08%s", sMultipleLines[y]);
		}
		PrintToChat(i, " %s▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬", ad.color);
	}
	currentAd = (currentAd == g_alAdvertisements.Length - 1) ? 0 : currentAd + 1;
	
	return Plugin_Continue;
}

stock void Colorize(char[] str, int maxlen) {
	for (int i = 0; i < sizeof(g_Colors); i++) {
		ReplaceString(str, maxlen, g_Colors[i][EColorCodes_Name], g_Colors[i][EColorCodes_Hex]);
	}
}
