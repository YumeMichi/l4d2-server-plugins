#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#define SCORE_DELAY_EMPTY_SERVER 3.0
#define VOTE_NO "no"
#define VOTE_YES "yes"

new VoteY = 0;
new VoteN = 0;
new bool:isL4D2 = false;
new String:VoteNsMap_ED[32];
new String:votesmaps[MAX_NAME_LENGTH];
new String:votesmapsname[MAX_NAME_LENGTH];
new Handle:g_hVoteMenu = INVALID_HANDLE;
new Handle:g_Cvar_Limits;
new Handle:VoteNsMapED;
new Handle:VoteNsED;
new Float:lastDisconnectTime;

new String:EN_name[64][16][16];
new String:CHI_name[64][16][16];

enum voteType
{
    map
}

new voteType:g_voteType = voteType;

public Plugin:myinfo =
{
    name = "Votes2 Mod",
    author = "Author @fenghf, modified by @YumeMichi",
    description = "Votes Commands",
    version = "1.2.2a",
    url = "http://bbs.3dmgame.com/thread-2094823-1-1.html"
};

public OnPluginStart()
{
    decl String: game_name[64];
    GetGameFolderName(game_name, sizeof(game_name));
    if (!StrEqual(game_name, "left4dead", false) && !StrEqual(game_name, "left4dead2", false))
    {
        SetFailState("只能在Left 4 Dead 1 & 2使用");
    }
    if (StrEqual(game_name, "left4dead2", false))
    {
        isL4D2 = true;
    }
    RegConsoleCmd("votesmapsmenu", Command_VotemapsMenu);
    RegConsoleCmd("sm_votes", Command_Votes, "打开投票菜单");

    g_Cvar_Limits = CreateConVar("sm_votes_s", "0.60", "投票同意票数百分比", 0, true, 0.05, true, 1.0);
    VoteNsMapED = CreateConVar("l4d_VoteNsMapED", "1", " 启用、关闭 投票换图功能", FCVAR_NOTIFY);
    VoteNsED = CreateConVar("l4d_VoteNs", "1", " 启用、关闭 投票插件", FCVAR_NOTIFY);

    AutoExecConfig(true, "l4d2_votes2_mod");

    MapInit();
}

public OnClientPutInServer(client)
{
    CreateTimer(30.0, TimerAnnounce, client);
}

public OnMapStart()
{
    //
}

public MapInit()
{
    new i = 0;
    new Handle:hFile = OpenConfig();

    if (KvGotoFirstSubKey(hFile))
    {
        KvGetString(hFile, "mapname", CHI_name[i][0][0], 64, "错误的地图名");
        KvGetString(hFile, "mapcode", EN_name[i][0][0], 64, "错误的建图代码");
        i++;
    }
    while (KvGotoNextKey(hFile))
    {
        KvGetString(hFile, "mapname", CHI_name[i][0][0], 64, "错误的地图名");
        KvGetString(hFile, "mapcode", EN_name[i][0][0], 64, "错误的建图代码");
        i++;
    }

    CloseHandle(hFile);
}

public Handle:OpenConfig()
{
    decl String:sPath[256];

    BuildPath(PathType:0, sPath, 256, "%s", "data/l4d2_abbw_map.txt");

    if (!FileExists(sPath, false, "GAME"))
    {
        SetFailState("找不到文件 data/l4d2_abbw_map.txt");
    }

    new Handle:hFile = CreateKeyValues("ThirdPartyMaps", "", "");
    if (FileToKeyValues(hFile, sPath))
    {
        PrintToServer("第三方地图数据 data/l4d2_abbw_map.txt 加载成功");
    }
    else
    {
        CloseHandle(hFile);
        SetFailState("无法载入文件 data/l4d2_abbw_map.txt");
    }

    return hFile;
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
    if (IsClientInGame(client))
    {
        PrintToChat(client, "[SM] 玩家可以输入 !votes 打开投票菜单.");
    }
}

public Action:Command_Votes(client, args)
{
    // Reload map data
    MapInit();

    if (GetConVarInt(VoteNsED) == 1)
    {
        new VoteNsMapE_D = GetConVarInt(VoteNsMapED);

        if(VoteNsMapE_D == 0)
        {
            VoteNsMap_ED = "启用";
        }
        else if(VoteNsMapE_D == 1)
        {
            VoteNsMap_ED = "禁用";
        }

        new Handle:menu = CreatePanel();
        new String:Value[64];
        SetPanelTitle(menu, "投票菜单");

        if (VoteNsMapE_D == 0)
        {
            DrawPanelItem(menu, "投票换图 已禁用");
        }
        else if (VoteNsMapE_D == 1)
        {
            DrawPanelItem(menu, "投票换图");
        }

        if (GetUserFlagBits(client) & ADMFLAG_ROOT || GetUserFlagBits(client) & ADMFLAG_CONVARS)
        {
            DrawPanelText(menu, "管理员选项");
            Format(Value, sizeof(Value), "%s 投票换图", VoteNsMap_ED);
            DrawPanelItem(menu, Value);
        }

        DrawPanelText(menu, " \n");
        DrawPanelItem(menu, "关闭");
        SendPanelToClient(menu, client, Votes_Menu, MENU_TIME_FOREVER);

        return Plugin_Handled;
    }
    else if(GetConVarInt(VoteNsED) == 0)
    {
        //
    }

    return Plugin_Stop;
}

public Votes_Menu(Handle:menu, MenuAction:action, client, itemNum)
{
    if (action == MenuAction_Select)
    {
        new VoteNsMapE_D = GetConVarInt(VoteNsMapED);

        switch (itemNum)
        {
            case 1:
            {
                if (VoteNsMapE_D == 0)
                {
                    FakeClientCommand(client, "sm_votes");
                    PrintToChat(client, "[SM] 投票换图 已禁用");
                    return ;
                }
                else if (VoteNsMapE_D == 1)
                {
                    FakeClientCommand(client, "votesmapsmenu");
                }
            }
            case 2:
            {
                if (VoteNsMapE_D == 0 && (GetUserFlagBits(client) & ADMFLAG_ROOT) || (GetUserFlagBits(client) & ADMFLAG_CONVARS) && VoteNsMapE_D == 0)
                {
                    SetConVarInt(FindConVar("l4d_VoteNsmapED"), 1);
                    PrintToChatAll("\x05[SM] \x04管理员 已启用投票换图");
                }
                else if (VoteNsMapE_D == 1 && (GetUserFlagBits(client) & ADMFLAG_ROOT) || (GetUserFlagBits(client) & ADMFLAG_CONVARS) && VoteNsMapE_D == 1)
                {
                    SetConVarInt(FindConVar("l4d_VoteNsmapED"), 0);
                    PrintToChatAll("\x05[SM] \x04管理员 已禁用投票换图");
                }
            }
        }
    }
}

public Action:Command_VotemapsMenu(client, args)
{
    if (GetConVarInt(VoteNsED) == 1 && GetConVarInt(VoteNsMapED) == 1)
    {
        if (!TestVoteDelay(client))
        {
            return Plugin_Handled;
        }

        new Handle:menu = CreateMenu(MapMenuHandler);
        SetMenuTitle(menu, "请选择地图");

        if (isL4D2)
        {
            AddMenuItem(menu, "c1m1_hotel", "死亡中心");
            AddMenuItem(menu, "c2m1_highway", "黑色狂欢节");
            AddMenuItem(menu, "c3m1_plankcountry", "沼泽激战");
            AddMenuItem(menu, "c4m1_milltown_a", "暴风骤雨");
            AddMenuItem(menu, "c5m1_waterfront", "教区");
            AddMenuItem(menu, "c6m1_riverbank", "短暂时刻");
            AddMenuItem(menu, "c7m1_docks", "牺牲");
            AddMenuItem(menu, "c8m1_apartment", "毫不留情");
            AddMenuItem(menu, "c9m1_alleys", "坠机险途");
            AddMenuItem(menu, "c10m1_caves", "死亡丧钟");
            AddMenuItem(menu, "c11m1_greenhouse", "静寂时分");
            AddMenuItem(menu, "c12m1_hilltop", "血腥收获");
            AddMenuItem(menu, "c13m1_alpinecreek", "刺骨寒溪");

            new i = 0;
            while (i < 64)
            {
                if (!StrEqual("", CHI_name[i][0][0], true))
                {
                    AddMenuItem(menu, EN_name[i][0][0], CHI_name[i][0][0]);
                }
                i++;
            }
        }
        else
        {
            AddMenuItem(menu, "l4d_vs_hospital01_apartment", "毫不留情");
            AddMenuItem(menu, "l4d_vs_airport01_greenhouse", "静寂时分");
            AddMenuItem(menu, "l4d_vs_smalltown01_caves", "死亡丧钟");
            AddMenuItem(menu, "l4d_vs_farm01_hilltop", "血腥收获");
            AddMenuItem(menu, "l4d_garage01_alleys", "坠机险途");
            AddMenuItem(menu, "l4d_river01_docks", "牺牲");
        }

        SetMenuExitBackButton(menu, true);
        SetMenuExitButton(menu, true);
        DisplayMenu(menu, client, MENU_TIME_FOREVER);

        return Plugin_Handled;
    }
    else if (GetConVarInt(VoteNsED) == 0 && GetConVarInt(VoteNsMapED) == 0)
    {
        PrintToChat(client, "[SM] 投票换图 已禁用");
    }

    return Plugin_Handled;
}

public MapMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
    if (action == MenuAction_Select)
    {
        new String:info[32], String:name[32];
        GetMenuItem(menu, itemNum, info, sizeof(info), _, name, sizeof(name));
        votesmaps = info;
        votesmapsname = name;
        PrintToChatAll("\x05[SM] \x04%N 发起投票换图 \x05 %s", client, votesmapsname);
        DisplayVoteMapsMenu(client);
    }
}

public DisplayVoteMapsMenu(client)
{
    if (IsVoteInProgress())
    {
        ReplyToCommand(client, "[SM] 已有投票在进行中");
        return;
    }
    if (!TestVoteDelay(client))
    {
        return;
    }

    g_voteType = voteType:map;
    g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);

    SetMenuTitle(g_hVoteMenu, "发起投票换图 %s %s", votesmapsname, votesmaps);
    AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
    AddMenuItem(g_hVoteMenu, VOTE_NO, "No");
    SetMenuExitButton(g_hVoteMenu, false);
    VoteMenuToAll(g_hVoteMenu, 20);
}

public Handler_VoteCallback(Handle:menu, MenuAction:action, param1, param2)
{
    // ==========================
    if (action == MenuAction_Select)
    {
        switch(param2)
        {
            case 0:
            {
                VoteY += 1;
                PrintToChatAll("\x03%N \x05投票了", param1);
            }
            case 1:
            {
                VoteN += 1;
                PrintToChatAll("\x03%N \x04投票了", param1);
            }
        }
    }
    // ==========================

    decl String:item[64], String:display[64];
    new Float:percent, Float:limit, votes, totalVotes;

    GetMenuVoteInfo(param2, votes, totalVotes);
    GetMenuItem(menu, param1, item, sizeof(item), _, display, sizeof(display));

    if (strcmp(item, VOTE_NO) == 0 && param1 == 1)
    {
        votes = totalVotes - votes;
    }

    percent = GetVotePercent(votes, totalVotes);
    limit = GetConVarFloat(g_Cvar_Limits);

    CheckVotes();

    if (action == MenuAction_End)
    {
        VoteMenuClose();
    }
    else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
    {
        PrintToChatAll("[SM] 没有票数");
    }
    else if (action == MenuAction_VoteEnd)
    {
        if ((strcmp(item, VOTE_YES) == 0 && FloatCompare(percent, limit) < 0 && param1 == 0) || (strcmp(item, VOTE_NO) == 0 && param1 == 1))
        {
            PrintToChatAll("[SM] 投票失败. 至少需要 %d%% 支持 (同意 %d%% 总共 %i 票)", RoundToNearest(100.0 * limit), RoundToNearest(100.0 * percent), totalVotes);
            CreateTimer(2.0, VoteEndDelay);
        }
        else
        {
            PrintToChatAll("[SM] 投票通过 (同意 %d%% 总共 %i 票)", RoundToNearest(100.0 * percent), totalVotes);
            CreateTimer(2.0, VoteEndDelay);
            switch (g_voteType)
            {
                case (voteType:map):
                {
                    CreateTimer(5.0, Changelevel_Map);
                    PrintToChatAll("\x03[SM] \x04 5秒后换图 \x05%s", votesmapsname);
                    PrintToChatAll("\x04 %s", votesmaps);
                    LogMessage("投票换图 %s %s 通过", votesmapsname, votesmaps);
                }
            }
        }
    }

    return 0;
}

CheckVotes()
{
    PrintHintTextToAll("同意: \x04%i\n不同意: \x04%i", VoteY, VoteN);
}

public Action:VoteEndDelay(Handle:timer)
{
    VoteY = 0;
    VoteN = 0;
}

public Action:Changelevel_Map(Handle:timer)
{
    ServerCommand("changelevel %s", votesmaps);
}

// ===============================
VoteMenuClose()
{
    VoteY = 0;
    VoteN = 0;
    CloseHandle(g_hVoteMenu);
    g_hVoteMenu = INVALID_HANDLE;
}

Float:GetVotePercent(votes, totalVotes)
{
    return FloatDiv(float(votes), float(totalVotes));
}

bool:TestVoteDelay(client)
{
    new delay = CheckVoteDelay();

    if (delay > 0)
    {
        if (delay > 60)
        {
            PrintToChat(client, "[SM] 您必须再等 %i 分钟後才能发起新一轮投票", delay % 60);
        }
        else
        {
            PrintToChat(client, "[SM] 您必须再等 %i 秒钟後才能发起新一轮投票", delay);
        }
        return false;
    }

    return true;
}
// =======================================

public OnClientDisconnect(client)
{
    if (IsClientInGame(client) && IsFakeClient(client))
    {
        return;
    }

    new Float:currenttime = GetGameTime();

    if (lastDisconnectTime == currenttime)
    {
        return;
    }

    CreateTimer(SCORE_DELAY_EMPTY_SERVER, IsNobodyConnected, currenttime);
    lastDisconnectTime = currenttime;
}

public Action:IsNobodyConnected(Handle:timer, any:timerDisconnectTime)
{
    if (timerDisconnectTime != lastDisconnectTime)
    {
        return Plugin_Stop;
    }

    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i) && !IsFakeClient(i))
        {
            return Plugin_Stop;
        }
    }

    return  Plugin_Stop;
}

