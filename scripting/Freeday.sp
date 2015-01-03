#include <sourcemod>
#include <sdktools>
#include <multicolors>

#undef REQUIRE_PLUGIN
#include <updater>

#define UPDATE_URL    "http://bitbucket.toastdev.de/sourcemod-plugins/raw/master/Freeday.txt"
public Plugin:myinfo = 
{
	name = "Freeday",
	author = "Toast",
	description = "A Freeday plugin for Jail",
	version = "1.0.4",
	url = "bitbucket.toastdev.de"
}
new Handle:c_fd_R;
new Handle:c_fd_G;
new Handle:c_fd_B;
new Handle:g_color;
new Handle:g_beacon;
new Handle:g_beacon_interval;
new Handle:g_radius
new Handle:BeaconHandles[MAXPLAYERS+1];
new Freeday[MAXPLAYERS +1];
new R;
new G;
new B;
new bool:colors = true;
new bool:beacon = false;
new FreedayRound[MAXPLAYERS + 1];
new g_BeamSprite = -1;
new g_HaloSprite = -1;
new g_Game = 0;
public OnMapStart()
{
	// Code from Last Request: FruitNinja plugin
	if(g_Game == 0)
	{
			decl String:gdir[PLATFORM_MAX_PATH];
			GetGameFolderName(gdir,sizeof(gdir));
			if (StrEqual(gdir,"cstrike",false)){
				g_Game = 1;
			}
	}
	// Precache any materials needed
	if(g_Game == 1)
	{
		g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
		g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	}
	else
	{
		g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
		g_HaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
	}
}

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", PlayerDeath);
	HookEvent("round_end", RoundEnd);
	HookEvent("player_disconnect", PlayerDissconnect);
	HookEvent("player_activate", PlayerJoin);
	
	CreateConVar("freeday_version", "1.0", "The current version of the plugin");
	c_fd_R = CreateConVar("freeday_R", "255", "The Red Color for marking");
	c_fd_G = CreateConVar("freeday_G", "0", "The Green Color for marking");
	c_fd_B = CreateConVar("freeday_B", "0", "The Blue Color for marking");
	g_color = CreateConVar("freeday_enable_color", "1", "Enable colored marking for Freeday players");
	g_beacon = CreateConVar("freeday_enable_beacon", "0", "Enable beacon marking for Freeday players");
	g_beacon_interval = CreateConVar("freeday_beacon_interval", "1.0", "The Interval for the beacon");
	g_radius = CreateConVar("freeday_beacon_radius", "375.0", "The radius of the beacon");
	HookConVarChange(c_fd_R, ConVarChanged);
	HookConVarChange(c_fd_G, ConVarChanged);
	HookConVarChange(c_fd_B, ConVarChanged);
	
	R = GetConVarInt(c_fd_R);
	G = GetConVarInt(c_fd_G);
	B = GetConVarInt(c_fd_B);

	if(g_color != INVALID_HANDLE){
		colors = GetConVarBool(g_color);
	}
	if(g_beacon != INVALID_HANDLE){
		beacon = GetConVarBool(g_beacon);
	}
	
	
	RegAdminCmd("sm_sf", FreedayCommandHandler, FlagToBit(Admin_Kick), "Give Freedays");
	
	LoadTranslations("freeday.phrases");
	LoadTranslations("common.phrases");
	AutoExecConfig();
	
	for (new i = 1; i <= MaxClients; i++)
	{
		Freeday[i] = 0;
		BeaconHandles[i] = INVALID_HANDLE;
	}

	if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }

	
}
public Action:BeaconTimer(Handle:timer, any:client)
{
	if(beacon && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new beaconColor[4];
		beaconColor[0] = R;
		beaconColor[1] = G;
		beaconColor[2] = B;
		beaconColor[3] = 500;
		// Code from CS:GO beacon plugin by Johnny
		new Float:vec[3];
		GetClientAbsOrigin(client, vec);
		vec[2] += 10;
		TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_radius), g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5,  beaconColor, 10, 0);
		TE_SendToAll();
	}
	
}
public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL)
    }
}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
   CreateNative("HasFreeday", Native_Has_Freeday);
   CreateNative("SetFreeday", Native_Set_Freeday);
   return APLRes_Success;
}
public PlayerDissconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid;
	userid = GetEventInt(event, "userid");
	new client;
	client = GetClientOfUserId(userid);
	Freeday[client] = 0;
	
}
public PlayerJoin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid;
	userid = GetEventInt(event, "userid");
	new client;
	client = GetClientOfUserId(userid);
	Freeday[client] = 0;
	
}
public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid;
	userid = GetEventInt(event, "userid");
	new client;
	client = GetClientOfUserId(userid);
	Freeday[client] = 0;
	if(FreedayRound[client] == 1)
	{
		MarkFreeday(client);
		Freeday[client] = 1;
	}
	FreedayRound[client] = 0;
}
public RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	KillAllBeaconTimers()
}
public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if(BeaconHandles[client] != INVALID_HANDLE){
		KillTimer(BeaconHandles[client])
		BeaconHandles[client] = INVALID_HANDLE;
	}
}

public ConVarChanged(Handle:cvar, const String:oldValue[], const String:newValue[]) {
	
	if(cvar == c_fd_R){
		R = StringToInt(newValue);
	}
	else if(cvar == c_fd_G){
		G = StringToInt(newValue);
	}
	else if(cvar == c_fd_B){
		B = StringToInt(newValue);
	}
	else if(cvar == g_color){
		colors = GetConVarBool(g_color);
	}
	else if(cvar == g_beacon){
		colors = GetConVarBool(g_beacon);
	}
	
}

public Action:FreedayCommandHandler(client, args)
{
	new String:Arg[MAX_TARGET_LENGTH];
	if (!IsClientInGame(client)) {
		CReplyToCommand(client, "%t %t", "prefix", "error_no_permission");
		return Plugin_Handled;
	}
	else if(args > 0)
	{
		GetCmdArg(1, Arg, sizeof(Arg));
		new String:target_name[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		target_count = ProcessTargetString(Arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY, target_name, sizeof(target_name), tn_is_ml);
		if(target_count <= 0){
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		for(new i; i <= target_count;i++){
			new target = target_list[i];
			if(IsPlayerAlive(target) && GetClientTeam(target) == 2)
			{
				MarkFreeday(target);
			}
			else if(GetClientTeam(target) == 2){
				FreedayRound[target] = 1;
				new String:targetname[MAX_NAME_LENGTH];
				GetClientName(target, targetname, sizeof(targetname)); 
				CPrintToChat(client, "%t %t", "prefix", "player_freeday_next_round", targetname);
			}
		}
		return Plugin_Handled;
		
	}
	else{
		new String:string[64];
		new Handle:menu = CreateMenu(FreedayMenuHandler);
		Format(string,sizeof(string),"%t", "FreedayMenuTitle", LANG_SERVER);
		SetMenuTitle(menu, string);
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i)){
				if(GetClientTeam(i) == 2 && IsPlayerAlive(i)){
					
					new String:info[32];
					GetClientName(i, string, sizeof(string));
					IntToString(i, info, sizeof(info));
					AddMenuItem(menu, info, string);
				}
			}
		}
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	return Plugin_Continue;
}


public FreedayMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[64];
		new t;
		GetMenuItem(menu, param2, info, sizeof(info));
		t = StringToInt(info);
		MarkFreeday(t);
		
		new String:string[64];
		new Handle:menu2 = CreateMenu(FreedayMenuHandler);
		Format(string,sizeof(string),"%t", "FreedayMenuTitle", LANG_SERVER);
		SetMenuTitle(menu2, string);
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i)){
				if(GetClientTeam(i) == 2 && IsPlayerAlive(i)){
					
					new String:info2[32];
					GetClientName(i, string, sizeof(string));
					IntToString(i, info2, sizeof(info2));
					AddMenuItem(menu2, info2, string);
				}
			}
		}
		SetMenuExitButton(menu, true);
		DisplayMenu(menu2, client, MENU_TIME_FOREVER);
	}
}


MarkFreeday(client)
{
	if(IsPlayerAlive(client))
	{
		new String:name[64];
		
		if(colors){
			SetEntityRenderMode(client,RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, R, G, B, 255);
		}
		if(beacon && BeaconHandles[client] == INVALID_HANDLE)
		{
			BeaconHandles[client] = CreateTimer(GetConVarFloat(g_beacon_interval), BeaconTimer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE)
		}
		GetClientName(client, name, sizeof(name));
		CPrintToChatAll("%t %t", "prefix", "freeday_sucess", name);
		Freeday[client] = 1;
	}
	
}

KillAllBeaconTimers()
{
	//Kill all timers
	for (new i = 1; i <= MaxClients; i++)
	{
		if(BeaconHandles[i] != INVALID_HANDLE){

			KillTimer(BeaconHandles[i]);
			BeaconHandles[i] = INVALID_HANDLE;
		}
	}	
}

public Native_Has_Freeday(Handle:plugin, numParams){
	new client = GetNativeCell(1);
	if(Freeday[client] == 1)
	{
		return true;
	}
	return false;
}
public Native_Set_Freeday(Handle:plugin, numParams){

	new client = GetNativeCell(1);
	if(IsClientInGame(client) && Freeday[client] != 1 && GetNativeCell(2) == 1){
		MarkFreeday(client);
		return true;
	}
	else if(IsClientInGame(client) && GetNativeCell(2) != 1){
		FreedayRound[client] = 1;
		return true;
	}
	else{
		return false;
	}
}
