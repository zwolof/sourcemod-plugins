Database g_Database = null;

Handle g_hChatHook[MAXPLAYERS+1];
char g_sBlipSound[PLATFORM_MAX_PATH];
bool bChatIsHooked[MAXPLAYERS+1] = {false, ...};
bool g_bIsInvisible[MAXPLAYERS+1] = {false, ...};

bool g_bMuted[MAXPLAYERS+1] = {false, ...};
bool g_bGagged[MAXPLAYERS+1] = {false, ...};


// Offsets
int g_iPlayerManager = -1;
int g_iConnectedOffset = -1;
int g_iAliveOffset = -1;
int g_iTeamOffset = -1;
int g_iPingOffset = -1;
int g_iScoreOffset = -1;
int g_iDeathsOffset = -1;
int g_iHealthOffset = -1;
    

// Enums
enum PunishmentType_t {
	PunishmentType_Ban = 0,	
	PunishmentType_Mute,	
	PunishmentType_Gag,	
	PunishmentType_Silence,	
};

enum struct PunishmentData_t {
	PunishmentType_t type;
	
	int date_banned;
	int date_expire;

	char reason[128];
	char admin_name[128];
	char admin_group[128];
}

// Structs
enum struct Punishment_t {
	char name[128];
	char steamid[64];
}
Punishment_t g_Punishment[MAXPLAYERS+1];
