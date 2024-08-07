enum struct Skyboxes_t {
	int _dummy;

	bool Set(int client, char[] skybox) {
		if (StrEqual(skybox, "mapdefault")) {
			//If it's default, get sv_skyname and set it to client
			char buffer[32];
			ConVar cvSkyName = FindConVar("sv_skyname");

			if(cvSkyName == INVALID_HANDLE) {
				return false;
			}

			cvSkyName.GetString(buffer, sizeof(buffer));
			cvSkyName.ReplicateToClient(client, buffer);
			return true;
		}
		ConVar cvSkyName = FindConVar("sv_skyname");
		cvSkyName.ReplicateToClient(client, skybox);
		return true;
	}

	bool Clear(int client) {
		this.Set(client, "mapdefault");
		return true;
	}
}

Skyboxes_t Skyboxes;