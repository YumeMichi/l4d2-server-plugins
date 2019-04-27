#pragma semicolon 1
#include <sourcemod>

new sikills[66];
new cikills[66];
new siheads[66];
new ciheads[66];
new teamff[66];
new sidmg[66];
new sidmgall;
new sikillsall;
new cikillsall;
new teamffall;
new IF;
new Handle:g_ads_1_on;
new Handle:g_ads_timer_1;
new Handle:g_timer_1;

public Plugin:myinfo =
{
    name = "击杀排行统计",
    description = "击杀排行统计",
    author = "白色幽灵 WhiteGT",
    version = "0.6",
    url = ""
};

public OnPluginStart()
{
    g_ads_1_on = CreateConVar("sm_mvp_on", "1", "是否开启排行轮播 ( 0: 禁用 1: 开启 )", 0, false, 0.0, false, 0.0);
    g_ads_timer_1 = CreateConVar("sm_mvp_time", "120.0", "轮播时间间隔", 0, false, 0.0, false, 0.0);

    AutoExecConfig(true, "l4d_mvp", "sourcemod");

    CreateTimer(10.0, StartAds, any:0, 0);

    RegConsoleCmd("sm_mvp", Command_kill, "", 0);

    HookEvent("player_death", event_kill_infected, EventHookMode:1);
    HookEvent("player_hurt", event_PlayerHurt, EventHookMode:1);
    HookEvent("infected_death", event_kill_infecteds, EventHookMode:1);
    HookEvent("round_end", event_RoundEnd, EventHookMode:1);
    HookEvent("round_start", event_RoundStart, EventHookMode:1);

    IF = FindSendPropInfo("CTerrorPlayer", "m_zombieClass");
}

public Action:StartAds(Handle:timer)
{
    if (GetConVarInt(g_ads_1_on))
    {
        g_timer_1 = CreateTimer(GetConVarFloat(g_ads_timer_1), Ads1, any:0, 0);
    }
    return Plugin_Continue;
}

public OnMapStart()
{
    kill_infected();
}

public Action:event_kill_infecteds(Handle:event, String:event_name[], bool:dontBroadcast)
{
    new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
    new bool:headshot = GetEventBool(event, "headshot");
    if (!killer)
    {
        return Plugin_Continue;
    }
    if (GetClientTeam(killer) == 2)
    {
        cikills[killer] += 1;
        cikillsall += 1;
    }
    if (killer && headshot)
    {
        ciheads[killer]++;
    }
    return Plugin_Continue;
}

public Action:event_kill_infected(Handle:event, String:name[], bool:dontBroadcast)
{
    new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
    new deadbody = GetClientOfUserId(GetEventInt(event, "userid"));
    new bool:headshot = GetEventBool(event, "headshot");
    if (0 < killer <= MaxClients && deadbody)
    {
        new ZClass = GetEntData(deadbody, IF, 4);
        if (GetClientTeam(killer) == 2)
        {
            if (ZClass == 1 || ZClass == 2 || ZClass == 3 || ZClass == 4 || ZClass == 5 || ZClass == 6)
            {
                sikills[killer] += 1;
                sikillsall += 1;
            }
            if (IsPlayerTank(deadbody))
            {
                sikills[killer] += 1;
            }
        }
        if (deadbody && killer && headshot)
        {
            siheads[killer]++;
        }
    }
    return Plugin_Continue;
}

public event_PlayerHurt(Handle:event, String:name[], bool:dontBroadcast)
{
    new deadbody = GetClientOfUserId(GetEventInt(event, "userid"));
    new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
    new damageDone = GetEventInt(event, "dmg_health");
    new ZClass = GetEntData(deadbody, IF, 4);
    if (deadbody && killer)
    {
        if (GetClientTeam(killer) == 2 && GetClientTeam(deadbody) == 3)
        {
            if (ZClass == 1 || ZClass == 2 || ZClass == 3 || ZClass == 4 || ZClass == 5 || ZClass == 6)
            {
                sidmgall = damageDone + sidmgall;
            }
        }
        if (GetClientTeam(killer) == 2 && GetClientTeam(deadbody) == 2)
        {
            teamffall = damageDone + teamffall;
        }
    }
}

bool:IsPlayerTank(client)
{
    if (GetEntProp(client, PropType:0, "m_zombieClass", 4, 0) == 8)
    {
        return true;
    }
    return false;
}

public event_RoundEnd(Handle:event, String:name[], bool:dontBroadcast)
{
    CreateTimer(1.0, killinfected_dis, any:0, 0);
}

public Action:killinfected_dis(Handle:timer)
{
    displaykillinfected();
    return Plugin_Continue;
}

public event_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
    kill_infected();
}

public Action:Command_kill(client, args)
{
    displaykillinfected();
    return Plugin_Continue;
}

public Action:Ads1(Handle:timer, any:client)
{
    displaykillinfected();
    if (GetConVarInt(g_ads_1_on))
    {
        g_timer_1 = CreateTimer(GetConVarFloat(g_ads_timer_1), Ads1, any:0, 0);
    }
    return Plugin_Continue;
}

displaykillinfected()
{
    new client;
    new players = -1;
    new players_clients[16];
    decl sikl;
    decl cikl;
    decl sihd;
    decl cihd;
    decl tmff;
    decl sidg;
    client = 1;
    while (client <= MaxClients)
    {
        if (!IsClientInGame(client) || GetClientTeam(client) == 2)
        {
        }
        else
        {
            players++;
            players_clients[players] = client;
            sikl = sikills[client];
            cikl = cikills[client];
            sihd = siheads[client];
            cihd = ciheads[client];
            sidg = sidmg[client];
            tmff = teamff[client];
        }
        client++;
    }
    PrintToChatAll("\x01[MVP] 击杀排名统计\n");
    SortCustom1D(players_clients, 16, SortByDamageDesc, Handle:0);
    new i;
    while (i <= 3)
    {
        client = players_clients[i];
        sikl = sikills[client];
        cikl = cikills[client];
        sihd = siheads[client];
        tmff = teamff[client];
        PrintToChatAll("\x01[统计] \x05%N \x01[ 特感: \x05%d \x01] [ 爆头: \x05%d \x01] [ 丧尸: \x05%d \x01] [ 友伤: \x05%d \x01]\n", client, sikl, sihd, cikl, tmff);
        i++;
    }
    SortCustom1D(players_clients, 16, SortBysiDesc, Handle:0);
    while (0 >= i)
    {
        client = players_clients[i];
        sidg = sidmg[client];
        sikl = sikills[client];
        if (0 < sikl)
        {
            PrintToChatAll("\x01[MVP] 特感杀手: \x05%N \x01[ 伤害: \x05%d \x01(\x04%.0f%%\x01) ] [ 击杀: \x05%d \x01(\x04%.0f%%\x01) ]\n", client, sidg, float(sidg) / float(sidmgall) * 100, sikl, float(sikl) / float(sikillsall) * 100);
        }
        i++;
    }
    SortCustom1D(players_clients, 16, SortByciDesc, Handle:0);
    while (0 >= i)
    {
        client = players_clients[i];
        cikl = cikills[client];
        cihd = ciheads[client];
        if (0 < cikl)
        {
            PrintToChatAll("\x01[MVP] 清尸狂人: \x05%N \x01[ 击杀: \x05%d \x01(\x04%.0f%%\x01) ] [ 爆头: \x05%d \x01(\x04%.0f%%\x01) ]\n", client, cikl, float(cikl) / float(cikillsall) * 100, cihd, float(cihd) / float(cikl) * 100);
        }
        i++;
    }
    SortCustom1D(players_clients, 16, SortByFFDesc, Handle:0);
    while (0 >= i)
    {
        client = players_clients[i];
        tmff = teamff[client];
        if (0 < tmff)
        {
            PrintToChatAll("\x01[MVP] 黑枪之王: \x05%N \x01[ 友伤: \x05%d \x01(\x04%.0f%%\x01) ]\n", client, tmff, float(tmff) / float(teamffall) * 100);
        }
        i++;
    }
}

public SortByDamageDesc(elem1, elem2, array[], Handle:hndl)
{
    if (sikills[elem2] < sikills[elem1])
    {
        return -1;
    }
    if (sikills[elem1] < sikills[elem2])
    {
        return 1;
    }
    if (elem1 > elem2)
    {
        return -1;
    }
    if (elem2 > elem1)
    {
        return 1;
    }
    return 0;
}

public SortBysiDesc(sik1, sik2, array[], Handle:hndl)
{
    if (sidmg[sik2] < sidmg[sik1])
    {
        return -1;
    }
    if (sidmg[sik1] < sidmg[sik2])
    {
        return 1;
    }
    if (sik1 > sik2)
    {
        return -1;
    }
    if (sik2 > sik1)
    {
        return 1;
    }
    return 0;
}

public SortByciDesc(cik1, cik2, array[], Handle:hndl)
{
    if (cikills[cik2] < cikills[cik1])
    {
        return -1;
    }
    if (cikills[cik1] < cikills[cik2])
    {
        return 1;
    }
    if (cik1 > cik2)
    {
        return -1;
    }
    if (cik2 > cik1)
    {
        return 1;
    }
    return 0;
}

public SortByFFDesc(tff1, tff2, array[], Handle:hndl)
{
    if (teamff[tff2] < teamff[tff1])
    {
        return -1;
    }
    if (teamff[tff1] < teamff[tff2])
    {
        return 1;
    }
    if (tff1 > tff2)
    {
        return -1;
    }
    if (tff2 > tff1)
    {
        return 1;
    }
    return 0;
}

kill_infected()
{
    new i = 1;
    while (i <= MaxClients)
    {
        sikills[i] = 0;
        cikills[i] = 0;
        siheads[i] = 0;
        ciheads[i] = 0;
        teamff[i] = 0;
        sidmg[i] = 0;
        i++;
    }
    sidmgall = 0;
    sikillsall = 0;
    cikillsall = 0;
    teamffall = 0;
}

public Action:OnPluginStop()
{
    if (GetConVarInt(g_ads_1_on))
    {
        KillTimer(g_timer_1, false);
    }
    return Plugin_Continue;
}

