char g_sRanks[][] = {
	"\x04VIP",
	"\x09VIP+",
	"\x0BPRO",
};

enum struct Donator
{
	int id;
	
	float donated;
	int expires;
	Rank rank;
	
    void Init() {
        this.rank = Rank_None;
        this.expires = GetTime();
        this.donated = 0.0;
    }
	// Methods
	void Get() {
		if(IsValidClient(this.id)) {
			char sQuery[512], sSteamId[64];
			GetClientAuthId(this.id, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

            // Query
			g_Database.Format(sQuery, sizeof(sQuery), 
            "SELECT amount_donated, rank, date_purchased, length, tag, chatcolor, namecolor FROM `%s_vip` WHERE steamid='%s' AND date_purchased+length > UNIX_TIMESTAMP() ORDER BY rank DESC LIMIT 1", DB_CONNECTION, sSteamId);
                
			g_Database.Query(SQL_GetRank_Callback, sQuery, GetClientUserId(this.id));
		}
	}
	void Set(Rank rRank) {
		if(IsValidClient(this.id)) {
			char sQuery[512], sSteamId[64];
			GetClientAuthId(this.id, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

            // Query
			g_Database.Format(sQuery, sizeof(sQuery), "UPDATE `%s_vip` SET rank = rank+1 WHERE steamid = '%s';", DB_CONNECTION, sSteamId);
			g_Database.Query(SQL_SetRank_Callback, sQuery);
		}
	}
}
enum struct ClientSettings {
    int id;

    // Settings
    int namecolor;
    int tag;
    int skybox;
    int trail;
    int vote;

	// Bool
	bool toggle_tag;
	bool toggle_trail;
	
	// Methods
    void Init() {
        this.namecolor = -1;
        this.tag = 0;
        this.skybox = -1;
        this.trail = 0;
        this.vote = 0;
		
		this.toggle_tag = true;
		this.toggle_trail = false;
    }
	
	void GetSettings() {
		if(IsValidClient(this.id)) {
			char sQuery[512], sSteamId[64];
			GetClientAuthId(this.id, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

            // Query
			g_Database.Format(sQuery, sizeof(sQuery), "SELECT toggle_tag, namecolor, tag, skybox FROM `ebans_vip` WHERE steamid = '%s' LIMIT 1;", sSteamId);
			g_Database.Query(SQL_GetSettings_Callback, sQuery, GetClientUserId(this.id));
		} 
	}
	
	void SaveSettings() {
		if(IsValidClient(this.id)) {
			char sQuery[512], sSteamId[64];
			GetClientAuthId(this.id, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

            // Query
			g_Database.Format(sQuery, sizeof(sQuery),
			"UPDATE `%s_vip` SET toggle_tag = %d, toggle_trail = %d, namecolor = %d, tag = %d, skybox = %d, trail = %d WHERE steamid = '%s';",
			DB_CONNECTION, this.toggle_tag ? 1 : 0, this.toggle_trail ? 1 : 0, this.namecolor, this.tag, this.skybox, this.trail, sSteamId);
			
			g_Database.Query(SQL_SaveSettings_Callback, sQuery);
		} 
	}
}
Donator Donor[MAXPLAYERS+1];
ClientSettings Settings[MAXPLAYERS+1];
