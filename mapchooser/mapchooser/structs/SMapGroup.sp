enum struct SMapGroup {
    char name[128];
    ArrayList maps;

    void create(char[] name) {
        strcopy(this.name, 128, name);
        this.maps = new ArrayList(sizeof(SMap));
        this.maps.Clear();
    }

    bool add(SMap map) {
        int idx = this.maps.PushArray(map, sizeof(SMap));

        return !(idx == -1);
    }

    bool remove(const char[] map) {
        if(this.maps == null) return false;

        int len = this.maps.Length, index = -1;
        
        SMap m;
        for(int i = 0; i < len; i++) {
            this.maps.GetArray(i, m, sizeof(SMap));
            if(StrEqual(map, m.filename, false)) {
                index = i;
                break;
            }
        }

        if(index != -1) {
            this.maps.Erase(index);
            return true;
        }
        return false;
    }
}
