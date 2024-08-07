#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

float g_fMultiplier = 5.0;

public Plugin myinfo = 
{
	name = "EFRAG [Flashboosting]",
	author = "zwolof",
	description = "Adds flashboosting to CS:GO",
	version = "1.0",
	url = "www.efrag.gg"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_flashvel", Command_FlashVel);
	RegConsoleCmd("sm_flash", Command_Flash);
}

public Action Command_Flash(int client, int args)
{
	GivePlayerItem(client, "weapon_flashbang");
	GivePlayerItem(client, "weapon_flashbang");
	return Plugin_Handled;
}

public Action Command_FlashVel(int client, int args)
{
	char sVel[12];
	GetCmdArg(1, sVel, sizeof(sVel));
	g_fMultiplier = StringToFloat(sVel);
	
	PrintToChatAll(" \x01\x04\x01[\x0F☰  FRAG\x01] Flashboost velocitymultiplier: \x04%d", g_fMultiplier);
	
	return Plugin_Handled;
}

public void OnClientPutInServer(int client) { SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); }
public void OnClientDisconnect(int client) { SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage); }

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	char sWeapon[32];
	if(IsValidEdict(inflictor))
	{
		GetEdictClassname(inflictor, sWeapon, 32);
		if(StrContains(sWeapon, "flashbang", false) != -1)
		{
			Flashboost(victim, inflictor);
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

stock void Flashboost(int client, int weapon)
{
	float fVictimVel[3], fVictimOri[3], fAttackerOri[3];				
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVictimVel);
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", fVictimOri);
	GetEntPropVector(weapon, Prop_Send, "m_vecOrigin", fAttackerOri);
	
	int owner = GetEntPropEnt(weapon, Prop_Send, "m_hThrower");
	
	// Debug
	//PrintToChatAll("Victim: \x04%.2f", victimOri[2]);
	//PrintToChatAll("Attacker: \x04%.2f", attackerOri[2]);
	//PrintToChatAll("Velocity: \x04%.2f", victimVel[2]);
	
	if(owner != -1)
	{
		if(fVictimOri[2] <= fAttackerOri[2] && fVictimVel[2] > 0.0)
		{
			if(GetEntityMoveType(client) != MOVETYPE_LADDER || GetEntityMoveType(client) != MOVETYPE_NOCLIP)
			{
				fVictimVel[2] *= view_as<float>(g_fMultiplier);
				
				PrintToChatAll(" \x01\x04\x01[\x0F☰  FRAG\x01] \x03%N\x08 flashboosted \x10%N\x08!", owner, client);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVictimVel);
			}
		}
	}
}

/* Stocks */
stock bool IsValidClient(int client) {
	return view_as<bool>(((1 <= client <= MaxClients) && IsClientInGame(client) && !IsFakeClient(client)));
}