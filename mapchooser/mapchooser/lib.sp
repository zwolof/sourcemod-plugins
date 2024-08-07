public int MC_FindMapIndexById(int id) {
    if(g_alMaps == null) {
        return -1;
    }
    int len = g_alMaps.Length, index = -1;

    SMap map;
    for(int i = 0; i < len; i++) {
        g_alMaps.GetArray(i, map, sizeof(SMap));

        if(map.id == id) {
            index = i;
            break;
        }
    }
    return index;
}

public bool MC_GetMapCleanNameByIndex(ArrayList list, int index, char[] buffer, int maxlen) {
    if(list == null || list.Length == 0) {
        return false;
    }
    SMap map; list.GetArray(index, map, sizeof(SMap));

    return (strcopy(buffer, maxlen, map.cleanname));
}

public bool MC_HasClientVoted(int client) {
    SVote vote;

    char sSteamId[64];
    GetClientAuthId(client, AuthId_SteamID64, sSteamId, sizeof(sSteamId));

    for(int i = 1; i <= MaxClients; i++) {
        if(IsClientInGame(i) && !IsFakeClient(i)) {
            g_alVotes.GetArray(i, vote, sizeof(SVote));

            if(StrEqual(sSteamId, vote.steamid, false)) {
                return true;
            }
        }
    }
    return false;
}

public int MC_GetMapVoteCount(const char[] filename) {
    int votes = 0, length = g_alVotes.Length;

    SVote vote;
    for(int i = 0; i < length; i++) {
        g_alVotes.GetArray(i, vote, sizeof(SVote));

        if(StrEqual(vote.map.filename, filename, false)) {
            votes++;
        }
    }
    return votes;
}

public bool MC_IsDonator(int client) {
    return true;
}

public int MC_Vote(int client, char[] map) {
    SVote vote;

    SMap _map;

    int idx = MC_FindMapIndexByFilename(map);
    g_alMaps.GetArray(idx, _map, sizeof(SMap));

    vote.map = _map;
    // strcopy(vote.map, SVote::map, map)
    vote.count = (MC_IsDonator(client)) ? 2 : 1;

    char steamid[64];
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
    strcopy(vote.steamid, SVote::steamid, steamid);

    if(!MC_HasClientVoted(client)) {
        g_alVotes.PushArray(vote, sizeof(SVote));
    }
}

public int MC_FindMapByPartionalString(char[] partial, char[] buffer, int maxlen) {
    if(g_alMaps == null) {
        return -1;
    }
    int len = g_alMaps.Length;

    SMap map;
    for(int i = 0; i < len; i++) {
        g_alMaps.GetArray(i, map, sizeof(SMap));

        bool containsFilename = (StrContains(map.filename, partial, false) != -1);
        bool containsCleanname = (StrContains(map.cleanname, partial, false) != -1);

        if(containsFilename || containsCleanname) {
            strcopy(buffer, maxlen, map.cleanname);
            return i;
        }
    }
    return -1;
}

public int MC_FindMapIndexByFilename(char[] filename) {
    if(g_alMaps == null) {
        return -1;
    }
    int len = g_alMaps.Length, index = -1;

    SMap map;
    for(int i = 0; i < len; i++) {
        g_alMaps.GetArray(i, map, sizeof(SMap));

        if(StrEqual(filename, map.filename, false)) {
            index = i;
            break;
        }
    }
    return index;
}

public int MC_FindMapIndexByMapId(ArrayList list, int id) {
    if(list == null) {
        return -1;
    }
    int len = list.Length;

    SMap map;
    for(int i = 0; i < len; i++) {
        list.GetArray(i, map, sizeof(SMap));

        if(map.id == id) {
            return i;
        }
    }
    return -1;
}

public int MC_FindMapIdByIndex(ArrayList list, int index) {
    if(list == null) {
        return -1;
    }
    int len = list.Length;

    SMap map; list.GetArray(index, map, sizeof(SMap));
    return map.id;
}

public bool MC_GetMapCleanName(char[] filename, char[] buffer, int maxlen) {
    if(g_alMaps == null) {
        return -1;
    }
    int len = g_alMaps.Length, id = -1;

    SMap map;
    for(int i = 0; i < len; i++) {
        g_alMaps.GetArray(i, map, sizeof(SMap));

        if(StrEqual(filename, map.filename, false)) {
            strcopy(buffer, maxlen, map.cleanname);
            return true;
        }
    }
    return false;
}

int MC_GetMapvoteWinnerIndex() {
    return MC_GetBiggestIntIndexFromArray(g_iVoteCount, g_alMaps_Random.Length);
}

int SummarizeIntArray(int[] arr, int len) {
    int max = -1;
    for(int i = 0; i < len; i++) {
        max += arr[i];
    }
    return max;
}

int MC_GetBiggestIntFromArray(int[] arr, int len) {
    int max = 0;
    for(int i = 0; i < len; i++) {
        if(arr[i] > max) {
            max = arr[i];
        }
    }
    return max;
}

int MC_GetBiggestIntIndexFromArray(int[] arr, int len) {
    int max = 0;
    for(int i = 0; i < len; i++) {
        if(arr[i] > max) {
            max = i;
        }
    }
    return max;
}

bool MC_IsMapNominated(int mapIndex) {
    if(g_alMaps.Length == 0) return false;

    for(int i = 1; i <= MaxClients; i++) {
        if(IsClientInGame(i) && !IsFakeClient(i)) {
            if(g_iNomination[i] == mapIndex) {
                return true;
            }
        }
    }
    return false;
}

bool MC_SortMapsByVotes(ArrayList sorted) {

}

bool MC_IsMapRecentlyPlayed(char[] filename) {

    if(g_alRecentlyPlayed.Length == 0) return false;
    
    for(int i = 0; i < g_alRecentlyPlayed.Length; i++) {
        RecentlyPlayed played;
        g_alRecentlyPlayed.GetArray(i, played, sizeof(RecentlyPlayed));

        if(StrEqual(filename, played.filename, false)) {
            return true;
        }
    }
    return false;
}

bool MC_ArrayHasValue(int[] arr, int len, int value) {
    for(int i = 0; i < len; i++) {
        if(arr[i] == value) {
            return true;
        }
    }
    return false;
}