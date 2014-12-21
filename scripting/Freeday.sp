#include <sourcemod>
#include <morecolors>

#undef REQUIRE_PLUGIN
#include <updater>

#define UPDATE_URL    "http://bitbucket.toastdev.de/sourcemod-plugins/raw/master/Freeday.txt"
public Plugin:myinfo = 
{
	name = "Freeday",
	author = "Toast",
	description = "A Freeday plugin for Jail",
	version = "1.0.2",
	url = "toastdev.de"
}
new Handle:c_fd_R;
new Handle:c_fd_G;
new Handle:c_fd_B;
new Freeday[MAXPLAYERS +1];
new R;
new G;
new B;
new FreedayRound[MAXPLAYERS + 1];

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_disconnect", PlayerDissconnect);
	HookEvent("player_activate", PlayerJoin);
	
	CreateConVar("freeday_version", "1.0", "The current version of the plugin");
	c_fd_R = CreateConVar("freeday_R", "255", "The Red Color for marking");
	c_fd_G = CreateConVar("freeday_G", "0", "The Green Color for marking");
	c_fd_B = CreateConVar("freeday_B", "0", "The Blue Color for marking");
	HookConVarChange(c_fd_R, ConVarChanged);
	HookConVarChange(c_fd_G, ConVarChanged);
	HookConVarChange(c_fd_B, ConVarChanged);
	
	R = GetConVarInt(c_fd_R);
	G = GetConVarInt(c_fd_G);
	B = GetConVarInt(c_fd_B);
	
	
	RegAdminCmd("sm_sf", FreedayCommandHandler, FlagToBit(Admin_Kick), "Give Freedays");
	
	LoadTranslations("freeday.phrases");
	LoadTranslations("common.phrases")
	
	for (new i = 1; i <= MaxClients; i++)
	{
		Freeday[i] = 0;
	}
	if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
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
		SetEntityRenderMode(client,RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, R, G, B, 255);
		GetClientName(client, name, sizeof(name));
		CPrintToChatAll("%t %t", "prefix", "freeday_sucess", name);
		Freeday[client] = 1;
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
