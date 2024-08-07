#if defined _efrag_included_
#endinput
#endif
#define _efrag_included_

#define GAMEUNITS_TO_METERS	0.01905
#define PLUGIN_PREFIX " \x01\x04\x01[\x0Fefrag.gg\x01] "

// General community stuff
native bool efrag_GetMenuTitle(char[] str, int maxlen);
native bool efrag_GetChatPrefix(char[] str, int maxlen);

// Server related
native int efrag_GetServerId();

// Player related
native int efrag_GetPlayerId(const char[] steamid);
native int efrag_GetPunishmentCount(const char[] steamid);
native bool efrag_IsPlayerVerified(const char[] steamid);

// Credits
native bool efrag_GetPlayerCredits(const char[] steamid);
native bool efrag_AddPlayerCredits(const char[] steamid, int amount);


void efrag_PrintToChat(int client, char[] message, any ...) {
	
	char sChatPrefix[128];
	efrag_GetChatPrefix(sChatPrefix, sizeof(sChatPrefix));

    if(client && IsClientInGame(client) && !IsFakeClient(client)) {
        char szBuffer[PLATFORM_MAX_PATH], szNewMessage[PLATFORM_MAX_PATH];
        Format(szBuffer, sizeof(szBuffer), "%s\x08%s", sChatPrefix, message);
        VFormat(szNewMessage, sizeof(szNewMessage), szBuffer, 3);

        Handle hBf = StartMessageOne("SayText2", client, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
		if(hBf != null) {
			if(GetUserMessageType() == UM_Protobuf) {
				Protobuf hProtoBuffer = UserMessageToProtobuf(hBf);
				hProtoBuffer.SetInt("ent_idx", client);
				hProtoBuffer.SetBool("chat", true);
				hProtoBuffer.SetString("msg_name", szNewMessage);
				hProtoBuffer.AddString("params", "");
				hProtoBuffer.AddString("params", "");
				hProtoBuffer.AddString("params", "");
				hProtoBuffer.AddString("params", "");
			}
			else {
				BfWrite hBfBuffer = UserMessageToBfWrite(hBf);
				hBfBuffer.WriteByte(client);
				hBfBuffer.WriteByte(true);
				hBfBuffer.WriteString(szNewMessage);
			}
		}
		EndMessage();
    }
}

void efrag_ChatAll(char[] message, any ...) {
    char szBuffer[PLATFORM_MAX_PATH], szNewMessage[PLATFORM_MAX_PATH];
    Format(szBuffer, sizeof(szBuffer), "\x08%s", message);
    VFormat(szNewMessage, sizeof(szNewMessage), szBuffer, 2);

    for(int i = 1; i <= MaxClients; i++) {
        if(IsClientInGame(i) && !IsFakeClient(i)) {
            efrag_PrintToChat(i, "%s", szNewMessage);
        }
    }
}

// Stocks
enum Strafe_t {
    STRF_INVALID = 0,
    STRF_LEFT,
    STRF_RIGHT
};

stock Strafe_t efrag_GetStrafeDir(float yaw, float prevyaw, float grace = 5.0) {
    float delta = yaw - prevyaw;
    
    if (delta == 0.0) return STRF_INVALID;

    float min = -180.0 + grace;
    float max = 180.0 - grace;
        
    if(delta > 0.0) {
        return (yaw > max && prevyaw < min) ? STRF_RIGHT : STRF_LEFT;
    }
    else {
        return (yaw < min && prevyaw > max) ? STRF_LEFT : STRF_RIGHT;
    }
}

stock float Math_UnitsToMeters(float units) {
	return (units * GAMEUNITS_TO_METERS);
}
