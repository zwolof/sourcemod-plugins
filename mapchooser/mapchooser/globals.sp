#define PLUGIN_PREFIX " \x01\x04\x01[\x0Fefrag.gg\x01] "
#define MC_MIN_ROCKTHEVOTE_PERCENTAGE 0.6
#define MAX_MAPS_IN_VOTE 5
#define COOLSYMBOL_TO_INDICATE_NOMINATED "> "
#define MIN_ROUNDS_TIL_RTV 4
#define MAX_MAPS 100

// Database
Database g_Database = null;

// Arraylists
ArrayList g_alMaps = null;
ArrayList g_alNominations = null;
ArrayList g_alMapGroups = null;
ArrayList g_alVotes = null;
ArrayList g_alMaps_Random = null;
ArrayList g_alRecentlyPlayed = null;

// Booleans
bool g_bRockTheVote[MAXPLAYERS+1];
bool g_bShouldShowVoteResultsMenu[MAXPLAYERS+1];
// bool g_bVoteInProgress = false;
bool g_bIsRTVAllowed = false;
bool g_bIsVoteDone = false;
bool g_bHasPrintedRTVMessage = false;

// Ints
int g_iRockTheVotes = 0;
int g_iNomination[MAXPLAYERS+1] = {-1, ...};
int g_iLastNomination[MAXPLAYERS+1] = {-1, ...};
int g_nextMapIdx = -1;
int g_iTimeToNextVote = 10;
int g_iRoundsPlayed = 0;
int g_iExtendMapVotes = 0;
bool g_bShouldMapBeExtended = false;

Handle g_hForceVoteTimer = null;
Handle g_hVoteCountDownTimer = null;
int g_iVoteCountDownTimer = 1;

// StringMaps
// StringMap g_smVotes = null;

// Handles
Handle g_hCheckStateTimer = null;
Handle g_hMapvoteResultsTimer[MAXPLAYERS+1];
Handle g_hAllowRTVTimer = null;

// Menus
Menu g_mMenuMaps = null;
Menu g_MapvoteMenu = null;
Menu g_mVoteMenu = null;

// Other
SPlayer g_player[MAXPLAYERS+1];
// SSpawns g_spawns;


int g_iVoteCount[MAXPLAYERS+1] = {0, ...};

// Map Vote State
enum EState {
    EState_NULL = -1,
    EState_MapStart = 0,
    EState_Vote,
    EState_PostVote
}

enum EVoteType {
    EVoteType_HintText,
    EVoteType_Panel,
    EVoteType_ClassicHUD
}

enum struct RecentlyPlayed {
    char filename[128];
    int id;
}


enum ETeam { ETeam_T, ETeam_CT }

EState g_currentState = EState_NULL;
EVoteType g_voteType = EVoteType_Panel;
