// Base Includes
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <ripext>
#include <fpvm_interface>
#include <chat-processor>
#include <efrag>

#pragma tabsize 0

// Plugin Info
#define PLUGIN_NAME                     "efrag.gg | Store System"
#define PLUGIN_DESCRIPTION              "Dynamic Store System with a NodeJS Backend"
#define PLUGIN_VERSION                  "1.0.3"
#define PLUGIN_URL                      "www.efrag.gg"
#define PLUGIN_AUTHOR                   "zwolof"




// Globals for the plugin
#define PREFIX                          " \x01\x04\x01[\x0Fefrag.gg\x01] "


// Max Strings & Array Sizes
#define MAX_NAME                        128
#define MAX_DESCRIPTION                 128
#define MAX_FLAGS                       16
#define MAX_SELL_PERCENTAGE             0.7
#define MAX_CATEGORIES                  100


// Store Specific
#define STORE_MENUTITLE                 "efrag.gg | Store"
#define STORE_CREDITS_PER_MINUTE        5


// API Endpoints
#define API_ENDPOINT                    "http://s1.efrag.eu:3010/api/store/"
#define API_AUTHKEY                     "5ae7fdde-8132-43bc-a3a5-1a87322d2163"

// Equipped items, update, put and get
#define API_EQUIPPED_ENDPOINT           "inventory/equipped/%s"
#define API_EQUIPPED_EQUIP_ENDPOINT     "inventory/equip/%s"
#define API_EQUIPPED_UNEQUIP_ENDPOINT   "inventory/unequip/%s"

// Get Inventory, sell and buy items
#define API_INVENTORY_ENDPOINT          "inventory/%s"
#define API_INVENTORY_BUY_ENDPOINT      "inventory/buy/%s"
#define API_INVENTORY_SELL_ENDPOINT     "inventory/sell/%s"

// Used for lootboxes, fetch and update
#define API_BOXES_REMOVE_ENDPOINT       "boxes/remove/%s"
#define API_BOXES_ADD_ENDPOINT          "boxes/add/%s"
#define API_BOXES_FETCH_ENDPOINT        "boxes/get/%s"

// Used to fetch userdata such as credits
#define API_USERS_ENDPOINT              "users/%s"

// Other Endpoints
#define API_MARKETPLACE_ENDPOINT        "marketplace/%s"
#define API_ITEMS_ENDPOINT              "items"
#define API_CATEGORIES_ENDPOINT         "categories"


// Chat & Colors
#define REWARD_COLOR_ITEM               "#e3ad39"
#define REWARD_COLOR_ITEM_HEX           "\x10"
#define REWARD_COLOR_CREDITS            "#40fe40"
#define REWARD_COLOR_CREDITS_HEX        "\x04"



// Plugin Information
public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

// Include Modules
#include "store/globals.sp"
#include "store/functions.sp"

// Items
#include "store/items/animatedclantags.sp"
#include "store/items/chattags.sp"
#include "store/items/clantags.sp"
#include "store/items/namecolors.sp"
#include "store/items/playermodels.sp"
#include "store/items/customknives.sp"
#include "store/items/skyboxes.sp"

// Other
#include "store/helpers.sp"
#include "store/forwards.sp"
#include "store/hooks.sp"
#include "store/core.sp"
#include "store/api.sp"
#include "store/database.sp"
#include "store/commandhandlers.sp"
#include "store/timers.sp"
#include "store/boxes.sp"
#include "store/menus.sp"
// #include "store/playerruncmd.sp"



// #include "store/items/colors.sp"
// #include "store/items/tags.sp"
// #include "store/items/grenademodels.sp"
// #include "store/items/hats.sp"
// #include "store/items/playermodels.sp"
// #include "store/items/skyboxes.sp"
// #include "store/items/trails.sp"
// #include "store/items/particletrails.sp"

public void OnMapStart() {
    char sPath[256];

	char szLocalFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szLocalFilePath, sizeof(szLocalFilePath), "data/efrag/downloads.json");

	if(!FileExists(szLocalFilePath)) {
		SetFailState("[Store] Unable to find: %s", szLocalFilePath);
		return;
	}
	JSONArray jArray = JSONArray.FromFile(szLocalFilePath);

	int len = jArray.Length;

	bool runDownloads = true;
	if(len == 0) {
		runDownloads = false;
		PrintToServer("[Store] Not gonna download shit");
	}

	if(runDownloads) {
		JSONObject jItem = new JSONObject();
		JSONObject jPaths = new JSONObject();
		JSONArray jMaterials = new JSONArray();
		JSONArray jModels = new JSONArray();
		PrintToServer("[Store] Created handles");

		for(int i = 0; i < len; i++) {
			jItem = jArray.Get(i);

			if(jItem.HasKey("paths")) {
				jPaths = jItem.Get("paths");
				int itemId = jItem.GetInt("item_id");

				if(jPaths.HasKey("models")) {
					jModels = jPaths.Get("models");

					for(int j = 0; j < jModels.Length; j++) {
						char szModel[128];
						jModels.GetString(j, szModel, sizeof(szModel));
						
						if(StrContains(szModel, ".mdl", false) != -1) {
							PrintToServer("[Store] Precaching: %s", szModel);	
							g_iPrecachedModel[itemId] = PrecacheModel(szModel, true);
						}

						AddFileToDownloadsTable(szModel);
						PrintToServer("[Store] Downloading Model: %i of %i", j+1, jModels.Length);
					}
				}

				if(jPaths.HasKey("materials")) {
					jMaterials = jPaths.Get("materials");

					for(int k = 0; k < jMaterials.Length; k++) {
						char szModel[128];
						jMaterials.GetString(k, szModel, sizeof(szModel));

						AddFileToDownloadsTable(szModel);
						PrintToServer("[Store] Downloading Material: %i of %i", k+1, jMaterials.Length);
					}
				}
			}
		}
		PrintToServer("[Store] Done downloading!");

		delete jArray;
		delete jItem;
		delete jModels;
		delete jModels;
		delete jPaths;
	}


	for(int type = 0; type < sizeof(g_sFileTypes); type++) {
		FormatEx(sPath, sizeof(sPath), g_sBoxModels[0]);
		FormatEx(sPath, sizeof(sPath), "%s%s", sPath, g_sFileTypes[type]);
		AddFileToDownloadsTable(sPath);
	}

	AddFileToDownloadsTable("materials/efrag2022/props/lootbox/LootBox_Green.vmt");
	AddFileToDownloadsTable("materials/efrag2022/props/lootbox/LootBox_Green.vtf");

	AddFileToDownloadsTable("materials/efrag2022/props/lootbox/LootBox_Orange.vmt");
	AddFileToDownloadsTable("materials/efrag2022/props/lootbox/LootBox_Orange.vtf");

	AddFileToDownloadsTable("materials/efrag2022/props/lootbox/LootBox_Purple.vmt");
	AddFileToDownloadsTable("materials/efrag2022/props/lootbox/LootBox_Purple.vtf");

	AddFileToDownloadsTable("materials/efrag2022/props/lootbox/LootBox_Red.vmt");
	AddFileToDownloadsTable("materials/efrag2022/props/lootbox/LootBox_Red.vtf");

	AddFileToDownloadsTable("materials/efrag2022/props/lootbox/LootBox_text.vmt");
	AddFileToDownloadsTable("materials/efrag2022/props/lootbox/LootBox_text.vtf");

	// PrecacheSound(SOUND_HEADBOOST_DEFAULT, true);
	// AddFileToDownloadsTable(SOUND_HEADBOOST_DEFAULT);
}