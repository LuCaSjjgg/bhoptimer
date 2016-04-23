/*
 * shavit's Timer - Player Stats
 * by: shavit
 *
 * This file is part of shavit's Timer.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
*/

#include <sourcemod>
#include <shavit>

#pragma semicolon 1
#pragma dynamic 131072 // let's make stuff faster
#pragma newdecls required // We're at 2015 :D

// database handle
Database gH_SQL = null;

// table prefix
char gS_MySQLPrefix[32];

public Plugin myinfo =
{
	name = "[shavit] Player Stats",
	author = "shavit",
	description = "Player stats for shavit's bhop timer.",
	version = SHAVIT_VERSION,
	url = "http://forums.alliedmods.net/member.php?u=163134"
}

public void OnAllPluginsLoaded()
{
	if(!LibraryExists("shavit-wr"))
	{
		SetFailState("shavit-wr is required for the plugin to work.");
	}

	// database related stuff
	Shavit_GetDB(gH_SQL);
	SetSQLInfo();
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_profile", Command_Profile, "Show the player's profile. Usage: sm_profile [target]");
	RegConsoleCmd("sm_stats", Command_Profile, "Show the player's profile. Usage: sm_profile [target]");

	RegConsoleCmd("sm_mapsdone", Command_Mapsdone, "Show maps that the player have done already. Usage: sm_mapsdone [target]");
	RegConsoleCmd("sm_mapsleft", Command_Mapsleft, "Show maps that the player doesn't have them cleared yet. Usage: sm_mapsleft [target]");

	RegConsoleCmd("sm_mapsdonesw", Command_MapsdoneSW, "[SW] Show maps done. Usage: sm_mapsdonesw [target]");
	RegConsoleCmd("sm_mapsleftsw", Command_MapsleftSW, "[SW] Show maps that the player doesn't have them cleared yet. Usage: sm_mapsleftsw [target]");

	LoadTranslations("common.phrases");
}

public void OnPrefixChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	strcopy(gS_MySQLPrefix, 32, newValue);
}

public Action CheckForSQLInfo(Handle Timer)
{
	return SetSQLInfo();
}

public Action SetSQLInfo()
{
	float fTime = 0.0;

	if(gH_SQL == null)
	{
		fTime = 0.5;
	}

	else
	{
		ConVar cvMySQLPrefix = FindConVar("shavit_core_sqlprefix");

		if(cvMySQLPrefix != null)
		{
			cvMySQLPrefix.GetString(gS_MySQLPrefix, 32);
			cvMySQLPrefix.AddChangeHook(OnPrefixChange);

			return Plugin_Stop;
		}

		fTime = 1.0;
	}

	CreateTimer(fTime, CheckForSQLInfo);

	return Plugin_Continue;
}

public Action Command_Mapsdone(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}

	int target = client;

	if(args > 0)
	{
		char[] sArgs = new char[64];
		GetCmdArgString(sArgs, 64);

		target = FindTarget(client, sArgs, true, false);

		if(target == -1)
		{
			return Plugin_Handled;
		}
	}

	ShowMaps(client, target, "mapsdone");

	return Plugin_Handled;
}

public Action Command_Mapsleft(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}

	int target = client;

	if(args > 0)
	{
		char[] sArgs = new char[64];
		GetCmdArgString(sArgs, 64);

		target = FindTarget(client, sArgs, true, false);

		if(target == -1)
		{
			return Plugin_Handled;
		}
	}

	ShowMaps(client, target, "mapsleft");

	return Plugin_Handled;
}

public Action Command_MapsdoneSW(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}

	int target = client;

	if(args > 0)
	{
		char[] sArgs = new char[64];
		GetCmdArgString(sArgs, 64);

		target = FindTarget(client, sArgs, true, false);

		if(target == -1)
		{
			return Plugin_Handled;
		}
	}

	ShowMaps(client, target, "mapsdonesw");

	return Plugin_Handled;
}

public Action Command_MapsleftSW(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}

	int target = client;

	if(args > 0)
	{
		char[] sArgs = new char[64];
		GetCmdArgString(sArgs, 64);

		target = FindTarget(client, sArgs, true, false);

		if(target == -1)
		{
			return Plugin_Handled;
		}
	}

	ShowMaps(client, target, "mapsleftsw");

	return Plugin_Handled;
}

public Action Command_Profile(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}

	int target = client;

	if(args > 0)
	{
		char[] sArgs = new char[64];
		GetCmdArgString(sArgs, 64);

		target = FindTarget(client, sArgs, true, false);

		if(target == -1)
		{
			return Plugin_Handled;
		}
	}

	char[] sAuthID = new char[32];
	GetClientAuthId(target, AuthId_Steam3, sAuthID, 32);

	Menu m = new Menu(MenuHandler_Profile);
	m.SetTitle("%N's profile.\nSteamID3: %s", target, sAuthID);

	m.AddItem("mapsdone", "Maps done (Forwards)");
	m.AddItem("mapsleft", "Maps left (Forwards)");
	m.AddItem("mapsdonesw", "Maps done (Sideways)");
	m.AddItem("mapsleftsw", "Maps left (Sideways)");

	char[] sTarget = new char[8];
	IntToString(target, sTarget, 8);

	m.AddItem("id", sTarget, ITEMDRAW_IGNORE);

	m.ExitButton = true;

	m.Display(client, 20);

	return Plugin_Handled;
}

public int MenuHandler_Profile(Menu m, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char[] info = new char[16];

		int target;

		for(int i = 0; i < m.ItemCount; i++)
		{
			char[] data = new char[8];
			m.GetItem(i, info, 16, _, data, 8);

			if(StrEqual(info, "id"))
			{
				target = StringToInt(data);

				break;
			}
		}

		m.GetItem(param2, info, 16);

		ShowMaps(param1, target, info);
	}

	else if(action == MenuAction_End)
	{
		delete m;
	}

	return 0;
}

// mapsleft - https://forums.alliedmods.net/showpost.php?p=2106711&postcount=4
public void ShowMaps(int client, int target, const char[] category)
{
	char[] sAuth = new char[32];
	GetClientAuthId(target, AuthId_Steam3, sAuth, 32);

	char[] sQuery = new char[256];

	if(StrContains(category, "done") != -1)
	{
		FormatEx(sQuery, 256, "SELECT map, time, jumps FROM %splayertimes WHERE auth = '%s' AND style = %d ORDER BY map;", gS_MySQLPrefix, sAuth, StrEqual(category, "mapsdone")? 0:1);
	}

	else
	{
		FormatEx(sQuery, 256, "SELECT DISTINCT m.map FROM %smapzones m LEFT JOIN %splayertimes r ON r.map = m.map AND r.auth = '%s' AND r.style = %d WHERE r.map IS NULL ORDER BY m.map;", gS_MySQLPrefix, gS_MySQLPrefix, sAuth, StrEqual(category, "mapsleft")? 0:1);
		// PrintToConsole(client, sQuery);
	}

	DataPack datapack = new DataPack();
	datapack.WriteCell(GetClientSerial(client));
	datapack.WriteCell(GetClientSerial(target));
	datapack.WriteString(category);

	gH_SQL.Query(ShowMapsCallback, sQuery, datapack, DBPrio_High);
}

public void ShowMapsCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == null)
	{
		delete view_as<DataPack>(data);

		LogError("Timer (ShowMaps SELECT) SQL query failed. Reason: %s", error);

		return;
	}

	ResetPack(data);

	int clientserial = ReadPackCell(data);
	int targetserial = ReadPackCell(data);

	char[] sCategory = new char[16];
	ReadPackString(data, sCategory, 16);

	delete view_as<DataPack>(data);

	int client = GetClientFromSerial(clientserial);

	if(!IsValidClient(client))
	{
		return;
	}

	int target = GetClientFromSerial(targetserial);

	if(!IsValidClient(client))
	{
		return;
	}

	int rows = SQL_GetRowCount(hndl);

	char[] sTitle = new char[64];

	if(StrEqual(sCategory, "mapsdone"))
	{
		FormatEx(sTitle, 32, "Maps done for %N: (%d)", target, rows);
	}

	else if(StrEqual(sCategory, "mapsleft"))
	{
		FormatEx(sTitle, 32, "Maps left for %N: (%d)", target, rows);
	}

	else if(StrEqual(sCategory, "mapsdonesw"))
	{
		FormatEx(sTitle, 32, "[SW] Maps done for %N: (%d)", target, rows);
	}

	else if(StrEqual(sCategory, "mapsleftsw"))
	{
		FormatEx(sTitle, 32, "[SW] Maps left for %N: (%d)", target, rows);
	}

	Menu m = new Menu(MenuHandler_ShowMaps);
	m.SetTitle(sTitle);

	while(SQL_FetchRow(hndl))
	{
		char[] sMap = new char[128];
		SQL_FetchString(hndl, 0, sMap, 128);

		char[] sDisplay = new char[192];

		if(StrContains(sCategory, "done") != -1)
		{
			float time = SQL_FetchFloat(hndl, 1);
			int jumps = SQL_FetchInt(hndl, 2);

			char[] sTime = new char[32];
			FormatSeconds(time, sTime, 32);

			FormatEx(sDisplay, 192, "%s - %s (%d jumps)", sMap, sTime, jumps);
		}

		else
		{
			strcopy(sDisplay, 192, sMap);
		}

		// adding map as info, may be used in the future
		m.AddItem(sMap, sDisplay);
	}

	if(!GetMenuItemCount(m))
	{
		m.AddItem("nope", "No results.");
	}

	m.ExitButton = true;

	m.Display(client, 60);
}

public int MenuHandler_ShowMaps(Menu m, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
	{
		delete m;
	}

	return 0;
}
