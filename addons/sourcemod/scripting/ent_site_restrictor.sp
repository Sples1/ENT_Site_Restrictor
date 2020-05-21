/*
 * SourceMod Entity Projects
 * by: Entity
 *
 * Copyright (C) 2020 Kőrösfalvi "Entity" Martin
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */
 
#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#pragma newdecls required

char PREFIX[] = "{default}「{lightred}RestrictSite{default}」";

public Plugin myinfo =
{
	name = "[CSGO] Site Restrictor", 
	author = "Entity", 
	description = "Site restrictor under 5v5", 
	version = "1.1"
};

int gShadow_BombsiteA = -1;
int gShadow_BombsiteB = -1;

int PlayersInCT = 0;
int PlayersInT = 0;
char DeniedSite[8];

EngineVersion g_EngineVersion;

public void OnPluginStart()
{
	g_EngineVersion = GetEngineVersion();
	if (g_EngineVersion != Engine_CSGO && g_EngineVersion != Engine_CSS)
	{
		SetFailState("This plugin is developed for CS:GO and CS:S");
	}

	LoadTranslations("ent_site_restrictor.phrases");
	
	HookEvent("round_start", Event_RoundStart);
}

public void OnMapStart()
{
	GetBomsitesIndexes();
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	GetBomsitesIndexes();

	if (gShadow_BombsiteA != -1) AcceptEntityInput(gShadow_BombsiteA, "Enable");
	if (gShadow_BombsiteB != -1) AcceptEntityInput(gShadow_BombsiteB, "Enable");

	if (gShadow_BombsiteA != -1 && gShadow_BombsiteB != -1)
	{
		PlayersInCT = 0; PlayersInT = 0;
		
		if(GameRules_GetProp("m_bWarmupPeriod") != 1)
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsValidClient(i))
				{
					if (GetClientTeam(i) == CS_TEAM_CT) PlayersInCT++;
					else if (GetClientTeam(i) == CS_TEAM_T) PlayersInT++;
				}
			}
			
			if ((PlayersInCT < 5) || (PlayersInT < 5))
			{
				int Random_Site_Num = GetRandomInt(0, 1);
				
				if (Random_Site_Num == 0)
				{
					Format(DeniedSite, sizeof(DeniedSite), "B");
					AcceptEntityInput(gShadow_BombsiteB, "Disable");
				}
				else if (Random_Site_Num == 1)
				{
					Format(DeniedSite, sizeof(DeniedSite), "A");
					AcceptEntityInput(gShadow_BombsiteA, "Disable");
				}
				
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i))
					{
						CPrintToChat(i, "%s %t", PREFIX, "Bombsite Disabled Colored", DeniedSite);
						PrintCenterText(i, "%t", "Bombsite Disabled", DeniedSite)
					}
				}
			}
		}
	}
}

stock void GetBomsitesIndexes()
{
	int index = -1;
    
	float vecBombsiteCenterA[3];
	float vecBombsiteCenterB[3];
    
	gShadow_BombsiteA = -1;
	gShadow_BombsiteB = -1;
	
	index = FindEntityByClassname(index, "cs_player_manager");
	if (index != -1)
	{
		GetEntPropVector(index, Prop_Send, "m_bombsiteCenterA", vecBombsiteCenterA);
		GetEntPropVector(index, Prop_Send, "m_bombsiteCenterB", vecBombsiteCenterB);
	}

	index = -1;
	while ((index = FindEntityByClassname(index, "func_bomb_target")) != -1)
	{
		float vecBombsiteMin[3];
		float vecBombsiteMax[3];
		
		GetEntPropVector(index, Prop_Send, "m_vecMins", vecBombsiteMin);
		GetEntPropVector(index, Prop_Send, "m_vecMaxs", vecBombsiteMax);
		
		if (IsVecBetween(vecBombsiteCenterA, vecBombsiteMin, vecBombsiteMax))
		{
			gShadow_BombsiteA = index;
		}
		else if (IsVecBetween(vecBombsiteCenterB, vecBombsiteMin, vecBombsiteMax))
		{
			gShadow_BombsiteB = index;
		}
	}
}

stock bool IsVecBetween(const float vecVector[3], const float vecMin[3], const float vecMax[3])
{
    return ( (vecMin[0] <= vecVector[0] <= vecMax[0]) &&
             (vecMin[1] <= vecVector[1] <= vecMax[1]) &&
             (vecMin[2] <= vecVector[2] <= vecMax[2])    );
} 

stock bool IsValidClient(int client)
{
	if((1 <= client <= MaxClients) && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client))
	{
		return true;
	}
	return false;
}