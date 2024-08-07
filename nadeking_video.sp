#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <smlib>
#include <devzones>
#include <overlays>

char g_szFirstChallengeZoneNames[][] = {"t_spawn", "a_bombsite"};
char g_szKZRaceZoneNames[][] = {"kz_start", "kz_end"};


int g_iLaserSprite;

// NOTES
// KZ RACE Checkpoints
// Easier map

// == GUNS == 
// mp_items_prohibited 
// Ban certain guns
// Accurate timer
// Timer

// == RACE CHALLENGE == [DONE]
// After x seconds, freeze players and show distance

// == STICKER CHALLENGE ==
// Prices: cents, 50+, 500+. Bold gaps

// == BOT SOUND TEST ==
// Grab from github

// == MOLOTOV DAMAGE TEST ==
// Throw molotov, take as much HP as possible
// dead = out


public Plugin myinfo = {
	name = "[NadeKing] Last To Leave (Pros)", 
	author = "zwolof", 
	description = "Plugin for NadeKing", 
	version = "1.0.0", 
	url = "https://steamcommunity.com/profiles/76561198062332030"
};

#define NADEKING_STEAMID 	"76561197994023214"
#define ZWOLOF_STEAMID 		"76561198062332030"
#define STICKER_MDL "models/inventory_items/sticker_inspect_chall_zwolof_fix.mdl"

bool g_bBot1;
bool g_bBot2;
int g_iBot1;
int g_iBot2;
float flBot1Pos[3];
float flBot2Pos[3];
bool g_iBotShoot1 = false;
bool g_iBotShoot2 = false;
bool g_bBotsShouldShoot = false;

int g_iStartTime = -1;
int g_iTimeToCompleteChallenge[MAXPLAYERS+1] = {-1, ...};

int g_iLastToReachSite = -1;
int g_iKZRaceStartTime[MAXPLAYERS+1] = {-1, ...};
int g_iTimeToCompleteKZRace[MAXPLAYERS+1] = {-1, ...};
int g_iLastToFinishKZMap = -1;
int g_i90SecondCountDown = 90;
int g_iStickerEnts[MAXPLAYERS+1] =  { INVALID_ENT_REFERENCE, ... };

bool g_bDidFinishKZCourse[MAXPLAYERS+1] = {false, ...};
bool g_bDidReachASite[MAXPLAYERS+1] = {false, ...};
bool g_bHasPurchasedWeapon[MAXPLAYERS+1] = {false, ...};
bool g_bStickerBlock = true;
bool g_bIsEveryoneFrozen = false;
bool g_bHasStartedKZRace[MAXPLAYERS+1] = {false, ...};
bool g_bDidFinishCourse[MAXPLAYERS+1] = {false, ...};
bool g_bCanShoot = false;

Handle g_HudSyncRaceTimer = INVALID_HANDLE;
Handle g_hRaceTimer = INVALID_HANDLE;
float g_fUnitsAwayFromBombsite[MAXPLAYERS+1] = {0.0, ...};
int g_iGunTossDroppedEntity[MAXPLAYERS+1] = {-1, ...};
float g_fGunTossDroppedOrigin[MAXPLAYERS+1][3];
float g_fGunTossJumpPosition[MAXPLAYERS+1][3];

bool g_bDidGunTossJump[MAXPLAYERS+1] = {false, ...};
bool g_bGunHasLanded[MAXPLAYERS+1] = {false, ...};

enum struct IBombSurvivor_t {
	int clientIdx;
	int damage;
}

enum ChallengeZones_t {
	ChallengeZones_TSPAWN = 0,
	ChallengeZones_ASITE
}

// g_szKZRaceZoneNames, KZRaceZones_t
enum KZRaceZones_t {
	KZRaceZones_Start = 0,
	KZRaceZones_End
}

char g_szChallenges[][] = {
	"No Challenge",
	"Dust2 Blindfold Race",
	"Empty Guns",
	"Bot Sound Test",
	"Bomb Challenge",
	"Sticker Challenge",
	"KZ Race",
	"1 vs 1",
	"Molotov Damage",
	"Gun Toss",
};

enum Challenge_t {
	Challenge_NONE = 0,
	Challenge_TSPAWNRACE,
	Challenge_EMPTY_GUNS, 
	Challenge_BOTSOUND,
	Challenge_BOMB_DAMAGE,
	Challenge_STICKERS,
	Challenge_KZRACE,
	Challenge_1VS1,
	Challenge_MOLOTOV_DAMAGE,
	Challenge_GUNTOSS,

	MAX_CHALLENGES
}

enum DuelChallenges_t {
	DuelChallenges_NONE = 0,

	DuelChallenges_GRAVITY,
	DuelChallenges_THIRDPERSON,
	DuelChallenges_FOV,
	DuelChallenges_FASTAFBOII,
	DuelChallenges_AUTOBHOP,
	DuelChallenges_KNIFE,
	DuelChallenges_NORMAL1,

	DuelChallenges_VAMPIRE,

	DuelChallenges_ONE_HP_GRENADE,
	DuelChallenges_BACKWARDS,
	DuelChallenges_NORMAL2,
	DuelChallenges_ZEUS,
	DuelChallenges_GRENADEWARS,
	DuelChallenges_HEADSHOT_ONLY,

	MAX_DUEL_CHALLENGES
}

char g_szDuelChallenges[][] = {
	"No Challenge",
	"Low Gravity",
	"Thirdperson",
	"High FOV",
	"Sonic Speed",
	"Auto Bhop",
	"Knife Duel",
	"Normal Round",

	"Vampire Round",

	"5 HP Grenade Battle",
	"Backwards Round",
	"Normal Round",
	"1 HP Zeus Round",
	"Grenade Wars",
	"Headshot Only Round",
};

Challenge_t g_CurrentChallenge = Challenge_NONE;
DuelChallenges_t g_CurrentDuelChallenge = DuelChallenges_NONE;
bool g_bVampireRound = false;

#define LoopAliveClients() for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i)) 
#define LoopDeadClients() for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsPlayerAlive(i) && !IsFakeClient(i)) 
#define LoopAllClients() for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i)) 

public void OnPluginStart() {
	RegConsoleCmd("sm_challenges", Command_OpenMenu);
	RegConsoleCmd("sm_go", Command_EnableShoot);
	// RegConsoleCmd("sm_cp", Command_OpenCheckpointMenu);
	RegConsoleCmd("sm_set1v1", Command_Set1v1);

	HookEvent("weapon_fire", Event_OnWeaponFire, EventHookMode_Post);
	HookEvent("bomb_exploded", Event_OnBombExploded, EventHookMode_Post);
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_jump", Event_OnPlayerJump, EventHookMode_Post);
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_Pre);
	HookEvent("player_hurt", Event_OnEventPlayerHurt, EventHookMode_Post);
	HookEvent("buytime_ended", Event_OnBuyTimeEnded, EventHookMode_Post);

	FindConVar("bot_quota").SetInt(0);
	ServerCommand("bot_kick");

	g_bCanShoot = false;
	g_bVampireRound = false;
	g_HudSyncRaceTimer = CreateHudSynchronizer();
}

public void OnPluginEnd() {
	g_bCanShoot = false;
	g_bVampireRound = false;

	delete g_hRaceTimer;
}

public void OnMapStart() {
	PrecacheModel(STICKER_MDL);	
	AddFileToDownloadsTable("models/inventory_items/sticker_inspect_chall_zwolof_fix.vvd");
	AddFileToDownloadsTable("models/inventory_items/sticker_inspect_chall_zwolof_fix.mdl");
	AddFileToDownloadsTable("models/inventory_items/sticker_inspect_chall_zwolof_fix.dx90.vtx");	
	AddFileToDownloadsTable("models/inventory_items/sticker_inspect_chall_zwolof_fix.phy");

	g_CurrentChallenge = Challenge_NONE;
	g_CurrentDuelChallenge = DuelChallenges_NONE;
	g_iLaserSprite = PrecacheModel("materials/sprites/laserbeam.vmt");

	ServerCommand("bot_kick");

    for(int i = 1; i < MaxClients; i++)  {
        if(IsClientInGame(i)) {
            OnClientPutInServer(i);
        }
	}
}

bool g_bHasTakenMolotovDamage[MAXPLAYERS+1] = {false, ...};

int g_iHealthBeforeMolotovDamage[MAXPLAYERS+1] = {100, ...};
int g_iHealthAfterMolotovDamage[MAXPLAYERS+1] = {100, ...};
int g_iMolotovDamageTaken[MAXPLAYERS+1] = {100, ...};

public void OnClientPutInServer(int client) {
	if (IsFakeClient(client)) {
		if (g_bBot1) {
			g_iBot1 = client;
			CS_RespawnPlayer(client);
			int weapon = GivePlayerItem(client, "weapon_ak47");
			EquipPlayerWeapon(client, weapon);
			g_bBot1 = false;

			if(IsPlayerAlive(g_bBot1)) {
				Entity_SetMaxHealth(g_bBot1, 100000);
				Entity_SetHealth(g_bBot1, 100000);
			}
		}

		if (g_bBot2) {
			g_iBot2 = client;
			CS_RespawnPlayer(client);
			int weapon = GivePlayerItem(client, "weapon_m4a1");
			EquipPlayerWeapon(client, weapon);
			g_bBot2 = false;

			if(IsPlayerAlive(g_bBot2)) {
				Entity_SetMaxHealth(g_bBot2, 100000);
				Entity_SetHealth(g_bBot2, 100000);
			}
		}
	}
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost); 
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse); 
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]) {
    char classname[64];
    if(!IsValidEntity(inflictor) || !GetEdictClassname(inflictor, classname, sizeof(classname))) {
        return Plugin_Continue;
	}

	if(g_CurrentDuelChallenge == DuelChallenges_ONE_HP_GRENADE) {
		char sClassName[128];
    	GetEntityClassname(inflictor, sClassName, sizeof(sClassName));
		PrintToServer("[1v1] Inflictor: %s", sClassName);

		if((StrContains(sClassName, "grenade", false) != -1)) {
			float fOriginalDamage = damage;

			int iHealth = GetEntProp(victim, Prop_Data, "m_iHealth");

			if(iHealth <= 1) {
				damage = fOriginalDamage;
				return Plugin_Changed;
			}

			damage = 1.0;
			// SetEntityHealth(victim, iHealth-1);
			return Plugin_Changed;
		}
    }
    if(StrEqual(classname, "inferno", false) && !g_bHasTakenMolotovDamage[victim]) {
        CreateTimer(6.0, Timer_OnMolotovDamage, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);

		g_bHasTakenMolotovDamage[victim] = true;
    	return Plugin_Continue;
    }
    return Plugin_Continue;
} 

public Action Timer_OnMolotovDamage(Handle tmr, any userid) {
	int client = GetClientOfUserId(userid);

	g_bHasTakenMolotovDamage[client] = false;
	g_iMolotovDamageTaken[client] = (100 - GetClientHealth(client));

	if(!IsPlayerAlive(client) || g_iMolotovDamageTaken[client] == 0) {
		PrintToNadeKing(" \x10%N\x05 died from the molotov, rip.", client);
		// CS_RespawnPlayer(client);
		return Plugin_Stop;
	}

	PrintToChatAll(" \x10%N\x05 has taken \x10%d\x05 molotov damage.", client, g_iMolotovDamageTaken[client]);
	return Plugin_Stop;
}

public Action Command_Set1v1(int client, int args) {
	if(args > 1) {
		return Plugin_Handled;
	}
	char sArg[16];
	GetCmdArg(1, sArg, sizeof(sArg));
	int count = StringToInt(sArg);
	g_CurrentDuelChallenge = count;
	PrintToChatAll(" \x10%N\x05 has set the duel challenge to \x10%d\x05.", client, count);
	// CreateCheckpointMenu(client);
	return Plugin_Handled;	
}
public Action Command_OpenCheckpointMenu(int client, int args) {
	if(args > 0) {
		return Plugin_Handled;
	}
	// CreateCheckpointMenu(client);
	return Plugin_Handled;	
}

public Action Event_OnBuyTimeEnded(Event event, const char[] name, bool bDontBroadcast) {
	// if(g_CurrentChallenge == Challenge_EMPTY_GUNS && !g_bCanShoot) {
		// PrintToNadeKing(" \x05Buytime has ended. The round will begin in \x105\x05 seconds.");
		// CreateTimer(5.0, Timer_StartShooting, _, TIMER_FLAG_NO_MAPCHANGE);
	// }
}

public Action Timer_StartShooting(Handle tmr) {
	g_bCanShoot = true;
	PrintToChatAll(" \x10EMPTY YOUR GUNS!!!");
	return Plugin_Stop;
}

public Action Event_OnEventPlayerHurt(Event event, const char[] name, bool bDontBroadcast) {
	if(g_bVampireRound) {
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

		if (attacker == 0) {
			return Plugin_Continue;
		}

		int attackerHealth = GetEntProp(attacker, Prop_Send, "m_iHealth");
		int damage = GetEventInt(event, "dmg_health");

		if(IsClientInGame(attacker) && IsPlayerAlive(attacker) && !IsFakeClient(attacker)) {
			int GiveHealth = attackerHealth + damage;
			SetEntityHealth(attacker, GiveHealth);
		}
	}

	if(g_CurrentDuelChallenge == DuelChallenges_HEADSHOT_ONLY) {
		int victim = GetClientOfUserId(GetEventInt(event, "userid"));
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		int hitgroup = event.GetInt("hitgroup");

		if(hitgroup != 1) {
			SetEntityHealth(victim, 100);
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public void Event_OnRoundEnd(Event event, const char[] name, bool bDontBroadcast) {
	
}

public Action Event_OnRoundStart(Event event, const char[] name, bool bDontBroadcast) {
	// if(g_CurrentChallenge == Challenge_1VS1) {
	// }
	if(g_CurrentChallenge == Challenge_1VS1) {
		g_CurrentDuelChallenge++;
		FindConVar("mp_ignore_round_win_conditions").SetInt(0);
		ResetDuelConVars();

		int score_ct = GetTeamScore(CS_TEAM_CT);
		int score_tt = GetTeamScore(CS_TEAM_T);

		int winningTeam = score_ct > score_tt ? CS_TEAM_CT : CS_TEAM_T;

		int teamScoreDiff = (winningTeam == CS_TEAM_CT) ? (score_ct - score_tt) : (score_tt - score_ct);
		// PrintToChatAll(" \x05Difference: \x10%d", teamScoreDiff);

		// if(teamScoreDiff < 0) {
		// 	teamScoreDiff *= -1;
		// }

		if(teamScoreDiff > 2) {
			LoopAliveClients() {
				if(GetClientTeam(i) == winningTeam) {
					SetEntityGravity(i, 2.0);
					SetEntityHealth(i, 50);

					PrintToChatAll(" \x05%N has been given a handicap for being in the lead.", i);
				}
			}
		}

		PrintToConsoleAll("============== NADEKING LAST TO LEAVE ==============");
		PrintToConsoleAll("%s", g_szDuelChallenges[g_CurrentDuelChallenge]);
		PrintToConsoleAll("====================================================");

		PrintToChatAll(" \x10%s\x05", g_szDuelChallenges[g_CurrentDuelChallenge]);

		switch(g_CurrentDuelChallenge) {
			case DuelChallenges_GRAVITY: {
				FindConVar("sv_gravity").SetInt(200);
			}
			case DuelChallenges_THIRDPERSON: {
				FindConVar("sv_allow_thirdperson").SetInt(1);

				LoopAliveClients() {
					ClientCommand(i, "thirdperson");
				}
			}
			case DuelChallenges_FOV: {
				LoopAliveClients() {
					SetEntProp(i, Prop_Send, "m_iDefaultFOV", 120);
					SetEntProp(i, Prop_Send, "m_iFOV", 120);
				}
			}
			case DuelChallenges_FASTAFBOII: {
				LoopAliveClients() {
					SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 2.0);
				}
			}
			case DuelChallenges_AUTOBHOP: {
				FindConVar("sv_enablebunnyhopping").SetInt(1);
				FindConVar("sv_autobunnyhopping").SetInt(1);
			}
			case DuelChallenges_KNIFE: {
				FindConVar("mp_weapons_allow_map_placed").SetInt(0);

				LoopAliveClients() {
					StripSlot(i, CS_SLOT_PRIMARY);
					StripSlot(i, CS_SLOT_SECONDARY);
					StripSlot(i, CS_SLOT_GRENADE);

					int iKnife = GivePlayerItem(i, "weapon_knife");
				}
			}
			// case DuelChallenges_WALLHACK: {
			// 	PrintToChatAll("Wallhack is now enabled.");
			// }
			case DuelChallenges_VAMPIRE: {
				g_bVampireRound = true;
			}
			case DuelChallenges_ONE_HP_GRENADE: {
				FindConVar("sv_infinite_ammo").SetInt(2);
				// FindConVar("mp_weapons_allow_map_placed").SetInt(0);

				LoopAliveClients() {
					StripSlot(i, CS_SLOT_PRIMARY);
					StripSlot(i, CS_SLOT_SECONDARY);
					StripSlot(i, CS_SLOT_GRENADE);
					StripSlot(i, CS_SLOT_KNIFE);

					SetEntityHealth(i, 5);
					GivePlayerItem(i, "weapon_hegrenade");
				}
			}
			case DuelChallenges_BACKWARDS: {
				FindConVar("sv_accelerate").SetFloat(-5.0);
			}
			case DuelChallenges_ZEUS: {
				FindConVar("sv_infinite_ammo").SetInt(1);

				LoopAliveClients() {
					StripSlot(i, CS_SLOT_PRIMARY);
					StripSlot(i, CS_SLOT_SECONDARY);
					StripSlot(i, CS_SLOT_GRENADE);
					StripSlot(i, CS_SLOT_KNIFE);
					
					SetEntityHealth(i, 1);
					int taser = GivePlayerItem(i, "weapon_taser");
					Weapon_SetClips(taser, 100, 100);
				}
			}
			case DuelChallenges_GRENADEWARS: {
				FindConVar("sv_infinite_ammo").SetInt(2);

				LoopAliveClients() {
					StripSlot(i, CS_SLOT_PRIMARY);
					StripSlot(i, CS_SLOT_SECONDARY);
					StripSlot(i, CS_SLOT_GRENADE);
					StripSlot(i, CS_SLOT_KNIFE);
					
					SetEntityHealth(i, 100);
					GivePlayerItem(i, "weapon_hegrenade");
				}
			}
		}
		

		if(g_CurrentDuelChallenge == DuelChallenges_HEADSHOT_ONLY) {
			g_CurrentDuelChallenge = DuelChallenges_NONE;
		}
	}
	else if(g_CurrentChallenge == Challenge_KZRACE) {
		float fZonePosition[3];
		Zone_GetZonePosition(g_szKZRaceZoneNames[KZRaceZones_Start], false, fZonePosition);
		fZonePosition[2] -= 32.0;

		float vAng[3];
		vAng[0] = 8.267547;
		vAng[1] = -83.794586;
		vAng[2] = 0.00;

		LoopAliveClients() {
			TeleportEntity(i, fZonePosition, vAng, NULL_VECTOR);
			CreateCheckpointMenu(i);
			// PrintToChat(i, " \x10Use \x05/cp\x10 to set checkpoints.");
		}
	}
	return Plugin_Continue;
}

stock void StripSlot(int client, int slot) {
    int weapon = -1;
	while((weapon = GetPlayerWeaponSlot(client, slot)) != -1) {
		RemovePlayerItem(client, weapon);
		
		if(IsValidEntity(weapon)) {
			AcceptEntityInput(weapon, "Kill");
	    }
	}
} 

public Action OnWeaponCanUse(int client, int weapon) {
    char sClassName[128];
    GetEdictClassname(weapon, sClassName, sizeof(sClassName));

	// if(g_CurrentDuelChallenge == DuelChallenges_ONE_HP_GRENADE && !(StrContains(sClassName, "g", false) != -1)) {
	// 	// PrintToChat(client, " \x10You cannot use this weapon\x08[\x05%s\x08].", sClassName);
	// 	return Plugin_Handled;
	// }
	return Plugin_Continue;
}

void SetAmmoToOne(int client) {
	PrintToChat(client, " \x10Ammo set to 1.");
	int iActiveWpn = Client_GetActiveWeapon(client);
	Weapon_SetPrimaryClip(iActiveWpn, 1);
	Weapon_SetSecondaryClip(iActiveWpn, 1);

	Weapon_SetPrimaryAmmoCount(iActiveWpn, 1);
	Weapon_SetSecondaryAmmoCount(iActiveWpn, 120);

	Weapon_SetClips(iActiveWpn, 1, 120);
	Weapon_SetAmmoCounts(iActiveWpn, 1, 120);
}

public Action OnWeaponSwitchPost(int client, int weapon) {
	
    if(g_CurrentChallenge == Challenge_1VS1 && !g_bVampireRound) {
		// PrintToChat(client, " \x10You cannot use this weapon\x08[\x05%s\x08].", sClassName);

		switch(g_CurrentDuelChallenge) {
			case DuelChallenges_HEADSHOT_ONLY: {
				SetAmmoToOne(client);
			}
			case DuelChallenges_ONE_HP_GRENADE: {
				char sClassName[128];
				GetEdictClassname(weapon, sClassName, sizeof(sClassName));

				if(!(StrContains(sClassName, "grenade", false) != -1)) {
					// PrintToChat(client, " \x10ONEHPDECOY: You cannot use this weapon.");
					RemovePlayerItem(client, weapon);
					AcceptEntityInput(weapon, "Kill");
					ClientCommand(client, "slot4");
				}
			}
			case DuelChallenges_ZEUS: {
				char sClassName[128];
				GetEdictClassname(weapon, sClassName, sizeof(sClassName));

				PrintToChat(client, " \x10ZEUS: You cannot use %s", sClassName);
				if(!(StrContains(sClassName, "taser", false) != -1)) {
					RemovePlayerItem(client, weapon);
					AcceptEntityInput(weapon, "Kill");
					ClientCommand(client, "slot3");
				}
			}
			case DuelChallenges_KNIFE: {
				char sClassName[128];
				GetEdictClassname(weapon, sClassName, sizeof(sClassName));

				if(!IsWeaponKnife(sClassName)) {
					// PrintToChat(client, " \x10OKNIFE DUEL: You cannot use this weapon.");
					RemovePlayerItem(client, weapon);
					AcceptEntityInput(weapon, "Kill");
					ClientCommand(client, "slot3");
				}
			}
		}
		// PrintToChatAll("Current duelchallenge: \x10%d --> %s", g_CurrentDuelChallenge, g_szDuelChallenges[g_CurrentDuelChallenge]);
    }
    return Plugin_Continue;
}

bool IsWeaponKnife(const char[] sWeaponName) {
    return (StrContains(sWeaponName, "knife", false) != -1 || StrContains(sWeaponName, "bayonet", false) != -1);
}

void ResetDuelConVars() {
	g_bVampireRound = false;

	FindConVar("sv_gravity").SetInt(800);
	FindConVar("sv_allow_thirdperson").SetInt(1);
	FindConVar("sv_accelerate").SetFloat(5.5);

	FindConVar("sv_enablebunnyhopping").SetInt(0);
	FindConVar("sv_autobunnyhopping").SetInt(0);

	FindConVar("mp_halftime").SetInt(0);
	FindConVar("mp_maxrounds").SetInt(36);
	FindConVar("sv_infinite_ammo").SetInt(0);
	FindConVar("mp_weapons_allow_map_placed").SetInt(1);

	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i)) {
			ClientCommand(i, "firstperson");

			SetEntProp(i, Prop_Send, "m_iDefaultFOV", 90);
			SetEntProp(i, Prop_Send, "m_iFOV", 90);

			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
			SetEntityGravity(i, 1.0);
		}
	}
}

public Action Event_OnPlayerJump(Event event, const char[] name, bool bDontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(!Helpers_IsConnected(client)) {
		return Plugin_Continue;
	}

	if(g_CurrentChallenge == Challenge_GUNTOSS) {
		Entity_GetAbsOrigin(client, g_fGunTossJumpPosition[client]);
		g_bDidGunTossJump[client] = true;
		g_bGunHasLanded[client] = false;

		// PrintToChatAll("%N jumped", client);
	}
	return Plugin_Continue;
}

public Action CS_OnCSWeaponDrop(int client, int weapon) {
	if(IsValidEdict(weapon)) {
		char sClassName[128];
    	GetEntityClassname(weapon, sClassName, sizeof(sClassName));

		g_iGunTossDroppedEntity[client] = weapon;

		CreateTimer(4.0, Timer_GunTossChecker, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		// PrintToChatAll(" \x10%N\x05 dropped \x10%s", client, sClassName);
	}
}

public Action Timer_GunTossChecker(Handle tmr, any userid) {
	int client = GetClientOfUserId(userid);

	if(!Helpers_IsConnected(client)) {
		return Plugin_Stop;
	}

	if(g_CurrentChallenge == Challenge_GUNTOSS && g_bDidGunTossJump[client]) {
		if(IsValidEntity(g_iGunTossDroppedEntity[client])) {
			if(!g_bGunHasLanded[client]) {
				Entity_GetAbsOrigin(g_iGunTossDroppedEntity[client], g_fGunTossDroppedOrigin[client]);
				float fThrowDistance = GetVectorDistance(g_fGunTossJumpPosition[client], g_fGunTossDroppedOrigin[client]);

				PrintToChatAll(" \x05%N has tossed their gun! (distance: %.2f)", client, fThrowDistance);

				float fNewJumpOrigin[3], fNewWeaponOrigin[3];
				CopyVector(g_fGunTossJumpPosition[client], fNewJumpOrigin);
				fNewJumpOrigin[2] += 32;

				CopyVector(g_fGunTossDroppedOrigin[client], fNewWeaponOrigin);
				fNewWeaponOrigin[2] += 32;

				// Draw beam where the gun landed
				TE_SetupBeamPoints(g_fGunTossDroppedOrigin[client], fNewWeaponOrigin, g_iLaserSprite, 0, 0, 0, 1200.0, 3.0, 3.0, 1, 0.0, view_as<int>({0, 255, 0, 255}), 0);
				TE_SendToAll();

				float fMiddleOfVector[3];
				GetMiddleOfVector(fNewWeaponOrigin, fNewJumpOrigin, fMiddleOfVector);
				fMiddleOfVector[2] += 16.0;

				char sName[128];
				GetClientName(client, sName, sizeof(sName));

				int iTextEnt = CreateStickerText(sName);
				TeleportEntity(iTextEnt, fMiddleOfVector, Float:{0.0, 0.0, 0.0}, NULL_VECTOR);

				// Draw beam from jump position
				TE_SetupBeamPoints(g_fGunTossJumpPosition[client], fNewJumpOrigin, g_iLaserSprite, 0, 0, 0, 1200.0, 3.0, 3.0, 1, 0.0, view_as<int>({255, 0, 0, 255}), 0);
				TE_SendToAll();

				// Draw line from jump position to weapon position
				TE_SetupBeamPoints(fNewWeaponOrigin, fNewJumpOrigin, g_iLaserSprite, 0, 0, 0, 1200.0, 3.0, 3.0, 1, 0.0, view_as<int>({0, 0, 255, 255}), 0);
				TE_SendToAll();

				g_bGunHasLanded[client] = true;
				g_bDidGunTossJump[client] = false;
				g_iGunTossDroppedEntity[client] = -1;
			}
		}
	}
	return Plugin_Stop;
}

void GetMiddleOfVector(float vec[3], float other[3], float fResultVec[3]) {
	fResultVec[0] = (vec[0] + other[0]) / 2.0;
	fResultVec[1] = (vec[1] + other[1]) / 2.0;
	fResultVec[2] = (vec[2] + other[2]) / 2.0;
}

// GUNTOSS RIGHT POS TO WALL: 504.00, -863.00, -255.91
// GUNTOSS LEFT POS TO WALL: -504.00, -939.00, -255.91

public Action Event_OnPlayerSpawn(Event event, const char[] name, bool bDontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!Helpers_IsConnected(client)) {
		return Plugin_Continue;
	}

	ShowOverlay(client, "", 1.0);
	return Plugin_Continue;
}

public void Event_OnBombExploded(Event event, const char[] name, bool bDontBroadcast) {
	if(g_CurrentChallenge == Challenge_BOMB_DAMAGE) {
		CreateTimer(2.0, Timer_CheckAliveBombExplosion, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_CheckAliveBombExplosion(Handle tmr, any data) {
	ArrayList bombSurvivalLeaderboard = new ArrayList(sizeof(IBombSurvivor_t));

	IBombSurvivor_t bombSurvivor;
	for(int i = 1; i <= MaxClients; i++) {
		if(Helpers_IsConnected(i) && IsPlayerAlive(i)) {
			bombSurvivor.clientIdx = i;

			int initialHealth = 100;

			// int damageTaken = initialHealth - GetClientHealth(i);
			int damageTaken = GetClientHealth(i);

			// bombSurvivor.damage = damageTaken;
			bombSurvivor.damage = damageTaken;
			PrintToConsoleAll("[BOMB] %N survived with %d HEALTH", i, damageTaken);
			
			bombSurvivalLeaderboard.PushArray(bombSurvivor, sizeof(IBombSurvivor_t));
		}
	}
	bombSurvivalLeaderboard.SortCustom(BombTimerSortCallback);

	int len = bombSurvivalLeaderboard.Length;

	Panel panel = new Panel();

	char sBuffer[4096], sName[128];
 
	for(int i = 0; i < len; i++) {
		bombSurvivalLeaderboard.GetArray(i, bombSurvivor, sizeof(IBombSurvivor_t));
		GetClientName(bombSurvivor.clientIdx, sName, sizeof(sName));

		int nameLength = strlen(sName);
		for(int j = nameLength; j < 16; j++) {
			StrCat(sName, sizeof(sName), " ");
		}
		sName[15] = '\0';
		FormatEx(sBuffer, sizeof(sBuffer), "%s%dHP | %s\n", sBuffer, bombSurvivor.damage, sName);

		PrintToChatAll(" \x05%N took \x10%d\x05 damage", bombSurvivor.clientIdx, bombSurvivor.damage);
	}
	panel.SetTitle(sBuffer);
	panel.DrawItem("Close");

	for(int i = 1; i <= MaxClients; i++) {
		if(Helpers_IsConnected(i) && IsPlayerAlive(i)) {
			panel.Send(i, BombSurvivalPanelHandler, MENU_TIME_FOREVER);
		}
	}

    delete panel;
	delete bombSurvivalLeaderboard;

	return Plugin_Stop;
}

public int BombSurvivalPanelHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        PrintToConsole(client, "You selected item: %d", param2);
    }
    else if (action == MenuAction_Cancel) {
        PrintToServer("Client %d's menu was cancelled.  Reason: %d", client, param2);
    }
}

public int BombTimerSortCallback(int index1, int index2, Handle array, Handle hndl) {
	IBombSurvivor_t first; IBombSurvivor_t second;

	GetArrayArray(array, index1, first, sizeof(IBombSurvivor_t));
	GetArrayArray(array, index2, second, sizeof(IBombSurvivor_t));

	return (first.damage > second.damage);
}

public Action Event_OnWeaponFire(Event event, const char[] name, bool bDontBroadcast) {

	char sWeapon[128];
	event.GetString("weapon", sWeapon, sizeof(sWeapon));

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!Helpers_IsConnected(client)) {
		return Plugin_Continue;
	}

	if(g_CurrentDuelChallenge == DuelChallenges_HEADSHOT_ONLY) {
		StripSlot(client, CS_SLOT_GRENADE);
		GivePlayerItem(client, "weapon_decoy");
		ClientCommand(client, "slot4");
	}

	if(g_CurrentDuelChallenge == DuelChallenges_HEADSHOT_ONLY) {
		SetAmmoToOne(client);
	}
	
	if(g_CurrentChallenge == Challenge_EMPTY_GUNS) {
		int iActiveWpn = Client_GetActiveWeapon(client);
		if(iActiveWpn == INVALID_ENT_REFERENCE) {
			return Plugin_Continue;
		}

		int primary = Weapon_GetPrimaryClip(iActiveWpn);
		int reserved = GetEntProp(iActiveWpn, Prop_Send, "m_iPrimaryReserveAmmoCount");

		// stupid.. when gun is empty, for some reason it doesn't send the reserve ammo count.
		if(primary == 1 && reserved == 0) {
			PrintToChatAll(" \x05%N has used their last bullet!", client);
		}
		// PrintToConsoleAll(" [NadeMod] Primary: %d", primary);
		// PrintToConsoleAll(" [NadeMod] Reserved: %d", reserved);
	}
	return Plugin_Continue;
}

int g_CurrentValue[3];
int g_ExpectedValue[3];
int g_FadeSpeed = 2;

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int&weapon) {
	static int changedButtons[MAXPLAYERS+1] = 0;

	// if(g_CurrentChallenge == Challenge_GUNTOSS && g_bDidGunTossJump[client]) {
	// 	if(IsValidEntity(g_iGunTossDroppedEntity[client])) {
	// 		bool bIsWeaponOnGround = (GetEntityFlags(g_iGunTossDroppedEntity[client]) & FL_ONGROUND);

	// 		// PrintToChatAll("Entity is %svalid", (IsValidEntity(g_iGunTossDroppedEntity[client]) ? "" : "not "));
	// 		// PrintToChatAll("(GetEntityFlags(g_iGunTossDroppedEntity[client]) & FL_ONGROUND): %s", bIsWeaponOnGround  ? "true" : "false");
	// 		// PrintToChatAll("bIsWeaponOnGround: %s", bIsWeaponOnGround  ? "true" : "false");

	// 		if(bIsWeaponOnGround && !g_bGunHasLanded[client]) {
	// 			g_bGunHasLanded[client] = true;
	// 			g_bDidGunTossJump[client] = false;

	// 			Entity_GetAbsOrigin(g_iGunTossDroppedEntity[client], g_fGunTossDroppedOrigin[client]);

	// 			PrintToChatAll(" \x05%N has tossed their gun!", client);

	// 			float fNewJumpOrigin[3], fNewWeaponOrigin[3];
	// 			CopyVector(g_fGunTossJumpPosition[client], fNewJumpOrigin);
	// 			fNewJumpOrigin[2] += 32;

	// 			CopyVector(g_fGunTossDroppedOrigin[client], fNewWeaponOrigin);
	// 			fNewWeaponOrigin[2] += 32;

	// 			TE_SetupBeamPoints(g_fGunTossDroppedOrigin[client], fNewWeaponOrigin, g_iLaserSprite, 0, 0, 0, 1200.0, 3.0, 3.0, 1, 0.0, view_as<int>({0, 255, 0, 255}), 0);
	// 			TE_SendToAll();

	// 			TE_SetupBeamPoints(g_fGunTossJumpPosition[client], fNewJumpOrigin, g_iLaserSprite, 0, 0, 0, 1200.0, 3.0, 3.0, 1, 0.0, view_as<int>({255, 0, 0, 255}), 0);
	// 			TE_SendToAll();
	// 		}
	// 	}
	// }

	if(g_CurrentChallenge == Challenge_EMPTY_GUNS && !g_bCanShoot) {
		if(buttons & IN_ATTACK) {
			buttons &= ~IN_ATTACK;
			changedButtons[client]++;
		}

		if(buttons & IN_ATTACK2) {
			buttons &= ~IN_ATTACK2;
			changedButtons[client]++;
		}

		if(changedButtons[client] > 0) {
			changedButtons[client] = 0;
			return Plugin_Changed;
		}
	}

	if(g_CurrentChallenge == Challenge_BOTSOUND && IsFakeClient(client) && IsPlayerAlive(client)) {
		int changedButtons = 0;
		if(g_iBotShoot1 && client == g_iBot1) {
			buttons |= IN_ATTACK;
			changedButtons++;
			PrintToConsoleAll("[BOT] g_iBot1 is shooting", client);
		}

		if(g_iBotShoot2 && client == g_iBot2) {
			buttons |= IN_ATTACK;
			changedButtons++;
			PrintToConsoleAll("[BOT] g_iBot2 is shooting", client);
		}

		if(changedButtons > 0) {
			return Plugin_Changed;
		}
		return Plugin_Continue;
	}

	if(g_CurrentChallenge == Challenge_KZRACE && Helpers_IsConnected(client) && IsPlayerAlive(client)) {

		for(int idx; idx < 3; idx++) {
			if (g_ExpectedValue[idx] > g_CurrentValue[idx]) {
				if(g_CurrentValue[idx] + g_FadeSpeed > g_ExpectedValue[idx])
					g_CurrentValue[idx] = g_ExpectedValue[idx];
				else
					g_CurrentValue[idx] += g_FadeSpeed;
			}
			
			if(g_ExpectedValue[idx] < g_CurrentValue[idx]) {
				if(g_CurrentValue[idx] - g_FadeSpeed < g_ExpectedValue[idx])
					g_CurrentValue[idx] = g_ExpectedValue[idx];
				else
					g_CurrentValue[idx] -= g_FadeSpeed;
			}

			if(g_ExpectedValue[idx] == g_CurrentValue[idx]) {
				g_ExpectedValue[idx] = GetRandomInt(0, 255);
			}
		}
		
		char sHex[32];
		FormatEx(sHex, sizeof(sHex), "#%02X%02X%02X", g_CurrentValue[0], g_CurrentValue[1], g_CurrentValue[2]);

		int iCurrentTime = GetTime();

		char sTimer[128];
		if(g_iKZRaceStartTime[client] == -1) {
			FormatEx(sTimer, sizeof(sTimer), "<font color=\"%s\">Start Zone</font>", sHex);
		}
		else if(g_bDidFinishKZCourse[client]) {
			FormatEx(sTimer, sizeof(sTimer), "<font color=\"%s\">End Zone</font>\n", sHex);
			FormatEx(sTimer, sizeof(sTimer), "%sYou finished in <font color=\"%s\">%d</font> seconds!", sTimer, sHex, g_iTimeToCompleteKZRace[client]);
		}
		else {
			FormatEx(sTimer, sizeof(sTimer), "<font class=\"fontSize-l\" face=\"verdana\">Time: %d</font>", (iCurrentTime - g_iKZRaceStartTime[client]));
		}
		PrintHintText(client, sTimer);
	}
	return Plugin_Continue;
}

public Action Command_EnableShoot(int client, int args) {
	if(args > 1) {
		PrintToChat(client, "Usage: sm_go");
		return Plugin_Handled;
	}

	if(g_CurrentChallenge == Challenge_EMPTY_GUNS) {
		g_bCanShoot = true;
		PrintToChatAll(" \x10SHOOT! EMPTY YOUR GUNS!");
		return Plugin_Handled;
	}

	PrintToChat(client, " \x10This command can only be used when the empty guns challenge is active.");
	return Plugin_Handled;
}

public Action Command_OpenMenu(int client, int args) {
	if(args > 1) {
		PrintToChat(client, "Usage: sm_challenge <challenge>");
		return Plugin_Handled;
	}
	CreateMainMenu(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action CS_OnBuyCommand(int client, const char[] weapon) {
	if(g_CurrentChallenge == Challenge_EMPTY_GUNS && !g_bHasPurchasedWeapon[client]) {
		PrintToChat(client, "You can only buy one gun.");
		g_bHasPurchasedWeapon[client] = true;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action CS_OnGetWeaponPrice(int client, const char[] weapon, int &price) {
	if(g_CurrentChallenge == Challenge_EMPTY_GUNS) {
		price = !g_bHasPurchasedWeapon[client] ? 0 : 42069;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

float g_fKZRaceCheckpointOrigin[MAXPLAYERS+1][3];
float g_fKZRaceCheckpointAngles[MAXPLAYERS+1][3];
float g_fKZRaceCheckpointVelocity[MAXPLAYERS+1][3];

int g_iKZRaceCheckpointCount[MAXPLAYERS+1] = {0, ...};

stock void CreateCheckpointMenu(int client, int time = MENU_TIME_FOREVER) {

	if(g_CurrentChallenge != Challenge_KZRACE) {
		PrintToChat(client, " \x05This challenge is not active.");
		return;
	}

	Menu menu = new Menu(CheckPointMenuHandler);
	menu.SetTitle("KZ Race");

	menu.AddItem("set_checkpoint", "Set checkpoint");
	menu.AddItem("goto_checkpoint", "Go to checkpoint\n ", (g_iKZRaceCheckpointCount[client] == 0) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

	menu.ExitButton = true;
	menu.Display(client, time);
}

public int CheckPointMenuHandler(Menu menu, MenuAction action, int client, int option) {
	char sItem[32];
	menu.GetItem(option, sItem, sizeof(sItem));

	switch(action) {
		case MenuAction_Select: {
			if(StrEqual(sItem, "set_checkpoint")) {

				if(!(GetEntityFlags(client) & FL_ONGROUND)) {
					PrintToChat(client, " \x10You must be on the ground to set a checkpoint.");
					CreateCheckpointMenu(client);
					return 0;
				}

				Entity_GetAbsOrigin(client, g_fKZRaceCheckpointOrigin[client]);
				GetClientEyeAngles(client, g_fKZRaceCheckpointAngles[client]);
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", g_fKZRaceCheckpointVelocity[client]);

				g_iKZRaceCheckpointCount[client]++;
				PrintToChat(client, " \x10Checkpoint set.");
			}

			if(StrEqual(sItem, "goto_checkpoint")) {
				TeleportEntity(client, g_fKZRaceCheckpointOrigin[client], g_fKZRaceCheckpointAngles[client], g_fKZRaceCheckpointVelocity[client]);
			}
			CreateCheckpointMenu(client);
		}
		case MenuAction_End: {
			delete menu;
		}
	}
}

stock void CreateMainMenu(int client, int time = MENU_TIME_FOREVER) {
	Menu menu = new Menu(MenuHandler_MainMenu);
	menu.SetTitle("Main Menu\n");

	char sOption[64];
	FormatEx(sOption, sizeof(sOption), g_bIsEveryoneFrozen ? "Unfreeze All" : "Freeze All");
	menu.AddItem(g_bIsEveryoneFrozen ? "unfreeze" : "freeze", sOption);

	bool bIsUsingNoclip = (GetEntityMoveType(client) == MOVETYPE_NOCLIP);

	FormatEx(sOption, sizeof(sOption), "Noclip: %s\n ", bIsUsingNoclip ? "ON" : "OFF");
	menu.AddItem("toggle_noclip", sOption);
	menu.AddItem("respawn_players", "Respawn All Players");

	menu.AddItem("challenges", "Challenges\n▬▬▬▬▬▬▬▬▬▬▬▬");

	// Challenge_NONE = 0,
	// Challenge_TSPAWNRACE,
	// Challenge_EMPTY_GUNS,
	// Challenge_BOTSOUND,
	// Challenge_BOMB_DAMAGE,
	// Challenge_STICKERS,
	// Challenge_KZRACE,
	// Challenge_1VS1,
	// Challenge_MOLOTOV_DAMAGE,

	switch(g_CurrentChallenge) {
		case Challenge_TSPAWNRACE: {
			menu.AddItem("print_race_results", "Show results");
		}
		case Challenge_BOMB_DAMAGE: {
			menu.AddItem("give_bomb", "Give bomb");
		}
		case Challenge_EMPTY_GUNS: {
			// menu.AddItem("empty_guns", "Empty Guns");
			menu.AddItem("start_gun_challenge", "Start");
		}
		case Challenge_MOLOTOV_DAMAGE: {
			menu.AddItem("spawn_molotov", "Spawn molotov");
		}
		case Challenge_STICKERS: {
			menu.AddItem("spawn_stickers", "Spawn stickers");
			menu.AddItem("remove_stickers", "Remove all stickers");
			menu.AddItem("stickers_togglemotion", "Toggle motion");
		}
		case Challenge_1VS1: {
			menu.AddItem("end_round", "End round");
		}
		case Challenge_BOTSOUND: {

			char text[64];

			// Format(text, sizeof(text), "Shooting: %s", g_bBotsShouldShoot ? "ON" : "OFF");
			// menu.AddItem("bots_toggle", text);

			Format(text, sizeof(text), "Bot1 shooting: %s", g_iBotShoot1 ? "ON" : "OFF");
			menu.AddItem("bots_shoot1", text);

			Format(text, sizeof(text), "Bot2 shooting: %s\n ", g_iBotShoot2 ? "ON" : "OFF");
			menu.AddItem("bots_shoot2", text);

			menu.AddItem("bots_add1", "Add Bot1");
			menu.AddItem("bots_add2", "Add Bot2");

			menu.AddItem("bots_teleport1", "Teleport Bot1");
			menu.AddItem("bots_teleport2", "Teleport Bot2");

			menu.AddItem("bots_respawn", "Respawn");

			menu.AddItem("bots_equip", "Equip with weapons");
			menu.AddItem("bots_remove", "Remove bots");

			menu.AddItem("bots_setdistance", "Set pos");
			menu.AddItem("bots_measure", "Measure");
		}
		// case Challenge_KZRACE: {
		// 	menu.AddItem("kz_start", "Randomize");
		// }
	}

	menu.ExitButton = true;

	menu.Display(client, time);
}

stock void CreateChallengesMenu(int client, int time = MENU_TIME_FOREVER) {
	Menu menu = new Menu(MenuHandler_Challenges);
	menu.SetTitle("Challenge Menu\n");

	char sIndex[16], sBuffer[256];
	for(int i = 0; i < MAX_CHALLENGES; i++) {
		bool bIsActive = (g_CurrentChallenge == view_as<Challenge_t>(i) && !(g_CurrentChallenge == Challenge_STICKERS));
		IntToString(i, sIndex, sizeof(sIndex));

		FormatEx(sBuffer, sizeof(sBuffer), "%s%s", g_szChallenges[i], bIsActive ? " (Active)" : "");
		menu.AddItem(sIndex, sBuffer, bIsActive ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	menu.ExitButton = true;
	menu.ExitBackButton = true;

	menu.Display(client, time);
}

public int MenuHandler_MainMenu(Menu menu, MenuAction action, int client, int option) {
	char sItem[32];
	menu.GetItem(option, sItem, sizeof(sItem));

	switch(action) {
		case MenuAction_Select: {
			int iChallenge = StringToInt(sItem);

			if(StrEqual(sItem, "challenges")) {
				CreateChallengesMenu(client, MENU_TIME_FOREVER);
			}
			if(StrEqual(sItem, "end_round")) {
				CreateChallengesMenu(client, MENU_TIME_FOREVER);
			}
			if(StrEqual(sItem, "print_race_results")) {
				LoopAllClients() {
					if(Helpers_IsConnected(i)) {
						PrintToChatAll(" \x10%N\x05 was \x10%.3f\x05 units away from the bombsite!", i, g_fUnitsAwayFromBombsite[i]);
					}
				}
			}

			if(StrEqual(sItem, "respawn_players")) {
				LoopDeadClients() {
					int iTeam = GetClientTeam(i);
					if(iTeam == CS_TEAM_CT || iTeam == CS_TEAM_T) {
						CS_RespawnPlayer(i);
					}
				}
				CreateMainMenu(client, MENU_TIME_FOREVER);
			}

			if(StrEqual(sItem, "toggle_noclip")) {
				bool bIsUsingNoclip = (GetEntityMoveType(client) == MOVETYPE_NOCLIP);
				SetEntityMoveType(client, bIsUsingNoclip ? MOVETYPE_WALK : MOVETYPE_NOCLIP);

				CreateMainMenu(client, MENU_TIME_FOREVER);
			}

			if(StrEqual(sItem, "give_bomb")) {
				GivePlayerItem(client, "weapon_c4");

				CreateMainMenu(client, MENU_TIME_FOREVER);
			}

			if(StrEqual(sItem, "spawn_stickers")) {
				SpawnStickerSet(client, "4", "3", "1", "5", "2", "6");

				CreateMainMenu(client, MENU_TIME_FOREVER);
			}

			if(StrEqual(sItem, "start_gun_challenge")) {
				g_bCanShoot = true;

				LoopAllClients() {
					g_bHasPurchasedWeapon[i] = false;
				}
				FindConVar("mp_buytime").SetInt(10);
				CreateMainMenu(client, MENU_TIME_FOREVER);
			}

			if (StrEqual(sItem, "remove_stickers", false)) {
				int ent = -1;
				
				while((ent = FindEntityByClassname(ent, "prop_dynamic_override")) != INVALID_ENT_REFERENCE) {
					char targetname[MAX_NAME_LENGTH];
					GetEntPropString(ent, Prop_Data, "m_iName", targetname, sizeof(targetname));
					
					if(String_StartsWith(targetname, "STICKER_")) {
						AcceptEntityInput(ent, "Kill");
					}
				}
				
				ent = -1;
				while((ent = FindEntityByClassname(ent, "point_worldtext")) != INVALID_ENT_REFERENCE) {
					char targetname[MAX_NAME_LENGTH];
					GetEntPropString(ent, Prop_Data, "m_iName", targetname, sizeof(targetname));
					
					if(String_StartsWith(targetname, "STICKER_")) {
						AcceptEntityInput(ent, "Kill");
					}
				}
				CreateMainMenu(client, MENU_TIME_FOREVER);
			}

			if(StrEqual(sItem, "stickers_togglemotion", false)) {
				g_bStickerBlock = !g_bStickerBlock;
				PrintToChat(client, " \x0FToggled motion %s", !g_bStickerBlock ? "on" : "off");

				CreateMainMenu(client, MENU_TIME_FOREVER);
			}

			if(StrEqual(sItem, "spawn_molotov")) {
				int iEntity = CreateEntityByName("molotov_projectile");
				
				int iAimEntity = GetPlayerClientIsAimingAt(client);

				float fTargetPosition[3];
				if(1 <= iAimEntity <= MaxClients) {
					GetEntPropVector(iAimEntity, Prop_Send, "m_vecOrigin", fTargetPosition);
					fTargetPosition[2] += 32.0;
				}
				else {
					if(!GetClientAimGroundPosition(client, fTargetPosition)) {
						PrintToChat(client, " \x0FCannot find target position");
						return 0;
					}
					fTargetPosition[2] += 8.0;
				}

				TeleportEntity(iEntity, fTargetPosition, NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(iEntity); 
				AcceptEntityInput(iEntity, "InitializeSpawnFromWorld"); 

				CreateMainMenu(client, MENU_TIME_FOREVER);
			}

			if(StrEqual(sItem, "unfreeze", false) || StrEqual(sItem, "freeze", false)) {
				g_bIsEveryoneFrozen = !g_bIsEveryoneFrozen;

				for(int i = 0; i <= MaxClients; i++) {
					if(Helpers_IsConnected(i)) {
						SetEntityMoveType(i, StrEqual(sItem, "freeze", false) ? MOVETYPE_NONE : MOVETYPE_WALK);
					}
				}
				CreateMainMenu(client, MENU_TIME_FOREVER);
			}

			char sBotTeamCommand[32];
			// FormatEx(sBotTeamCommand, sizeof(sBotTeamCommand), "bot_add_%s", (GetClientTeam(client) == CS_TEAM_CT) ? "ct" : "t");
			FormatEx(sBotTeamCommand, sizeof(sBotTeamCommand), "bot_add_ct");
			
			if(StrEqual(sItem, "bots_add1")) {
				g_bBot1 = true;
				ServerCommand(sBotTeamCommand);
				FindConVar("bot_stop").SetInt(1);
				FindConVar("bot_freeze").SetInt(1);
				FindConVar("bot_zombie").SetInt(1);

				CreateMainMenu(client, MENU_TIME_FOREVER);
			}
			
			if(StrEqual(sItem, "bots_add2")) {
				g_bBot2 = true;
				ServerCommand(sBotTeamCommand);

				FindConVar("bot_stop").SetInt(1);
				FindConVar("bot_freeze").SetInt(1);
				FindConVar("bot_zombie").SetInt(1);

				CreateMainMenu(client, MENU_TIME_FOREVER);
			} 
			
			if(StrEqual(sItem, "bots_respawn"))
			{
				if (g_iBot1) CS_RespawnPlayer(g_iBot1);
				if (g_iBot2) CS_RespawnPlayer(g_iBot2);

				CreateMainMenu(client, MENU_TIME_FOREVER);
			}
			
			if(StrEqual(sItem, "bots_teleport1")) {
				float flPos[3];
				float flAng[3];
				Entity_GetAbsOrigin(client, flPos);
				Entity_GetAbsAngles(client, flAng);
				TeleportEntity(g_iBot1, flPos, flAng, NULL_VECTOR);

				CreateMainMenu(client, MENU_TIME_FOREVER);
			}
			
			if(StrEqual(sItem, "bots_teleport2")) {
				float flPos[3];
				float flAng[3];
				Entity_GetAbsOrigin(client, flPos);
				Entity_GetAbsAngles(client, flAng);
				TeleportEntity(g_iBot2, flPos, flAng, NULL_VECTOR);

				CreateMainMenu(client, MENU_TIME_FOREVER);
			}
			
			if(StrEqual(sItem, "bots_toggle")) {
				g_bBotsShouldShoot = !g_bBotsShouldShoot;
				
				int weapon = Client_GetActiveWeapon(client);
				PrintToServer("PaintKit %i", GetEntProp(weapon, Prop_Send, "m_nFallbackPaintKit"));

				CreateMainMenu(client, MENU_TIME_FOREVER);
			}
			
			if(StrEqual(sItem, "bots_equip")) {
				int iCurrentBot = g_iBot1 ? g_iBot1 : g_iBot2;
				
				if(iCurrentBot) {
					int weapon = Client_GetWeaponBySlot(iCurrentBot, CS_SLOT_SECONDARY);
					EquipPlayerWeapon(iCurrentBot, weapon);
				}
				CreateMainMenu(client, MENU_TIME_FOREVER);
			}
			
			if(StrEqual(sItem, "bots_remove")) {
				ServerCommand("bot_kick");

				CreateMainMenu(client, MENU_TIME_FOREVER);
			}
			
			if(StrEqual(sItem, "bots_shoot1")) {
				g_iBotShoot1 = !g_iBotShoot1;

				CreateMainMenu(client, MENU_TIME_FOREVER);
			}
			
			if(StrEqual(sItem, "bots_shoot2")) {
				g_iBotShoot2 = !g_iBotShoot2;

				CreateMainMenu(client, MENU_TIME_FOREVER);
			}
			
			if(StrEqual(sItem, "bots_setdistance")) {
				Entity_GetAbsOrigin(g_iBot1, flBot1Pos);
				Entity_GetAbsOrigin(g_iBot2, flBot2Pos);

				CreateMainMenu(client, MENU_TIME_FOREVER);
			}
			
			if(StrEqual(sItem, "bots_measure")) {
				float temp1[3], temp2[3];
				
				Entity_GetAbsOrigin(g_iBot1, temp1);
				Entity_GetAbsOrigin(g_iBot2, temp2);
				
				float dist1 = GetVectorDistance(temp1, flBot1Pos);
				float dist2 = GetVectorDistance(temp2, flBot2Pos);
				float total = dist1 + dist2;
				PrintToServer("[BOT] Bot1 off by %f, Bot2 off by %f, total diff %f", dist1, dist2, total);

				PrintToNadeKing_Console("============== NADEKING LAST TO LEAVE ==============");
				PrintToNadeKing_Console("[BOT] Bot1 off by %f, Bot2 off by %f, total diff %f", dist1, dist2, total);
				PrintToNadeKing_Console("====================================================");

				CreateMainMenu(client, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_End: {
			delete menu;
		}
	}
	return 0;
}

stock bool GetClientAimGroundPosition(int client, float fPosition[3]) {
    // if(!GetEntityFlags(client) & FL_ONGROUND || !GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == 0) {
    //     return false;
    // }

	float vAngles[3], fOrigin[3];
	GetClientEyePosition(client, fOrigin);
	GetClientEyeAngles(client, vAngles);
    
    TR_TraceRayFilter(fOrigin, vAngles, MASK_ALL, RayType_Infinite, TraceRayNoPlayers, client);
    if (TR_DidHit()) {
        TR_GetEndPosition(fPosition);
		return true;
    }
    return false;
}

stock bool TraceRayNoPlayers(int entity, int mask, any data){
    return !(entity == data);
}

public int MenuHandler_Challenges(Menu menu, MenuAction action, int client, int option) {
	char sItem[32];
	menu.GetItem(option, sItem, sizeof(sItem));

	switch(action) {
		case MenuAction_Select: {
			int iChallenge = StringToInt(sItem);

			switch(iChallenge) {
				case Challenge_NONE: {
					g_CurrentChallenge = Challenge_NONE;
					CreateChallengesMenu(client, MENU_TIME_FOREVER);
				}
				case Challenge_TSPAWNRACE: {
					char sCurrentMap[128];
					GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

					if(!(StrEqual(sCurrentMap, "de_dust2", false))) {
						PrintToNadeKing("You must be in Dust2 to play this challenge.");
						CreateChallengesMenu(client, MENU_TIME_FOREVER);
						return 0;
					}

					if(g_hRaceTimer != null) {
						delete g_hRaceTimer;
					}
					
					ServerCommand("sv_disable_radar 1");

					g_CurrentChallenge = Challenge_TSPAWNRACE;
					
					SetRoundConVars();

					for(int i = 0; i <= MaxClients; i++) {
						g_bDidReachASite[i] = false;
					}
					g_i90SecondCountDown = 90;
					g_hRaceTimer = CreateTimer(1.0, Timer_RaceTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

					PrintToNadeKing(" \x05%s\x05 has been selected.", g_szChallenges[iChallenge]);
				}
				case Challenge_EMPTY_GUNS: {
					g_CurrentChallenge = Challenge_EMPTY_GUNS;
					
					for(int i = 0; i <= MaxClients; i++) {
						g_bHasPurchasedWeapon[i] = false;
					}

					// 30 - CZ75 Auto
					int iProhibited[] = {
						43, // Flashbang
						44, // HE Grenade
						45, // Smoke Grenade
						46, // Molotov
						47, // Decoy Grenade
						48, // Incendiary Grenade
						30, // CZ-75 Auto
						31, // Zeus
						50, // Kevlar
						51 	// Kevlar + Helmet
					};
					char sProhibitedItems[64];
					for(int i = 0; i < sizeof(iProhibited); i++) {
						FormatEx(sProhibitedItems, sizeof(sProhibitedItems), "%s%d%s",
							sProhibitedItems,
							iProhibited[i],
							i == (sizeof(iProhibited) - 1) ? "" : ","
						);
					}
					FindConVar("mp_buy_allow_guns").SetInt(255);
					FindConVar("mp_items_prohibited").SetString("43,44,45,46,47,48,30,31,50,51");

					SetRoundConVars();

					FindConVar("mp_buy_allow_guns").SetInt(1);
					FindConVar("mp_buytime").SetInt(25);
					FindConVar("mp_buy_anywhere").SetInt(1);

					int iMaxMoney = 65535;
					FindConVar("mp_maxmoney").SetInt(iMaxMoney);
					FindConVar("mp_startmoney").SetInt(iMaxMoney);
					SetEntProp(client, Prop_Send, "m_iAccount", iMaxMoney);

					Client_SetMoney(client, iMaxMoney);

					PrintToNadeKing(" \x05%s\x05 has been selected.", g_szChallenges[iChallenge]);
				}
				case Challenge_BOMB_DAMAGE: {
					
					for(int i = 1; i <= MaxClients; i++) {
						if(Helpers_IsConnected(i) && IsPlayerAlive(i)) {
							Entity_SetMaxHealth(i, 100);
							Entity_SetHealth(i, 100);
						}
					}
					g_CurrentChallenge = Challenge_BOMB_DAMAGE;
				}
				case Challenge_STICKERS: {
					g_CurrentChallenge = Challenge_STICKERS;
					PrintToNadeKing(" \x05%s\x05 has been selected.", g_szChallenges[iChallenge]);
				}
				case Challenge_BOTSOUND: {
					g_CurrentChallenge = Challenge_BOTSOUND;
					FindConVar("bot_quota_mode").SetInt(0);
					FindConVar("sv_falldamage_scale").SetInt(0);
					FindConVar("mp_teammates_are_enemies").SetInt(1);

					PrintToNadeKing(" \x05%s\x05 has been selected.", g_szChallenges[iChallenge]);
				}
				case Challenge_KZRACE: {
					g_CurrentChallenge = Challenge_KZRACE;

					ServerCommand("mp_solid_teammates 0");
					ServerCommand("sv_airaccelerate 300");
					ServerCommand("sv_accelerate 6");
					ServerCommand("sv_friction 5.5");


					// g_szKZRaceZoneNames[KZRaceZones_Start]
					// g_szKZRaceZoneNames[KZRaceZones_Start]
					float fZonePosition[3];
					Zone_GetZonePosition(g_szKZRaceZoneNames[KZRaceZones_Start], false, fZonePosition);
					fZonePosition[2] -= 32.0;

					float vAng[3];
					vAng[0] = 8.267547;
					vAng[1] = -83.794586;
					vAng[2] = 0.00;
					LoopAliveClients() {
						TeleportEntity(i, fZonePosition, vAng, NULL_VECTOR);
						CreateCheckpointMenu(i);
						PrintToChat(i, " \x10Use \x05/cp\x10 to set checkpoints.");
					}

					PrintToNadeKing(" \x05%s\x05 has been selected.", g_szChallenges[iChallenge]);
				}
				case Challenge_1VS1: {
					g_CurrentChallenge = Challenge_1VS1;

					FindConVar("mp_maxrounds").SetInt(36);

					PrintToNadeKing(" \x05%s\x05 has been selected.", g_szChallenges[iChallenge]);
				}
				case Challenge_GUNTOSS: {
					g_CurrentChallenge = Challenge_GUNTOSS;

					FindConVar("mp_maxrounds").SetInt(36);

					float fPositionRight[3], fPositionLeft[3];
					fPositionRight[0] = 504.00;
					fPositionRight[1] = -863.00;
					fPositionRight[2] = -255.91;
					CopyVector(fPositionRight, fPositionLeft);
					fPositionLeft[1] -= 76.0;

					int vColour[4] = { 0, 0, 255, 0 };
					TE_SetupBeamPoints(fPositionRight, fPositionLeft, g_iLaserSprite, 0, 0, 0, 1200.0, 3.0, 3.0, 1, 0.0, vColour, 0);
					TE_SendToAll();
					// GUNTOSS RIGHT POS TO WALL: 504.00, -863.00, -255.91
					// GUNTOSS LEFT POS TO WALL: -504.00, -939.00, -255.91

					LoopAliveClients() {
						int iWeaponEnt = GivePlayerItem(i, "weapon_p250");
						// set the owner of iWpn to i
						SetEntPropEnt(iWeaponEnt, Prop_Send, "m_hOwnerEntity", i);
					}

					PrintToNadeKing(" \x05%s\x05 has been selected.", g_szChallenges[iChallenge]);
				}
				case Challenge_MOLOTOV_DAMAGE: {
					g_CurrentChallenge = Challenge_MOLOTOV_DAMAGE;
					LoopAllClients() {
						if(Helpers_IsConnected(i) && IsPlayerAlive(i)) {
							Entity_SetMaxHealth(i, 100);
							Entity_SetHealth(i, 100);
						}
						g_bHasTakenMolotovDamage[i] = false;
					}
					FindConVar("mp_maxrounds").SetInt(36);

					PrintToNadeKing(" \x05%s\x05 has been selected.", g_szChallenges[iChallenge]);
				}
				// Challenge_NONE = 0,
				// Challenge_TSPAWNRACE,
				// Challenge_EMPTY_GUNS,
				// Challenge_BOTSOUND,
				// Challenge_BOMB_DAMAGE,
				// Challenge_STICKERS,
				// Challenge_KZRACE,
				// Challenge_1VS1,
				// Challenge_MOLOTOV_DAMAGE,
			}
			CreateMainMenu(client, MENU_TIME_FOREVER);
		}
		case MenuAction_Cancel: {
			if(option == MenuCancel_ExitBack) {
				CreateMainMenu(client, MENU_TIME_FOREVER); // param1 is client
			}
		}
		case MenuAction_End: {
			delete menu;
		}
	}
	return 0;
}

stock void CopyVector(const float source[3], float dest[3]) {
	dest[0] = source[0];
	dest[1] = source[1];
	dest[2] = source[2];
}

int GetPlayerClientIsAimingAt(int client) {
	float vAngles[3], fOrigin[3];
	GetClientEyePosition(client,fOrigin);
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_ALL, RayType_Infinite, TraceEntityFilterPlayer, GetClientUserId(client));
		
	if(TR_DidHit(trace)) {
		int iEnt = TR_GetEntityIndex(trace);
		CloseHandle(trace);

		return iEnt;
	}
	return -1;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask, any data) {
	int client = GetClientOfUserId(data);
	return ((0 <= entity <= MaxClients) && client != entity);
} 

void ScreenFade(int iClient, int iFlags = FFADE_PURGE, const int iaColor[4] = {0, 0, 0, 0}, int iDuration = 0, int iHoldTime = 0) {
    Handle hScreenFade = StartMessageOne("Fade", iClient);
    PbSetInt(hScreenFade, "duration", iDuration * 500);
    PbSetInt(hScreenFade, "hold_time", iHoldTime * 500);
    PbSetInt(hScreenFade, "flags", iFlags);
    PbSetColor(hScreenFade, "clr", iaColor);
    EndMessage();
}

stock void SetRoundConVars() {
	FindConVar("mp_restartgame").SetInt(1);
	FindConVar("mp_ignore_round_win_conditions").SetInt(1);
	FindConVar("mp_roundtime").SetInt(60);
	FindConVar("mp_roundtime_defuse").SetInt(60);
	FindConVar("mp_roundtime_deployment").SetInt(60);
	FindConVar("mp_roundtime_hostage").SetInt(60);
	FindConVar("mp_freezetime").SetInt(0);
}

public Action Timer_RaceTimer(Handle tmr, any data) {

	if(g_i90SecondCountDown > 0) {
		g_i90SecondCountDown--;
		Race_SendHudTimerToAll();

		return Plugin_Continue;
	}

	float fZonePosition[3];
	Zone_GetZonePosition(g_szFirstChallengeZoneNames[ChallengeZones_ASITE], false, fZonePosition);

	float fOrigin[3];
	for(int i = 1; i <= MaxClients; i++) {
		if(g_bDidReachASite[i] || !Helpers_IsConnected(i)) {
			continue;
		}

		// Freeze after timer is up
		SetEntityMoveType(i, MOVETYPE_NONE);
		ShowOverlay(i, "", 1.0);
		g_bIsEveryoneFrozen = true;

		float delta[3];
		Entity_GetAbsOrigin(i, fOrigin);

		float fResult = GetVectorDistance(fOrigin, fZonePosition);
		// for(int j = 0; j < 3; i++) {
		// 	delta[j] = (fZonePosition[j] - fOrigin[j]);
		// }
		// float dxy = SquareRoot(Pow(delta[0], 2.0) + Pow(delta[1], 2.0));

		int vColour[4] = { 0, 0, 255, 255 };
		TE_SetupBeamPoints(fZonePosition, fOrigin, g_iLaserSprite, 0, 0, 0, 30.0, 3.0, 3.0, 1, 0.0, vColour, 0);
		TE_SendToAll();

		g_fUnitsAwayFromBombsite[i] = fResult;

		// PrintToNadeKing(" \x10%N was %.5f units away from the bombsite", i, fResult);
	}

	Race_ClearAllHudTimers();
	g_hRaceTimer = null;
	return Plugin_Stop;
}

void Race_SendHudTimerToAll() {
	for(int i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || IsClientSourceTV(i) || IsFakeClient(i)) {
			continue;
		}
		
		SetHudTextParams(0.0, 0.0, 99999.0, 255, 255, 255, 255);

		int iMinutes = g_i90SecondCountDown / 60;
		int iSeconds = g_i90SecondCountDown % 60;

		if(iMinutes < 1 && iSeconds < 10) {
			SetHudTextParams(0.0, 0.0, 99999.0, 255, 64, 64, 255);
		}
		
		ShowSyncHudText(i, g_HudSyncRaceTimer, "Time: %s%d:%s%d",
			iMinutes < 10 ? "0" : "",
			iMinutes,
			iSeconds < 10 ? "0" : "",
			iSeconds
		);
	}
}

void Race_ClearAllHudTimers() {
	for(int i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || IsClientSourceTV(i) || IsFakeClient(i)) {
			continue;
		}
		ClearSyncHud(i, g_HudSyncRaceTimer);
	}
}

public void Zone_OnClientEntry(int client, const char[] zone) {
	if(!Helpers_IsConnected(client) || !IsPlayerAlive(client)) {
		return;
	}

	if(StrEqual(zone, "guntoss_cheat_zone", false) && g_CurrentChallenge == Challenge_GUNTOSS && !g_bDidGunTossJump[client]) {
		PrintToNadeKing("%N jumped too late", client);
	}

	if(StrEqual(zone, g_szFirstChallengeZoneNames[ChallengeZones_ASITE], false) && g_CurrentChallenge == Challenge_TSPAWNRACE && !g_bDidReachASite[client]) {
		g_iTimeToCompleteChallenge[client] = (GetTime()-g_iStartTime);
		PrintToNadeKing(" \x10%N completed the challenge in \x05%d\x05 seconds.", client, g_iTimeToCompleteChallenge[client]);
		// ScreenFade(client, FFADE_IN|FFADE_PURGE, BLINDFOLD_COLOR, 1, RoundToFloor(1.0));
		ShowOverlay(client, "", 1.0);

		g_bDidReachASite[client] = true;
		g_iLastToReachSite = client;
	}

	if(StrEqual(zone, g_szKZRaceZoneNames[KZRaceZones_Start], false) && g_CurrentChallenge == Challenge_KZRACE && g_bHasStartedKZRace[client]) {
		g_iKZRaceStartTime[client] = -1;
		g_bHasStartedKZRace[client] = false;
		// PrintToChatAll(" \x10%N left the start zone!", client);
	}

	if(StrEqual(zone, g_szKZRaceZoneNames[KZRaceZones_End], false) && g_CurrentChallenge == Challenge_KZRACE && !g_bDidFinishKZCourse[client]) {
		g_iTimeToCompleteKZRace[client] = (GetTime() - g_iKZRaceStartTime[client]);
		g_bDidFinishKZCourse[client] = true;
		g_iLastToFinishKZMap = client;

		PrintToChatAll(" \x10%N completed the course in \x05%d\x05 seconds.",
			client,
			g_iTimeToCompleteKZRace[client]
		);
	}
}

public void Zone_OnClientLeave(int client, const char[] zone) {
	if(!Helpers_IsConnected(client) || !IsPlayerAlive(client)) {
		return;
	}

	if(StrEqual(zone, g_szFirstChallengeZoneNames[ChallengeZones_TSPAWN], false) && g_CurrentChallenge == Challenge_TSPAWNRACE) {
		g_iStartTime = GetTime();
		PrintToChatAll(" \x10%N left T-Spawn!", client, g_iTimeToCompleteChallenge[client]);


		// if(!IsNadeKing(client)) {
			ShowOverlay(client, "effects/black", 0.0);
		// }
	}

	// g_szKZRaceZoneNames, KZRaceZones_t
	// start a stopwatch whenever they leave the zone "kz_start" and end it when they enter the zone "kz_end"
	if(StrEqual(zone, g_szKZRaceZoneNames[KZRaceZones_Start], false) && g_CurrentChallenge == Challenge_KZRACE && !g_bHasStartedKZRace[client]) {
		g_iKZRaceStartTime[client] = GetTime();
		g_bHasStartedKZRace[client] = true;
		g_bDidFinishKZCourse[client] = false;
		
		PrintToConsoleAll(" \x10%N left the start zone!", client);
	}
}

#define STICKERS_MAX 6

stock void SpawnStickerSet(int client, char[] st1, char[] st2, char[] st3, char[] st4, char[] st5, char[] st6) {

	float vEyePos[3], vEyeAngles[3], vEyeFwd[3], vEyeRight[3]; // Base values
	float vEndPoint[3];
	float distance = 40.0;
	
	GetClientEyeAngles(client, vEyeAngles);
	GetClientEyePosition(client,vEyePos);
	GetAngleVectors(vEyeAngles, vEyeFwd, vEyeRight, NULL_VECTOR);
	
	for(int i = 0; i < 3; i++) {
		vEndPoint[i] = (vEyePos[i] + (vEyeFwd[i] * distance));
	}

	float flAng[3];
	MakeVectorFromPoints(vEndPoint, vEyePos, flAng);
	GetVectorAngles(flAng, flAng);
	flAng[0] = 0.0;
	
	int ents[STICKERS_MAX];
	for(int i = 0; i < STICKERS_MAX; i++) {
		vEndPoint[0] = vEyePos[0] + (vEyeRight[0] * (i * distance));
		vEndPoint[1] = vEyePos[1] + (vEyeRight[1] * (i * distance));
	
		ents[i] = CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(ents[i], "targetname", "STICKER_PROP");
		DispatchKeyValue(ents[i], "solid", "6");

		SetEntProp(ents[i], Prop_Data, "m_nSolidType", 6);

		DispatchKeyValue(ents[i], "spawnflags", "8"); 
		// SetEntProp(ents[i], Prop_Send, "m_usSolidFlags", 8);
		// SetEntProp(ents[i], Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS); //COLLISION_GROUP_DEBRIS 

		SetEntProp(ents[i], Prop_Data, "m_CollisionGroup", 5);
		SetEntityModel(ents[i], STICKER_MDL);
		DispatchSpawn(ents[i]);
		TeleportEntity(ents[i], vEndPoint, flAng, NULL_VECTOR);
		
		AcceptEntityInput(ents[i], "EnableCollision"); 
		AcceptEntityInput(ents[i], "TurnOn", ents[i], ents[i], 0);
		
		SetEntPropFloat(ents[i], Prop_Send, "m_flModelScale", 1.5); 
		
		float tempAng[3];
		float tempPos[3];
		tempPos = vEndPoint;
		tempAng = flAng;
		tempAng[1] -= 180.0;

		// new
		bool bShouldSpawnText = (i == 0 || i == 5);

		if(bShouldSpawnText) {
			int ent = CreateStickerText(i == 5 ? "high" : "low");
			tempPos[2] -= 30.0;
			TeleportEntity(ent, tempPos, tempAng, NULL_VECTOR);
		}

		char skin[12]; 
		IntToString(i+1, skin, sizeof(skin));
		DispatchKeyValue(ents[0], "skin", st1);
	}
	
	DispatchKeyValue(ents[1], "skin", st2);
	DispatchKeyValue(ents[2], "skin", st3);
	DispatchKeyValue(ents[3], "skin", st4);
	DispatchKeyValue(ents[4], "skin", st5);
	DispatchKeyValue(ents[5], "skin", st6);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2]) {
	int pressedButtons = GetEntProp(client, Prop_Data, "m_afButtonPressed");
	int releasedButtons = GetEntProp(client, Prop_Data, "m_afButtonReleased");
	
	if(pressedButtons & IN_USE) {
		//PrintToChatAll("Pressed called");
		
		int ent = GetClientAimTarget(client, false);
		if(Entity_IsValid(ent)) {
			char targetname[MAX_NAME_LENGTH];
			GetEntPropString(ent, Prop_Data, "m_iName", targetname, sizeof(targetname));
			
			if(String_StartsWith(targetname, "STICKER_")) {
				float vEntOrigin[3];
				float vOrigin[3];
				float distance;
				
				Entity_GetAbsOrigin(ent, vEntOrigin);
				Entity_GetAbsOrigin(client, vOrigin);
				distance = GetVectorDistance(vOrigin, vEntOrigin);
				
				if(distance < 250.0) {
					g_iStickerEnts[client] = EntIndexToEntRef(ent);
				}
			}
		}
		
		if(Client_IsValid(ent)) {
			if(IsFakeClient(ent)) {
				float vEntOrigin[3];
				float vOrigin[3];
				float distance;
				
				Entity_GetAbsOrigin(ent, vEntOrigin);
				Entity_GetAbsOrigin(client, vOrigin);
				distance = GetVectorDistance(vOrigin, vEntOrigin);
				
				if(distance < 250.0) {
					g_iStickerEnts[client] = EntIndexToEntRef(ent);
				}
			}
		}
	}
	
	if(releasedButtons & IN_USE) {
		g_iStickerEnts[client] = INVALID_ENT_REFERENCE;
	}
	
	if(g_iStickerEnts[client] != INVALID_ENT_REFERENCE && g_bStickerBlock) {
		int ent = EntRefToEntIndex(g_iStickerEnts[client]);

		if(Entity_IsValid(ent)) {
			// Teleport 20.0 distance away
			float vEyePos[3], vEyeFwd[3]; // Base values
			float vEndPoint[3];
			
			float distance = 70.0;
			
			GetClientEyePosition(client,vEyePos);
			GetAngleVectors(angles, vEyeFwd, NULL_VECTOR, NULL_VECTOR);
			
			vEndPoint[0] = vEyePos[0] + (vEyeFwd[0]*distance);
			vEndPoint[1] = vEyePos[1] + (vEyeFwd[1]*distance);
			vEndPoint[2] = vEyePos[2] + (vEyeFwd[2]*distance);
			
			TeleportEntity(ent, vEndPoint, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

stock int CreateStickerText(char[] message) {
	int worldtextHigh = CreateEntityByName("point_worldtext");
	DispatchKeyValue(worldtextHigh, "targetname", "STICKER_PROP");
	DispatchKeyValue(worldtextHigh, "color", "255 255 255");
	DispatchKeyValue(worldtextHigh, "textsize", "5"); 
	DispatchKeyValue(worldtextHigh, "message", message); 
	DispatchSpawn(worldtextHigh);
	
	return worldtextHigh;
}

stock bool Helpers_IsConnected(int client) {
    return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client);
}

stock bool PrintToNadeKing(const char[] message, any ...) {

	char szBuffer[256];
	VFormat(szBuffer, sizeof(szBuffer), message, 2);

	for(int i = 1; i <= MaxClients; i++) {
		if(Helpers_IsConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && IsNadeKing(i)) {
			PrintToChat(i, szBuffer);
		}
	}
}
stock bool PrintToNadeKing_Console(const char[] message, any ...) {

	char szBuffer[256];
	VFormat(szBuffer, sizeof(szBuffer), message, 2);

	for(int i = 1; i <= MaxClients; i++) {
		if(Helpers_IsConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && IsNadeKing(i)) {
			PrintToConsole(i, szBuffer);
		}
	}
}

stock bool IsNadeKing(int client) {
	char sSteamId[64];
	GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));
	
	return (StrEqual(sSteamId, NADEKING_STEAMID, false) || StrEqual(sSteamId, ZWOLOF_STEAMID, false));
}