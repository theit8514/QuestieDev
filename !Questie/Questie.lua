--[[
local L_DB_Creatures = DB_Creatures;
local L_DB_Gameobjects = DB_Gameobjects;
local L_DB_Items = DB_Items;
local L_DB_DB_Quests = DB_Quest;
local L_DB_QuestLookup = DB_QuestLookup;
local L_DB_Zones = DB_Zones;
]]--

-----------------------------------------------------------------------------
--Storing global functions as local speeds up it's use. also fuck you lua why u do dis --PERFORMANCE CHANGE--
-----------------------------------------------------------------------------
local strfind = string.find
local strlen = string.len
local gsub = gsub
local pairs = pairs
local ipairs = ipairs
local type = type
local tinsert = table.insert
local tremove = table.remove
local unpack = unpack
local max = math.max
local floor = floor
local ceil = ceil
local loadstring = loadstring
local tostring = tostring
local setmetatable = setmetatable
local getmetatable = getmetatable
local getn = table.getn
local format = format
local sin = math.sin
local min = math.min;
local byte = string.byte;
-----------------------------------------------------------------------------
--End of globals
-----------------------------------------------------------------------------


local Races = {
	["Human"] = 1,
	["Orc"] = 2,
	["Dwarf"] = 4,
	["NightElf"] = 8,
	["Scourge"] = 16,
	["Tauren"] = 32,
	["Gnome"] = 64,
	["Troll"] = 128,
}


local Classes = {
	["WARRIOR"] = 1,
	["PALADIN"] = 2,
	["HUNTER"] = 4,
	["ROGUE"] = 8,
	["PRIEST"] = 16,
	["DEATHKNIGHT"] = 32, --we live in the future here
	["SHAMAN"] = 64,
	["MAGE"] = 128,
	["WARLOCK"] = 256,
	["DRUID"] = 1024,
}

local ShowLowLevelQuests = nil;

local Faction, _ = UnitFactionGroup("player");
local _, Race = UnitRace("player");
local _, Class = UnitClass("player");

local DB_ZoneQuestLookup = {};

local DB_CreatureLookup = {};
local DB_GameobjectLookup = {};

local Questie = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0",  "AceDB-2.0", "AceDebug-2.0", "AceEvent-2.0", "AceHook-2.1", "AceComm-2.0");

Questie.MajorVersion = 3;
Questie.Minorversion = 1;



function Questie:OnInitialize()
	Questie:debug_Print("Questie: Initialized!");

	--Event Registers
	Questie:RegisterEvent("QUEST_LOG_UPDATE", Questie.QuestLogEvents);
	Questie:RegisterEvent("DelayedUpdate", Questie.DelayedUpdater);
	--Questie:RegisterEvent("CHAT_MSG_CHANNEL_JOIN", Questie.OnJoin);
	--Questie:RegisterEvent("CHAT_MSG_CHANNEL", Questie.OnMessage);

	Questie:ScheduleEvent("DelayedUpdate",1);

	--Questie:RegisterEvent("JoinVersionChannel", Questie.CheckVersionChannel);
	--Questie:ScheduleEvent("JoinVersionChannel",5);

	--If this is true SetDefault values;
	if(QuestieConfig == nil) then
		QuestieConfig = {};
		QuestieConfig.tracker = 1;
		QuestieConfig.debug = 0;
		QuestieConfig.trackall = 0;
	end

	--Todo: Do filtering before activating continent check
	DB_ZoneQuestLookup[1] = {};
	DB_ZoneQuestLookup[1][0] = {};
	DB_ZoneQuestLookup[2] = {};
	DB_ZoneQuestLookup[2][0] = {};
	DB_ZoneQuestLookup[0] = {};
	DB_ZoneQuestLookup[0][0] = {};
	for Qid, Data in DB_Quests do
		for index, NPC in Data.Starter do
			if(DB_Creatures[NPC.ID] and DB_Creatures[NPC.ID].Locations) then
				if(table.getn(DB_Creatures[NPC.ID].Locations) > 5) then 
					--DEFAULT_CHAT_FRAME:AddMessage("QID:"..Qid.." NPC:"..DB_Creatures[NPC.ID].Name.." has more than 5 locations");
					local zones = Questie:CalcHotzones(DB_Creatures[NPC.ID].Locations,10);
					local t = Questie:CenterPoint(zones[1]);
					if(DB_ZoneQuestLookup[t.c][t.z] == nil) then DB_ZoneQuestLookup[t.c][t.z] = {}; end
					if(DB_ZoneQuestLookup[t.c][t.z][NPC.ID] == nil) then DB_ZoneQuestLookup[t.c][t.z][NPC.ID] = {}; end
					if(DB_ZoneQuestLookup[t.c][0][NPC.ID] == nil) then DB_ZoneQuestLookup[t.c][0][NPC.ID] = {}; end
					if getn(t) == 1 then
							table.insert(DB_ZoneQuestLookup[t.c][t.z][NPC.ID], Qid);
							table.insert(DB_ZoneQuestLookup[t.c][0][NPC.ID], Qid);
							table.insert(DB_ZoneQuestLookup[0][0][NPC.ID], Qid);
					else
						--TODO DRAW POLYGON INSTEAD!!!
						--Questie:debug_Print("QID: "..Qid," Name: '"..Data.Title,"' More than one zone TODO!!!")
						table.insert(DB_ZoneQuestLookup[t.c][t.z][NPC.ID], Qid);
						table.insert(DB_ZoneQuestLookup[t.c][0][NPC.ID], Qid);
					end
				else
					for k, Pos in DB_Creatures[NPC.ID].Locations do
						if(DB_ZoneQuestLookup[Pos.c][Pos.z] == nil) then DB_ZoneQuestLookup[Pos.c][Pos.z] = {}; end
						if(DB_ZoneQuestLookup[Pos.c][Pos.z][NPC.ID] == nil) then DB_ZoneQuestLookup[Pos.c][Pos.z][NPC.ID] = {}; end
						if(DB_ZoneQuestLookup[Pos.c][0][NPC.ID] == nil) then DB_ZoneQuestLookup[Pos.c][0][NPC.ID] = {}; end
						if(DB_ZoneQuestLookup[0][0][NPC.ID] == nil) then DB_ZoneQuestLookup[0][0][NPC.ID] = {}; end
						table.insert(DB_ZoneQuestLookup[Pos.c][Pos.z][NPC.ID], Qid);
						table.insert(DB_ZoneQuestLookup[Pos.c][0][NPC.ID], Qid);
						table.insert(DB_ZoneQuestLookup[0][0][NPC.ID], Qid);
					end
				end
			end
		end

		for index, NPC in Data.Finisher do
			if(NPC and NPC.ID and DB_Creatures[NPC.ID] and DB_Creatures[NPC.ID].Locations and getn(DB_Creatures[NPC.ID].Locations) > 0) then
				if(table.getn(DB_Creatures[NPC.ID].Locations) > 5) then 
					--DEFAULT_CHAT_FRAME:AddMessage("QID:"..Qid.." NPC:"..DB_Creatures[NPC.ID].Name.." has more than 5 locations");
					local zones = Questie:CalcHotzones(DB_Creatures[NPC.ID].Locations,10);
					local t = Questie:CenterPoint(zones[1]);
					if(DB_ZoneQuestLookup[t.c][t.z] == nil) then DB_ZoneQuestLookup[t.c][t.z] = {}; end
					if(DB_ZoneQuestLookup[t.c][t.z][NPC.ID] == nil) then DB_ZoneQuestLookup[t.c][t.z][NPC.ID] = {}; end
					if(DB_ZoneQuestLookup[t.c][0][NPC.ID] == nil) then DB_ZoneQuestLookup[t.c][0][NPC.ID] = {}; end
					if getn(t) == 1 then
						local a = true;
						for _, v in DB_ZoneQuestLookup[t.c][t.z][NPC.ID] do
							if(v == Qid) then
								a = false;
							end
						end
						if(a == true)then
							table.insert(DB_ZoneQuestLookup[t.c][t.z][NPC.ID], Qid);
							table.insert(DB_ZoneQuestLookup[t.c][0][NPC.ID], Qid);
							table.insert(DB_ZoneQuestLookup[0][0][NPC.ID], Qid);
						end
					else
						--TODO DRAW POLYGON INSTEAD!!!
						--Questie:debug_Print("QID: "..Qid," Name: '"..Data.Title,"' More than one zone TODO!!!")
						local a = true;
						for _, v in DB_ZoneQuestLookup[t.c][t.z][NPC.ID] do
							if(v == Qid) then
								a = false;
							end
						end
						if(a == true)then
							table.insert(DB_ZoneQuestLookup[t.c][t.z][NPC.ID], Qid);
							table.insert(DB_ZoneQuestLookup[t.c][0][NPC.ID], Qid);
						end
					end
				else
					for k, Pos in DB_Creatures[NPC.ID].Locations do
						if(DB_ZoneQuestLookup[Pos.c] == nil) then DB_ZoneQuestLookup[Pos.c] = {}; end
						if(DB_ZoneQuestLookup[Pos.c][Pos.z] == nil) then DB_ZoneQuestLookup[Pos.c][Pos.z] = {}; end
						if(DB_ZoneQuestLookup[Pos.c][Pos.z][NPC.ID] == nil) then DB_ZoneQuestLookup[Pos.c][Pos.z][NPC.ID] = {}; end
						if(DB_ZoneQuestLookup[Pos.c][0] == nil) then DB_ZoneQuestLookup[Pos.c][0] = {}; end
						if(DB_ZoneQuestLookup[Pos.c][0][NPC.ID] == nil) then DB_ZoneQuestLookup[Pos.c][0][NPC.ID] = {}; end
						if(DB_ZoneQuestLookup[0][0][NPC.ID] == nil) then DB_ZoneQuestLookup[0][0][NPC.ID] = {}; end
						local a = true;
						for _, v in DB_ZoneQuestLookup[Pos.c][Pos.z][NPC.ID] do
							if(v == Qid) then
								a = false;
							end
						end
						if(a == true)then
							table.insert(DB_ZoneQuestLookup[Pos.c][Pos.z][NPC.ID], Qid);
							table.insert(DB_ZoneQuestLookup[Pos.c][0][NPC.ID], Qid);
							table.insert(DB_ZoneQuestLookup[0][0][NPC.ID], Qid);
						end
					end
				end
			end
		end
	end
	Questie:debug_Print("Questie: DB_ZoneQuestLookup Created!");

	for NPCID, Data in DB_Creatures do
		DB_CreatureLookup[Data.Name] = NPCID;
	end
	Questie:debug_Print("Questie: DB_CreatureLookup Created!");

	for GOID, Data in DB_Gameobjects do
		DB_GameobjectLookup[Data.Name] = GOID;
	end
	Questie:debug_Print("Questie: DB_GameobjectLookup Created!");

	BMS:RegisterAddon("Questie", Questie);
	DataStore_Quests_API:RegisterAddon("Questie", Questie);

	Questie:RegisterChatCommand({ "/questie" }, {
		  type = "group",
		  args = {
		    send = {
		      type = "execute",
		      name = "Sends version message",
		      desc = "Sends version message (BROKEN)",
		      func =function ()
		      			for k, v in DataStore_Quests_API:GetTrackedQuests() do
		      				DEFAULT_CHAT_FRAME:AddMessage(tostring(k).." "..tostring(v));
		      			end
				    end
		    },
		    --[[config = {
		      type = "execute",
		      name = "Config",
		      desc = "Open the configuration window",
		      func =function(arg1)
		        		DEFAULT_CHAT_FRAME:AddMessage(tostring(arg1));
		      		end
		    },]]--
		    tracker = {
				type = "toggle",
				name = "Toggle Questie Tracker",
				desc = "Toggles the display of Questies tracker, contra other addons",
				get = function()
					return QuestieConfig.tracker == 1;
				end,
				set = function()
				    QuestieConfig.tracker = 1 - QuestieConfig.tracker;
				end
			},
			trackall = {
				type = "toggle",
				name = "Toggle Questie to track all quests",
				desc = "Toggles Questie to track all quests",
				get = function()
					return QuestieConfig.trackall == 1;
				end,
				set = function()
				    QuestieConfig.trackall = 1 - QuestieConfig.trackall;
				    Questie:ScheduleEvent("DelayedUpdate", 0.1);
				end
			},
			standby = {
				type = "toggle",
				name = "Toggle standby",
				desc = "Toggles standby of Questie [Off] == Standby",
				get = function()
					return QuestieConfig.standby == 0;
				end,
				set = function()
				    QuestieConfig.standby = 1 - QuestieConfig.standby;
				end
			},
			debug = {
				type = "toggle",
				name = "Toggle Questie debugging",
				desc = "Toggles debugging of Questie",
				get = function()
					return QuestieConfig.debug == 1;
				end,
				set = function()
				    QuestieConfig.debug = 1 - QuestieConfig.debug;
				end
			},
		  },
		});


end


local LastMsg = time();
function Questie:OnJoin(u,sender,n,channelString,o,w,channelNumber,channelName)
	if(time()-LastMsg > math.random(5,10) and channelName == "QuestieVersionControl") then
	    SendChatMessage(Questie.MajorVersion.."."..Questie.Minorversion, "CHANNEL" ,nil ,channelNumber);
	    LastMsg = time();
	end
end


local WarningDone = nil;
function Questie:OnMessage()
	--DEFAULT_CHAT_FRAME:AddMessage(tostring(this)..tostring(event)..tostring(arg1)..tostring(arg2)..tostring(arg3)..tostring(arg4)..tostring(arg5)..tostring(arg6)..tostring(arg7)..tostring(arg8)..tostring(arg9)..tostring(arg10));
	if(string.lower(arg9) == "questieversioncontrol" and WarningDone == nil) then
		if(tonumber(arg1) == tonumber(Questie.MajorVersion.."."..Questie.Minorversion)) then
			DEFAULT_CHAT_FRAME:AddMessage("New Questie version available! Download at https://www.github.com/AeroScripts/QuestieDev",0,1,0)
			WarningDone = true;
		end
	end
end

----------------------------------------
------Checks the reqClass bitmask in the DB if you are indeed one of the classes required, 1 if you are, nil if you are not
----------------------------------------
function Questie:CheckClass(reqClass)
	if(bit.band(reqClass, Classes[Class]) ~= 0 or reqClass == 0) then
		return 1;
	end
	return nil;
end

----------------------------------------
------Checks the reqRace bitmask in the DB if you are indeed one of the races required, 1 if you are, nil if you are not
----------------------------------------
function Questie:CheckFaction(reqRace)
	if(bit.band(reqRace, Races[Race]) ~= 0 or reqRace == 0) then
		return 1;
	end
	return nil;
end

----------------------------------------
------Used to check how the creature reacts towards the player, Return 1 if friendly / Neutral, nil if hostile
----------------------------------------
function Questie:CheckFriendly(react)
	if react == nil then return nil; end
	while(Faction == nil) do
		Faction, _ = UnitFactionGroup("player");
	end
	if(Faction == "Alliance") then
		if(react.A >= 0) then
			return 1;
		else
			return nil;
		end
	else
		if(react.H >= 0) then
			return 1;
		else
			return nil;
		end
	end
end

----------------------------------------
------Used to check if we have the proffesion and skill required for a quest
----------------------------------------
function Questie:CheckProffesions(reqSkill)
	if(reqSkill == 0) then return true; end;
	--TODO Cant seem to be able to check current proffesions :(

end

----------------------------------------
------Gets the center point of a set of points
----------------------------------------
function Questie:CenterPoint(points)
	local center = {};
	center.x = 0;
	center.y = 0;
	--TODO Check if this is correct
	center.z = points[1].z;
	center.c = points[1].c;
	for i=1, table.getn(points) do
		center.x = center.x + points[i].x
		center.y = center.y + points[i].y
	end
	center.x = center.x / table.getn(points);
	center.y = center.y / table.getn(points);
	return center;
end

function Questie:QuestUpdateEvent(QuestID)
	--DEFAULT_CHAT_FRAME:AddMessage(tostring(QuestID));
	Questie:ScheduleEvent("DelayedUpdate",0.5);
end


local Old_QuestLogTitle = {};
local FirstRun = true;
function Questie:DelayedUpdater()
	--DEFAULT_CHAT_FRAME:AddMessage("delayed");
	BMS:Refresh(true);
	if(FirstRun) then
		if(IsAddOnLoaded("EQL3")) then
			Questie:debug_Print("EQL3 Questlog loaded!");
			for i = 1, 20 do
				Old_QuestLogTitle[i] = getglobal("EQL3_QuestLogTitle"..i):GetScript("OnClick");
				Questie:HookScript(getglobal("EQL3_QuestLogTitle"..i),"OnClick", Questie.TrackHook);
			end
		else
			Questie:debug_Print("Standard Questlog loaded!");
			for i = 1, 20 do
				if(getglobal("QuestLogTitle"..i)) then
					Old_QuestLogTitle[i] = getglobal("QuestLogTitle"..i):GetScript("OnClick")--QuestRewardCompleteButton_OnClick
					Questie:HookScript(getglobal("QuestLogTitle"..i),"OnClick", Questie.TrackHook);
					--DEFAULT_CHAT_FRAME:AddMessage(tostring(getglobal("QuestLogTitle"..i):GetScript("OnClick")).." "..tostring(Old_QuestLogTitle[i]));
				end
			end
		end
		LeaveChannelByName("QuestieVersionControl")
		FirstRun = nil;
	end
end


local Joined = nil;
function Questie:CheckVersionChannel()
	--DEFAULT_CHAT_FRAME:AddMessage("JOIN");
		JoinChannelByName("QuestieVersionControl");
	
		Joined = true;
end


----------------------------------------
------External call from BMS
----------------------------------------
function Questie:GetNodes(continent, zone)
local Faction, _ = UnitFactionGroup("player");
local _, Race = UnitRace("player");
local _, Class = UnitClass("player");

	--Questie:debug_Print("Questie:GetNodes Fired!");
	Notes = {};
	if(DB_ZoneQuestLookup[continent] and DB_ZoneQuestLookup[continent][zone]) then
		local CompQuests = DataStore_Quests_API:GetAllCompleteQuestsInLog();
		for i, Zone in DB_ZoneQuestLookup[continent] do
			for NPCID, QuestTable in Zone do
				--				local zones = Questie:CalcHotzones(DB_Creatures[NPC.ID].Locations,10);
				--	local t = Questie:CenterPoint(zones[1]);
				--Sets values that i want to use for the notes THIS IS WIP MORE INFO MAY BE NEDED BOTH IN PARAMETERS AND NOTES!!!
				local AvailableQuests = {};
				local CompleteQuests = {};
				--Available Quests
				for index, QuestID in QuestTable do
					local Quest = DB_Quests[QuestID];

					if(Questie:CheckFaction(Quest.reqRace) and
					 	Questie:CheckClass(Quest.reqClass) and
					 	UnitLevel("player") >= Quest.minLevel and
					 	(UnitLevel("player")-7 <= Quest.Level or ShowLowLevelQuests) and
					 	DataStore_Quests_API:isQuestCompleted(Quest.reqQuest) and
					 	not DataStore_Quests_API:isQuestCompleted(Quest.ID) and
					 	DataStore_Quests_API:OnQuest(QuestID) == nil and
					 	Questie:CheckFriendly(DB_Creatures[NPCID].React) and
					 	Questie:CheckProffesions(Quest.reqSkill))--TODO: reqSkill needs to be implemented 
					then
						for k, Data in Quest.Starter do
							if(Data.ID == NPCID) then
								table.insert(AvailableQuests, QuestID);
								break;
							end
						end
					end
				end

				--Complete Quests for NPCs
				for index, QuestID in CompQuests do
					local QuestData = DB_Quests[QuestID];
					for k, Finisher in QuestData.Finisher do
						if(Finisher.type == "NPC" and Finisher.ID == NPCID) then
							table.insert(CompleteQuests, QuestID);
						end
					end
				end

				if(getn(AvailableQuests) > 0 or getn(CompleteQuests) > 0) then
					local icon;
					if(getn(CompleteQuests) > 0) then
						icon = Icons["complete"].path;
					else
						icon = Icons["available"].path;
					end
					local zones = Questie:CalcHotzones(DB_Creatures[NPCID].Locations,10);
					if(getn(zones) <= 1) then
						local t = Questie:CenterPoint(zones[1]);
						local n = Questie:CreateNote(t, icon, Questie.AvailableQuestTooltipEnter, Questie.AvailableQuestClick, {InteractType="NPC", NPCID = NPCID, AvailableQuests=AvailableQuests, CompleteQuests=CompleteQuests})
						table.insert(Notes, n);
					else
						local points = {}
						for index, point in DB_Creatures[NPCID].Locations do
							local nX, nY = Astrolabe:TranslateWorldMapPosition(point.c, point.z, point.x, point.y, continent, zone);
							points[index] = {};
							points[index].x = nX;
							points[index].y = nY;
							points[index].c = point.c;
							points[index].z = point.z;
						end
						local center = Questie:CenterPoint(points);
						local n = Questie:CreateNote(center, icon, Questie.AvailableQuestTooltipEnter, Questie.AvailableQuestClick, {InteractType="NPC", NPCID = NPCID, AvailableQuests=AvailableQuests, CompleteQuests=CompleteQuests, PolygonPoints=points})
						table.insert(Notes, n);
					end
					--[[
					Note = {};
					Note.x = t.x;
					Note.y = t.y;
					Note.zoneid = t.z;
					Note.continent = t.c;
					Note.icon = Icons["available"].path;
					Note.Tooltip = Questie.AvailableQuestTooltip;
					Note.Click = Questie.AvailableQuestClick;
					Note.customData = {NPCID = NPCID, AvailableQuests=AvailableQuests, CompleteQuests=CompleteQuests};
					--Inserts it into the right zone and continent for later use.
					table.insert(Notes, Note);]]--
				end
			end
		end
		--Note.customData = {NPCID = NPCID, AvailableQuests=AvailableQuests, CompleteQuests=CompleteQuests};
		--Complete Quests for GameObjects
		local GO = {};
		for index, QuestID in CompQuests do
			--DEFAULT_CHAT_FRAME:AddMessage(QuestID);
			local QuestData = DB_Quests[QuestID];
			for k, Finisher in QuestData.Finisher do
				if(Finisher.type == "Object") then
					if(GO[Finisher.ID] == nil) then GO[Finisher.ID]={}; end
					table.insert(GO[Finisher.ID], QuestID);
				end
			end
		end
		for GoID, QuestTable in GO do
			local Quests = {};
			for index, Qid in QuestTable do
				table.insert(Quests, Qid);
			end
			if(DB_Gameobjects[GoID] and DB_Gameobjects[GoID].Locations) then
				local zones = Questie:CalcHotzones(DB_Gameobjects[GoID].Locations,10);
			end
			--[[
			local t = Questie:CenterPoint(zones[1]);
			local n = Questie:CreateNote(t, Icons["complete"].path, Questie.AvailableQuestTooltip, Questie.AvailableQuestClick, {InteractType="Object", NPCID = GoID, AvailableQuests={}, CompleteQuests=Quests})
			table.insert(Notes,n);]]--


			if(zones and getn(zones) <= 1) then
				local t = Questie:CenterPoint(zones[1]);
				local n = Questie:CreateNote(t, Icons["complete"].path, Questie.AvailableQuestTooltipEnter, Questie.AvailableQuestClick, {InteractType="Object", NPCID = GoID, AvailableQuests={}, CompleteQuests=Quests})
				table.insert(Notes, n);
			elseif(DB_Gameobjects[GoID] and DB_Gameobjects[GoID].Locations) then
				local points = {}
				--DEFAULT_CHAT_FRAME:AddMessage(GoID);
				for index, point in DB_Gameobjects[GoID].Locations do
					local nX, nY = Astrolabe:TranslateWorldMapPosition(point.c, point.z, point.x, point.y, continent, zone);
					points[index] = {};
					points[index].x = nX;
					points[index].y = nY;
					points[index].c = point.c;
					points[index].z = point.z;

				end
				for i = 1, table.getn(points) do	
					if(points[i].x < center.x) then
						points[i].x = points[i].x * (1-Spread);
					else
						points[i].x = points[i].x * (1+Spread);
					end

					if(points[i].y < center.y) then
						points[i].y = points[i].y * (1-Spread);
					else
						points[i].y = points[i].y * (1+Spread);
					end
				end
				local center = Questie:CenterPoint(points);
				local n = Questie:CreateNote(center, Icons["complete"].path, Questie.AvailableQuestTooltipEnter, Questie.AvailableQuestClick, {InteractType="Object", NPCID = GoID, AvailableQuests={}, CompleteQuests=Quests, PolygonPoints=points});
				table.insert(Notes, n);
			end
		end

	end
	local asdf = Questie:GetQuestObjectiveNotes(continent, zone);
	--table.insert(Notes, Questie:GetQuestObjectiveNotes());
	for k, v in asdf do
		table.insert(Notes, v);
	end
	return Notes;
end

local quests = { }
local colorValue = 0;
local colorSize = 256;
local Phi = 1.61803398; -- 1.618033988749894848204586834
function Questie:GetQuestObjectiveNotes(continent, zone)
	local Notes = {};
	local QuestData;
	if(QuestieConfig.trackall == 1) then
		QuestData = DataStore_Quests_API:GetAllQuestsInLog();
	elseif(QuestieConfig.trackall == 0) then
		QuestData = DataStore_Quests_API:GetTrackedQuests();
	end
	for ID, Data in QuestData do
		local Quest = DB_Quests[ID];
		if(Quest and Quest.Objectives) then
			local Locations = {};
			local IconList = {};
			for index, Objective in Quest.Objectives do
				local Location;
				local icon;
				if(Objective.type == "NPC") then
					Location = DB_Creatures[Objective.ID].Locations
					icon = Icons["slay"].path;
				elseif(Objective.type == "Object") then
					if(Location == nil) then Location = {}; end
					Location = DB_Gameobjects[Objective.ID].Locations
					icon = Icons["object"].path
				elseif(Objective.type == "Item") then
					icon = Icons["loot"].path
					if(DB_Items[Objective.ID] and DB_Items[Objective.ID].Sources) then
						for NPCID, source in DB_Items[Objective.ID].Sources do
							if(Location == nil) then Location = {}; end

							if(source.type == "NPC") then
								if(DB_Creatures[NPCID].Locations) then
									for k, v in DB_Creatures[NPCID].Locations do
										table.insert(Location, v);
									end
								end
							elseif(source.type == "Gameobject") then
								if(DB_Gameobjects[NPCID] and DB_Gameobjects[NPCID].Locations) then
									for k, v in DB_Gameobjects[NPCID].Locations do
										table.insert(Location, v);
									end
								end
							elseif(source.type == "Use") then
								if(DB_Uses[NPCID] and DB_Uses[NPCID].Locations) then
									for k, v in DB_Uses[NPCID].Locations do
										table.insert(Location, v);
									end
								end
							end
						end
					end
				end
				if(Data.RawObjectives[index] and Data.RawObjectives[index].isDone == nil) then
					if(Location) then
						for k, v in Location do
							table.insert(Locations, v);
						end
					end
					table.insert(IconList, {Icon = icon, InteractType=Objective.type, NPCID = Objective.ID, Objective=Objective, QuestID = ID, rawDataIndex = index});
				end
			end
			local zones = Questie:CalcHotzones(Locations,8);
			if(getn(zones) == 1) then
				zones = Questie:CalcHotzones(Locations,4)
			end

			if(getn(zones)==1 or getn(Quest.Objectives) == getn(Locations)) then

				for k, v in IconList do
					local t;
					if(getn(Quest.Objectives) ~= getn(Locations)) then
						t = Questie:CenterPoint(zones[1]);
					else
						t = Locations[k];
					end
					local IconInfo = {}
					local ic;


						table.insert(IconInfo, {InteractType=v.InteractType, Qid = v.QuestID, rawDataIndex = v.rawDataIndex, Objective=v.Objective});
						if(v.InteractType == "NPC") then
							ic = Icons["slay"].path;
						elseif(v.InteractType == "Object") then
							ic = Icons["object"].path
						elseif(v.InteractType == "Item") then
							ic = Icons["loot"].path
						elseif(v.InteractType == "Use") then
							ic = Icons["object"].path
						end
					local n = Questie:CreateNote(t, ic, Questie.AvailableQuestTooltipEnter, Questie.AvailableQuestClick, {NoteInfo=IconInfo})
					table.insert(Notes, n);
				end
			elseif(getn(zones)>1)then
				for v, z in zones do
					local points = {}
					for index, point in z do
						local nX, nY = Astrolabe:TranslateWorldMapPosition(point.c, point.z, point.x, point.y, continent, zone);
						points[index] = {};
						points[index].x = nX;
						points[index].y = nY;
						points[index].c = point.c;
						points[index].z = point.z;

					end
					local Spread = 0.03;
					local center = Questie:CenterPoint(points);
					--The spead is to great on zone 0 so lets not do it when its here.
					if(zone ~= 0) then
						for i = 1, table.getn(points) do	
							if(points[i].x < center.x) then
								points[i].x = points[i].x * (1-Spread);
							else
								points[i].x = points[i].x * (1+Spread);
							end

							if(points[i].y < center.y) then
								points[i].y = points[i].y * (1-Spread);
							else
								points[i].y = points[i].y * (1+Spread);
							end
						end
					end
					local hull = Polygon:jarvis_march(points);
					if(hull) then
						center = Questie:CenterPoint(hull);
						local u = {x=center.x,y=center.y,z=zone,c=continent};
						local sizeUnits = 1/WorldMapButton:GetWidth();
						local itt = ceil(-getn(IconList)/2);
						local IconInfo = {}
						local ic;
						local Color;
						for k, v in IconList do
							table.insert(IconInfo, {InteractType=v.InteractType, Qid = v.QuestID, rawDataIndex = v.rawDataIndex, Objective=v.Objective});
							if(v.InteractType == "NPC") then
								ic = Icons["slay"].path;
							elseif(v.InteractType == "Object") then
								ic = Icons["object"].path
							elseif(v.InteractType == "Item") then
								ic = Icons["loot"].path
							end
							--colorValue = mod(v.QuestID, colorSize); -- 0 - 4096
							if quests[v.QuestID] == nil then
							  quests[v.QuestID] = colorValue
							  colorValue = mod(colorValue + colorSize * Phi, colorSize)
							end
							Color = quests[v.QuestID];
						end
						--local n = Questie:CreateNote(center, icon, Questie.AvailableQuestTooltipEnter, Questie.AvailableQuestClick, {InteractType=Objective.type, NPCID = Objective.ID, Objective=Objective, QuestID = ID, rawDesc = Data.RawObjectives[index].desc});
						local FrameList;
						if(getn(points) > 3) then
							local R,G,B,A = hsvToRgb(Color / colorSize,1,0.9, 1);
							FrameList = Polygon:DrawPointList(hull, R,G,B);
						end
						colorValue = colorValue + colorSize*Phi;
						colorValue = mod(colorValue, colorSize);
						local n = Questie:CreateNote(u, ic, Questie.AvailableQuestTooltipEnter, Questie.AvailableQuestClick, {NoteInfo=IconInfo, Polygon_Frames=FrameList});
						table.insert(Notes, n);
						--table.insert(Notes, n);
					end
				end
			end
		end
	end
	return Notes;
end

 function hsvToRgb(h, s, v, a)
  local r, g, b
  local i = floor(h * 6);
  local f = h * 6 - i;
  local p = v * (1 - s);
  local q = v * (1 - f * s);
  local t = v * (1 - (1 - f) * s);
  i = mod(i, 6)
  if i == 0 then r, g, b = v, t, p
  elseif i == 1 then r, g, b = q, v, p
  elseif i == 2 then r, g, b = p, v, t
  elseif i == 3 then r, g, b = p, q, v
  elseif i == 4 then r, g, b = t, p, v
  elseif i == 5 then r, g, b = v, p, q
  end
  return r, g, b, a
end

function Questie:CreateNote(Pos, icon, Tooltip, Click, customData)
	Note = {};
	Note.x = Pos.x;
	Note.y = Pos.y;
	Note.zoneid = Pos.z;
	Note.continent = Pos.c;
	Note.icon = icon;
	Note.Tooltip = Tooltip;
	Note.Click = Click;
	if(customData.PolygonPoints or customData.Polygon_Frames) then
		Note.TooltipLeave = Questie.AvailableQuestTooltipLeave;
	end
	Note.customData = customData;
	return Note;
end



function Questie:TrackHook()
	local ID;
	if(IsAddOnLoaded("EQL3")) then
		ID = gsub(this:GetName(), "EQL3_QuestLogTitle","")
	else
		ID = gsub(this:GetName(), "QuestLogTitle", "");
	end
	ID = tonumber(ID);
	local set;
	--DEFAULT_CHAT_FRAME:AddMessage(ID);

	--Todo Take over EQL code stops this!
	local f = Old_QuestLogTitle[ID];
	if(f) then
		f();
	end
	DataStore_Quests_API:ForceUpdateQuestLog();
	Questie:ScheduleEvent("DelayedUpdate", 0.05);
	SelectQuestLogEntry(ID);
end






				--if(QuestAdded == nil) then
				--	local color = GetDifficultyColor(Quest.Level);
				--	GameTooltip:AddLine("["..Quest.Level.."] "..Quest.Title,color.r,color.g,color.b);
				--	QuestAdded = true;
				--end

--Hooks
function Questie:CreatureTooltip(this)
	local monster = UnitName("mouseover")
	local objective = GameTooltipTextLeft1:GetText();

	if(monster or objective) then
		local MouseoverObject = DB_Creatures[DB_CreatureLookup[monster]];
		if(MouseoverObject == nil) then
			MouseoverObject = DB_Gameobjects[DB_GameobjectLookup[objective]];
		end
		if(MouseoverObject) then
			local AddQuest;
			local objective = GameTooltipTextLeft1:GetText();
			local Strings = {};
			for ID, Data in DataStore_Quests_API:GetAllQuestsInLog() do
				local Quest = DB_Quests[ID];
				if(Quest.Objectives) then
					for index, Objective in Quest.Objectives do
						if(Objective.type == "NPC") then
							if(Objective.ID == MouseoverObject.ID) then
								local i, j, itemName, numItems, numNeeded = string.find(Data.RawObjectives[index].desc, "(.*):%s*([%d]+)%s*/%s*([%d]+)");
								if(Strings[Quest.ID] == nil) then Strings[Quest.ID] = {} end
								table.insert(Strings[Quest.ID], {text="  "..MouseoverObject.Name..": "..numItems.."/"..numNeeded, r=0,g=1,b=0});
								AddQuest = true;
							end
						elseif(Objective.type =="Item") then
							local Item = DB_Items[Objective.ID];
							if(Item and Item.Sources[MouseoverObject.ID]) then
								local i, j, itemName, numItems, numNeeded = string.find(Data.RawObjectives[index].desc, "(.*):%s*([%d]+)%s*/%s*([%d]+)");
								if(Strings[Quest.ID] == nil) then Strings[Quest.ID] = {} end
								table.insert(Strings[Quest.ID], {text="  "..Item.Name..": "..numItems.."/"..numNeeded, r=0,g=1,b=0});
								AddQuest = true;
							end
						end
					end
				end
			end

			for ID, StringHeap in Strings do
				local Quest = DB_Quests[ID];
				local color = GetDifficultyColor(Quest.Level);
				GameTooltip:AddLine(Quest.Title,color.r,color.g,color.b);
				for index, String in StringHeap do
					GameTooltip:AddLine(String.text, String.r,String.g,String.b);
				end
			end
		end
	end
	GameTooltip:Show();
end
Questie:HookScript(GameTooltip,"OnShow", Questie.CreatureTooltip); --TODO Does this work?

----------------------------------------
------Tooltip function for the hover over available quests.
----------------------------------------
function Questie:AvailableQuestTooltipEnter()
	local monster = UnitName("mouseover")
	local objective = GameTooltipTextLeft1:GetText();

	local Tooltip = GameTooltip;
	if(this.type == "WorldMapNote") then
		Tooltip = WorldMapTooltip;
	else
		Tooltip = GameTooltip;
	end
	Tooltip:SetOwner(this, this); --"ANCHOR_CURSOR"
	if(this.data.customData.CompleteQuests or this.data.customData.AvailableQuests) then
		local NPCorGO;
		if(this.data.customData.InteractType == "NPC") then
			NPCorGO = DB_Creatures[this.data.customData.NPCID];
		else
			NPCorGO = DB_Gameobjects[this.data.customData.NPCID];
		end
		--Tooltip code! NOT DONE!
		Tooltip:AddLine(NPCorGO.Name);
		if (getn(this.data.customData.CompleteQuests) > 0 and getn(this.data.customData.AvailableQuests) > 0) then
			Tooltip:AddLine("Available:");
		end
		for index, Qid in this.data.customData.AvailableQuests do
			local Quest = DB_Quests[Qid];
			local color = GetDifficultyColor(Quest.Level);
			Tooltip:AddLine("["..Quest.Level.."] "..Quest.Title, color.r,color.g,color.b);
		end
		if(getn(this.data.customData.CompleteQuests) > 0) then
			if (getn(this.data.customData.AvailableQuests) > 0) then
				Tooltip:AddLine("Complete:");
			end
			for index, Qid in this.data.customData.CompleteQuests do
				local Quest = DB_Quests[Qid];
				local color = GetDifficultyColor(Quest.Level);
				Tooltip:AddLine("["..Quest.Level.."] "..Quest.Title, color.r,color.g,color.b);
			end
		end
	elseif(this.data.customData.NoteInfo) then
		--NPCID = Objective.ID, Objective=Objective}
		local Done = {};
		for k , Data in this.data.customData.NoteInfo do
			if(Done[Data.Qid] == nil) then
				Done[Data.Qid] = true;
				local Quest = DB_Quests[Data.Qid];
				local color = GetDifficultyColor(Quest.Level);
				Tooltip:AddLine(Quest.Title, color.r,color.g,color.b);
				for r, Data2 in this.data.customData.NoteInfo do
					if(Data2.Qid == Data.Qid) then
						Tooltip:AddLine(DataStore_Quests_API:GetQuestByQuestID(Data.Qid).RawObjectives[Data2.rawDataIndex].desc);
					end
				end
			end
		end
		if(this.data.customData.Polygon_Frames) then
			for k, f in this.data.customData.Polygon_Frames do
				local r,g,b,a = f.texture:GetVertexColor();
				f.orgColor = {r=r,g=g,b=b,a=a};
				f.texture:SetVertexColor(1,1,1);
				--f.texture:SetAllPoints(f);
				--f:Hide();
				--f:Hide();
			end
		end

		--[[local NPCorGO;
		if(this.data.customData.InteractType == "NPC") then
			NPCorGO = DB_Creatures[this.data.customData.NPCID];
		else
			NPCorGO = DB_Gameobjects[this.data.customData.NPCID];
		end
		local Quest = DB_Quests[this.data.customData.QuestID];
		local color = GetDifficultyColor(Quest.Level);
		Tooltip:AddLine(Quest.Title, color.r,color.g,color.b);
		Tooltip:AddLine(this.data.customData.rawDesc);]]--
	end
	if(this.data.customData.AvailableQuests) then
		Tooltip:AddLine("Shift+Ctrl click to complete!")
	end
	Tooltip:SetFrameLevel(15);
	Tooltip:Show();

	if(this.data.customData.PolygonPoints) then
		Polygon:DrawPointList(this.data.customData.PolygonPoints, 1,1,1);
	end
end


local Tooltip_Gametooltip = GameTooltip:GetFrameLevel();
local Tooltip_WorldMapTooltip = WorldMapTooltip:GetFrameLevel();
function Questie:AvailableQuestTooltipLeave()
	if(this.data.customData.PolygonPoints) then
		Polygon:CLEAR_ALL_NOTES();
		BMS:Refresh(true);
	end
	if(this.data.customData.Polygon_Frames) then
		for k, f in this.data.customData.Polygon_Frames do
			f.texture:SetVertexColor(f.orgColor.r,f.orgColor.g,f.orgColor.b,f.orgColor.a);
		end
	end
	if(WorldMapTooltip) then WorldMapTooltip:Hide(); WorldMapTooltip:SetFrameLevel(Tooltip_Gametooltip); end 
	if(GameTooltip) then GameTooltip:Hide(); GameTooltip:SetFrameLevel(Tooltip_Gametooltip); end
end

----------------------------------------
------External call from BMS
----------------------------------------
function Questie:AvailableQuestClick()


	--DEFAULT_CHAT_FRAME:AddMessage(tostring(arg1).." "..tostring(button).." "..tostring(down)); Enable if you want to see what it prints.

	if ( IsShiftKeyDown() and IsControlKeyDown() and this.data.customData.AvailableQuests or this.data.customData.CompleteQuests ) then
		local Quest;
		for index, Qid in this.data.customData.AvailableQuests do
			Quest = DB_Quests[Qid];
			--DataStore_Quests_API:ForceCompleteQuest(Quest.ID);
			break;
		end
		if(Quest == nil) then
			for index, Qid in this.data.customData.CompleteQuests do
				Quest = DB_Quests[Qid];
				--DataStore_Quests_API:ForceCompleteQuest(Quest.ID);
				break;
			end
		end
		StaticPopupDialogs["QUESTIE_COMPLETE"] = {
		  text = "|cFFFF0000You are about to force complete |r\n'["..Quest.Level.."] "..Quest.Title.."' : "..Quest.ID.."\n|cFFFF0000Do you wish to continue?|r",
		  button1 = "Yes",
		  button2 = "No",
		  OnAccept = function()
		  	DataStore_Quests_API:ForceCompleteQuest(Quest.ID)
		  	Questie:ScheduleEvent("DelayedUpdate", 0.1);
			Questie:debug_Print("Completed quest '"..Quest.Title.."' with QuestID: "..Quest.ID);
		  end,
		  timeout = 0,
		  whileDead = true,
		  hideOnEscape = true,
		  parent = WorldMapFrame,
		  preferredIndex = 1,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
		}
		StaticPopup_Show ("QUESTIE_COMPLETE")
		local frame = StaticPopup_FindVisible("QUESTIE_COMPLETE");
		frame:SetParent(WorldMapFrame);
		frame:Show();
		return;
	elseif(arg1 == "LeftButton") then
		--TODO: Point Arrow to what was just clicked.
	end
	if(this.data.customData.NoteInfo == nil) then return; end
	for k, v in this.data.customData.NoteInfo do
		for k1, v1 in v do
			DEFAULT_CHAT_FRAME:AddMessage(k1.." : "..tostring(v1))
		end 
	end
end

function Questie:QuestLogEvents()
	Questie:ScheduleEvent("DelayedUpdate",0.5);
end

------------------------------------------
---------Gives smaller pointclouds from a big pointlist
------------------------------------------
function Questie:CalcHotzones(points, rangeR)
	if(points == nil) then return nil; end
    local allPoints = {};
    for k, v in points do
    	allPoints[k] = {c=v.c,z=v.z,x=v.x,y=v.y};
    end
    local range = rangeR or 10;
    local t = {};
    local itt = 0;
    while(true) do
    	local FoundUntouched = nil;
    	for k, v in allPoints do
    		if(v.touched == nil) then
    			local notes = {};
    			FoundUntouched = "true";
    			v.touched = true;
    			table.insert(notes, v);
    			for k2,v2 in allPoints do
    				local times = 1;
    				--TODO Better stuff!!!

    				if(v.x < 1.01 and v.y < 1.01) then times = 100; end
    				local dX = (v.x*times) - (v2.x*times)
    				local dY = (v.y*times) - (v2.y*times);
    				if(dX*dX + dY * dY < (range*range) and v2.touched == nil and v.c == v2.c and v.z == v2.z) then
    					v2.touched = true;
    					table.insert(notes, v2);
    				end
    			end
    			table.insert(t, notes);
    		end
    	end
    	if(FoundUntouched == nil) then
    		break;
    	end
    	itt = itt +1
    end
    return t;
end

--Debug print function
function Questie:debug_Print(...)
	local debugWin = 0;
	local name, shown;

	local out = "";
	for i = 1, arg.n, 1 do
		if (i > 1) then out = out .. ", "; end
		local t = type(arg[i]);
		if (t == "string") then
			out = out .. '"'..arg[i]..'"';
		elseif (t == "number") then
			out = out .. arg[i];
		else
			out = out .. dump(arg[i]);
		end
	end
	DEFAULT_CHAT_FRAME:AddMessage(out, 1.0, 1.0, 0.3);
end
