#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <chat-processor>

#define DB_CONNECTION "ebans"
Database g_Database = null;
// INSERT INTO `ebans_vip`(`steamid`, `rank`, `amount_donated`, `date_purchased`, `length`, `tag`, `chatcolor`, `namecolor`) VALUES ("76561198795562077", 1, 4, 1599404269300, 86400,"VIP", NULL, NULL);

public Plugin info = {
	name        = "EFRAG [VIP System]",
	author      = "zwolof",	
	description = "Advanced VIP System",
	version     = "1.0",
	url         = "www.efrag.eu"
}

enum Rank {
	Rank_None = 0,
	Rank_VIP,
	Rank_VIPPlus,
	Rank_PRO
}

// Include modules
#include "vip/globals.sp"
#include "vip/sql.sp"
#include "vip/settings.sp"
#include "vip/trails.sp"
#include "vip/tags.sp"
#include "vip/skyboxes.sp"
#include "vip/votes.sp"
#include "vip/namecolors.sp"
//#include "vip/agents.sp"
#include "vip/stocks.sp"


public void OnPluginStart() {
    RegConsoleCmd("sm_vip", Command_VIP);
    RegConsoleCmd("sm_settings", Command_Settings);
    HookEvent("player_disconnect", Event_OnPlayerDisconnect, EventHookMode_Pre); 
    HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post); 

    Database.Connect(SQL_ConnectCallback, DB_CONNECTION);
}

public void SQL_ConnectCallback(Database db, const char[] error, any data)
{
	if(db == null) {
		LogError("T_Connect returned invalid Database Handle");
		return;
	}
	g_Database = db;
}

public void OnMapStart() {
    LoadSkyboxes();
}

public void Event_OnPlayerDisconnect(Event event, const char[] sName, bool bDontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(IsValidClient(client)) {
        Settings[client].SaveSettings();
    }
}

public void Event_OnPlayerSpawn(Event event, const char[] sName, bool bDontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(IsValidClient(client)) {
        if(Settings[client].skybox == -1) {
            SetSkybox(client, "default");
        }
        else SetSkybox(client, g_sSkyboxes[Settings[client].skybox][0])
    }
}

public void OnClientPostAdminCheck(int client) {
	if(IsValidClient(client)) {
        // Set Client UserId
		Donor[client].id = client;
		Settings[client].id = client;

        // Reset Variables
		Donor[client].Init();
		Settings[client].Init();

        // Get VIP Status FROM db
        Donor[client].Get();
	}
}

public Action Command_VIP(int client, int args) {
    if(args > 0) return Plugin_Handled;
    if(Donor[client].rank != Rank_None) {
        CreateMainMenu(client, 0);
    }
    return Plugin_Handled;
}

public Action Command_Settings(int client, int args) {
    if(args > 0) return Plugin_Handled;
    if(Donor[client].rank != Rank_None) {
        Settings[client].GetSettings();
    }
    return Plugin_Handled;
}

public Action CreateMainMenu(int client, int args)
{
	Menu menu = new Menu(MainMenuHandler);	
	FormatMenuTitle(menu, "Main Menu");
	
	menu.AddItem("trails", 		"Trails");
	menu.AddItem("skybox", 		"Skyboxes");
	menu.AddItem("tags", 		"Tags");
	menu.AddItem("votes", 		"Votes", ITEMDRAW_DISABLED);
	//menu.AddItem("scoremoji",	"Scoremojis");
	menu.AddItem("namecolors", 	"Name Colors\n ");
	menu.AddItem("settings", 	"Settings");
	
	menu.ExitButton = true;
	menu.ExitBackButton = false;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int MainMenuHandler(Menu menu, MenuAction aAction, int client, int option)
{
    char sItem[64];
	menu.GetItem(option, sItem, sizeof(sItem));
	
    switch(aAction) {
        case MenuAction_Select: {
            if(StrEqual(sItem, "trails", false)) {
                CreateTrailsMenu(client, 0);
            }
            else if(StrEqual(sItem, "skybox", false)) { 
                CreateSkyboxMenu(client, 0); 
            }
            else if(StrEqual(sItem, "tags", false)) { 
                CreateTagsMenu(client, 0); 
            }
            else if(StrEqual(sItem, "votes", false)) { 
                CreateVoteMenu(client, 0); 
            }
            //else if(StrEqual(sItem, "scoremoji", false)) { 
            //    CreateScoremojiMenu(client, 0); 
            //}
            else if(StrEqual(sItem, "namecolors", false)) { 
                CreateNamecolorMenu(client, 0); 
            }
            else if(StrEqual(sItem, "settings", false)) { 
                CreateSettingsMenu(client, 0); 
            }
        }
        case MenuAction_End: {
            delete menu;
        }
    }
}

public Action CP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors)
{
	char sNewName[MAXLENGTH_NAME], sNewMessage[MAXLENGTH_MESSAGE];
	
    if(Donor[author].rank != Rank_None) {
        int nc = Settings[author].namecolor;
        int tag = Settings[author].tag;
        
        if(nc == -1) {
            if(!Settings[author].toggle_tag) {
                Format(sNewName, MAXLENGTH_NAME, "\x03%s", name);
            }
            else Format(sNewName, MAXLENGTH_NAME, "\x01[%s%s\x01] \x03%s", g_sTags[tag][1], g_sTags[tag][0], name);
        }
        else if(nc != -1)
        {
            if(!Settings[author].toggle_tag) {
                Format(sNewName, MAXLENGTH_NAME, "%s%s", g_sColors[nc][1], name);
            }
            else Format(sNewName, MAXLENGTH_NAME, "\x01[%s%s\x01] %s%s", g_sTags[tag][1], g_sTags[tag][0], g_sColors[nc][1], name);
            //Format(sNewName, MAXLENGTH_NAME, "\x01[%s%s\x01] %s%s", g_sTags[tag][1], g_sTags[tag][0], g_sColors[nc][1], name);
        }
    }
	else Format(sNewName, MAXLENGTH_NAME, "\x03%s", name);
	
	static char sPassedName[MAXLENGTH_NAME];
	sPassedName = sNewName;
	
    //Update the name & message
	strcopy(name, MAXLENGTH_NAME, sPassedName);
	strcopy(message, MAXLENGTH_MESSAGE, message);

	processcolors = true;
	removecolors = false;

	return Plugin_Changed;
}