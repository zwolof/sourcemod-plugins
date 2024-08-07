void MC_LoadMapsFromKeyvalues(EGamemode gamemode) {

    KeyValues kv = new KeyValues("Maps");
    kv.ImportFromFile("efrag_mapchooser.txt");

    do {
        if(kv.GotoFirstSubKey(false)) {
            MC_LoadMapsFromKeyvalues(gamemode);
            kv.GoBack();
        }
        else {
            if(kv.GetDataType(NULL_STRING) != KvData_None) {
                char keyName[128];
                kv.GetSectionName(keyName, sizeof(keyName));

                SMapGroup mg;
                mg.create(keyName);
                


            }
            else {
                continue;
            }
        }
    } while(kv.GotoNextKey(false))

    // switch(gamemode) {
    //     case EGamemode_Hidenseek: {

    //     }
    //     case EGamemode_Retakes: {

    //     }
    // }
}

public bool MC_GetMapGroupType(char[] buffer, int maxlen) {
    char sMapGroup[128];

    strcopy(buffer, maxlen, sMapGroup);
}