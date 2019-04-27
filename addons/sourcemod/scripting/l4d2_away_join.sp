#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

ConVar g_hAwayJoinAnnounce, g_hAwayJoinEnabled;

public Plugin myinfo = 
{
	name = "[L4D2] Away and Join for Multiplayer",
	author = "YumeMichi",
	description = "!away and !join for Multiplayer.",
	version = PLUGIN_VERSION,
	url = "https://github.com/YumeMichi/l4d2_away_join"
}

public void OnPluginStart()
{
	char GameName[50];
	GetGameFolderName(GameName, sizeof(GameName));
	if (!StrEqual(GameName, "left4dead2", false)) {
		SetFailState("Left 4 Dead 2 only.");
		return;
	}

	CreateConVar("l4d2_away_join_version", PLUGIN_VERSION, "插件版本.");
	g_hAwayJoinAnnounce = CreateConVar("l4d2_away_join_announce", "1", "是否开启插件提示.");
	g_hAwayJoinEnabled = CreateConVar("l4d2_away_join_enabled", "1", "是否启用插件.");

	RegConsoleCmd("sm_away", Away);
	RegConsoleCmd("sm_join", Join);

	AutoExecConfig(true, "l4d2_away_join");
}

public void OnClientPutInServer(int client)
{
	if (GetConVarBool(g_hAwayJoinAnnounce)) {
		CreateTimer(10.0, TimerAnnounce, client);
	}
}

public Action TimerAnnounce(Handle timer, int client)
{
	if (IsClientInGame(client))	{
		PrintToChat(client, "\x04[SM]\x03 玩家可以输入 !away 闲置和 !join 加入游戏.");
	}
}

public Action Away(int client, int args)
{
	if (g_hAwayJoinEnabled)
	{
		ChangeClientTeam(client, 1);
	}
	else
	{
		PrintToChat(client, "\x05[SM]\x04 服务器没有开启 !away 功能.");
	}

	return Plugin_Handled;
}

public Action Join(int client, int args)
{
	int botNums = GetBotNums();
	if (g_hAwayJoinEnabled)
	{
		if (botNums > 0)
		{
			ClientCommand(client, "jointeam 2");
			ClientCommand(client, "go_away_from_keyboard");
		}
		else
		{
			PrintToChat(client, "\x05[SM]\x04 没有多余的空位.");
		}
	}
	else
	{
		PrintToChat(client, "\x05[SM]\x04 服务器没有开启 !join 功能.");
	}

	return Plugin_Handled;
}

public int GetBotNums()
{
	int numBots = 0;
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			numBots++;
			i++;
		}
		i++;
	}

	return numBots;
}

