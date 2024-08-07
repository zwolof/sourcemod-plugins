#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <geoip>
//#include <ebans>
#include <smlib>
#include <efrag>
//#include <filenetmessages>



#define PLUGIN_PREFIX      "[Shield]"

#define COMMUNITY_NAME 	"eFrag"
#define SQL_CONNECTION 	"ebans"
#define DB_NAME 		"ebans"
#define PREFIX	 		" \x01\x04\x01[\x0F☰  FRAG\x01] "
#define STOREURL		"www.store.efrag.gg"
#define DISCORDURL		"www.discord.efrag.gg"
#define BANSURL			"www.bans.efrag.gg"
#define SITEURL			"www.efrag.gg"
#define MS 				MAXPLAYERS+1

// Modules
#include "ebans/globals.sp"
#include "ebans/queries.sp"
#include "ebans/adminmenu.sp"
#include "ebans/sql.sp"
#include "ebans/funcs.sp"
#include "ebans/natives.sp"

public Plugin myinfo = {
    name = "efrag.gg | Ban- & Admin Manager",
    author = "zwolof",
    description = "Custom Administrator system",
    version = "1.0.0",
    url = "www.efrag.gg"
};

public void OnPluginStart() {
	Database.Connect(SQL_ConnectCallback, SQL_CONNECTION);

	// Restricted Commands
	RegAdminCmd("sm_ban", Command_eBan, ADMFLAG_GENERIC);
	RegAdminCmd("sm_mute", 	Command_eMute, ADMFLAG_GENERIC);
	RegAdminCmd("sm_gag", 	Command_eGag, ADMFLAG_GENERIC);

	RegAdminCmd("sm_admin", Command_eAdmin, ADMFLAG_GENERIC);

	// Chat Hook
	RegConsoleCmd("say", Command_Say);

	LoadTranslations("common.phrases");
}

public void OnMapStart() {
	GameConfGetKeyValue(LoadGameConfigFile("funcommands.games"), "SoundBlip", g_sBlipSound, sizeof(g_sBlipSound));
	PrecacheSound(g_sBlipSound, true);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	RegPluginLibrary("ebans");

	CreateNative("EB_BanCheater", Native_EBBanCheater);
	CreateNative("EB_BanCheaterCustom", Native_EBBanCheaterWithCustomReason);
	CreateNative("EB_BanEvadingPlayer", Native_EBBanEvasion);
	CreateNative("EB_BanDDoser", Native_EBBanDDoser);
    CreateNative("EB_PunishAdvertisement", Native_EBPunishAdvertisement);
    CreateNative("EB_PunishBadLanguage", Native_EBPunishLanguage);
    CreateNative("EB_PunishMicspam", Native_EBPunishMicspam);

    CreateNative("EB_IsGagged", Native_EBIsGagged);
    CreateNative("EB_IsMuted", Native_EBIsMuted);
    CreateNative("EB_KickClient", Native_EBKickClient);
    CreateNative("EB_KickSmurfAccount", Native_EBKickSmurfAccount);
    
    return APLRes_Success;
}

public void SQL_ConnectCallback(Database db, const char[] error, any data)
{
	if(db == null) {
		SetFailState("T_Connect returned invalid Database Handle");
	}
	g_Database = db;
    g_Database.SetCharset("utf8mb4");
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs) {
	if(g_bGagged[client]) { 
		efrag_PrintToChat(client, "\x08You are currently \x0Fgagged\x08!");
		return Plugin_Stop; 
	}
	return Plugin_Continue;
}

public void OnClientPutInServer(int client) {
	if(!IsValidClient(client)) {
		return;
	}
	bMenu[client].id = client;
	RequestFrame(Task_CheckUser, GetClientUserId(client));
}

public void Task_CheckUser(any userid) {

	int client = GetClientOfUserId(userid);

	if(!IsClientInGame(client)) {
		return;
	}

	//PrintToChat(client, "%s SteamID64: \x0F%s", PREFIX, szSteamId);
	g_bGagged[client] = false;
	g_bMuted[client] = false;
	
	// Set listening flags
	SetClientListeningFlags(client, VOICE_NORMAL);

	SQL_GetUserInfo(client);
	SQL_GetAdminPerms(client);
	
	// Get Active Punishments
	SQL_CheckPunishments(client);
	
	// We need to update their row with new name and ip
	SQL_UpdateUser(client);
	return;
}


/*
SET names "utf8_general_ci";

CREATE TABLE IF NOT EXISTS `ebans_users`(`steamid` INT(64), `name` VARCHAR(255), `ip` VARCHAR(32), `country` VARCHAR(16), `is_banned` INT(7));
CREATE TABLE IF NOT EXISTS `ebans_punishments`(`steamid` INT(64), `banned_on` bigint DEFAULT NULL, `expires_on` bigint DEFAULT NULL, `reason` VARCHAR(255) DEFAULT NULL, `banned_by` VARCHAR(255) DEFAULT NULL, `type` smallint, `unbanned` smallint DEFAULT NULL, `unbanned_by` VARCHAR(255) DEFAULT NULL);
CREATE TABLE IF NOT EXISTS `ebans_admins`(`steamid` INT(64), `rank` smallint DEFAULT 0, `immunity` smallint DEFAULT 0);

*/