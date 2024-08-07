public OnPostThinkPostAnimationFix(client)
{
	new clientview = EntRefToEntIndex(g_PVMid[client]);
	if(clientview == INVALID_ENT_REFERENCE)
	{
		SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPostAnimationFix);
		//PrintToChat(client, "quitado");
		hook[client] = false;
		return;
	}
	
	int Sequence = GetEntProp(clientview, Prop_Send, "m_nSequence");
	float Cycle = GetEntPropFloat(clientview, Prop_Data, "m_flCycle");
    
	if ((Cycle < OldCycle[client]) && (Sequence == OldSequence[client]))
	{
		if(StrEqual(g_classname[client], "weapon_knife"))
		{
			switch (Sequence)
			{
				case 3: SetEntProp(clientview, Prop_Send, "m_nSequence", 4);
				case 4: SetEntProp(clientview, Prop_Send, "m_nSequence", 3);

				case 5: SetEntProp(clientview, Prop_Send, "m_nSequence", 6);
				case 6: SetEntProp(clientview, Prop_Send, "m_nSequence", 5);

				case 7: SetEntProp(clientview, Prop_Send, "m_nSequence", 8);
				case 8: SetEntProp(clientview, Prop_Send, "m_nSequence", 7);
                
				case 9: SetEntProp(clientview, Prop_Send, "m_nSequence", 10);
				case 10: SetEntProp(clientview, Prop_Send, "m_nSequence", 11); 
				case 11: SetEntProp(clientview, Prop_Send, "m_nSequence", 10);
			}
		}
		else if(StrEqual(g_classname[client], "weapon_ak47"))
		{
			switch (Sequence)
			{
				case 3:
					SetEntProp(clientview, Prop_Send, "m_nSequence", 2);
				case 2:
					SetEntProp(clientview, Prop_Send, "m_nSequence", 1);
				case 1:
					SetEntProp(clientview, Prop_Send, "m_nSequence", 3);			
			}
		}
		else if(StrEqual(g_classname[client], "weapon_mp7"))
		{
			switch (Sequence)
			{
				case 3:
				{
					SetEntProp(clientview, Prop_Send, "m_nSequence", -1);
				}
			}
		}
		else if(StrEqual(g_classname[client], "weapon_awp"))
		{
			switch (Sequence)
			{
				case 1:
				{
					SetEntProp(clientview, Prop_Send, "m_nSequence", -1);	
				}	
			}
		}
		else if(StrEqual(g_classname[client], "weapon_deagle"))
		{
			switch (Sequence)
			{
				case 3:
					SetEntProp(clientview, Prop_Send, "m_nSequence", 2);
				case 2:
					SetEntProp(clientview, Prop_Send, "m_nSequence", 1);
				case 1:
					SetEntProp(clientview, Prop_Send, "m_nSequence", 3);	
			}
		}
		//SetEntProp(clientview, Prop_Send, "m_nSequence", Sequence);
	}
	
	OldSequence[client] = Sequence;
	OldCycle[client] = Cycle;
}