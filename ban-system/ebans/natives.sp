/*********************************************************
 * Ban Player from server
 *
 * @param admin		The steamid of the admin
 * @param target	The client index of the target
 * @param time		The time to ban the player for, string
 * @param reason	The reason to ban the player from the server
 * @noreturn
 *********************************************************/
public Native_EBBanCheater(Handle plugin, int numParams) {
	PunishPlayer(0, GetNativeCell(1), PunishmentType_Ban, "p", "[Shield] Cheating Infraction");
}
/*********************************************************/

/*********************************************************
 * Ban Player from server
 *
 * @param admin		The steamid of the admin
 * @param target	The client index of the target
 * @param time		The time to ban the player for, string
 * @param reason	The reason to ban the player from the server
 * @noreturn
 *********************************************************/
public Native_EBBanCheaterWithCustomReason(Handle plugin, int numParams) {
    char reason[256]; GetNativeString(2, reason, sizeof(reason));
    char formatted[512];
    FormatEx(formatted, sizeof(formatted), "[Shield] %s", reason);
	PunishPlayer(0, GetNativeCell(1), PunishmentType_Ban, "p", formatted);
}
/*********************************************************/



/*********************************************************
 * Ban Evading Player from server
 *
 * @param admin		The steamid of the admin
 * @param target	The client index of the target
 * @param time		The time to ban the player for, string
 * @param reason	The reason to ban the player from the server
 * @noreturn
 *********************************************************/
public Native_EBBanEvasion(Handle plugin, int numParams) {
	PunishPlayer(0, GetNativeCell(1), PunishmentType_Ban, "p", "[Shield] Ban Evasion");
}
/*********************************************************/


/*********************************************************
 * Ban Ddosers from the servers
 *
 * @param admin		The steamid of the admin
 * @param target	The client index of the target
 * @param time		The time to ban the player for, string
 * @param reason	The reason to ban the player from the server
 * @noreturn
 *********************************************************/
public Native_EBBanDDoser(Handle plugin, int numParams) {
	PunishPlayer(0, GetNativeCell(1), PunishmentType_Ban, "p", "[Shield] Causing Service Interruption");
}
/*********************************************************/



/*********************************************************
 * Permanently Gag Player
 *
 * @param admin		The steamid of the admin
 * @param target	The client index of the target
 * @param time		The time to gag the player for, string
 * @param reason	The reason to gag the player from the server
 * @noreturn
 *********************************************************/
public Native_EBPunishAdvertisement(Handle plugin, int numParams) {
	PunishPlayer(0, GetNativeCell(1), PunishmentType_Gag, "p", "[Shield] Advertisement");
}
/*********************************************************/


/*********************************************************
 * Kick Client
 *
 * @param admin		The steamid of the admin
 * @param target	The client index of the target
 * @param time		The time to gag the player for, string
 * @param reason	The reason to gag the player from the server
 * @noreturn
 *********************************************************/
public Native_EBKickClient(Handle plugin, int numParams) {
    char sReason[128], buffer[256];
    GetNativeString(2, sReason, sizeof(sReason));
    FormatEx(buffer, sizeof(buffer), "[Shield] %s", sReason);
    KickClient(GetNativeCell(1), buffer);
}
/*********************************************************/



/*********************************************************
 * Kick Smurf
 *
 * @param admin		The steamid of the admin
 * @param target	The client index of the target
 * @param time		The time to gag the player for, string
 * @param reason	The reason to gag the player from the server
 * @noreturn
 *********************************************************/
public Native_EBKickSmurfAccount(Handle plugin, int numParams) {
    char sReason[128], buffer[256];
    GetNativeString(2, sReason, sizeof(sReason));
    FormatEx(buffer, sizeof(buffer), "[Shield] %s", sReason);
    KickClient(GetNativeCell(1), buffer);
}
/*********************************************************/



/*********************************************************
 * Permanently Gag Player
 *
 * @param admin		The steamid of the admin
 * @param target	The client index of the target
 * @param time		The time to gag the player for, string
 * @param reason	The reason to gag the player from the server
 * @noreturn
 *********************************************************/
public Native_EBPunishLanguage(Handle plugin, int numParams) {
	PunishPlayer(0, GetNativeCell(1), PunishmentType_Gag, "1d", "[Shield] Inappropriate Language");
	efrag_PrintToChat(GetNativeCell(1), "\x08Please mind your language.");
}
/*********************************************************/


/*********************************************************
 * Permanently Mute Player
 *
 * @param admin		The steamid of the admin
 * @param target	The client index of the target
 * @param time		The time to gag the player for, string
 * @param reason	The reason to gag the player from the server
 * @noreturn
 *********************************************************/
public Native_EBPunishMicspam(Handle plugin, int numParams) {
	PunishPlayer(0, GetNativeCell(1), PunishmentType_Mute, "1d", "[Shield] Micspam");
}
/*********************************************************/


/*********************************************************/
public Native_EBIsGagged(Handle plugin, int numParams) {
	return g_bGagged[GetNativeCell(1)];
}
/*********************************************************/


/*********************************************************/
public Native_EBIsMuted(Handle plugin, int numParams) {
	return g_bMuted[GetNativeCell(1)];
}
/*********************************************************/