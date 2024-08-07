#include <sourcemod>
#include <sdktools>
#include <efrag>

Database g_Database = null;
char g_sDiscord[128], g_sSteam[128];

public Plugin myinfo = {
	name = "efrag.gg | Server Settings",
	author = "zwolof",
	description = "Loads and updates server settings dynamically.",
	version = "1.0.0",
	url = "www.efrag.gg"
};

char g_szDiscordUrl[128];
char g_szSteamGroupUrl[128];

enum struct ServerLinks_t {
	char steamgroup[128];
	char discord[128];
	char website[128];
}

ServerLinks_t links;

public void OnPluginStart() {
	Database.Connect(SQL_ConnectCallback, "ebans");

	RegConsoleCmd("sm_discord", Command_Discord);
	RegConsoleCmd("sm_steam", Command_Steam);

	RegConsoleCmd("sm_web", Command_Website);
	RegConsoleCmd("sm_website", Command_Website);
}

public void SQL_ConnectCallback(Database db, const char[] error, any data) {
	if(db == null) {
		LogError("T_Connect returned invalid Database Handle");
		return;
	}
	g_Database = db;
	GetServerLinks();
}

public Action Command_Website(int client, int args) {
	if(args > 1) {
		return Plugin_Handled;
	}
    efrag_PrintToChat(client, "Website: \x10%s", links.website);
	return Plugin_Handled;
}

public Action Command_Discord(int client, int args) {
	if(args > 1) {
		return Plugin_Handled;
	}
    efrag_PrintToChat(client, "Discord: \x10%s", links.discord);
	return Plugin_Handled;
}

public Action Command_Steam(int client, int args) {
	if(args > 1) {
		return Plugin_Handled;
	}
    efrag_PrintToChat(client, "Steam Group: \x10%s", links.steamgroup);
	return Plugin_Handled;
}

void GetServerLinks() {
	char szQuery[256];
	g_Database.Format(szQuery, sizeof(szQuery), "SELECT discord, steam_group, website FROM `ebans_settings` LIMIT 1;");
	g_Database.Query(SQL_LinksQueryCallback, szQuery);
}

public int SQL_LinksQueryCallback(Database db, DBResultSet results, const char[] szError, any data) {
	if(db == null || results == null || results.RowCount == 0) {
		LogError("[SQL] Hostname Query failure: %s", szError);
		return;
	}

	int discord; 		results.FieldNameToNum("discord", discord);
	int steam_group; 	results.FieldNameToNum("steam_group", steam_group);
	int website; 		results.FieldNameToNum("website", website);

	if(results.FetchRow()) {
		results.FetchString(discord, links.discord, sizeof(ServerLinks_t::discord));
		results.FetchString(steam_group, links.steamgroup, sizeof(ServerLinks_t::steamgroup));
		results.FetchString(website, links.website, sizeof(ServerLinks_t::website));

		File fCode = OpenFile("motd.txt", "w+");
		fCode.Flush();
		fCode.WriteString(links.discord, true);
		fCode.Close();

		PrintToServer("[efrag.gg] Motd Loaded (%s)", links.discord);
	}
}