enum DataOrigin {
    DataOrigin_API,
    DataOrigin_DB
}
int g_iCurrentRebuildStringLevel = 0;
bool g_bIsDebugging = false;

DataOrigin g_dataOrigin = DataOrigin_DB;

Database g_StoreDatabase = null
HTTPClient httpClient = null;

ArrayList g_alCategories = null;
ArrayList g_alItems = null;
ArrayList g_alInventory[MAXPLAYERS+1];
ArrayList g_alEquipped[MAXPLAYERS+1];
ArrayList g_alMarketplace = null;
ArrayList g_alBoxes = null;
ArrayList g_alClientBoxes[MAXPLAYERS+1];
//ArrayList g_alInventory = null;

Handle g_hCreditsTimer[MAXPLAYERS+1] = {null, ...};
Handle g_hOpeningTimer[MAXPLAYERS+1] = {null, ...};

#define BOX_OPENING_ANIM_COUNT 12

ConVar g_SkyName = FindConVar("sv_skyname");

char g_sDownloadsPath[128];

enum QuestionType {
    QT_Facts = 0,
    QT_Math
}
#define MAX_ITEMS 1024
#define STORE_CREDITSNAME_UC "Credits"
#define STORE_CREDITSNAME_LC "credits"
#define SOUND_HEADBOOST_DEFAULT "*efrag2022/hns/headboost_default.mp3"

bool g_bIsClientTakingQuiz[MAXPLAYERS+1][QuestionType];
bool g_bSetPriceChatHook[MAXPLAYERS+1];

int g_iChosenCategory[MAXPLAYERS+1] = {-1, ...};
int g_iChosenItem[MAXPLAYERS+1] = {-1, ...};
int g_iChosenMarketItem[MAXPLAYERS+1] = {-1, ...};
int g_iMarketItemCount[MAXPLAYERS+1] = {1, ...};
int g_iBoxOpeningAnimationState[MAXPLAYERS+1] = {BOX_OPENING_ANIM_COUNT, ...};
int g_iClientQuizAnswer[MAXPLAYERS+1] = {-1, ...};
int g_iPrecachedModel[MAX_ITEMS] = {-1, ...};

// Macro funcs
#define LoopCategories(%1) for(int %1 = 0; %1 < MAX_CATEGORIES; %1++)

int g_iEquippedItem[MAXPLAYERS+1][MAX_CATEGORIES];

// HUD
int g_iHudEntity = -1;

Handle g_hForward_OnCreditsAdded, g_hForward_OnCreditsRemoved, g_hForward_OnCategoryFetched;

char g_szOldPlayerModel[MAXPLAYERS+1][128];
char g_szEquippedChatTag[MAXPLAYERS+1][128];
char g_szEquippedClanTag[MAXPLAYERS+1][128];
char g_szEquippedNameColor[MAXPLAYERS+1][128];

int g_mhGroundEntityOffset = -1;
int g_iHeadBoostTime = 0;
int g_iHeadBoostCount[MAXPLAYERS+1][MAXPLAYERS+1];

enum IItemCategory {
	IIIItemCategory_None = 0,
	IIIItemCategory_PlayerSkin,
}

enum struct Category {
    int id;
    char name[MAX_NAME];
	char shortname[128];
}

enum BoxType {
    BoxType_Common = 0,
    BoxType_Rare,
    BoxType_Epic,
    BoxType_Legendary
}

enum struct Box {
    int entity_id;
    int owner;
    BoxType boxtype;
}

enum MoneyAction {
    MA_Add = 0,
    MA_Remove
}

enum struct IItemAttribute_t {
	char key[128];
	char value[128];
}

enum struct Item {
    int itemid;

    char name[MAX_NAME];
    int categoryid;
    int price;

	ArrayList attributes;

	void __init() {
		this.attributes = new ArrayList(sizeof(IItemAttribute_t));
	}

	void __destroy() {
		delete this.attributes;
	}
}

enum struct MarketItem {
    Item item;
    int count;

    char sSellerAuthId[128];
    char sBuyerAuthId[128];
}

enum struct Store {
    int credits;
    int userid;

    void add(int amt) {
        this.credits += amt;

        Call_StartForward(g_hForward_OnCreditsAdded);
        Call_PushCell(GetClientOfUserId(this.userid));
        Call_PushCell(amt);
        Call_Finish();
    }

    void remove(int amt) {
        this.credits -= amt;

        Call_StartForward(g_hForward_OnCreditsRemoved);
        Call_PushCell(GetClientOfUserId(this.userid));
        Call_PushCell(amt);
        Call_Finish();
    }
}
Store eStore[MAXPLAYERS+1];
Item g_ChosenItem[MAXPLAYERS+1];
int g_iChosenItemIndex[MAXPLAYERS+1];

char g_sBoxModels[1][] = { "models/efrag2022/props/lootbox/efrag_lootbox" }

char g_sFileTypes[4][] = {
	".mdl",
	".vvd",
	".phy",
	".dx90.vtx"
};

char g_sBoxMaterials[4][] = {
	"materials/efrag2022/props/lootbox/LootBox_Green.vmt",
	"materials/efrag2022/props/lootbox/LootBox_Red.vmt",
	"materials/efrag2022/props/lootbox/LootBox_Purple.vmt",
	"materials/efrag2022/props/lootbox/LootBox_Orange.vmt",
}

char g_sBoxRarities[][] = {
    "Common",
    "Rare",
    "Epic",
    "Legendary"
}

int g_iCreditsPerType[BoxType] = { 25, 20, 15, 12 }

int g_iCreditIntervalPerType[BoxType][] = {
    {10, 50},
    {20, 70},
    {30, 80},
    {50, 100}
}

char g_sBoxRarityColors[][] = {
    "\x04",
    "\x0F",
    "\x0E",
    "\x10"
}