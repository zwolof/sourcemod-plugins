/////////////////////////////////////////
/////////////   STOCKS   ////////////////
/////////////////////////////////////////
stock void EF_Print(int client, char[] szMessage, any ...)
{
	if(client && IsClientInGame(client) && !IsFakeClient(client))
	{
		char szBuffer[PLATFORM_MAX_PATH], szNewMessage[PLATFORM_MAX_PATH];
        Format(szBuffer, sizeof(szBuffer), " \x01\x04\x01[\x0F☰  FRAG\x01] \x08%s", szMessage);
        VFormat(szNewMessage, sizeof(szNewMessage), szBuffer, 3);

		Handle hBf = StartMessageOne("SayText2", client, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
		if(hBf != null)
		{
			if(GetUserMessageType() == UM_Protobuf)
			{
				Protobuf hProtoBuffer = UserMessageToProtobuf(hBf);
				hProtoBuffer.SetInt("ent_idx", client);
				hProtoBuffer.SetBool("chat", true);
				hProtoBuffer.SetString("msg_name", szNewMessage);
				hProtoBuffer.AddString("params", "");
				hProtoBuffer.AddString("params", "");
				hProtoBuffer.AddString("params", "");
				hProtoBuffer.AddString("params", "");
			}
			else
			{
				BfWrite hBfBuffer = UserMessageToBfWrite(hBf);
				hBfBuffer.WriteByte(client);
				hBfBuffer.WriteByte(true);
				hBfBuffer.WriteString(szNewMessage);
			}
		}
		EndMessage();
	}
}

stock void EF_PrintAll(char[] szMessage, any ...)
{
	for(int client = 1; client <= MaxClients; client++) {
		if(client && IsClientInGame(client) && !IsFakeClient(client))
		{
			char szBuffer[PLATFORM_MAX_PATH], szNewMessage[PLATFORM_MAX_PATH];
			Format(szBuffer, sizeof(szBuffer), " \x01\x04\x01[\x0F☰  FRAG\x01] \x08%s", szMessage);
			VFormat(szNewMessage, sizeof(szNewMessage), szBuffer, 3);

			Handle hBf = StartMessageOne("SayText2", client, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
			if(hBf != null)
			{
				if(GetUserMessageType() == UM_Protobuf)
				{
					Protobuf hProtoBuffer = UserMessageToProtobuf(hBf);
					hProtoBuffer.SetInt("ent_idx", client);
					hProtoBuffer.SetBool("chat", true);
					hProtoBuffer.SetString("msg_name", szNewMessage);
					hProtoBuffer.AddString("params", "");
					hProtoBuffer.AddString("params", "");
					hProtoBuffer.AddString("params", "");
					hProtoBuffer.AddString("params", "");
				}
				else
				{
					BfWrite hBfBuffer = UserMessageToBfWrite(hBf);
					hBfBuffer.WriteByte(client);
					hBfBuffer.WriteByte(true);
					hBfBuffer.WriteString(szNewMessage);
				}
			}
			EndMessage();
		}
	}
}

void FormatMenuTitle(Menu hMenu, char[] szFormat, any ...)
{
	char sTitle[192];
	FormatEx(sTitle, sizeof(sTitle), " ☰FRAG VIP\n  ⊳ %s      \n▬▬▬▬▬▬▬▬▬▬▬▬", szFormat);
	hMenu.SetTitle(sTitle);
}

public void SetSkybox(int client, char[] skybox) {
	ConVar SkyName = FindConVar("sv_skyname");
	
	if (StrEqual(skybox, "mapdefault")) {
		char buffer[32];
		GetConVarString(SkyName, buffer, sizeof(buffer));
		SendConVarValue(client, SkyName, buffer);
		
		return;
	}
	SendConVarValue(client, SkyName, skybox);
}

stock bool IsValidClient(int client) {
    return ((1 <= client <= MaxClients) && IsClientInGame(client) && !IsFakeClient(client));
}
/////////////////////////////////////////