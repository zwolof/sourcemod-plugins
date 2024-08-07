/////////////////////////////////////////
///////////////   SQL   /////////////////
/////////////////////////////////////////
public int SQL_SetRank_Callback(Database db, DBResultSet results, const char[] szError, any data)
{
	if(db == null || results == null) {
		PrintToChatAll("[SQL] Update Query failure: %s", szError);
		return;
	}
}

public int SQL_SaveSettings_Callback(Database db, DBResultSet results, const char[] szError, any data)
{
	if(db == null || results == null) {
		PrintToChatAll("[SQL] Update Query failure: %s", szError);
		return;
	}
	else PrintToServer("UPDATED");
}

public int SQL_GetRank_Callback(Database db, DBResultSet results, const char[] szError, int userid)
{	
	int client = GetClientOfUserId(userid); if(client == 0) return;
	
	if(db == null || results == null) {
		PrintToChatAll("[SQL] Fetch Check Query failure: %s", szError);
		return;
	}
	else if(results.RowCount == 1) {
		if(IsValidClient(client)) {
			int amount_donated, vip_rank, date_purchased, length;
			
			results.FieldNameToNum("amount_donated", amount_donated);
			results.FieldNameToNum("rank", vip_rank);
			results.FieldNameToNum("date_purchased", date_purchased);
			results.FieldNameToNum("length", length);
			
			if(results.FetchRow())
			{
				Donor[client].donated = results.FetchInt(amount_donated);
				Donor[client].rank = view_as<Rank>(results.FetchInt(vip_rank));
				Donor[client].expires = results.FetchInt(date_purchased)+results.FetchInt(length);
				
				CreateTimer(5.0, Timer_GivePerks, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public int SQL_GetSettings_Callback(Database db, DBResultSet results, const char[] szError, int userid)
{	
	int client = GetClientOfUserId(userid); if(client == 0) return;
	
	if(db == null || results == null) {
		LogError("[SQL] Fetch Check Query failure: %s", szError);
		return;
	}
	else
	{
		//PrintToChatAll("1");
		if(IsValidClient(client)) {
			//PrintToChatAll("2");
			int toggle_tag, namecolor, tag, skybox, trail;
			
			results.FieldNameToNum("toggle_tag", toggle_tag);
			results.FieldNameToNum("namecolor", namecolor);
			results.FieldNameToNum("tag", tag);
			results.FieldNameToNum("skybox", skybox);
			
			if(results.FetchRow())
			{
				//PrintToChatAll("3");
				//int temp1 = results.FetchInt(toggle_tag);
				//Settings[client].toggle_tag = temp1 == 1 ? true : false;
				
				Settings[client].namecolor = results.FetchInt(namecolor);
				//PrintToChatAll("Namecolor: \x0F%d", Settings[client].namecolor);
				
				Settings[client].tag = results.FetchInt(tag);
				//PrintToChatAll("Tag: \x0F%d", Settings[client].tag);
				
				Settings[client].skybox = results.FetchInt(skybox);
				//PrintToChatAll("Skybox: \x0F%d", Settings[client].skybox);
			}
		}
	}
}

void GiveDonatorRank(int client, char[] sFlags)
{
	int bits = ReadFlagString(sFlags);
    int flags = GetUserFlagBits(client);
    flags |= bits;
	SetUserFlagBits(client, flags);
}

public Action Timer_GivePerks(Handle tmr, any data) {
	int client = GetClientOfUserId(data);
	if(IsValidClient(client)) {
		int rank = Donor[client].rank;
        EF_Print(client, "You have received your %s perks!", g_sRanks[rank]);
		GiveDonatorRank(client, "t");
		
		Settings[client].GetSettings();
	}
	return Plugin_Continue;
}
/////////////////////////////////////////