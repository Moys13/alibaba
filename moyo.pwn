#include <a_samp>
#include <zcmd>
#include <sscanf2>
#include <streamer>
#include <foreach>
#include <a_mysql>
#include <mapandreas>

#include <asgh>
#include <market>
#include <palomino>
#include <sweeper>
#include <verona>
// ============================Colors Define==================================
// NOTE: If you want to add color you must add "FF" behind your HexCode
#define	COLOR_RED 				0xFF0000FF
#define COLOR_GREEN				0x008000FF
#define COLOR_YELLOW			0xFFFF00FF
#define COLOR_USAGE 			0xB8B8B8FF
// ============================End Of Colors==================================

// =============================Define=======================================
	// Mengganti MAX_PLAYES dengan jumlah slot player yang kita mau
	// default dari MAX_PLAYERS adalah 1000
	 #undef	  	MAX_PLAYERS
	 #define	 	MAX_PLAYERS			50	

	// Konfigurasi MYSQL
	#define			MYSQL_HOSTNAME		"127.0.0.1"
	#define			MYSQL_USERNAME		"root"
	#define			MYSQL_PASSWORD		""
	#define			MYSQL_DATABASE		"datasamp"

	// koneksi handle
	new MySQL: connection;

	// berapa lama waktu agar player di kick saat login lama sekali
	#define 		SECOND_TO_LOGIN		30

	// tempat spawn default
	#define 		DEFAULT_POS_X 		1958.3783
	#define 		DEFAULT_POS_Y 		1343.1572
	#define 		DEFAULT_POS_Z 		15.3746
	#define 		DEFAULT_POS_A 		270.1425
// =========================End Of Defined====================================

// =============================Enums=========================================
// E_PLAYERS merupakan enum yang berisi data data player yang nanti nya sangat berguna untuk menyimpan data
enum E_PLAYERS
{
	ID,
	Name[MAX_PLAYER_NAME],
	Password[65],
	Salt[17],
	Float: X_Pos,
	Float: Y_Pos,
	Float: Z_Pos,
	Float: A_Pos,
	Interior,
	World,
	Cache: Cache_ID,
	bool:ISloggedIn,
	LoginAttemps,
	LoginTimer
};
new player[MAX_PLAYERS][E_PLAYERS];
/*
	g_MysqlRaceCheck[MAX_PLAYERS] ini bertujuan untuk mencegah load data yang bukan player miliki seperti contoh:
	PLAYER A KONEK KE GAME -> QUERY AKTIF -> QUERY INI SANGAT MEMERLUKAN WAKTU YANG SANGAT LAMA, PLAYER A DENGAN ID 2 DISKONEK
	LALU PLAYER B JOIN DENGAN WAKTU YANG PAS DENGAN ID -> QUERY YANG TADI LAMBAN AKHIRNYA SELESAI, TAPI DENGAN PLAYER YANG SALAH.

	CARA KERJA g_MysqlRaceCheck[MAX_PLAYERS] Dengan cara membuat jumlah koneksi pada masing masing player dan jumlah akan meningkat
	setiap player konek dan diskonek.
*/
new g_MysqlRaceCheck[MAX_PLAYERS]; 


enum TEMP_VEHICLE 
{
	TEMP_VEHICLE_ID,
	TEMP_VEHICLE_NAME,
	bool: TEMP_VEHICLE_ACTIVE
};
new tempVehicle[MAX_PLAYERS][TEMP_VEHICLE];

enum
{
	DIALOG_UNUSED,
	DIALOG_LOGIN,
	DIALOG_REGISTER
};
// =============================End Of Enums==================================

// =============================Static========================================
static stock g_arrVehicleNames[][] = {
    "Landstalker", "Bravura", "Buffalo", "Linerunner", "Perrenial", "Sentinel", "Dumper", "Firetruck", "Trashmaster",
    "Stretch", "Manana", "Infernus", "Voodoo", "Pony", "Mule", "Cheetah", "Ambulance", "Leviathan", "Moonbeam",
    "Esperanto", "Taxi", "Washington", "Bobcat", "Whoopee", "BF Injection", "Hunter", "Premier", "Enforcer",
    "Securicar", "Banshee", "Predator", "Bus", "Rhino", "Barracks", "Hotknife", "Trailer", "Previon", "Coach",
    "Cabbie", "Stallion", "Rumpo", "RC Bandit", "Romero", "Packer", "Monster", "Admiral", "Squalo", "Seasparrow",
    "Pizzaboy", "Tram", "Trailer", "Turismo", "Speeder", "Reefer", "Tropic", "Flatbed", "Yankee", "Caddy", "Solair",
    "Berkley's RC Van", "Skimmer", "PCJ-600", "Faggio", "Freeway", "RC Baron", "RC Raider", "Glendale", "Oceanic",
    "Sanchez", "Sparrow", "Patriot", "Quad", "Coastguard", "Dinghy", "Hermes", "Sabre", "Rustler", "ZR-350", "Walton",
    "Regina", "Comet", "BMX", "Burrito", "Camper", "Marquis", "Baggage", "Dozer", "Maverick", "News Chopper", "Rancher",
    "FBI Rancher", "Virgo", "Greenwood", "Jetmax", "Hotring", "Sandking", "Blista Compact", "Police Maverick",
    "Boxville", "Benson", "Mesa", "RC Goblin", "Hotring Racer A", "Hotring Racer B", "Bloodring Banger", "Rancher",
    "Super GT", "Elegant", "Journey", "Bike", "Mountain Bike", "Beagle", "Cropduster", "Stunt", "Tanker", "Roadtrain",
    "Nebula", "Majestic", "Buccaneer", "Shamal", "Hydra", "FCR-900", "NRG-500", "HPV1000", "Cement Truck", "Tow Truck",
    "Fortune", "Cadrona", "SWAT Truck", "Willard", "Forklift", "Tractor", "Combine", "Feltzer", "Remington", "Slamvan",
    "Blade", "Streak", "Freight", "Vortex", "Vincent", "Bullet", "Clover", "Sadler", "Firetruck", "Hustler", "Intruder",
    "Primo", "Cargobob", "Tampa", "Sunrise", "Merit", "Utility", "Nevada", "Yosemite", "Windsor", "Monster", "Monster",
    "Uranus", "Jester", "Sultan", "Stratum", "Elegy", "Raindance", "RC Tiger", "Flash", "Tahoma", "Savanna", "Bandito",
    "Freight Flat", "Streak Carriage", "Kart", "Mower", "Dune", "Sweeper", "Broadway", "Tornado", "AT-400", "DFT-30",
    "Huntley", "Stafford", "BF-400", "News Van", "Tug", "Trailer", "Emperor", "Wayfarer", "Euros", "Hotdog", "Club",
    "Freight Box", "Trailer", "Andromada", "Dodo", "RC Cam", "Launch", "LSPD Cruiser", "SFPD Cruiser", "LVPD Cruiser",
    "Police Rancher", "Picador", "S.W.A.T", "Alpha", "Phoenix", "Glendale", "Sadler", "Luggage", "Luggage", "Stairs",
    "Boxville", "Tiller", "Utility Trailer"
};
// ==========================End Of Static====================================


main()
{
	print("\n-----------------------------------");
	print(" Moyo Gamemode by your Moys13 here");
	print("-----------------------------------\n");
}

public OnGameModeInit()
{
	new MySQLOpt: option_id = mysql_init_options();
	mysql_set_option(option_id, AUTO_RECONNECT, true); // Untuk mengulang koneksi secara otomatis saat hilang koneksi ke MYSQL

	connection = mysql_connect(MYSQL_HOSTNAME, MYSQL_USERNAME, MYSQL_PASSWORD, MYSQL_DATABASE, option_id);
	if(connection == MYSQL_INVALID_HANDLE || mysql_errno(connection) != 0)
	{
		print("MYSQL Gagal di hubungkan [TIDAK AKTIF]");
		SendRconCommand("exit"); // otomatis menutup server jika tidak ada koneksi
		return 1;
	}
	print("MYSQL Berhasil di hubungkan [AKTIF]");
	// =============================Load Mappingan=====================================
	loadMappingVerona();
	loadMappingAsgh();
	loadMappingPalomino();
	loadMappingMarket();
	loadMappingSweeper();
	// =============================End Of Load Mappingan===============================
	new Safull[50];
	format(Safull, sizeof(Safull), "scriptfiles/SAFull.hmap");
	MapAndreas_Init(MAP_ANDREAS_MODE_FULL, Safull);
    new Float:pos;
    if (MapAndreas_FindAverageZ(20.001, 25.006, pos)) {
        // Found position - position saved in 'pos'
    }
	return 1;
}

public OnGameModeExit()
{
	for(new i = 0, j = GetPlayerPoolSize(); i <=j; i++) //Pengulangan untuk mendapatkan semua player sesuai dengan player yang ada, GetPlayerPoolSize() adalah untuk mendapatkan player tertinggi saat itu juga. 
	{
		if(IsPlayerConnected(i))
		{
			OnPlayerDisconnect(i, 1);
		}
	}
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	return 0;
}

public OnPlayerConnect(playerid)
{
	g_MysqlRaceCheck[playerid]++;
	// reset data player saat konek
	static const empty_player[E_PLAYERS];
	player[playerid] = empty_player;
	GetPlayerName(playerid, player[playerid][Name], MAX_PLAYER_NAME);

	new query[128];
	mysql_format(connection, query, sizeof query, "SELECT * FROM `players` WHERE `username` = '%e' LIMIT 1", player[playerid][Name]);
	mysql_tquery(connection, query, "OnPlayerDataLoaded", "dd", playerid, g_MysqlRaceCheck[playerid]);

	// ============================Remove Building============================================
		removeBuildingVerona(playerid);
		removeBuildingSweeper(playerid);
	// ============================End Of Remove Building=====================================
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	g_MysqlRaceCheck[playerid]++;

	UpdatePlayerData(playerid, reason);

	// if the player was kicked (either wrong password or taking too long) during the login part, remove the data from the memory
	if(cache_is_valid(player[playerid][Cache_ID]))
	{
		cache_delete(player[playerid][Cache_ID]);
		player[playerid][Cache_ID] = MYSQL_INVALID_CACHE;
	}

	// if the player was kicked before the time expires (30 seconds), kill the timer
	if (player[playerid][LoginTimer])
	{
		KillTimer(player[playerid][LoginTimer]);
		player[playerid][LoginTimer] = 0;
	}

	// sets "IsLoggedIn" to false when the player disconnects, it prevents from saving the player data twice when "gmx" is used
	player[playerid][ISloggedIn] = false;
	return 1;
}

public OnPlayerSpawn(playerid)
{
	// spawn the player to their last saved position
	SetPlayerInterior(playerid, player[playerid][Interior]);
	SetPlayerPos(playerid, player[playerid][X_Pos], player[playerid][Y_Pos], player[playerid][Z_Pos]);
	SetPlayerFacingAngle(playerid, player[playerid][A_Pos]);

	SetCameraBehindPlayer(playerid);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

public OnPlayerText(playerid, text[])
{
	return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
	if (strcmp("/mycommand", cmdtext, true, 10) == 0)
	{
		// Do something here
		return 1;
	}
	return 0;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	if(oldstate == PLAYER_STATE_DRIVER && tempVehicle[playerid][TEMP_VEHICLE_ID] != -1)
	{
		tempVehicle[playerid][TEMP_VEHICLE_ACTIVE] = false;
		DestroyVehicle(tempVehicle[playerid][TEMP_VEHICLE_ID]);
	}
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
		case DIALOG_UNUSED: return 1;

		case DIALOG_LOGIN:
		{
			if(!response)
				Kick(playerid);
			
			new hash_pass[70];
			SHA256_PassHash(inputtext, player[playerid][Salt], hash_pass, 70);

			if(strcmp(hash_pass, player[playerid][Password]) == 0)
			{
				// Jika password benar, spawn player
				ShowPlayerDialog(playerid, DIALOG_UNUSED, DIALOG_STYLE_MSGBOX, "Login", "Kamu berhasil login ke dalam game", "okay", "");

				// setel cache yang ditetntukan secara cache aktif agar dapat mengambil data pemain lainnya
				cache_set_active(player[playerid][Cache_ID]);

				AssignPlayerData(playerid);
				
				// menghapus cache aktif dari memory dan hapus cache juga
				cache_delete(player[playerid][Cache_ID]);
				player[playerid][Cache_ID] = MYSQL_INVALID_CACHE;

				KillTimer(player[playerid][LoginTimer]);
				player[playerid][LoginTimer] = 0;
				player[playerid][ISloggedIn] = true;

				// spawn player ke default posisi
				SetSpawnInfo(playerid, NO_TEAM, 0, player[playerid][X_Pos], player[playerid][Y_Pos], player[playerid][Z_Pos], player[playerid][A_Pos], 0, 0, 0, 0, 0, 0);
				SpawnPlayer(playerid);
			}
			else
			{
				player[playerid][LoginAttemps]++;

				if(player[playerid][LoginAttemps] >= 3)
				{
					ShowPlayerDialog(playerid, DIALOG_UNUSED, DIALOG_STYLE_MSGBOX, "Login", "Kamu telah Melakukan input 3 kali!", "okay", "");
					Delaykick(playerid);
				}
				else
				{
					new string[128];
					format(string, sizeof string, "%i\nPasword Salah!\nTolong masukan password kembali:", player[playerid][LoginAttemps]);
					ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", string, "Login", "Batal");
				}
			}
		}
		case DIALOG_REGISTER:
		{
			if(!response)
				return Kick(playerid);
			if(strlen(inputtext) <= 5 )
				return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Registrasi", "Kamu harus memasukan password lebih dari 5 karakte\nTolong masukan password anda dibawah:)", "Register", "");

			// 16 karakter secara acak dari 33 ke126 (dalam ASCII) untuk Salt
			for (new i = 0; i < 16; i++) player[playerid][Salt][i] = random(94) + 33;
			SHA256_PassHash(inputtext, player[playerid][Salt], player[playerid][Password], 65);

			new query[221];
			mysql_format(connection, query, sizeof query, "INSERT INTO `players` (`username`, `password`, `salt`) VALUES ('%e', '%s', '%e')", player[playerid][Name], player[playerid][Password], player[playerid][Salt]);
			mysql_tquery(connection, query, "OnPlayerRegister", "d", playerid);
		}
		default: return 0; //Dialog ID tidak ditemukan
	}
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}

public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
	new string[200];
	MapAndreas_FindAverageZ(fX, fY, fZ);
	SetPlayerPos(playerid, fX, fY, fZ+2);
	format(string, sizeof string, "X=%f Y=%f Z=%f", fX, fY, fZ);
	SendClientMessage(playerid, COLOR_RED, string);
	Delayspawn(playerid);
	SetVehiclePos(GetPlayerVehicleID(playerid), fX, fY, fZ+1);
	Delayspawn(playerid);
	PutPlayerInVehicle(playerid, GetPlayerVehicleID(playerid), 0);
	LinkVehicleToInterior(GetPlayerVehicleID(playerid), GetPlayerInterior(playerid));
	return 1;
}

// ============================Callback================================
forward OnPlayerDataLoaded(playerid, race_check);
public OnPlayerDataLoaded(playerid, race_check)
{
	/* 
		Mengecek jumlah koneksi jika race_check sama dengan g_MysqlRaceCheck dengan callback dan jika koneksi keduanya sama makan AMAN dan berjalan LANCAR
		dan jika berbeda makan player akan di kick
	*/
	if(race_check != g_MysqlRaceCheck[playerid])
		return Kick(playerid);
	if(cache_num_rows() > 0)
	{
		// menyimpan Password dan Salt sehingga dapat membandingkan kata sandi yang dimasukan pemain
		cache_get_value(0, "password", player[playerid][Password], 65);
		cache_get_value(0, "salt", player[playerid][Salt], 17);

		// menyimpan cache aktif dalam memori dan mengembalikan Cache_ID untuk di gunakan nanti
		player[playerid][Cache_ID] = cache_save();
		new string[128];
		format(string, sizeof string, "Akun ini (%s) telah terdaftar. Tolong masukan password dibawah:", player[playerid][Name]);
		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", string, "Login", "Batal");

		// dari sekarang, player memiliki waktu 30 detik untuk login
		player[playerid][LoginTimer] = SetTimerEx("OnLoginTimeout", SECOND_TO_LOGIN * 1000, false, "d", playerid);
	}
	else
	{
		new string[200];
		format(string, sizeof string, "Selamat Datang %s, Silahkan untuk Register di Bawah ini:", player[playerid][Name]);
		ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Register Akun", string, "Register", "Batal");
	}
	return 1;
}

forward OnLoginTimeout(playerid);
public OnLoginTimeout(playerid)
{
	// reset timerid
	player[playerid][LoginTimer] = 0;
	ShowPlayerDialog(playerid, DIALOG_UNUSED, DIALOG_STYLE_MSGBOX, "Login", "Kamu telah di kick, karena lama tidak memasukan password.", "Okay", "");
	Delaykick(playerid);
	
	return 1;
}

forward OnPlayerRegister(playerid);
public OnPlayerRegister(playerid)
{
	// menghasilkan id yang di hasilkan kolom AUTO_INCREMENT oleh query yang di kirim
	player[playerid][ID] = cache_insert_id();

	ShowPlayerDialog(playerid, DIALOG_UNUSED, DIALOG_STYLE_MSGBOX, "Register", "Akun telah terdaftar, kamu akan login secara otomatis", "Okay", "");

	player[playerid][ISloggedIn] = true;

	player[playerid][X_Pos] = DEFAULT_POS_X;
	player[playerid][Y_Pos] = DEFAULT_POS_Y;
	player[playerid][Z_Pos] = DEFAULT_POS_Z;
	player[playerid][A_Pos] = DEFAULT_POS_A;

	SetSpawnInfo(playerid, NO_TEAM, 0, player[playerid][X_Pos], player[playerid][Y_Pos], player[playerid][Z_Pos], player[playerid][A_Pos], 0, 0, 0, 0, 0, 0);
	SpawnPlayer(playerid);

	return 1;
}

forward PlayerKickDelay(playerid);
public PlayerKickDelay(playerid)
{
	Kick(playerid);
	return 1;
}

forward PlayerSawnDelay(playerid);
public PlayerSawnDelay(playerid)
{
	TogglePlayerControllable(playerid, true);
	return 1;
}
// ============================End Of Callback=========================

stock AssignPlayerData(playerid)
{
	cache_get_value_int(0, "id", player[playerid][ID]);

	cache_get_value_float(0, "x_pos", player[playerid][X_Pos]);
	cache_get_value_float(0, "y_pos", player[playerid][Y_Pos]);
	cache_get_value_float(0, "z_pos", player[playerid][Z_Pos]);
	cache_get_value_float(0, "angle", player[playerid][A_Pos]);
	cache_get_value_int(0, "interior", player[playerid][Interior]);
	cache_get_value_int(0, "world", player[playerid][World]);
}

stock Delaykick(playerid, time = 500)
{
	SetTimerEx("PlayerKickDelay", time, false, "d", playerid);
	return 1;
}

stock Delayspawn(playerid, time = 1000)
{
	TogglePlayerControllable(playerid, false);
	SetTimerEx("PlayerSawnDelay", time, false, "d", playerid);
	return 1;
}

stock UpdatePlayerData(playerid, reason)
{
	if (player[playerid][ISloggedIn] == false) return 0;

	// Jika client crash, tidak mungkin mendapatkan posisi pemain di pangggil balik OnPlayerDisconnect
	// jadi mengatasinya dengan menyimpan posisi sebelumnya
	if (reason == 1)
	{
		GetPlayerPos(playerid, player[playerid][X_Pos], player[playerid][Y_Pos], player[playerid][Z_Pos]);
		GetPlayerFacingAngle(playerid, player[playerid][A_Pos]);
	}

	new query[280];
	mysql_format(connection, query, sizeof query, "UPDATE `players` SET `x_pos` = %f, `y_pos` = %f, `z_pos` = %f, `angle` = %f, `interior` = %d, `world` = %d WHERE `id` = %d LIMIT 1", player[playerid][X_Pos], player[playerid][Y_Pos], player[playerid][Z_Pos], player[playerid][A_Pos], GetPlayerInterior(playerid), GetPlayerVirtualWorld(playerid),player[playerid][ID]);
	mysql_tquery(connection, query);
	return 1;
}

// ======================================Command=========================================================
CMD:money(playerid, params[])
{
	new money;
	new target;
	if(sscanf(params, "ii", target, money))
		return SendClientMessage(playerid, COLOR_USAGE, "SERVER: Usage /money [playerID] [Money]");
	GivePlayerMoney(target, money);
	SendClientMessage(playerid, COLOR_GREEN, "[SERVER]: Anda mendapatkan uang");
	return 1;
}
CMD:help(playerid, params[]) {
    SendClientMessage(playerid, COLOR_YELLOW, "This is the help command");
    return 1;
}
CMD:tmpveh(playerid, params[]) {
	new Float:pos[4];
	new vehicleid;
	if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
		return SendClientMessage(playerid, COLOR_USAGE, "SERVER: Tidak bisa spawn di dalam kendaraan!");
	if(sscanf(params, "i", vehicleid) || vehicleid < 400 || vehicleid > 611)
		return SendClientMessage(playerid, COLOR_USAGE, "SERVER: Usage /veh [vehicleID]");
	GetPlayerPos(playerid, pos[0], pos[1], pos[2]);
	GetPlayerFacingAngle(playerid, pos[3]);
	tempVehicle[playerid][TEMP_VEHICLE_ID] = CreateVehicle(vehicleid, pos[0], pos[1], pos[2], pos[3], -1, -1, 0, 0);
	tempVehicle[playerid][TEMP_VEHICLE_ACTIVE] = true;
	PutPlayerInVehicle(playerid, tempVehicle[playerid][TEMP_VEHICLE_ID], 0);
	return 1;
}
// ======================================End Of Command==================================================
