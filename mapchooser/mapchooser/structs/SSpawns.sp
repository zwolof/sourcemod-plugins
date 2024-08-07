enum struct SSpawn {
    float position[3];
    float eyeangles[3];
}

enum struct SSpawns {
    ArrayList spawns[ETeam];

    void init() {
        this.spawns[ETeam_T] = new ArrayList(sizeof(SSpawn));
        this.spawns[ETeam_CT] = new ArrayList(sizeof(SSpawn));
    }

    void add(ETeam team, SSpawns spawn, int maxlen) {
        this.spawns[team].PushArray(spawn, maxlen);
    }

    bool remove(ETeam team) {
        if(this.spawns[team] == null) {
            return false;
        }
        int len = this.spawns[team].Length;

        if(len < 1) {
            return false;
        }
        this.spawns[team].Erase(len-1);
        return true;
    }
}
