enum struct SPlayer {
    int client;
    int nominationIdx;
    bool hasVoted;
    bool hasRTVd;

    bool init(int client) {
        this.client = client;
        this.nominationIdx = -1;
        this.hasVoted = false;
        this.hasRTVd = false;
        
        if(!this.valid()) {
            return false;
        }
        return true;
    }

    bool valid() {
        return ((0 < this.client <= MaxClients) && IsClientInGame(this.client) && !IsFakeClient(this.client));
    }
}