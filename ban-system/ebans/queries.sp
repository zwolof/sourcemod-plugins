#define BAN_MESSAGE "\
	[efrag.gg] You are banned!\n \n \
	Reason:         %s\n \
	Admin:          %s(%s)\n \
	Expires:        %s\n \n \
	Appeal your ban over at http://efrag.gg\n \
	or purchase an unban at http://efrag.gg/store \
"

#define DB_UPDATEUSER_QUERY "\
	UPDATE `ebans_users` SET `playername`='%s', `ip`='%s', `country`='%s', `lastconnected`='%d' WHERE playerid='%d';\
"

#define DB_ADDPUNISHMENT_QUERY "\
	INSERT INTO `ebans_punishments`(\
		`player_id`, \
		`banned_by`, \
		`unbanned_by`, \
		`banned_on`, \
		`expires_on`, \
		`reason`, \
		`type`, \
		`unbanned`\
	) \
		VALUES('%d', '%d', 0, '%d','%d','%s','%d','%d'); \
"

#define DB_CHECKADMINPERMS_QUERY "\
	SELECT users.displayname, \
		groups.groupname, \
		groups.flags \
	FROM `ebans_users` users \
	INNER JOIN `ebans_servers_admins` admins ON users.playerid = admins.player_id \
	RIGHT JOIN `ebans_servers_new` servers ON admins.server_id = servers.server_id \
	LEFT JOIN `ebans_groups` groups ON users.group_id = groups.group_id \
	WHERE users.playerid = '%d' \
		AND admins.server_id = '%d' \
	LIMIT 1; \
"

#define DB_CHECKPUNISHMENT_QUERY "\
	SELECT adm.playername AS admin_name, \
       groups.groupname as admin_group, \
       bans.type, \
       bans.banned_on AS date_banned, \
       bans.expires_on AS date_expire, \
       bans.reason \
	FROM `ebans_punishments` bans \
	RIGHT JOIN `ebans_users` users ON users.playerid = bans.player_id \
	RIGHT JOIN `ebans_users` adm ON adm.playerid = bans.banned_by \
	LEFT JOIN `ebans_groups` groups ON adm.group_id = groups.group_id \
	WHERE bans.player_id IN \
		(SELECT playerid \
		FROM `ebans_users` \
		WHERE ip = \
			(SELECT ip \
			FROM `ebans_users` \
			WHERE playerid = '%d')) \
	AND bans.unbanned != 1 \
	ORDER BY `bid` DESC \
"


// SELECT a.steamid as s_steamid, 
// 		  s.server_id as s_serverid,
// 		  s.port as s_port, 
// 		  u.displayname as u_displayname, 
// 		  a.server_id as a_serverid, 
// 		  g.group_id as g_groupid, 
// 		  g.groupname as g_groupname, 
// 		  g.flags as g_flags, 
// 		  u.group_id as u_groupid 
// 		FROM `ebans_users` u, `ebans_servers_new` s, `ebans_servers_admins` a, `ebans_groups` g 
// 		WHERE g.group_id = u.group_id AND u.authid = a.steamid AND port=%d AND s.ip = '%s' AND u.authid = '%s' 
// 		LIMIT 1;


// SELECT users.displayname, groups.groupname, groups.flags FROM `ebans_users` users
// INNER JOIN `ebans_servers_admins` admins ON users.playerid = admins.player_id
// RIGHT JOIN `ebans_servers_new` servers ON admins.server_id = servers.server_id
// LEFT JOIN `ebans_groups` groups ON users.group_id = groups.group_id
// WHERE users.playerid = 1 AND admins.server_id = 1
